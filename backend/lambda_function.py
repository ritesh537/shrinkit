import json
import boto3
import base64
import io
import requests
from PIL import Image
import os
from datetime import datetime

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

BUCKET_NAME = os.environ.get('BUCKET_NAME', 'shrinkit-images')
RECAPTCHA_SECRET_KEY = os.environ.get('RECAPTCHA_SECRET_KEY', '')
RECAPTCHA_SCORE_THRESHOLD = float(os.environ.get('RECAPTCHA_SCORE_THRESHOLD', '0.5'))
VISITORS_TABLE = os.environ.get('VISITORS_TABLE', 'shrinkit-visitors')
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB - strict limit to prevent DoS

# Security: Only allow requests from authorized origins
ALLOWED_ORIGINS = [
    'https://shrinkit.goodvibes-app.com',
    'http://localhost:3000'  # Local development
]

def is_origin_allowed(origin):
    """Validate request origin (security check)"""
    if not origin:
        return False

    if origin in ALLOWED_ORIGINS:
        return True

    # Allow localhost variants for development
    if origin.startswith('http://localhost'):
        return True

    return False


def increment_visitor_count():
    """Increment and return total visitor count"""
    try:
        table = dynamodb.Table(VISITORS_TABLE)
        response = table.update_item(
            Key={'metric': 'total_visitors'},
            UpdateExpression='ADD visitor_count :inc',
            ExpressionAttributeValues={':inc': 1},
            ReturnValues='ALL_NEW'
        )
        return int(response['Attributes']['visitor_count'])
    except Exception as e:
        print(f"Error tracking visitors: {str(e)}")
        return 0


def get_visitor_count():
    """Get total visitor count"""
    try:
        table = dynamodb.Table(VISITORS_TABLE)
        response = table.get_item(Key={'metric': 'total_visitors'})
        if 'Item' in response:
            return int(response['Item']['visitor_count'])
        return 0
    except Exception as e:
        print(f"Error getting visitor count: {str(e)}")
        return 0


def lambda_handler(event, context):
    """Handle image upload and compression requests"""

    http_method = event.get('httpMethod', 'POST')
    path = event.get('path', '/')
    origin = event.get('headers', {}).get('origin', '')

    # Security: Validate origin (prevent API abuse from other websites)
    if not is_origin_allowed(origin):
        print(f"Rejected request from unauthorized origin: {origin}")
        return error_response('Unauthorized origin', 403)

    try:
        if path == '/compress' and http_method == 'POST':
            return handle_compress(event, context)
        elif path == '/health' and http_method == 'GET':
            return success_response({'status': 'healthy'})
        elif path == '/stats' and http_method == 'GET':
            # Track visitor and return stats
            visitor_count = increment_visitor_count()
            return success_response({'visitors': visitor_count})
        else:
            return error_response('Not found', 404)
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(str(e), 500)


def verify_recaptcha(recaptcha_token):
    """Verify reCAPTCHA token with Google"""
    if not RECAPTCHA_SECRET_KEY:
        return True  # Skip if no secret key configured

    try:
        response = requests.post(
            'https://www.google.com/recaptcha/api/siteverify',
            data={
                'secret': RECAPTCHA_SECRET_KEY,
                'response': recaptcha_token
            }
        )

        result = response.json()
        score = result.get('score', 0)

        if result.get('success') and score >= RECAPTCHA_SCORE_THRESHOLD:
            return True

        return False
    except Exception as e:
        print(f"reCAPTCHA verification error: {str(e)}")
        return False


def handle_compress(event, context):
    """Compress image to target size"""

    try:
        body = event.get('body', '{}')
        if event.get('isBase64Encoded'):
            body = base64.b64decode(body)
        else:
            body = body.encode('utf-8')

        # Parse multipart form data
        image_data, target_size, recaptcha_token = parse_multipart_form(event)
        if not image_data:
            return error_response('No image provided', 400)

        # Validate file size (strict 10MB limit)
        if len(image_data) > MAX_FILE_SIZE:
            size_mb = len(image_data) / (1024 * 1024)
            return error_response(
                f'File too large: {size_mb:.2f}MB. Maximum size is 10MB',
                413  # Payload Too Large
            )

        # Verify reCAPTCHA if configured
        if not verify_recaptcha(recaptcha_token):
            return error_response('reCAPTCHA verification failed', 403)

        # Validate target size
        target_size_kb = int(target_size) if target_size else 500
        if target_size_kb <= 0:
            return error_response('Target size must be greater than 0', 400)

        target_size_bytes = target_size_kb * 1024

        # Open image and get format
        image = Image.open(io.BytesIO(image_data))
        original_format = image.format or 'JPEG'

        # Compress image
        compressed_data = compress_image(image, target_size_bytes, original_format)

        # Store in S3
        file_key = f"images/{datetime.now().timestamp()}.{original_format.lower()}"
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=file_key,
            Body=compressed_data,
            ContentType=f'image/{original_format.lower()}'
        )

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': f'image/{original_format.lower()}',
                'Content-Length': str(len(compressed_data))
            },
            'body': base64.b64encode(compressed_data).decode('utf-8'),
            'isBase64Encoded': True
        }

    except Exception as e:
        print(f"Compression error: {str(e)}")
        return error_response(f'Error compressing image: {str(e)}', 400)


def compress_image(image, target_size, format_type):
    """Compress image to target size"""

    # Convert RGBA to RGB if needed
    if image.mode == 'RGBA':
        image = image.convert('RGB')

    # Start with quality 85
    quality = 85
    max_iterations = 20
    iteration = 0

    while iteration < max_iterations:
        output = io.BytesIO()
        image.save(
            output,
            format=format_type,
            quality=quality,
            optimize=True
        )

        file_size = output.tell()

        # Check if we're close to target
        if file_size <= target_size:
            output.seek(0)
            return output.getvalue()

        # Reduce quality for next iteration
        quality = max(1, int(quality * 0.9))
        iteration += 1

    # If still too large after quality reduction, resize image
    if output.tell() > target_size:
        scale = (target_size / output.tell()) ** 0.5
        new_width = int(image.width * scale)
        new_height = int(image.height * scale)

        resized = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
        output = io.BytesIO()
        resized.save(
            output,
            format=format_type,
            quality=85,
            optimize=True
        )

    output.seek(0)
    return output.getvalue()


def parse_multipart_form(event):
    """Parse multipart form data from API Gateway"""

    body = event.get('body', '')
    is_base64 = event.get('isBase64Encoded', False)

    if is_base64:
        body = base64.b64decode(body)
    else:
        body = body.encode('utf-8')

    headers = event.get('headers', {})
    content_type = headers.get('content-type', '') or headers.get('Content-Type', '')

    if 'multipart/form-data' not in content_type:
        return None, None, None

    # Extract boundary
    boundary = content_type.split('boundary=')[1].encode('utf-8')

    # Split by boundary
    parts = body.split(b'--' + boundary)

    image_data = None
    target_size = None
    recaptcha_token = None

    for part in parts:
        if b'Content-Disposition' not in part:
            continue

        # Extract form field name
        if b'filename=' in part:
            # This is the file part
            image_data = part.split(b'\r\n\r\n')[1].split(b'\r\n--')[0]
        elif b'name="targetSize"' in part:
            # This is the targetSize field
            target_size = part.split(b'\r\n\r\n')[1].split(b'\r\n--')[0].decode('utf-8').strip()
        elif b'name="recaptchaToken"' in part:
            # This is the reCAPTCHA token
            recaptcha_token = part.split(b'\r\n\r\n')[1].split(b'\r\n--')[0].decode('utf-8').strip()

    return image_data, target_size, recaptcha_token


def success_response(body):
    """Return success response"""
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(body)
    }


def error_response(message, status_code=400):
    """Return error response"""
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'error': message})
    }

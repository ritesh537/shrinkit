# ShinkIt - Image Compression Tool

A serverless web application to compress images using AWS S3, Lambda, and API Gateway.

## Features

- Upload JPG, JPEG, PNG images
- View original file size
- Compress to target size
- Download compressed image
- Automatic cleanup (1-day retention)

## Project Structure

```
shrinkit/
├── frontend/          # React web app
├── backend/           # Python Lambda function
├── terraform/         # Infrastructure as Code
└── README.md
```

## Setup

### Prerequisites
- Node.js (v16+)
- Python 3.9+
- Terraform
- AWS CLI configured with credentials

### Deployment

1. **Deploy Infrastructure (Terraform)**
```bash
cd terraform
terraform init
terraform apply
```

2. **Deploy Backend (Lambda)**
```bash
cd backend
pip install -r requirements.txt -t package/
cd package && zip -r ../lambda.zip . && cd ..
zip lambda.zip lambda_function.py
# Upload via Terraform or AWS Console
```

3. **Deploy Frontend (React)**
```bash
cd frontend
npm install
npm run build
# Deploy to S3/CloudFront or your hosting
```

## Environment Variables

Frontend `.env`:
```
REACT_APP_API_ENDPOINT=<API Gateway URL from Terraform>
```

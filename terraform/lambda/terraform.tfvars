aws_region    = "ap-southeast-2"
project_name  = "shrinkit"
environment   = "dev"

# Lambda configuration
lambda_zip_path = "../../backend/lambda.zip"
lambda_timeout  = 60
lambda_memory   = 1024

# From S3 deployment (terraform/s3/outputs)
# After deploying S3, copy these values here:
s3_bucket_name = "shrinkit-images-ACCOUNT_ID"  # Get from: terraform -chdir=../s3 output bucket_name
s3_bucket_arn  = "arn:aws:s3:::shrinkit-images-ACCOUNT_ID"  # Get from: terraform -chdir=../s3 output bucket_arn

# reCAPTCHA (from Google Admin Console)
recaptcha_secret_key     = ""  # https://www.google.com/recaptcha/admin
recaptcha_score_threshold = "0.5"


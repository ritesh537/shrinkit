aws_region   = "ap-south-1"
project_name = "shrinkit"
environment  = "dev"

# From Lambda deployment (terraform/lambda/outputs)
# After deploying Lambda, copy these values here:
lambda_function_name = "shrinkit-compressor-dev"  # Get from: terraform -chdir=../lambda output function_name
lambda_function_arn  = "arn:aws:lambda:ap-south-1:ACCOUNT_ID:function:shrinkit-compressor-dev"  # Get from: terraform -chdir=../lambda output function_arn

# API Gateway throttling
throttle_burst_limit = 10  # Concurrent requests
throttle_rate_limit  = 10  # Requests per second (600 per minute)


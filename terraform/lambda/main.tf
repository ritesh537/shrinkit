terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-lambda-role"
    Module  = "lambda"
    Environment = var.environment
  }
}

# Lambda basic execution policy (for CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 access policy for Lambda
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}-lambda-s3-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "compressor" {
  filename      = var.lambda_zip_path
  function_name = "${var.project_name}-compressor-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  environment {
    variables = {
      BUCKET_NAME              = var.s3_bucket_name
      RECAPTCHA_SECRET_KEY     = var.recaptcha_secret_key
      RECAPTCHA_SCORE_THRESHOLD = var.recaptcha_score_threshold
      VISITORS_TABLE           = aws_dynamodb_table.visitors.name
    }
  }

  tags = {
    Name        = "${var.project_name}-compressor"
    Module      = "lambda"
    Environment = var.environment
  }

  depends_on = [aws_iam_role_policy.lambda_s3_policy]
}


# DynamoDB table for visitor counting
resource "aws_dynamodb_table" "visitors" {
  name           = "${var.project_name}-visitors-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "metric"

  attribute {
    name = "metric"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-visitors"
    Module      = "lambda"
    Environment = var.environment
  }
}

# DynamoDB permission for Lambda
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-lambda-dynamodb-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitors.arn
      }
    ]
  })
}

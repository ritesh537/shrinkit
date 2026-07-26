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

# API Gateway HTTP API (Compression endpoint only)
# Frontend served via GitHub Pages (no rate limiting on static files)
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-compress-api-${var.environment}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://shrinkit.goodvibes-app.com"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Module      = "api-gateway"
    Environment = var.environment
  }
}

# Lambda integration (for API endpoints only)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id              = aws_apigatewayv2_api.api.id
  integration_type    = "AWS_PROXY"
  integration_method  = "POST"
  payload_format_version = "2.0"
  target              = var.lambda_function_arn
}

# POST /compress route (image compression with rate limiting)
# Payload size validated in Lambda (10MB limit)
resource "aws_apigatewayv2_route" "compress" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /compress"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# GET /health route (health check)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# GET /stats route (visitor counter)
resource "aws_apigatewayv2_route" "stats" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /stats"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# API Gateway stage with throttling
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.environment
  auto_deploy = true

  # Rate limiting (applies ONLY to /compress and /health endpoints)
  # Frontend files served directly from S3 (no rate limiting)
  throttle_settings {
    burst_limit = var.throttle_burst_limit    # 10 concurrent
    rate_limit  = var.throttle_rate_limit     # 10 per second (600 per minute)
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Module      = "api-gateway"
    Environment = var.environment
  }
}

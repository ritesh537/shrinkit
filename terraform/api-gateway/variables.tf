variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "shrinkit"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Lambda configuration (from Lambda module)
variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_function_arn" {
  description = "Lambda function ARN"
  type        = string
}

# Throttling configuration
variable "throttle_burst_limit" {
  description = "API Gateway burst limit (concurrent requests)"
  type        = number
  default     = 10
}

variable "throttle_rate_limit" {
  description = "API Gateway rate limit (requests per second)"
  type        = number
  default     = 10
}


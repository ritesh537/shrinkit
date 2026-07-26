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

variable "lambda_zip_path" {
  description = "Path to Lambda function zip file"
  type        = string
  default     = "../../backend/lambda.zip"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 1024
}

# S3 bucket details (from S3 module)
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

# reCAPTCHA configuration
variable "recaptcha_secret_key" {
  description = "reCAPTCHA v3 secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "recaptcha_score_threshold" {
  description = "reCAPTCHA score threshold (0-1)"
  type        = string
  default     = "0.5"
}

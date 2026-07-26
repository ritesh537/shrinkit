variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
  default     = "../backend/lambda.zip"
}

variable "recaptcha_secret_key" {
  description = "reCAPTCHA v3 secret key from Google"
  type        = string
  sensitive   = true
  default     = ""
}

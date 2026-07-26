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

variable "retention_days" {
  description = "Number of days to retain images in S3"
  type        = number
  default     = 1
}

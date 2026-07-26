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

# S3 Bucket for storing images
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-images"
    Environment = var.environment
    Module      = "s3"
  }
}

# Enable versioning (optional)
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Lifecycle policy: Delete objects after 1 day
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "delete-old-images"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }
  }
}

# Block public access (Images)
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

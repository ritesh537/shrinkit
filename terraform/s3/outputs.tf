# Images Bucket Outputs
output "images_bucket_name" {
  description = "Images S3 bucket name (private, 1-day retention)"
  value       = aws_s3_bucket.images.id
}

output "images_bucket_arn" {
  description = "Images S3 bucket ARN"
  value       = aws_s3_bucket.images.arn
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

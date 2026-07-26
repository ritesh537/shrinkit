output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.api.invoke_url
}

output "s3_bucket_name" {
  description = "S3 bucket name for images"
  value       = aws_s3_bucket.images.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.compressor.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.compressor.arn
}

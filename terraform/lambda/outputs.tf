output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.compressor.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.compressor.arn
}

output "function_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

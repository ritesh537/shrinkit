output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.api.invoke_url
}

output "api_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.api.id
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_apigatewayv2_stage.api.name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

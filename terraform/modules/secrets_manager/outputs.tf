# Secrets Manager Module Outputs

output "opensearch_secret_arn" {
  description = "ARN of the OpenSearch credentials secret"
  value       = aws_secretsmanager_secret.opensearch_credentials.arn
}

output "opensearch_secret_name" {
  description = "Name of the OpenSearch credentials secret"
  value       = aws_secretsmanager_secret.opensearch_credentials.name
}

output "auth_secret_arn" {
  description = "ARN of the authentication settings secret"
  value       = var.auth_enabled ? aws_secretsmanager_secret.auth_settings[0].arn : null
}

output "auth_secret_name" {
  description = "Name of the authentication settings secret"
  value       = var.auth_enabled ? aws_secretsmanager_secret.auth_settings[0].name : null
}
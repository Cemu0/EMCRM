# Cognito Module Outputs

output "main_user_pool_id" {
  description = "ID of the main Cognito User Pool"
  value       = var.auth_enabled ? aws_cognito_user_pool.main_user_pool[0].id : null
}

output "main_client_id" {
  description = "ID of the main Cognito User Pool Client"
  value       = var.auth_enabled ? aws_cognito_user_pool_client.main_client[0].id : null
}

output "main_client_secret" {
  description = "Secret of the main Cognito User Pool Client"
  value       = var.auth_enabled ? aws_cognito_user_pool_client.main_client[0].client_secret : null
  sensitive   = true
}

output "main_domain" {
  description = "Cognito User Pool Domain"
  value       = var.auth_enabled ? aws_cognito_user_pool_domain.main_domain[0].domain : null
}

output "main_login_url" {
  description = "Cognito Login URL"
  value       = var.auth_enabled ? "https://${aws_cognito_user_pool_domain.main_domain[0].domain}.auth.${var.aws_region}.amazoncognito.com/login" : null
}

output "opensearch_user_pool_id" {
  description = "ID of the OpenSearch Cognito User Pool"
  value       = var.opensearch_cognito_enabled ? aws_cognito_user_pool.opensearch_users[0].id : null
}

output "opensearch_client_id" {
  description = "ID of the OpenSearch Cognito User Pool Client"
  value       = var.opensearch_cognito_enabled ? aws_cognito_user_pool_client.opensearch_client[0].id : null
}

output "opensearch_identity_pool_id" {
  description = "ID of the OpenSearch Cognito Identity Pool"
  value       = var.opensearch_cognito_enabled ? aws_cognito_identity_pool.opensearch_identity_pool[0].id : null
}
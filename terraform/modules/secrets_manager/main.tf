# Secrets Manager Module
# Manages sensitive credentials for OpenSearch and authentication

# OpenSearch credentials secret
resource "aws_secretsmanager_secret" "opensearch_credentials" {
  name        = "emcrm-opensearch-credentials-${var.environment}"
  description = "OpenSearch master user credentials"
  
  tags = {
    Name        = "EMCRM OpenSearch Credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "opensearch_credentials" {
  secret_id = aws_secretsmanager_secret.opensearch_credentials.id
  secret_string = jsonencode({
    username = var.opensearch_username
    password = var.opensearch_password
  })
}

# Authentication settings secret (conditionally created)
resource "aws_secretsmanager_secret" "auth_settings" {
  count       = var.auth_enabled ? 1 : 0
  name        = "emcrm-auth-settings-${var.environment}"
  description = "Authentication settings for EMCRM"
  
  tags = {
    Name        = "EMCRM Auth Settings"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "auth_settings" {
  count     = var.auth_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.auth_settings[0].id
  secret_string = jsonencode({
    cognito_user_pool_id     = var.cognito_user_pool_id
    cognito_client_id        = var.cognito_client_id
    cognito_client_secret    = var.cognito_client_secret
    cognito_domain          = var.cognito_domain
    jwt_secret              = var.jwt_secret
  })
}
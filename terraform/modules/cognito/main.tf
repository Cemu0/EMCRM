# Cognito Module
# Creates Cognito user pools for main application and OpenSearch

# Random string for unique domain suffix
resource "random_string" "cognito_domain_suffix" {
  count   = var.auth_enabled ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Main Application Cognito User Pool
resource "aws_cognito_user_pool" "main_user_pool" {
  count = var.auth_enabled ? 1 : 0
  name  = "emcrm-main-users-${var.environment}"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }
  
  auto_verified_attributes = ["email"]
  
  username_attributes = ["email"]
  
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  tags = {
    Name        = "EMCRM Main User Pool"
    Environment = var.environment
  }
}

# Main Application Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main_client" {
  count        = var.auth_enabled ? 1 : 0
  name         = "emcrm-main-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main_user_pool[0].id
  
  generate_secret = true
  
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "phone"]
  
  callback_urls = [
    "http://localhost:8080/auth/callback",
    "https://${var.domain_name != "" ? var.domain_name : var.load_balancer_dns_name}/auth/callback"
  ]
  
  logout_urls = [
    "http://localhost:8080",
    "https://${var.domain_name != "" ? var.domain_name : var.load_balancer_dns_name}"
  ]
  
  supported_identity_providers = ["COGNITO"]
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# Main Application Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main_domain" {
  count        = var.auth_enabled ? 1 : 0
  domain       = "emcrm-auth-${var.environment}-${random_string.cognito_domain_suffix[0].result}"
  user_pool_id = aws_cognito_user_pool.main_user_pool[0].id
}

# OpenSearch Dashboard Cognito configuration (optional)
resource "aws_cognito_user_pool" "opensearch_users" {
  count = var.opensearch_cognito_enabled ? 1 : 0
  name  = "emcrm-opensearch-users"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  
  tags = {
    Name        = "EMCRM OpenSearch User Pool"
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_domain" "opensearch_domain" {
  count        = var.opensearch_cognito_enabled ? 1 : 0
  domain       = "emcrm-opensearch-${var.environment}"
  user_pool_id = aws_cognito_user_pool.opensearch_users[0].id
}

resource "aws_cognito_identity_pool" "opensearch_identity_pool" {
  count                            = var.opensearch_cognito_enabled ? 1 : 0
  identity_pool_name               = "emcrm_opensearch_identity_pool"
  allow_unauthenticated_identities = false
  
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.opensearch_client[0].id
    provider_name           = aws_cognito_user_pool.opensearch_users[0].endpoint
    server_side_token_check = false
  }
  
  tags = {
    Name        = "EMCRM OpenSearch Identity Pool"
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "opensearch_client" {
  count                                = var.opensearch_cognito_enabled ? 1 : 0
  name                                 = "opensearch-dashboards"
  user_pool_id                         = aws_cognito_user_pool.opensearch_users[0].id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  callback_urls                        = ["https://${var.opensearch_endpoint}/_dashboards/app/home"]
  supported_identity_providers         = ["COGNITO"]
}
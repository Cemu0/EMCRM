# Secrets Manager Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "opensearch_username" {
  description = "OpenSearch master username"
  type        = string
}

variable "opensearch_password" {
  description = "OpenSearch master password"
  type        = string
  sensitive   = true
}

variable "auth_enabled" {
  description = "Whether authentication is enabled"
  type        = bool
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "cognito_client_id" {
  description = "Cognito Client ID"
  type        = string
  default     = ""
}

variable "cognito_client_secret" {
  description = "Cognito Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_domain" {
  description = "Cognito Domain"
  type        = string
  default     = ""
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  default     = ""
  sensitive   = true
}
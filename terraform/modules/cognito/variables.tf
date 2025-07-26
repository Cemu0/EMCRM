# Cognito Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "auth_enabled" {
  description = "Whether authentication is enabled"
  type        = bool
}

variable "domain_name" {
  description = "Custom domain name for the application"
  type        = string
  default     = ""
}

variable "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  type        = string
}

variable "opensearch_cognito_enabled" {
  description = "Whether to enable Cognito for OpenSearch"
  type        = bool
  default     = false
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  type        = string
  default     = ""
}
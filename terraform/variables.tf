variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "create_vpc" {
  description = "Whether to create a new VPC or use an existing one"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy to (only used when create_vpc is false)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDR blocks must be provided for high availability."
  }
}

variable "subnet_ids" {
  description = "The IDs of the subnets to deploy to (only used when create_vpc is false)"
  type        = list(string)
  default     = []
}

variable "dynamodb_main_table_name" {
  description = "The name of the main DynamoDB table"
  type        = string
  default     = "crm_data"
}

variable "dynamodb_email_table_name" {
  description = "The name of the email DynamoDB table"
  type        = string
  default     = "email_data"
}

# OpenSearch Configuration Variables
variable "opensearch_domain_name" {
  description = "The name of the OpenSearch domain"
  type        = string
  default     = "emcrm"
}

variable "opensearch_engine_version" {
  description = "The version of OpenSearch to deploy"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "opensearch_host" {
  description = "The host of the OpenSearch domain (used for existing domains)"
  type        = string
  default     = ""
}

variable "opensearch_username" {
  description = "The username for OpenSearch"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "opensearch_password" {
  description = "The password for OpenSearch"
  type        = string
  sensitive   = true
}

variable "opensearch_instance_type" {
  description = "The instance type for OpenSearch"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "The number of instances in the OpenSearch cluster"
  type        = number
  default     = 1
}

# Simplified OpenSearch Configuration for MVP
variable "opensearch_vpc_enabled" {
  description = "Whether to deploy OpenSearch within a VPC (false for simpler MVP deployment)"
  type        = bool
  default     = false
}

variable "opensearch_allowed_cidr_blocks" {
  description = "List of CIDR blocks to allow access to the OpenSearch domain"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "existing_vpc_id" {
  description = "The ID of an existing VPC to use (when not creating a new VPC)"
  type        = string
  default     = ""
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs to use (when not creating a new VPC)"
  type        = list(string)
  default     = []
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
  default     = "default-jwt-secret-change-in-production"
}

variable "opensearch_log_publishing_enabled" {
  description = "Whether to enable log publishing for OpenSearch"
  type        = bool
  default     = true
}

variable "opensearch_cognito_enabled" {
  description = "Whether to enable Cognito authentication for OpenSearch Dashboards"
  type        = bool
  default     = false
}

variable "container_cpu" {
  description = "The amount of CPU to allocate to the container"
  type        = string
  default     = "256"
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container"
  type        = string
  default     = "512"
}

variable "service_desired_count" {
  description = "The desired number of instances of the task"
  type        = number
  default     = 2
}

variable "cognito_user_pool_id" {
  description = "AWS Cognito User Pool ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_client_id" {
  description = "AWS Cognito Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_client_secret" {
  description = "AWS Cognito Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "auth_enabled" {
  description = "Enable authentication and create Cognito resources"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "force_destroy_resources" {
  description = "Force destroy resources that might have dependencies"
  type        = bool
  default     = true
}

variable "manage_domain_records" {
  description = "Whether to manage Route53 domain records (set to false to preserve existing CNAME records)"
  type        = bool
  default     = true
}

variable "preserve_ssl_cname" {
  description = "Whether to preserve SSL validation CNAME records during destroy"
  type        = bool
  default     = true
}
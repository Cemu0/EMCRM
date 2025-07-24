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

variable "vpc_id" {
  description = "The ID of the VPC to deploy to"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets to deploy to"
  type        = list(string)
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

variable "opensearch_dedicated_master_enabled" {
  description = "Whether to enable dedicated master nodes"
  type        = bool
  default     = false
}

variable "opensearch_dedicated_master_count" {
  description = "The number of dedicated master nodes"
  type        = number
  default     = 3
}

variable "opensearch_dedicated_master_type" {
  description = "The instance type of the dedicated master nodes"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_warm_enabled" {
  description = "Whether to enable warm nodes"
  type        = bool
  default     = false
}

variable "opensearch_warm_count" {
  description = "The number of warm nodes"
  type        = number
  default     = 2
}

variable "opensearch_warm_type" {
  description = "The instance type of the warm nodes"
  type        = string
  default     = "ultrawarm1.medium.search"
}

variable "opensearch_vpc_enabled" {
  description = "Whether to deploy OpenSearch within a VPC"
  type        = bool
  default     = false
}

variable "opensearch_volume_type" {
  description = "The EBS volume type for OpenSearch"
  type        = string
  default     = "gp3"
}

variable "opensearch_volume_size" {
  description = "The size of the EBS volume for OpenSearch in GB"
  type        = number
  default     = 10
}

variable "opensearch_volume_iops" {
  description = "The IOPS for the EBS volume (only applicable for gp3 or io1 volume types)"
  type        = number
  default     = 3000
}

variable "opensearch_kms_key_id" {
  description = "The KMS key ID to encrypt the OpenSearch domain with"
  type        = string
  default     = null
}

variable "opensearch_custom_endpoint_enabled" {
  description = "Whether to enable a custom endpoint for OpenSearch"
  type        = bool
  default     = false
}

variable "opensearch_custom_endpoint" {
  description = "The custom endpoint for OpenSearch"
  type        = string
  default     = ""
}

variable "opensearch_custom_endpoint_certificate_arn" {
  description = "The ARN of the ACM certificate for the custom endpoint"
  type        = string
  default     = ""
}

variable "opensearch_auto_tune_enabled" {
  description = "Whether to enable Auto-Tune for OpenSearch"
  type        = bool
  default     = true
}

variable "opensearch_allowed_cidr_blocks" {
  description = "List of CIDR blocks to allow access to the OpenSearch domain"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
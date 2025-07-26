# IAM Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "crm_table_arn" {
  description = "ARN of the CRM DynamoDB table"
  type        = string
}

variable "email_table_arn" {
  description = "ARN of the email DynamoDB table"
  type        = string
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs"
  type        = list(string)
}
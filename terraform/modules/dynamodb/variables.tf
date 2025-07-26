# DynamoDB Module Variables

variable "dynamodb_main_table_name" {
  description = "Name of the main DynamoDB table"
  type        = string
}

variable "dynamodb_email_table_name" {
  description = "Name of the email DynamoDB table"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
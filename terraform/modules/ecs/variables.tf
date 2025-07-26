# ECS Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = string
}

variable "container_memory" {
  description = "Memory for the container"
  type        = string
}

variable "service_desired_count" {
  description = "Desired number of ECS service instances"
  type        = number
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "dynamodb_main_table_name" {
  description = "Name of the main DynamoDB table"
  type        = string
}

variable "dynamodb_email_table_name" {
  description = "Name of the email DynamoDB table"
  type        = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  type        = string
}

variable "opensearch_vpc_enabled" {
  description = "Whether OpenSearch is deployed in VPC"
  type        = bool
}

variable "auth_enabled" {
  description = "Whether authentication is enabled"
  type        = bool
}

variable "opensearch_secret_arn" {
  description = "ARN of the OpenSearch secrets"
  type        = string
}

variable "auth_secret_arn" {
  description = "ARN of the auth secrets"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
}

variable "lb_listener_arn" {
  description = "ARN of the load balancer listener"
  type        = string
}
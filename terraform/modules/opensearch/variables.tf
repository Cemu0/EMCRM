# OpenSearch Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
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



variable "opensearch_domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
}

variable "opensearch_engine_version" {
  description = "OpenSearch engine version"
  type        = string
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type"
  type        = string
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
}

variable "opensearch_vpc_enabled" {
  description = "Whether to deploy OpenSearch in VPC"
  type        = bool
}

# Simplified variables for MVP
variable "opensearch_username" {
  description = "OpenSearch master username"
  type        = string
}

variable "opensearch_password" {
  description = "OpenSearch master password"
  type        = string
  sensitive   = true
}
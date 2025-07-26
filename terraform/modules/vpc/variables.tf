# VPC Module Variables

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing one"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "existing_vpc_id" {
  description = "ID of existing VPC (used when create_vpc is false)"
  type        = string
  default     = ""
}

variable "existing_subnet_ids" {
  description = "IDs of existing subnets (used when create_vpc is false)"
  type        = list(string)
  default     = []
}
# VPC Module Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = var.create_vpc ? aws_subnet.public[*].id : var.existing_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.create_vpc ? aws_internet_gateway.main[0].id : null
}

output "route_table_id" {
  description = "ID of the public route table"
  value       = var.create_vpc ? aws_route_table.public[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : null
}
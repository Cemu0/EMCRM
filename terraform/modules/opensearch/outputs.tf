# OpenSearch Module Outputs

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.emcrm_domain.arn
}

output "domain_id" {
  description = "ID of the OpenSearch domain"
  value       = aws_opensearch_domain.emcrm_domain.domain_id
}

output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.emcrm_domain.domain_name
}

output "endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests"
  value       = aws_opensearch_domain.emcrm_domain.endpoint
}

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for OpenSearch Dashboards"
  value       = "${aws_opensearch_domain.emcrm_domain.endpoint}/_dashboards/"
}

output "security_group_id" {
  description = "ID of the OpenSearch security group"
  value       = var.opensearch_vpc_enabled ? aws_security_group.opensearch_sg[0].id : null
}
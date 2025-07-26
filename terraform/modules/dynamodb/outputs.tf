# DynamoDB Module Outputs

output "crm_table_name" {
  description = "Name of the CRM data table"
  value       = aws_dynamodb_table.crm_data.name
}

output "crm_table_arn" {
  description = "ARN of the CRM data table"
  value       = aws_dynamodb_table.crm_data.arn
}

output "email_table_name" {
  description = "Name of the email data table"
  value       = aws_dynamodb_table.email_data.name
}

output "email_table_arn" {
  description = "ARN of the email data table"
  value       = aws_dynamodb_table.email_data.arn
}
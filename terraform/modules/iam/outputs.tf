# IAM Module Outputs

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "dynamodb_policy_arn" {
  description = "ARN of the DynamoDB policy"
  value       = aws_iam_policy.dynamodb_policy.arn
}

output "secrets_manager_policy_arn" {
  description = "ARN of the Secrets Manager policy"
  value       = aws_iam_policy.secrets_manager_policy.arn
}
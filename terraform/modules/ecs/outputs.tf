# ECS Module Outputs

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.emcrm_cluster.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.emcrm_cluster.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.emcrm_service.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.emcrm_task.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.emcrm_app.repository_url
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs_sg.id
}
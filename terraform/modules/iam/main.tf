# IAM Module
# Creates IAM roles and policies for ECS tasks and services

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "emcrm-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EMCRM ECS Execution Role"
    Environment = var.environment
  }
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "emcrm-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EMCRM ECS Task Role"
    Environment = var.environment
  }
}

# DynamoDB Policy
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "emcrm-dynamodb-policy"
  description = "Policy for DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Effect = "Allow"
        Resource = [
          var.crm_table_arn,
          "${var.crm_table_arn}/index/*",
          var.email_table_arn,
          "${var.email_table_arn}/index/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "EMCRM DynamoDB Policy"
    Environment = var.environment
  }
}

# Secrets Manager Policy
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "emcrm-secrets-manager-policy"
  description = "Policy for Secrets Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = var.secrets_manager_arns
      }
    ]
  })

  tags = {
    Name        = "EMCRM Secrets Manager Policy"
    Environment = var.environment
  }
}

# Policy Attachments
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_manager_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

# IAM Service Linked Role for OpenSearch
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service Linked Role for Amazon OpenSearch Service"
}
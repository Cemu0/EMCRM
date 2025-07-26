# ECS Module
# Creates ECS cluster, task definition, service, and ECR repository

# ECR Repository for Docker Images
resource "aws_ecr_repository" "emcrm_app" {
  name                 = "emcrm-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Add this line

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "EMCRM App Repository"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "emcrm_cluster" {
  name = "emcrm-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "EMCRM Cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "emcrm_logs" {
  name              = "/ecs/emcrm"
  retention_in_days = 30

  tags = {
    Name        = "EMCRM Logs"
    Environment = var.environment
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_sg" {
  name        = "emcrm-ecs-sg"
  description = "Security group for EMCRM ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EMCRM ECS Security Group"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "emcrm_task" {
  family                   = "emcrm-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "emcrm-app"
      image     = "${aws_ecr_repository.emcrm_app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        # Database Configuration (non-sensitive)
        { name = "DB_AWS_REGION", value = var.aws_region },
        { name = "DB_MAIN_TABLE_NAME", value = var.dynamodb_main_table_name },
        { name = "DB_EMAIL_TABLE_NAME", value = var.dynamodb_email_table_name },
        { name = "DB_MAX_RETRIES", value = "2" },
        { name = "DB_CONNECT_TIMEOUT", value = "5" },
        { name = "DB_READ_TIMEOUT", value = "10" },
        { name = "DB_MAX_POOL_CONNECTIONS", value = "10" },
        
        # OpenSearch Configuration (non-sensitive)
        { name = "OPENSEARCH_MODE", value = "cloud" },
        { name = "OPENSEARCH_HOST", value = var.opensearch_endpoint },
        { name = "OPENSEARCH_PORT", value = "443" },
        { name = "OPENSEARCH_USE_SSL", value = "true" },
        { name = "OPENSEARCH_VERIFY_CERTS", value = var.opensearch_vpc_enabled ? "false" : "true" },
        
        # Application Configuration
        { name = "APP_NAME", value = "EMCRM" },
        { name = "APP_DEBUG", value = "false" },
        { name = "APP_LOG_LEVEL", value = "INFO" },
        { name = "APP_API_PORT", value = "8080" },
        { name = "APP_API_HOST", value = "0.0.0.0" },
        { name = "APP_PRODUCTION", value = "true" },  # ADD THIS LINE
        
        # Authentication Configuration (non-sensitive)
        { name = "AUTH_ENABLED", value = var.auth_enabled ? "true" : "false" },
        { name = "AUTH_COGNITO_REGION", value = var.aws_region },
        { name = "AUTH_JWT_ALGORITHM", value = "RS256" },
        { name = "AUTH_TOKEN_EXPIRY_HOURS", value = "24" }
      ]
      secrets = [
        # OpenSearch Credentials (sensitive)
        { name = "OPENSEARCH_USERNAME", valueFrom = "${var.opensearch_secret_arn}:username::" },
        { name = "OPENSEARCH_PASSWORD", valueFrom = "${var.opensearch_secret_arn}:password::" },
        
        # Authentication Settings (sensitive)
        { name = "AUTH_COGNITO_USER_POOL_ID", valueFrom = "${var.auth_secret_arn}:cognito_user_pool_id::" },
        { name = "AUTH_COGNITO_CLIENT_ID", valueFrom = "${var.auth_secret_arn}:cognito_client_id::" },
        { name = "AUTH_COGNITO_CLIENT_SECRET", valueFrom = "${var.auth_secret_arn}:cognito_client_secret::" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.emcrm_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "EMCRM Task Definition"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "emcrm_service" {
  name            = "emcrm-service"
  cluster         = aws_ecs_cluster.emcrm_cluster.id
  task_definition = aws_ecs_task_definition.emcrm_task.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "emcrm-app"
    container_port   = 8080
  }

  depends_on = [var.lb_listener_arn]

  tags = {
    Name        = "EMCRM Service"
    Environment = var.environment
  }
}
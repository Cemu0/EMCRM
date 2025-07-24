# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# DynamoDB Tables
resource "aws_dynamodb_table" "crm_data" {
  name         = var.dynamodb_main_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "type"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "TypeIndex"
    hash_key        = "type"
    projection_type = "ALL"
  }

  tags = {
    Name        = "CRM Data Table"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "email_data" {
  name         = var.dynamodb_email_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Email Data Table"
    Environment = var.environment
  }
}

# ECR Repository for Docker Images
resource "aws_ecr_repository" "emcrm_app" {
  name                 = "emcrm-app"
  image_tag_mutability = "MUTABLE"

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

# ECS Task Definition
resource "aws_ecs_task_definition" "emcrm_task" {
  family                   = "emcrm-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

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
        # Database Configuration
        { name = "DB_AWS_REGION", value = var.aws_region },
        { name = "DB_MAIN_TABLE_NAME", value = var.dynamodb_main_table_name },
        { name = "DB_EMAIL_TABLE_NAME", value = var.dynamodb_email_table_name },
        
        # OpenSearch Configuration
        { name = "OPENSEARCH_MODE", value = "cloud" },
        { name = "OPENSEARCH_HOST", value = var.opensearch_host != "" ? var.opensearch_host : aws_opensearch_domain.emcrm_domain.endpoint },
        { name = "OPENSEARCH_PORT", value = "443" },
        { name = "OPENSEARCH_USE_SSL", value = "true" },
        { name = "OPENSEARCH_VERIFY_CERTS", value = var.opensearch_vpc_enabled ? "false" : "true" },
        
        # Application Configuration
        { name = "APP_NAME", value = "EMCRM" },
        { name = "APP_DEBUG", value = "false" },
        { name = "APP_LOG_LEVEL", value = "INFO" },
        { name = "APP_PORT", value = "8080" },
        { name = "APP_HOST", value = "0.0.0.0" }
      ]
      secrets = [
        { name = "OPENSEARCH_USERNAME", valueFrom = aws_secretsmanager_secret.opensearch_credentials.arn },
        { name = "OPENSEARCH_PASSWORD", valueFrom = aws_secretsmanager_secret.opensearch_credentials.arn }
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
    target_group_arn = aws_lb_target_group.emcrm_tg.arn
    container_name   = "emcrm-app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.emcrm_listener]

  tags = {
    Name        = "EMCRM Service"
    Environment = var.environment
  }
}

# IAM Roles
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

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_manager_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.crm_data.arn,
          "${aws_dynamodb_table.crm_data.arn}/index/*",
          aws_dynamodb_table.email_data.arn
        ]
      }
    ]
  })

  tags = {
    Name        = "EMCRM DynamoDB Policy"
    Environment = var.environment
  }
}

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
        Resource = aws_secretsmanager_secret.opensearch_credentials.arn
      }
    ]
  })

  tags = {
    Name        = "EMCRM Secrets Manager Policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

# Secrets Manager for OpenSearch credentials
resource "aws_secretsmanager_secret" "opensearch_credentials" {
  name        = "emcrm-opensearch-credentials"
  description = "OpenSearch credentials for EMCRM"

  tags = {
    Name        = "EMCRM OpenSearch Credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "opensearch_credentials" {
  secret_id = aws_secretsmanager_secret.opensearch_credentials.id
  secret_string = jsonencode({
    username = var.opensearch_username
    password = var.opensearch_password
  })
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

# Application Load Balancer
resource "aws_lb" "emcrm_lb" {
  name               = "emcrm-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name        = "EMCRM Load Balancer"
    Environment = var.environment
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "emcrm-lb-sg"
  description = "Security group for EMCRM load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "EMCRM LB Security Group"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "emcrm_tg" {
  name        = "emcrm-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "EMCRM Target Group"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "emcrm_listener" {
  load_balancer_arn = aws_lb.emcrm_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.emcrm_tg.arn
  }

  tags = {
    Name        = "EMCRM Listener"
    Environment = var.environment
  }
}

# OpenSearch Domain and Configuration
resource "aws_opensearch_domain" "emcrm_domain" {
  domain_name    = var.opensearch_domain_name
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type            = var.opensearch_instance_type
    instance_count           = var.opensearch_instance_count
    zone_awareness_enabled   = var.opensearch_instance_count > 1 ? true : false
    
    # Only apply zone awareness config if multiple instances are used
    dynamic "zone_awareness_config" {
      for_each = var.opensearch_instance_count > 1 ? [1] : []
      content {
        availability_zone_count = min(var.opensearch_instance_count, length(var.subnet_ids))
      }
    }
    
    # Add dedicated master nodes if specified
    dynamic "dedicated_master_options" {
      for_each = var.opensearch_dedicated_master_enabled ? [1] : []
      content {
        enabled = true
        count   = var.opensearch_dedicated_master_count
        type    = var.opensearch_dedicated_master_type
      }
    }
    
    # Add warm nodes if specified
    dynamic "warm_options" {
      for_each = var.opensearch_warm_enabled ? [1] : []
      content {
        enabled = true
        count   = var.opensearch_warm_count
        type    = var.opensearch_warm_type
      }
    }
  }

  # VPC options if VPC deployment is enabled
  dynamic "vpc_options" {
    for_each = var.opensearch_vpc_enabled ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.opensearch_sg[0].id]
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.opensearch_volume_type
    volume_size = var.opensearch_volume_size
    iops        = var.opensearch_volume_type == "gp3" || var.opensearch_volume_type == "io1" ? var.opensearch_volume_iops : null
  }

  encrypt_at_rest {
    enabled = true
    kms_key_id = var.opensearch_kms_key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
    custom_endpoint_enabled = var.opensearch_custom_endpoint_enabled
    custom_endpoint = var.opensearch_custom_endpoint_enabled ? var.opensearch_custom_endpoint : null
    custom_endpoint_certificate_arn = var.opensearch_custom_endpoint_enabled ? var.opensearch_custom_endpoint_certificate_arn : null
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.opensearch_username
      master_user_password = var.opensearch_password
    }
  }

  # Auto-Tune options
  auto_tune_options {
    desired_state = var.opensearch_auto_tune_enabled ? "ENABLED" : "DISABLED"
    rollback_on_disable = var.opensearch_auto_tune_enabled ? "NO_ROLLBACK" : null
    
    maintenance_schedule {
      start_at = var.opensearch_auto_tune_enabled ? timeadd(timestamp(), "168h") : null  # 7 days from now
      duration {
        value = var.opensearch_auto_tune_enabled ? 2 : null
        unit  = var.opensearch_auto_tune_enabled ? "HOURS" : null
      }
      cron_expression_for_recurrence = var.opensearch_auto_tune_enabled ? "cron(0 0 ? * SUN *)" : null  # Every Sunday at midnight
    }
  }

  # Use conditional access policy based on VPC deployment
  access_policies = var.opensearch_vpc_enabled ? null : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp": var.opensearch_allowed_cidr_blocks
          }
        }
      }
    ]
  })

  log_publishing_options {
    enabled                  = var.opensearch_log_publishing_enabled
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = var.opensearch_log_publishing_enabled ? aws_cloudwatch_log_group.opensearch_logs[0].arn : null
  }

  log_publishing_options {
    enabled                  = var.opensearch_log_publishing_enabled
    log_type                 = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = var.opensearch_log_publishing_enabled ? aws_cloudwatch_log_group.opensearch_logs[0].arn : null
  }

  log_publishing_options {
    enabled                  = var.opensearch_log_publishing_enabled
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = var.opensearch_log_publishing_enabled ? aws_cloudwatch_log_group.opensearch_logs[0].arn : null
  }

  tags = {
    Name        = "EMCRM OpenSearch Domain"
    Environment = var.environment
    Service     = "EMCRM"
    Terraform   = "true"
  }

  depends_on = [
    aws_iam_service_linked_role.opensearch
  ]
}

# CloudWatch Log Group for OpenSearch logs
resource "aws_cloudwatch_log_group" "opensearch_logs" {
  count             = var.opensearch_log_publishing_enabled ? 1 : 0
  name              = "/aws/opensearch/domains/${var.opensearch_domain_name}"
  retention_in_days = 30

  tags = {
    Name        = "EMCRM OpenSearch Logs"
    Environment = var.environment
  }
}

# Security Group for OpenSearch if VPC deployment is enabled
resource "aws_security_group" "opensearch_sg" {
  count       = var.opensearch_vpc_enabled ? 1 : 0
  name        = "emcrm-opensearch-sg"
  description = "Security group for EMCRM OpenSearch domain"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EMCRM OpenSearch Security Group"
    Environment = var.environment
  }
}

# IAM Service Linked Role for OpenSearch
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service Linked Role for Amazon OpenSearch Service"
}

# OpenSearch Dashboard Cognito configuration (optional)
resource "aws_cognito_user_pool" "opensearch_users" {
  count = var.opensearch_cognito_enabled ? 1 : 0
  name  = "emcrm-opensearch-users"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  
  tags = {
    Name        = "EMCRM OpenSearch User Pool"
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_domain" "opensearch_domain" {
  count        = var.opensearch_cognito_enabled ? 1 : 0
  domain       = "emcrm-opensearch-${var.environment}"
  user_pool_id = aws_cognito_user_pool.opensearch_users[0].id
}

resource "aws_cognito_identity_pool" "opensearch_identity_pool" {
  count                            = var.opensearch_cognito_enabled ? 1 : 0
  identity_pool_name               = "emcrm_opensearch_identity_pool"
  allow_unauthenticated_identities = false
  
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.opensearch_client[0].id
    provider_name           = aws_cognito_user_pool.opensearch_users[0].endpoint
    server_side_token_check = false
  }
  
  tags = {
    Name        = "EMCRM OpenSearch Identity Pool"
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "opensearch_client" {
  count                                = var.opensearch_cognito_enabled ? 1 : 0
  name                                 = "opensearch-dashboards"
  user_pool_id                         = aws_cognito_user_pool.opensearch_users[0].id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  callback_urls                        = ["https://${aws_opensearch_domain.emcrm_domain.endpoint}/_dashboards/app/home"]
  supported_identity_providers         = ["COGNITO"]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Outputs
output "load_balancer_dns" {
  value       = aws_lb.emcrm_lb.dns_name
  description = "The DNS name of the load balancer"
}

output "opensearch_endpoint" {
  value       = aws_opensearch_domain.emcrm_domain.endpoint
  description = "The endpoint of the OpenSearch domain"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.emcrm_app.repository_url
  description = "The URL of the ECR repository"
}
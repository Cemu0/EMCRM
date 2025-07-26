# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  create_vpc           = var.create_vpc
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  environment         = var.environment
  existing_vpc_id     = var.existing_vpc_id
  existing_subnet_ids = var.existing_subnet_ids
}

# Local values for VPC and subnet IDs
locals {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"
  
  dynamodb_main_table_name  = var.dynamodb_main_table_name
  dynamodb_email_table_name = var.dynamodb_email_table_name
  environment               = var.environment
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  environment           = var.environment
  crm_table_arn        = module.dynamodb.crm_table_arn
  email_table_arn      = module.dynamodb.email_table_arn
  secrets_manager_arns = [module.secrets_manager.opensearch_secret_arn, module.secrets_manager.auth_secret_arn]
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load_balancer"
  
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.subnet_ids
  certificate_arn = var.domain_name != "" ? aws_acm_certificate_validation.main[0].certificate_arn : var.certificate_arn
  enable_https    = var.enable_https
  ssl_policy      = var.ssl_policy
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  environment               = var.environment
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.subnet_ids
  container_cpu            = var.container_cpu
  container_memory         = var.container_memory
  service_desired_count    = var.service_desired_count
  ecs_execution_role_arn   = module.iam.ecs_execution_role_arn
  ecs_task_role_arn        = module.iam.ecs_task_role_arn
  aws_region               = var.aws_region
  dynamodb_main_table_name = var.dynamodb_main_table_name
  dynamodb_email_table_name = var.dynamodb_email_table_name
  opensearch_endpoint      = module.opensearch.endpoint
  opensearch_vpc_enabled   = var.opensearch_vpc_enabled
  auth_enabled             = var.auth_enabled
  opensearch_secret_arn    = module.secrets_manager.opensearch_secret_arn
  auth_secret_arn          = module.secrets_manager.auth_secret_arn
  target_group_arn         = module.load_balancer.target_group_arn
  lb_listener_arn          = module.load_balancer.listener_arn
}



# Cognito Module
module "cognito" {
  source = "./modules/cognito"
  
  environment              = var.environment
  aws_region              = var.aws_region
  auth_enabled            = var.auth_enabled
  domain_name             = var.domain_name
  load_balancer_dns_name  = module.load_balancer.load_balancer_dns_name
  opensearch_cognito_enabled = false
  opensearch_endpoint     = module.opensearch.endpoint
}

# Secrets Manager Module
module "secrets_manager" {
  source = "./modules/secrets_manager"
  
  environment           = var.environment
  opensearch_username   = var.opensearch_username
  opensearch_password   = var.opensearch_password
  auth_enabled         = var.auth_enabled
  cognito_user_pool_id = module.cognito.main_user_pool_id
  cognito_client_id    = module.cognito.main_client_id
  cognito_client_secret = module.cognito.main_client_secret
  cognito_domain       = module.cognito.main_domain
  jwt_secret           = var.jwt_secret
}



# Simplified OpenSearch Module for MVP
module "opensearch" {
  source = "./modules/opensearch"
  
  environment               = var.environment
  aws_region               = var.aws_region
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.subnet_ids
  opensearch_domain_name   = var.opensearch_domain_name
  opensearch_engine_version = var.opensearch_engine_version
  opensearch_instance_type = var.opensearch_instance_type
  opensearch_instance_count = var.opensearch_instance_count
  opensearch_vpc_enabled   = var.opensearch_vpc_enabled
  opensearch_username      = var.opensearch_username
  opensearch_password      = var.opensearch_password
}





# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Outputs
output "load_balancer_dns" {
  value       = module.load_balancer.load_balancer_dns_name
  description = "The DNS name of the load balancer"
}

output "opensearch_endpoint" {
  value       = module.opensearch.endpoint
  description = "The endpoint of the OpenSearch domain"
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = module.opensearch.dashboard_endpoint
}

output "ecr_repository_url" {
  value       = module.ecs.ecr_repository_url
  description = "The URL of the ECR repository"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC used for deployment"
}

output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "The IDs of the subnets used for deployment"
}

output "vpc_created" {
  value       = var.create_vpc
  description = "Whether a new VPC was created or existing one was used"
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "ID of the main Cognito User Pool"
  value       = module.cognito.main_user_pool_id
}

output "cognito_client_id" {
  description = "ID of the main Cognito User Pool Client"
  value       = module.cognito.main_client_id
}

output "cognito_domain" {
  description = "Cognito User Pool Domain"
  value       = module.cognito.main_domain
}

output "cognito_login_url" {
  description = "Cognito Login URL"
  value       = module.cognito.main_login_url
}


# ACM Certificate (only if domain_name is provided)
# ACM Certificate (use existing or create new)
locals {
  use_existing_cert = var.certificate_arn != ""
}

# ACM Certificate (only if domain_name is provided and no existing cert)
resource "aws_acm_certificate" "main" {
  count = var.domain_name != "" && !local.use_existing_cert ? 1 : 0
  
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "EMCRM SSL Certificate"
    Environment = var.environment
  }
}

# Route53 validation (optional - requires Route53 hosted zone)
data "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# SSL Certificate validation records (only for new certificates)
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" && var.preserve_ssl_cname && !local.use_existing_cert ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count = var.domain_name != "" && !local.use_existing_cert ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# A Record for root domain pointing to load balancer (conditionally managed)
resource "aws_route53_record" "main" {
  count = var.domain_name != "" && var.manage_domain_records ? 1 : 0
  
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.load_balancer.load_balancer_dns_name
    zone_id                = module.load_balancer.load_balancer_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_acm_certificate_validation.main]
}

# A Record for www subdomain pointing to load balancer (conditionally managed)
resource "aws_route53_record" "www" {
  count = var.domain_name != "" && var.manage_domain_records ? 1 : 0
  
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.load_balancer.load_balancer_dns_name
    zone_id                = module.load_balancer.load_balancer_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_acm_certificate_validation.main]
}

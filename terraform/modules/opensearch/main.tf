# Simplified OpenSearch Module for MVP
# Creates a basic OpenSearch domain

# Get current AWS account ID
data "aws_caller_identity" "current" {}

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
    cidr_blocks = ["10.0.0.0/16"]  # Allow access from VPC CIDR
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

# Simplified OpenSearch Domain for MVP
resource "aws_opensearch_domain" "emcrm_domain" {
  domain_name    = var.opensearch_domain_name
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = var.opensearch_instance_count
  }

  # VPC options if VPC deployment is enabled
  dynamic "vpc_options" {
    for_each = var.opensearch_vpc_enabled ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.opensearch_sg[0].id]
    }
  }

  # Simple EBS configuration for MVP
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
  }

  # Basic encryption
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Simple authentication for MVP
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.opensearch_username
      master_user_password = var.opensearch_password
    }
  }

  # Simple access policy for non-VPC deployment
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
            "aws:SourceIp": ["0.0.0.0/0"]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "EMCRM OpenSearch Domain"
    Environment = var.environment
    Service     = "EMCRM"
    Terraform   = "true"
  }


}
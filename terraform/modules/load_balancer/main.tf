# Load Balancer Module
# Creates Application Load Balancer, target group, and listener

# Security Group for Load Balancer
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

# Target Group
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

# HTTP Listener - Redirect to HTTPS (only if HTTPS is enabled)
resource "aws_lb_listener" "emcrm_http_listener" {
  load_balancer_arn = aws_lb.emcrm_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.enable_https && var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.enable_https && var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.enable_https && var.certificate_arn != "" ? [] : [1]
      content {
        target_group {
          arn    = aws_lb_target_group.emcrm_tg.arn
          weight = 100
        }
      }
    }
  }

  tags = {
    Name        = "EMCRM HTTP Listener"
    Environment = var.environment
  }
}

# HTTPS Listener (only if HTTPS is enabled and certificate is provided)
resource "aws_lb_listener" "emcrm_https_listener" {
  count = var.enable_https ? 1 : 0
  
  load_balancer_arn = aws_lb.emcrm_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.emcrm_tg.arn
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      certificate_arn
    ]
  }

  tags = {
    Name        = "EMCRM HTTPS Listener"
    Environment = var.environment
  }
}
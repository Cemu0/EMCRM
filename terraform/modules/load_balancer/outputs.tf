# Load Balancer Module Outputs

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.emcrm_lb.arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.emcrm_lb.dns_name
}

output "load_balancer_zone_id" {
  description = "The zone ID of the load balancer"
  value       = aws_lb.emcrm_lb.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.emcrm_tg.arn
}

output "listener_arn" {
  description = "ARN of the listener (HTTP or HTTPS depending on configuration)"
  value       = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.emcrm_https_listener[0].arn : aws_lb_listener.emcrm_http_listener.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.emcrm_http_listener.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if enabled)"
  value       = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.emcrm_https_listener[0].arn : null
}

output "security_group_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.lb_sg.id
}
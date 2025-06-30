output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "global_accelerator_dns" {
  description = "Global Accelerator DNS"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "route53_zone_id" {
  description = "Route53 Zone ID"
  value       = aws_route53_zone.main.id
}
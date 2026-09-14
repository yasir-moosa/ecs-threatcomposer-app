output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS name to hit the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.tg.arn
  description = "Attach ECS service to this"

}

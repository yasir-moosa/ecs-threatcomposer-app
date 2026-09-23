output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS name to hit the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.tg.arn
  description = "Attach ECS service to this"

}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}

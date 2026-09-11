output "alb_sg_id" {
  value       = aws_security_group.alb_sg.id
  description = "Security group ID for the ALB"
}

output "ecs_task_sg_id" {
  value       = aws_security_group.ecs_task_sg.id
  description = "Security group ID for the ECS tasks"
}

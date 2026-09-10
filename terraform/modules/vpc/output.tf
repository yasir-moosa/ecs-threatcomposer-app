output "vpc_id" {
  value       = aws_vpc.ecs_vpc.id
  description = "vpc id for ecs project"
}

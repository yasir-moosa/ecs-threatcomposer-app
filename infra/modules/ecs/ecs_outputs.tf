output "ecs_cluster_name" {
  value       = aws_ecs_cluster.ecs_cluster.name
  description = "ECS cluster name"
}

output "ecs_service_name" {
  value       = aws_ecs_service.ecs_service.name
  description = "ECS service name"
}

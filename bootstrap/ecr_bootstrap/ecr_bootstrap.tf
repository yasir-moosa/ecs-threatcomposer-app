# Create ECR Repository
resource "aws_ecr_repository" "ecs_project_repo" {
  name         = var.ecr_name
  force_delete = true
}

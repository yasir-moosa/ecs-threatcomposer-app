# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "ecs_cw_group" {
  name              = "/ecs/threat-app"
  retention_in_days = 3

  tags = {
    Name    = "ecs_cloudwatch_group"
    Project = "ecs"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name    = "ecs_cluster"
    Project = "ecs"
  }
}

# Existing IAM role that lets ECS pull images and write logs
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# Latest image pushed to ECR
data "aws_ecr_image" "app_image" {
  repository_name = var.ecr_repo_name
  most_recent     = true
}

# Task Definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecs_task_definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "threat-app"
      image     = data.aws_ecr_image.app_image.image_uri
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [
        {
          containerPort = var.app_port
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_cw_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "threat-app-task"
        }
      }
    }
  ])

  tags = {
    Name    = "ecs_task_definition"
    Project = "ecs"
  }
}

# ECS Service
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs_service"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [var.ecs_task_sg_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "threat-app"
    container_port   = var.app_port
  }

  tags = {
    Name    = "ecs_service"
    Project = "ecs"
  }
}

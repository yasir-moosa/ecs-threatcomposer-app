# Security group for ALB

resource "aws_security_group" "alb_sg" {

  name        = "alb-sg"
  description = "Allow inbound HTTP to ALB"
  vpc_id      = var.vpc_id


  tags = {
    Name    = "alb-sg"
    Project = "ecs"
  }
}

# Security group for ECS tasks

resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "allow inbound only from ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "ecs-task-sg"
    Project = "ecs"
  }

}

# ALB SG to allow inbound HTTP from internet

resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress" {

  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

}

# ALB SG to allow inbound HTTPS from internet

resource "aws_vpc_security_group_ingress_rule" "alb_https_ingress" {

  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

}

# ALB SG to allow outbound only to ECS task SG on the app port

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs_task" {

  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_task_sg.id
  from_port                    = var.ecs_task_port
  to_port                      = var.ecs_task_port
  ip_protocol                  = "tcp"

}
# ECS Task SG to allow inbound only from ALB SG on app port
resource "aws_vpc_security_group_ingress_rule" "ecs_task_ingress_from_alb" {
  security_group_id            = aws_security_group.ecs_task_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = var.ecs_task_port
  to_port                      = var.ecs_task_port
  ip_protocol                  = "tcp"

}


#ECS Task to SG to allow outbound HTTPS - so task can reach ECR/Cloudwatch/etc

resource "aws_vpc_security_group_egress_rule" "ecs_task_egress" {
  security_group_id = aws_security_group.ecs_task_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

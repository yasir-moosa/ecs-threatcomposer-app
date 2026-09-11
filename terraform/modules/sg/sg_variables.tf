variable "vpc_id" {
  type        = string
  description = "VPC the security group belongs to"

}

variable "ecs_task_port" {
  type        = number
  description = "the port ECS task listens on"


}

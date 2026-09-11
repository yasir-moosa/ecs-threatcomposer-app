variable "vpc_id" {
  type        = string
  description = "VPC to deploy to"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnets for ALB"
}

variable "sg_id" {
  type        = string
  description = "security group for ALB"

}

variable "app_port" {

  type        = number
  description = "port the app listen on"
  default     = 80

}

variable "region" {
  type        = string
  description = "aws region"
  default     = "eu-west-2"
}

variable "bucket_name" {
  type        = string
  description = "s3 bucket name"
  default     = "ecs-proj-s3-bucket"
}

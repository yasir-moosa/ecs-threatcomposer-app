terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # backend "s3" {
  #   bucket       = "ecs-s3-bucket-test"
  #   key          = "ecs-project/s3-boostrap/terraform.tfstate"
  #   region       = "eu-west-2"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

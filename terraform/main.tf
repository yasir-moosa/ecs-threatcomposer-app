terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "ecs-proj-s3-bucket"
    key          = "ecs-project/app/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "sg" {
  source        = "./modules/sg"
  vpc_id        = module.vpc.vpc_id
  ecs_task_port = 80
}

module "alb" {
  source     = "./modules/alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnet_2a_id, module.vpc.public_subnet_2b_id]
  sg_id      = module.sg.alb_sg_id
  app_port   = 80
}

# vpc
# subnet
# igw
# reg nat
# route tables
# sg

# alb
#
# ecs
# cluster

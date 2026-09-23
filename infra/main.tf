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

# look up for the existing hosted zone
data "aws_route53_zone" "this" {

  name         = var.domain_name
  private_zone = false

}

module "vpc" {
  source = "./modules/vpc"
}

module "sg" {
  source        = "./modules/sg"
  vpc_id        = module.vpc.vpc_id
  ecs_task_port = 8080
}

module "alb" {
  source          = "./modules/alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = [module.vpc.public_subnet_2a_id, module.vpc.public_subnet_2b_id]
  sg_id           = module.sg.alb_sg_id
  app_port        = 8080
  certificate_arn = module.acm.certificate_arn
}

# Requests SSL cert for tm.yasirmoosa.tech and confirms it via CNAME in hosted zone
module "acm" {
  source  = "./modules/acm"
  fqdn    = "${var.subdomain}.${var.domain_name}"
  zone_id = data.aws_route53_zone.this.zone_id
}
# Points tm.yasirmoosa.tech to the ALB
module "route53" {
  source       = "./modules/route53"
  fqdn         = "${var.subdomain}.${var.domain_name}"
  zone_id      = data.aws_route53_zone.this.zone_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}
module "ecs" {
  source             = "./modules/ecs"
  private_subnet_ids = [module.vpc.private_subnet_2a_id, module.vpc.private_subnet_2b_id]
  ecs_task_sg_id     = module.sg.ecs_task_sg_id
  target_group_arn   = module.alb.target_group_arn
  app_port           = 8080
  aws_region         = var.region
  alb_dimension      = module.alb.alb_arn_suffix
}

# VPC Section
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "ecs-vpc"
    Project = "ecs"
  }
}

# IGW Section
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    Name    = "ecs-igw"
    Project = "ecs"

  }

}

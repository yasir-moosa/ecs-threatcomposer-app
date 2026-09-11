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

# Subnet Section

## Public Subnet

# Public Subnet 2A
resource "aws_subnet" "public_sn_2a" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.0.0/26"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "public-sn-eu-west-2a"
    Project = "ecs"
  }
}
# Public Subnet 2B
resource "aws_subnet" "public_sn_2b" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "public-sn-eu-west-2b"
    Project = "ecs"
  }
}

# Private Subnet 2A
resource "aws_subnet" "private_sn_2a" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.0.128/26"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "private-sn-eu-west-2a"
    Project = "ecs"
  }
}

# Private Subnet 2B
resource "aws_subnet" "private_sn_2b" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.0.192/26"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "private-sn-eu-west-2b"
    Project = "ecs"
  }
}


# Regional NAT Gateway Section

resource "aws_nat_gateway" "ecs_nat" {

  vpc_id            = aws_vpc.ecs_vpc.id
  availability_mode = "regional"
  depends_on        = [aws_internet_gateway.ecs_igw]


  tags = {
    Name    = "ecs-regional-natgw"
    Project = "ecs"
  }
}

# # Route Tables Section
# Public Route Table
resource "aws_route_table" "ecs_public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name    = "ecs-public-rt"
    Project = "ecs"
  }
}

# Private Route Table

resource "aws_route_table" "ecs_private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat.id
  }

  tags = {
    Name    = "ecs-private-rt"
    Project = "ecs"
  }
}

# # Route Table Association With Corresponding Subnets

resource "aws_route_table_association" "ecs_public_rt_2a_association" {
  subnet_id      = aws_subnet.public_sn_2a.id
  route_table_id = aws_route_table.ecs_public_rt.id
}

resource "aws_route_table_association" "ecs_public_rt_2b_association" {
  subnet_id      = aws_subnet.public_sn_2b.id
  route_table_id = aws_route_table.ecs_public_rt.id
}

resource "aws_route_table_association" "ecs_private_rt_2a_association" {
  subnet_id      = aws_subnet.private_sn_2a.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

resource "aws_route_table_association" "ecs_private_rt_2b_association" {
  subnet_id      = aws_subnet.private_sn_2b.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

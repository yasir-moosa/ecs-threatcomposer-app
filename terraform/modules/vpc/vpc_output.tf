output "vpc_id" {
  value       = aws_vpc.ecs_vpc.id
  description = "vpc id for ecs project"
}

# Echoes back the CIDR range defined on the VPC resource
output "vpc_cidr_block" {
  value = aws_vpc.ecs_vpc.cidr_block
}
# Public Subnet Outputs
output "public_subnet_2a_ID" {
  value       = aws_subnet.public_sn_2a.id
  description = "ECS public subnet 2a id"
}

output "public_subnet_2b_ID" {
  value       = aws_subnet.public_sn_2b.id
  description = "ECS public subnet 2b id"
}

output "private_subnet_2a_ID" {
  value       = aws_subnet.private_sn_2a.id
  description = "ECS private subnet 2a id"
}

output "private_subnet_2b_ID" {
  value       = aws_subnet.private_sn_2b.id
  description = "ECS private subnet 2b id"
}

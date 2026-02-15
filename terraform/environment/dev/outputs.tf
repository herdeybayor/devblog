# Dev Environment Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = module.security.security_group_id
}

# Instance Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = module.compute.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = module.compute.instance_private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = module.compute.instance_public_dns
}

# SSH Connection
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/devblog ubuntu@${module.compute.instance_public_ip}"
}

# AMI Information
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = module.compute.ami_id
}

# Key Pair
output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = module.compute.key_pair_name
}

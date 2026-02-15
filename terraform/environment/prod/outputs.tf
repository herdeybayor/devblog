# Production Environment Outputs

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

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.networking.public_subnet_availability_zones
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (HA setup)"
  value       = module.networking.nat_gateway_ids
}

output "nat_eip_public_ips" {
  description = "NAT Gateway Elastic IPs"
  value       = module.networking.nat_eip_public_ips
}

# VPC Flow Logs
output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = module.networking.flow_log_id
}

output "flow_log_cloudwatch_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = module.networking.flow_log_cloudwatch_log_group
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

output "instance_availability_zone" {
  description = "Availability zone of the instance"
  value       = module.compute.availability_zone
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

# Monitoring
output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs (for monitoring queries)"
  value       = module.networking.flow_log_cloudwatch_log_group
}

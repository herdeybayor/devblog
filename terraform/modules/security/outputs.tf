# Security Module Outputs

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.main.arn
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.main.name
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = aws_security_group.main.vpc_id
}

output "security_group_owner_id" {
  description = "Owner ID of the security group"
  value       = aws_security_group.main.owner_id
}

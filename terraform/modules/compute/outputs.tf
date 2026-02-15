# Compute Module Outputs

# Instance Details
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.main.instance_state
}

# Network Information
output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "instance_private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.main.private_dns
}

# Key Pair Information
output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].key_name : var.existing_key_pair_name
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].fingerprint : null
}

output "key_pair_id" {
  description = "ID of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].id : null
}

# IAM Information
output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].name : var.existing_instance_profile_name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].arn : null
}

# AMI Information
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

# Availability Zone
output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.main.availability_zone
}

# Root Volume
output "root_volume_id" {
  description = "ID of the root volume"
  value       = aws_instance.main.root_block_device[0].volume_id
}

# Compute Module Variables

# Required Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = true
}

# AMI Configuration
variable "ami_id" {
  description = "Specific AMI ID to use (overrides ami_filters)"
  type        = string
  default     = null
}

variable "ami_filters" {
  description = "Filters to find the AMI (used if ami_id is null)"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = [
    {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    },
    {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  ]
}

variable "ami_owners" {
  description = "Owner IDs for AMI lookup"
  type        = list(string)
  default     = ["099720109477"] # Canonical (Ubuntu)
}

# SSH Key Configuration
variable "create_key_pair" {
  description = "Create a new SSH key pair"
  type        = bool
  default     = false
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (used if ssh_public_key is null)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key" {
  description = "SSH public key content (overrides ssh_public_key_path)"
  type        = string
  default     = null
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair to use (if not creating new one)"
  type        = string
  default     = null
}

# IAM Configuration
variable "create_instance_profile" {
  description = "Create IAM instance profile"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "IAM role name to attach to instance profile (required if create_instance_profile is true)"
  type        = string
  default     = null
}

variable "existing_instance_profile_name" {
  description = "Name of existing instance profile to use"
  type        = string
  default     = null
}

# User Data
variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Replace instance if user_data changes"
  type        = bool
  default     = false
}

# EBS Volume Configuration
variable "root_volume_type" {
  description = "Root volume type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "additional_ebs_volumes" {
  description = "Additional EBS volumes to attach"
  type = list(object({
    device_name           = string
    volume_type           = string
    volume_size           = number
    encrypted             = bool
    delete_on_termination = bool
  }))
  default = []
}

# Metadata and Monitoring
variable "require_imdsv2" {
  description = "Require IMDSv2 (Instance Metadata Service V2)"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

# Note: ignore_ami_changes removed because lifecycle ignore_changes
# doesn't support conditional expressions in Terraform

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

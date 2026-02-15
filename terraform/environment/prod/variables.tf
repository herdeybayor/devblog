# Production Environment Variables

variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of instance to launch"
  type        = string
  default     = "t3.small"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "devblog"
}

variable "environment" {
  description = "The environment to deploy the resources"
  type        = string
  default     = "prod"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks for SSH - MUST be your office/VPN IP, NOT 0.0.0.0/0"
  type        = list(string)

  validation {
    condition     = !contains(var.ssh_allowed_cidrs, "0.0.0.0/0")
    error_message = "SSH cannot be open to 0.0.0.0/0 in production. Set to your office IP (get it with 'curl ifconfig.me')."
  }

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0
    error_message = "You must specify at least one CIDR block for SSH access."
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "DevBlog"
    Environment = "production"
    ManagedBy   = "terraform"
    Compliance  = "required"
    CostCenter  = "production"
  }
}

# Dev Environment Variables

variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of instance to launch"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "devblog"
}

variable "environment" {
  description = "The environment to deploy the resources"
  type        = string
  default     = "dev"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access (set to your IP for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # CHANGE THIS: Get your IP with 'curl ifconfig.me'

  # Note: The security module will validate this - 0.0.0.0/0 will cause an error
  # Run: ssh_allowed_cidrs = ["$(curl -s ifconfig.me)/32"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "DevBlog"
    Environment = "dev"
    ManagedBy   = "terraform"
    CostCenter  = "development"
  }
}

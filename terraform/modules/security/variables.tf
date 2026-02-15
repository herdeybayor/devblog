# Security Module Variables

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

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

# Security Group Configuration
variable "security_group_name" {
  description = "Name of the security group (defaults to {project}-{environment}-sg)"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = null
}

# Predefined SSH Rule
variable "enable_ssh_rule" {
  description = "Enable SSH access (port 22)"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.ssh_cidr_blocks, "0.0.0.0/0")
    error_message = "SSH should not be open to 0.0.0.0/0 - specify your IP address instead."
  }
}

# Predefined HTTP Rule
variable "enable_http_rule" {
  description = "Enable HTTP access (port 80)"
  type        = bool
  default     = false
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Predefined HTTPS Rule
variable "enable_https_rule" {
  description = "Enable HTTPS access (port 443)"
  type        = bool
  default     = false
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Custom Ingress Rules
variable "ingress_rules" {
  description = "List of custom ingress rules"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      (rule.cidr_blocks != null || rule.source_security_group_id != null)
    ])
    error_message = "Each ingress rule must have either cidr_blocks or source_security_group_id."
  }
}

# Custom Egress Rules
variable "egress_rules" {
  description = "List of custom egress rules (if empty, default allow-all egress is used)"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.egress_rules :
      (rule.cidr_blocks != null || rule.source_security_group_id != null)
    ])
    error_message = "Each egress rule must have either cidr_blocks or source_security_group_id."
  }
}

# Default Egress
variable "enable_default_egress" {
  description = "Enable default egress rule (allow all outbound) if no custom egress rules"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

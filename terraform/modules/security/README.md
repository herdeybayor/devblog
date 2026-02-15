# Security Module

This module manages AWS Security Groups with predefined rule templates and dynamic custom rules. It includes built-in security validations to prevent common misconfigurations.

## Features

- **Predefined Rules**: SSH, HTTP, HTTPS with enable/disable flags
- **SSH CIDR Validation**: Prevents opening SSH to 0.0.0.0/0
- **Dynamic Rule Creation**: Custom ingress and egress rules via variables
- **Flexible Sources**: Support for CIDR blocks and security group references
- **Default Egress**: Optional allow-all outbound traffic
- **Security Best Practices**: Validation and secure defaults

## Usage

### Basic Example (Web Server)

```hcl
module "security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "dev"
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"

  # Predefined rules
  enable_ssh_rule  = true
  ssh_cidr_blocks  = ["203.0.113.0/24"]  # Your office IP
  enable_http_rule = true
  enable_https_rule = true

  tags = {
    Project     = "DevBlog"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Example (Custom Rules)

```hcl
module "security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = module.networking.vpc_id

  security_group_name = "app-sg"

  # SSH from bastion host only
  enable_ssh_rule  = true
  ssh_cidr_blocks  = ["10.0.1.0/24"]

  # Web traffic
  enable_http_rule  = true
  enable_https_rule = true

  # Custom application ports
  ingress_rules = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Node.js application"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      source_security_group_id = aws_security_group.database.id
      description = "PostgreSQL from app tier"
    }
  ]

  # Custom egress (restrict outbound)
  egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS to internet"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      destination_security_group_id = aws_security_group.database.id
      description = "PostgreSQL to database"
    }
  ]

  enable_default_egress = false  # Using custom egress only
}
```

### Multi-Tier Architecture Example

```hcl
# Web Tier Security Group
module "web_security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-tier-sg"

  enable_http_rule  = true
  enable_https_rule = true

  ingress_rules = [
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.bastion_security.security_group_id
      description              = "SSH from bastion"
    }
  ]
}

# App Tier Security Group
module "app_security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = module.networking.vpc_id

  security_group_name = "app-tier-sg"

  ingress_rules = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.web_security.security_group_id
      description              = "App port from web tier"
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.bastion_security.security_group_id
      description              = "SSH from bastion"
    }
  ]
}

# Database Tier Security Group
module "db_security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = module.networking.vpc_id

  security_group_name = "db-tier-sg"

  ingress_rules = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.app_security.security_group_id
      description              = "PostgreSQL from app tier"
    }
  ]

  # No egress needed for database
  enable_default_egress = false
}
```

## Security Best Practices

### SSH Access Hardening

**CRITICAL**: Never open SSH to 0.0.0.0/0. This module validates SSH CIDR blocks:

```hcl
# ❌ BAD - Will fail validation
module "security" {
  enable_ssh_rule = true
  ssh_cidr_blocks = ["0.0.0.0/0"]  # ERROR: SSH should not be open to 0.0.0.0/0
}

# ✅ GOOD - Restrict to your IP
module "security" {
  enable_ssh_rule = true
  ssh_cidr_blocks = ["203.0.113.50/32"]  # Your specific IP
}

# ✅ BETTER - Use bastion host
module "app_security" {
  ingress_rules = [
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.bastion_security.security_group_id
      description              = "SSH from bastion only"
    }
  ]
}
```

### Getting Your IP Address

```bash
# Get your current public IP
curl -s ifconfig.me

# Use in Terraform
ssh_cidr_blocks = ["$(curl -s ifconfig.me)/32"]

# Or set as variable
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### Least Privilege Egress

By default, the module allows all outbound traffic. For production, restrict egress:

```hcl
module "security" {
  # ... other config ...

  # Disable default allow-all egress
  enable_default_egress = false

  # Only allow specific outbound traffic
  egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS for package updates"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP for package updates"
    }
  ]
}
```

### Environment-Specific Rules

Use different rules for different environments:

```hcl
locals {
  is_production = var.environment == "prod"

  ssh_cidr_blocks = local.is_production ? [
    "10.0.1.0/24"  # Bastion subnet only
  ] : [
    var.developer_ip  # Direct SSH in dev
  ]
}

module "security" {
  enable_ssh_rule = true
  ssh_cidr_blocks = local.ssh_cidr_blocks
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | - | yes |
| environment | Environment name (dev/staging/prod) | string | - | yes |
| vpc_id | VPC ID for security group | string | - | yes |
| security_group_name | Security group name | string | null (auto-generated) | no |
| security_group_description | Security group description | string | null (auto-generated) | no |
| enable_ssh_rule | Enable SSH (port 22) | bool | false | no |
| ssh_cidr_blocks | SSH allowed CIDRs (validated) | list(string) | [] | no |
| enable_http_rule | Enable HTTP (port 80) | bool | false | no |
| http_cidr_blocks | HTTP allowed CIDRs | list(string) | ["0.0.0.0/0"] | no |
| enable_https_rule | Enable HTTPS (port 443) | bool | false | no |
| https_cidr_blocks | HTTPS allowed CIDRs | list(string) | ["0.0.0.0/0"] | no |
| ingress_rules | Custom ingress rules | list(object) | [] | no |
| egress_rules | Custom egress rules | list(object) | [] | no |
| enable_default_egress | Allow all outbound if no custom egress | bool | true | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | Security group ID |
| security_group_arn | Security group ARN |
| security_group_name | Security group name |
| security_group_vpc_id | VPC ID |
| security_group_owner_id | Owner ID |

## Common Patterns

### Application Load Balancer

```hcl
module "alb_security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = var.vpc_id

  security_group_name = "alb-sg"
  enable_http_rule    = true
  enable_https_rule   = true
}

module "app_security" {
  source = "../../modules/security"

  # ... config ...

  ingress_rules = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.alb_security.security_group_id
      description              = "Traffic from ALB"
    }
  ]
}
```

### Bastion Host

```hcl
module "bastion_security" {
  source = "../../modules/security"

  project_name = "devblog"
  environment  = "prod"
  vpc_id       = var.vpc_id

  security_group_name = "bastion-sg"
  enable_ssh_rule     = true
  ssh_cidr_blocks     = ["203.0.113.0/24"]  # Office IP range
}
```

### VPC Peering

```hcl
module "app_security" {
  source = "../../modules/security"

  # ... config ...

  ingress_rules = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["10.1.0.0/16"]  # Peered VPC CIDR
      description = "App traffic from peered VPC"
    }
  ]
}
```

## Troubleshooting

### SSH Rule Validation Error

```
Error: SSH should not be open to 0.0.0.0/0 - specify your IP address instead.
```

**Solution**: Get your IP and use it:
```bash
curl ifconfig.me  # Returns your public IP
# Use: ssh_cidr_blocks = ["YOUR.IP.HERE/32"]
```

### Rule Conflicts

If you see "duplicate rule" errors, check for:
1. Predefined rules overlapping with custom rules
2. Duplicate entries in `ingress_rules` or `egress_rules`

### No Outbound Connectivity

If instances can't reach the internet:
1. Check if `enable_default_egress = false` is set
2. Add explicit egress rules for required protocols
3. Verify NAT gateway configuration in networking module

## Notes

- **Rule Limit**: AWS allows 60 rules per security group (ingress + egress)
- **CIDR Validation**: Only SSH has CIDR validation; add custom validations as needed
- **Rule Priority**: AWS security groups are stateful; return traffic is automatically allowed
- **Updates**: Changing rules may cause brief interruption during update

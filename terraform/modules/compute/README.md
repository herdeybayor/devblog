# Compute Module

This module manages EC2 instances with security best practices including IMDSv2 enforcement, EBS encryption, and flexible IAM integration.

## Features

- **Flexible AMI Selection**: Use specific AMI ID or filter-based lookup (Ubuntu/Amazon Linux/custom)
- **SSH Key Management**: Create new key pairs or use existing ones
- **IAM Integration**: Optional instance profile creation for role attachment
- **Security Hardening**:
  - IMDSv2 enforcement (prevents SSRF attacks)
  - EBS root volume encryption by default
  - Configurable security groups
- **Volume Management**: Root volume customization + additional EBS volumes support
- **User Data**: Script execution on launch with replace-on-change option
- **Monitoring**: Optional CloudWatch detailed monitoring
- **Lifecycle Management**: Ignore AMI changes to prevent unwanted replacements

## Usage

### Basic Example (Dev Environment)

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name       = "devblog"
  environment        = "dev"
  instance_type      = "t2.micro"
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = true
  create_key_pair             = true
  ssh_public_key_path         = "~/.ssh/devblog.pub"

  root_volume_type      = "gp3"
  root_volume_size      = 20
  root_volume_encrypted = true
  require_imdsv2        = true

  tags = {
    Project     = "DevBlog"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Example (Production with IAM)

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name       = "devblog"
  environment        = "prod"
  instance_type      = "t3.small"
  subnet_id          = module.networking.private_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = false

  # Use existing key pair
  create_key_pair         = false
  existing_key_pair_name  = "production-keypair"

  # Attach IAM role for S3/CloudWatch access
  create_instance_profile = true
  iam_role_name          = aws_iam_role.ec2_role.name

  # Production storage
  root_volume_type      = "gp3"
  root_volume_size      = 50
  root_volume_encrypted = true

  # Additional data volume
  additional_ebs_volumes = [
    {
      device_name           = "/dev/sdf"
      volume_type           = "gp3"
      volume_size           = 100
      encrypted             = true
      delete_on_termination = false
    }
  ]

  # User data script
  user_data = templatefile("${path.module}/user-data.sh", {
    environment = "prod"
  })
  user_data_replace_on_change = false

  # Production monitoring
  enable_detailed_monitoring = true
  require_imdsv2            = true

  tags = {
    Project     = "DevBlog"
    Environment = "prod"
    ManagedBy   = "terraform"
    Compliance  = "required"
  }
}
```

### Custom AMI Example

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name       = "devblog"
  environment        = "staging"
  instance_type      = "t3.micro"
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids

  # Use specific AMI
  ami_id = "ami-0c55b159cbfafe1f0"

  # OR use custom filters
  ami_filters = [
    {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    },
    {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  ]
  ami_owners = ["137112412989"] # Amazon

  create_key_pair     = true
  ssh_public_key_path = "~/.ssh/staging.pub"
}
```

## Security Best Practices

### IMDSv2 Enforcement

This module enforces IMDSv2 by default (`require_imdsv2 = true`), which prevents SSRF attacks on the instance metadata service:

```hcl
metadata_options {
  http_endpoint = "enabled"
  http_tokens   = "required"  # IMDSv2 only
}
```

### EBS Encryption

All root volumes are encrypted by default:

```hcl
root_block_device {
  encrypted = true  # Default
}
```

### SSH Key Management

**Best Practice**: Use separate key pairs per environment:

```bash
# Generate key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/devblog-dev -C "devblog-dev"

# Use in Terraform
module "compute" {
  create_key_pair     = true
  ssh_public_key_path = "~/.ssh/devblog-dev.pub"
}
```

**Security Note**: Never commit private keys to version control. Use `.gitignore`:

```
*.pem
*.ppk
id_rsa
id_rsa.pub
devblog*.pub
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | - | yes |
| environment | Environment name (dev/staging/prod) | string | - | yes |
| subnet_id | Subnet ID for instance | string | - | yes |
| security_group_ids | Security group IDs | list(string) | - | yes |
| instance_type | EC2 instance type | string | "t3.micro" | no |
| associate_public_ip_address | Associate public IP | bool | true | no |
| ami_id | Specific AMI ID (overrides filters) | string | null | no |
| ami_filters | AMI search filters | list(object) | Ubuntu 22.04 | no |
| ami_owners | AMI owner IDs | list(string) | ["099720109477"] | no |
| create_key_pair | Create new SSH key pair | bool | false | no |
| ssh_public_key_path | Path to SSH public key | string | "~/.ssh/id_rsa.pub" | no |
| ssh_public_key | SSH public key content | string | null | no |
| existing_key_pair_name | Existing key pair name | string | null | no |
| create_instance_profile | Create IAM instance profile | bool | false | no |
| iam_role_name | IAM role name | string | null | no |
| existing_instance_profile_name | Existing instance profile | string | null | no |
| user_data | User data script | string | null | no |
| user_data_replace_on_change | Replace on user data change | bool | false | no |
| root_volume_type | Root volume type | string | "gp3" | no |
| root_volume_size | Root volume size (GB) | number | 20 | no |
| root_volume_encrypted | Encrypt root volume | bool | true | no |
| root_volume_delete_on_termination | Delete on termination | bool | true | no |
| additional_ebs_volumes | Additional EBS volumes | list(object) | [] | no |
| require_imdsv2 | Require IMDSv2 | bool | true | no |
| enable_detailed_monitoring | CloudWatch monitoring | bool | false | no |
| ignore_ami_changes | Ignore AMI updates | bool | true | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| instance_arn | EC2 instance ARN |
| instance_state | Instance state |
| instance_public_ip | Public IP address |
| instance_private_ip | Private IP address |
| instance_public_dns | Public DNS name |
| instance_private_dns | Private DNS name |
| key_pair_name | SSH key pair name |
| key_pair_fingerprint | Key pair fingerprint |
| instance_profile_name | IAM instance profile name |
| instance_profile_arn | IAM instance profile ARN |
| ami_id | AMI ID used |
| availability_zone | Instance AZ |
| root_volume_id | Root volume ID |

## Notes

- **AMI Lifecycle**: By default, AMI changes are ignored (`ignore_ami_changes = true`) to prevent instance replacement on AMI updates. Set to `false` if you want to replace instances when AMI updates.
- **Cost Optimization**: Use `t3` instances for better performance/cost ratio compared to `t2`
- **Monitoring**: Enable detailed monitoring in production for better metrics granularity
- **User Data**: Set `user_data_replace_on_change = true` if you want instances recreated when user data changes (useful for dev/staging)

## Examples

See the `examples/` directory for more usage patterns:
- Simple web server
- Private instance with bastion
- Auto Scaling Group integration
- Multi-instance deployment

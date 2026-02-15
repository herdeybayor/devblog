# Terraform Modularization Plan: Compute & Security Modules

## Context

The DevBlog Terraform infrastructure currently has:
- ✅ **Networking module** - Extracted but basic (single AZ, no private subnets)
- ❌ **Compute resources** - EC2 instances and key pairs inline in environment files (duplicated across dev/staging)
- ❌ **Security resources** - Security groups inline in environment files (duplicated, SSH open to 0.0.0.0/0)
- ❌ **Production environment** - Doesn't exist yet

This refactoring will:
1. Apply DevOps/Terraform best practices to the networking module
2. Extract compute and security resources into reusable modules
3. Eliminate code duplication across environments
4. Add production environment with HA and security hardening
5. Fix critical security issue (SSH exposed to entire internet)

---

## High-Level Approach

### Module Structure
```
terraform/
├── modules/
│   ├── networking/   # ENHANCE: Add multi-AZ, NAT gateway, private subnets
│   ├── compute/      # NEW: EC2 instances, key pairs, IAM profiles
│   └── security/     # NEW: Security groups with rule templating
└── environment/
    ├── dev/          # UPDATE: Use all 3 modules
    ├── staging/      # UPDATE: Use all 3 modules
    └── prod/         # NEW: Production with HA & security hardening
```

### Environment Characteristics

| Environment | AZs | Subnets | NAT Gateway | VPC CIDR | Instance Type | SSH Access |
|-------------|-----|---------|-------------|----------|---------------|------------|
| Dev | 1 | Public only | None | 10.0.0.0/16 | t2.micro | Restricted CIDR |
| Staging | 2 | Public + Private | Single | 10.1.0.0/16 | t3.micro | Restricted CIDR |
| Prod | 3 | Public + Private | HA (per AZ) | 10.2.0.0/16 | t3.small | Strict validation |

---

## Module Designs

### 1. Enhanced Networking Module

**File**: `modules/networking/main.tf`

**Enhancements**:
- Multi-AZ support with dynamic subnet creation across 1-3 AZs
- Private subnets with NAT gateway support
- Conditional NAT gateway (single for cost optimization or HA per AZ)
- VPC Flow Logs (optional, enabled for prod)
- DNS hostnames enabled
- Comprehensive tagging with merge strategy

**New Variables** (`modules/networking/variables.tf`):
- `vpc_cidr` - VPC CIDR with validation
- `availability_zones` - List of AZs (1-3)
- `public_subnet_cidrs` - List of public subnet CIDRs
- `private_subnet_cidrs` - List of private subnet CIDRs (empty = no private subnets)
- `enable_nat_gateway` - Enable NAT for private subnets
- `single_nat_gateway` - Cost optimization vs HA NAT
- `enable_flow_logs` - VPC Flow Logs for security monitoring
- `tags` - Additional tags to merge

**New Outputs** (`modules/networking/outputs.tf`):
- `vpc_id`, `vpc_cidr`
- `public_subnet_ids` (list)
- `private_subnet_ids` (list)
- `nat_gateway_ids` (list)
- `public_subnet_id` (deprecated, backward compatibility)

**Implementation Pattern**:
- Use `count` with `length(var.availability_zones)` for dynamic subnet creation
- Use `for_each` for route table associations
- Conditional NAT: `count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0`

---

### 2. New Compute Module

**File**: `modules/compute/main.tf`

**Resources**:
1. **AMI Data Source** - Configurable filters for Ubuntu/Amazon Linux/custom AMIs
2. **SSH Key Pair** - Conditional creation with file or string input
3. **IAM Instance Profile** - Optional, for attaching IAM roles
4. **EC2 Instance** - Fully configurable with security best practices

**Key Features**:
- Flexible AMI selection (specific ID or filter-based lookup)
- SSH key management (create new or use existing)
- IMDSv2 enforcement (metadata security)
- EBS encryption by default
- Root volume customization (type, size, encryption)
- Additional EBS volumes support
- User data with replace-on-change option
- CloudWatch detailed monitoring (configurable)
- Lifecycle ignore for AMI changes

**Variables** (`modules/compute/variables.tf`):
- `project_name`, `environment` (required)
- `instance_type` (with validation for t2/t3 types)
- `subnet_id`, `security_group_ids`
- `associate_public_ip_address` (default: true)
- `ami_id` (optional override), `ami_filters`, `ami_owners`
- `create_key_pair`, `ssh_public_key_path`, `ssh_public_key`
- `create_instance_profile`, `iam_role_name`
- `user_data`, `user_data_replace_on_change`
- `root_volume_type`, `root_volume_size`, `root_volume_encrypted`
- `require_imdsv2` (default: true)
- `tags`

**Outputs** (`modules/compute/outputs.tf`):
- `instance_id`, `instance_arn`
- `instance_public_ip`, `instance_private_ip`
- `instance_public_dns`, `instance_private_dns`
- `key_pair_name`, `key_pair_fingerprint`

---

### 3. New Security Module

**File**: `modules/security/main.tf`

**Resources**:
1. **Security Group** - Main security group
2. **Dynamic Ingress Rules** - Custom rules via variable
3. **Predefined Rules** - SSH, HTTP, HTTPS with enable flags
4. **Dynamic Egress Rules** - Custom egress or default allow-all

**Key Features**:
- Rule templating with predefined patterns
- SSH CIDR validation (prevents 0.0.0.0/0)
- Dynamic rule creation using `for_each`
- Support for CIDR-based and SG-based rules
- Flexible egress control

**Variables** (`modules/security/variables.tf`):
- `project_name`, `environment`, `vpc_id` (required)
- `security_group_name`, `security_group_description`
- **Predefined rules**:
  - `enable_ssh_rule`, `ssh_cidr_blocks` (with validation)
  - `enable_http_rule`, `http_cidr_blocks`
  - `enable_https_rule`, `https_cidr_blocks`
- **Custom rules**:
  - `ingress_rules` (list of objects)
  - `egress_rules` (list of objects)
- `tags`

**Security Hardening**:
```hcl
# SSH CIDR validation in variables.tf
validation {
  condition     = !contains(var.ssh_cidr_blocks, "0.0.0.0/0")
  error_message = "SSH should not be open to 0.0.0.0/0"
}
```

**Outputs** (`modules/security/outputs.tf`):
- `security_group_id`, `security_group_arn`
- `security_group_name`, `security_group_vpc_id`

---

## Implementation Steps

### Phase 1: Create New Modules

#### 1.1 Compute Module
- [ ] Create `modules/compute/` directory
- [ ] Create `modules/compute/main.tf` (AMI data source, key pair, instance profile, EC2 instance)
- [ ] Create `modules/compute/variables.tf` (all configurable inputs)
- [ ] Create `modules/compute/outputs.tf` (instance details, IPs, key pair info)
- [ ] Create `modules/compute/README.md` (usage examples, security notes)

#### 1.2 Security Module
- [ ] Create `modules/security/` directory
- [ ] Create `modules/security/main.tf` (security group, dynamic rules, predefined rules)
- [ ] Create `modules/security/variables.tf` (with SSH CIDR validation)
- [ ] Create `modules/security/outputs.tf` (security group details)
- [ ] Create `modules/security/README.md` (security best practices)

#### 1.3 Enhance Networking Module
- [ ] Update `modules/networking/main.tf`:
  - Enable DNS hostnames on VPC
  - Convert single subnet to dynamic list with `count`
  - Add private subnets (conditional)
  - Add Elastic IPs for NAT gateways
  - Add NAT gateways (conditional, single or HA)
  - Add private route tables with NAT routes
  - Add VPC Flow Logs (conditional)
- [ ] Update `modules/networking/variables.tf`:
  - Replace `cidr_block` with `vpc_cidr`
  - Replace single subnet vars with lists
  - Add `availability_zones`, `enable_nat_gateway`, `single_nat_gateway`, `enable_flow_logs`, `tags`
- [ ] Update `modules/networking/outputs.tf`:
  - Change outputs to lists (backward compatible with `[0]` accessor)
  - Add NAT gateway outputs
- [ ] Create `modules/networking/README.md`

---

### Phase 2: Update Dev Environment

**Critical Files**:
- `environment/dev/main.tf`
- `environment/dev/variables.tf`
- `environment/dev/outputs.tf`
- `environment/dev/security.tf` (DELETE)

#### 2.1 Update `environment/dev/main.tf`

Replace inline resources with module calls:

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a"]
  public_subnet_cidrs = ["10.0.1.0/24"]
  private_subnet_cidrs = []  # No private subnets for dev
  enable_nat_gateway = false
  enable_flow_logs   = false
  tags = var.common_tags
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"
  enable_ssh_rule     = true
  ssh_cidr_blocks     = var.ssh_allowed_cidrs  # User must set this
  enable_http_rule    = true
  enable_https_rule   = false
  tags = var.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = "t2.micro"
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = true
  create_key_pair            = true
  ssh_public_key_path        = "~/.ssh/devblog.pub"

  root_volume_type     = "gp3"
  root_volume_size     = 20
  root_volume_encrypted = true
  require_imdsv2       = true

  tags = var.common_tags
}
```

Delete inline resources:
- Remove `data "aws_ami" "ubuntu"`
- Remove `resource "aws_key_pair" "main"`
- Remove `resource "aws_instance" "main"`

#### 2.2 Update `environment/dev/variables.tf`

Add new variables:
```hcl
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH (set to your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # User must change this
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "DevBlog"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

#### 2.3 Update `environment/dev/outputs.tf`

```hcl
output "vpc_id" {
  value = module.networking.vpc_id
}

output "instance_id" {
  value = module.compute.instance_id
}

output "instance_public_ip" {
  value = module.compute.instance_public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/devblog ubuntu@${module.compute.instance_public_ip}"
}

output "security_group_id" {
  value = module.security.security_group_id
}
```

#### 2.4 Delete `environment/dev/security.tf`

All security group logic now in security module.

---

### Phase 3: Update Staging Environment

**Critical Files**:
- `environment/staging/main.tf`
- `environment/staging/variables.tf`
- `environment/staging/outputs.tf`
- `environment/staging/security.tf` (DELETE)

#### 3.1 Update `environment/staging/main.tf`

Multi-AZ configuration with private subnets:

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization
  enable_flow_logs   = false
  tags = var.common_tags
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"
  enable_ssh_rule     = true
  ssh_cidr_blocks     = var.ssh_allowed_cidrs
  enable_http_rule    = true
  enable_https_rule   = true  # HTTPS for staging
  tags = var.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = "t3.micro"
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = true
  create_key_pair            = true
  ssh_public_key_path        = "~/.ssh/devblog.pub"

  root_volume_size     = 30  # Larger for staging
  root_volume_encrypted = true
  require_imdsv2       = true

  tags = var.common_tags
}
```

#### 3.2 Update variables and outputs

Same pattern as dev, but with `environment = "staging"` defaults.

#### 3.3 Delete `environment/staging/security.tf`

---

### Phase 4: Create Production Environment

**New Directory**: `environment/prod/`

#### 4.1 Create `environment/prod/providers.tf`

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31"
    }
  }
  backend "s3" {
    bucket       = "devblog-terraform-state"
    key          = "prod.tfstate"
    region       = "us-east-1"
    profile      = "slime"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "slime"

  default_tags {
    tags = {
      Project     = "DevBlog"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
```

#### 4.2 Create `environment/prod/main.tf`

HA configuration with strict security:

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.2.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # HA NAT per AZ
  enable_flow_logs   = true   # Security monitoring
  tags = var.common_tags
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"
  enable_ssh_rule     = true
  ssh_cidr_blocks     = var.ssh_allowed_cidrs  # MUST be set, validated
  enable_http_rule    = true
  enable_https_rule   = true
  tags = var.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = "t3.small"  # Larger for production
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = true
  create_key_pair            = true
  ssh_public_key_path        = "~/.ssh/devblog.pub"

  root_volume_size     = 50  # Production storage
  root_volume_encrypted = true
  require_imdsv2       = true

  enable_detailed_monitoring = true  # CloudWatch monitoring

  tags = var.common_tags
}
```

#### 4.3 Create `environment/prod/variables.tf`

**CRITICAL**: Add SSH validation to prevent 0.0.0.0/0:

```hcl
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks for SSH - MUST be your office/VPN IP"
  type        = list(string)

  validation {
    condition     = !contains(var.ssh_allowed_cidrs, "0.0.0.0/0")
    error_message = "SSH cannot be open to 0.0.0.0/0 in production"
  }
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "DevBlog"
    Environment = "production"
    ManagedBy   = "terraform"
    Compliance  = "required"
  }
}
```

#### 4.4 Create `environment/prod/outputs.tf` and `terraform.tfvars`

Same pattern as dev/staging.

---

### Phase 5: State Migration (for dev/staging)

Since we're refactoring existing resources into modules, use Terraform state move:

```bash
cd environment/dev

# Move networking resources (already done, verify)
terraform state list | grep aws_vpc

# Move security group to module
terraform state mv aws_security_group.main module.security.aws_security_group.main

# Move compute resources to module
terraform state mv aws_instance.main module.compute.aws_instance.main
terraform state mv aws_key_pair.main 'module.compute.aws_key_pair.main[0]'

# Run plan to verify (should show no changes except adds for new features)
terraform plan
```

Repeat for staging environment.

---

## Critical Files to Create/Modify

### NEW FILES (15 total):

**Compute Module**:
1. `modules/compute/main.tf`
2. `modules/compute/variables.tf`
3. `modules/compute/outputs.tf`
4. `modules/compute/README.md`

**Security Module**:
5. `modules/security/main.tf`
6. `modules/security/variables.tf`
7. `modules/security/outputs.tf`
8. `modules/security/README.md`

**Networking Module**:
9. `modules/networking/README.md`

**Production Environment**:
10. `environment/prod/providers.tf`
11. `environment/prod/main.tf`
12. `environment/prod/variables.tf`
13. `environment/prod/outputs.tf`
14. `environment/prod/terraform.tfvars`
15. `environment/prod/.terraform.lock.hcl` (after init)

### MODIFY FILES (9 total):

**Networking Module**:
1. `modules/networking/main.tf` - Add multi-AZ, NAT, private subnets
2. `modules/networking/variables.tf` - New variables
3. `modules/networking/output.tf` - List outputs

**Dev Environment**:
4. `environment/dev/main.tf` - Use all modules
5. `environment/dev/variables.tf` - Add ssh_allowed_cidrs, common_tags
6. `environment/dev/outputs.tf` - Module outputs

**Staging Environment**:
7. `environment/staging/main.tf` - Use all modules with multi-AZ
8. `environment/staging/variables.tf` - Add new variables
9. `environment/staging/outputs.tf` - Module outputs

### DELETE FILES (2 total):
1. `environment/dev/security.tf`
2. `environment/staging/security.tf`

---

## Security Hardening Summary

### Critical Fixes:
1. **SSH Access**: Replace 0.0.0.0/0 with user-specific CIDR (e.g., office IP)
2. **Production Validation**: SSH CIDR validation prevents 0.0.0.0/0 in prod
3. **Encryption**: EBS root volumes encrypted by default
4. **IMDSv2**: Required for all instances (prevents SSRF attacks)
5. **Flow Logs**: Enabled in production for security monitoring
6. **HTTPS**: Added to staging and production

### Before Deployment:
- [ ] Set `ssh_allowed_cidrs` to your actual IP (use `curl ifconfig.me`)
- [ ] Create S3 bucket for prod state if using different bucket
- [ ] Verify AWS credentials profile "slime" is configured

---

## Verification Steps

### 1. Module Validation
```bash
terraform -chdir=modules/networking validate
terraform -chdir=modules/compute validate
terraform -chdir=modules/security validate
```

### 2. Environment Planning
```bash
# Dev
cd environment/dev
terraform init -upgrade
terraform plan  # Should show resource moves, minimal changes

# Staging
cd environment/staging
terraform init -upgrade
terraform plan

# Production
cd environment/prod
terraform init
terraform plan
```

### 3. Deployment Order
1. Apply dev (test module integration)
2. Verify dev instance is accessible
3. Apply staging (test multi-AZ, NAT)
4. Verify staging instance
5. Apply production (after setting SSH CIDRs)

### 4. Post-Deployment Tests
```bash
# Test SSH access
ssh -i ~/.ssh/devblog ubuntu@<instance-public-ip>

# Test HTTP access (if web server installed)
curl http://<instance-public-ip>

# Verify security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify instance metadata is IMDSv2
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].MetadataOptions'
```

---

## Cost Impact

### Development: ~$10-15/month
- 1 t2.micro instance: ~$8.50/month
- Elastic IP (if stopped): $3.65/month
- Data transfer: minimal

### Staging: ~$25-35/month
- 1 t3.micro instance: ~$7.50/month
- 1 NAT Gateway: ~$32/month
- 2 AZs, public/private subnets

### Production: ~$150-200/month
- 1 t3.small instance: ~$15/month
- 3 NAT Gateways (HA): ~$96/month
- VPC Flow Logs: ~$5-10/month
- CloudWatch detailed monitoring: ~$5/month
- 3 AZs with full redundancy

**Cost Optimization Tips**:
- Use `single_nat_gateway = true` in staging
- Disable `enable_flow_logs` in non-prod
- Use smaller instance types for testing
- Stop instances when not in use

---

## Tagging Strategy

All resources tagged with:
- `Name` - `{project}-{environment}-{resource}`
- `Project` - "DevBlog"
- `Environment` - "dev"/"staging"/"prod"
- `ManagedBy` - "terraform"
- `CostCenter` - Environment-specific
- `Compliance` - "required" (prod only)

Applied via:
- Provider `default_tags` (environment-wide)
- Module `tags` variable (resource-specific)
- `merge(var.tags, {...})` in modules

---

## Future Enhancements

Post-implementation:
1. Auto Scaling Groups (replace single instance)
2. Application Load Balancer (multi-AZ HA)
3. RDS module (database tier)
4. Secrets Manager module (API keys, passwords)
5. CloudWatch alarms module (monitoring)
6. Backup module (AWS Backup integration)
7. Module versioning (git tags)
8. CI/CD pipeline (GitHub Actions)

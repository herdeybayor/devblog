# DevBlog Terraform Infrastructure

Modular Terraform infrastructure for the DevBlog project with support for dev, staging, and production environments.

## 📁 Directory Structure

```
terraform/
├── modules/                    # Reusable infrastructure modules
│   ├── networking/            # VPC, subnets, NAT gateway, Flow Logs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security/              # Security groups with rule templates
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── compute/               # EC2 instances, key pairs, IAM
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── environment/               # Environment-specific configurations
│   ├── dev/                  # Development (1 AZ, public only)
│   │   ├── providers.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/              # Staging (2 AZ, private subnets, 1 NAT)
│   │   ├── providers.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/                 # Production (3 AZ, HA NAT, Flow Logs)
│       ├── providers.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── DEPLOYMENT_GUIDE.md       # Comprehensive deployment guide
├── STATE_MIGRATION.sh        # Automated state migration script
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with profile "slime"
2. **Terraform** >= 1.5
3. **SSH key pair** at `~/.ssh/devblog.pub`
4. Your **public IP** for SSH access

### Get Your IP

```bash
curl ifconfig.me
# Result: 203.0.113.50 (example)
```

### Deploy Dev Environment

```bash
cd environment/dev

# Initialize
terraform init

# Plan
terraform plan -var="ssh_allowed_cidrs=[\"203.0.113.50/32\"]"

# Apply
terraform apply -var="ssh_allowed_cidrs=[\"203.0.113.50/32\"]"

# Get SSH command
terraform output ssh_command
```

### Deploy Staging Environment

```bash
cd environment/staging

terraform init
terraform plan -var="ssh_allowed_cidrs=[\"203.0.113.50/32\"]"
terraform apply -var="ssh_allowed_cidrs=[\"203.0.113.50/32\"]"
```

### Deploy Production Environment

```bash
cd environment/prod

# Update terraform.tfvars with your IP first!
# ssh_allowed_cidrs = ["203.0.113.50/32"]

terraform init
terraform plan
terraform apply
```

## 📊 Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Availability Zones** | 1 | 2 | 3 |
| **Public Subnets** | 1 | 2 | 3 |
| **Private Subnets** | 0 | 2 | 3 |
| **NAT Gateway** | None | 1 (shared) | 3 (HA) |
| **VPC Flow Logs** | No | No | Yes |
| **Instance Type** | t2.micro | t3.micro | t3.small |
| **Root Volume** | 20 GB | 30 GB | 50 GB |
| **Detailed Monitoring** | No | No | Yes |
| **SSH Access** | Your IP | Your IP | Validated (no 0.0.0.0/0) |
| **Monthly Cost** | ~$10-15 | ~$40-50 | ~$150-200 |

## 🔒 Security Features

### All Environments

- ✅ **EBS Encryption**: All root volumes encrypted by default
- ✅ **IMDSv2**: Instance Metadata Service V2 enforced (prevents SSRF)
- ✅ **Security Groups**: Modular, validated rules
- ✅ **SSH Key Management**: Separate key pairs per environment

### Production Only

- ✅ **SSH CIDR Validation**: Cannot use 0.0.0.0/0
- ✅ **VPC Flow Logs**: Network traffic monitoring
- ✅ **High Availability**: Resources across 3 AZs
- ✅ **Detailed Monitoring**: CloudWatch metrics every 1 minute

## 📖 Module Documentation

Each module has comprehensive documentation:

- **[Networking Module](modules/networking/README.md)** - VPC, subnets, NAT, Flow Logs
- **[Security Module](modules/security/README.md)** - Security groups, SSH validation
- **[Compute Module](modules/compute/README.md)** - EC2 instances, IMDSv2, encryption

## 🔄 State Migration

If you have existing infrastructure, use the migration script:

```bash
# Migrate dev environment
./STATE_MIGRATION.sh dev

# Migrate staging environment
./STATE_MIGRATION.sh staging
```

Or follow the [Deployment Guide](DEPLOYMENT_GUIDE.md) for manual migration.

## 💰 Cost Management

### Monthly Estimates (us-east-1)

**Development**:
- EC2 t2.micro: ~$8.50
- EBS 20GB gp3: ~$1.60
- **Total: ~$10-15/month**

**Staging**:
- EC2 t3.micro: ~$7.50
- NAT Gateway: ~$32.85
- EBS 30GB gp3: ~$2.40
- **Total: ~$40-50/month**

**Production**:
- EC2 t3.small: ~$15.00
- 3x NAT Gateways: ~$98.55
- VPC Flow Logs: ~$5-10
- EBS 50GB gp3: ~$4.00
- CloudWatch Monitoring: ~$5.00
- **Total: ~$150-200/month**

### Cost Optimization

1. **Dev**: Stop instances when not in use
   ```bash
   cd environment/dev
   aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id) --profile slime
   ```

2. **Staging**: Already using single NAT gateway (cost-optimized)

3. **Production**: Evaluate if 3 NAT gateways needed
   - Single NAT: Saves ~$65/month
   - Trade-off: No HA if single AZ fails

## 🛠️ Common Operations

### SSH to Instance

```bash
cd environment/<env>
$(terraform output -raw ssh_command)
```

### Update SSH CIDR

```bash
# Get new IP
MY_IP=$(curl -s ifconfig.me)

# Update and apply
terraform apply -var="ssh_allowed_cidrs=[\"${MY_IP}/32\"]"
```

### Scale Instance Type

```bash
# Edit variables.tf or use -var
terraform apply -var="instance_type=t3.medium"
```

### View All Resources

```bash
terraform state list
```

### Destroy Environment

```bash
# Warning: This deletes everything!
terraform destroy
```

## 📋 Deployment Checklist

Before deploying to production:

- [ ] Set `ssh_allowed_cidrs` in `prod/terraform.tfvars`
- [ ] Verify SSH key exists at `~/.ssh/devblog.pub`
- [ ] Test SSH access in dev/staging first
- [ ] Review cost estimates
- [ ] Confirm AWS credentials are correct
- [ ] Back up any existing state files
- [ ] Review the deployment plan carefully
- [ ] Set up CloudWatch alarms (post-deployment)
- [ ] Document SSH access IPs securely

## 🐛 Troubleshooting

### SSH Validation Error

```
Error: SSH should not be open to 0.0.0.0/0
```

**Solution**: Set your IP address:
```bash
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### State Migration Failed

```
Error: Resource not found in state
```

**Solution**: Check existing state:
```bash
terraform state list
terraform state show <resource-name>
```

### NAT Gateway Timeout

NAT gateways take 3-5 minutes to create. This is normal AWS behavior.

### Module Not Found

```
Error: Module not installed
```

**Solution**: Run `terraform init -upgrade`

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws)
- [Terraform Module Best Practices](https://www.terraform.io/docs/language/modules/develop/index.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🤝 Contributing

When adding new infrastructure:

1. Use modules for reusable components
2. Add comprehensive documentation (README.md)
3. Include usage examples
4. Follow security best practices
5. Test in dev before staging/prod
6. Update cost estimates

## 📄 License

This infrastructure code is part of the DevBlog project.

---

**Need help?** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

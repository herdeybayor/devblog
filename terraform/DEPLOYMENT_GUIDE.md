# Terraform Modularization - Deployment Guide

This guide walks you through deploying the refactored Terraform infrastructure with modular architecture.

## Overview

The infrastructure has been refactored from inline resources to reusable modules:

- ✅ **Networking Module**: VPC, subnets, NAT gateway, VPC Flow Logs
- ✅ **Security Module**: Security groups with predefined and custom rules
- ✅ **Compute Module**: EC2 instances, key pairs, IAM profiles

## Pre-Deployment Checklist

### 1. Set SSH Access IP

**CRITICAL**: Update `ssh_allowed_cidrs` before deploying to prevent SSH lockout or security issues.

```bash
# Get your current public IP
curl ifconfig.me

# Result example: 203.0.113.50
```

Then update the appropriate `terraform.tfvars` or set via command line:

```bash
# Command line (recommended for testing)
terraform apply -var="ssh_allowed_cidrs=[\"203.0.113.50/32\"]"

# Or update terraform.tfvars
ssh_allowed_cidrs = ["203.0.113.50/32"]
```

### 2. Verify SSH Key Exists

Ensure your SSH public key exists at `~/.ssh/devblog.pub`:

```bash
# Check if key exists
ls -la ~/.ssh/devblog.pub

# If not, create one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/devblog -C "devblog"
```

### 3. Verify AWS Credentials

Ensure AWS profile "slime" is configured:

```bash
aws sts get-caller-identity --profile slime
```

## Module Validation

Before deploying, validate all modules:

```bash
# Validate networking module
cd modules/networking
terraform init
terraform validate
cd ../..

# Validate security module
cd modules/security
terraform init
terraform validate
cd ../..

# Validate compute module
cd modules/compute
terraform init
terraform validate
cd ../..
```

## Deployment Order

Deploy in this order to minimize disruption:

1. **Dev** - Test module integration
2. **Staging** - Validate multi-AZ setup
3. **Production** - Deploy with full HA

---

## Dev Environment Deployment

### State Migration (Existing Resources)

Since dev environment already exists, we need to migrate resources to modules:

```bash
cd environment/dev

# Step 1: Initialize with new modules
terraform init -upgrade

# Step 2: Import existing resources to module state
# Note: Networking resources should already be in the module

# Move security group to security module
terraform state mv aws_security_group.main module.security.aws_security_group.main

# Move compute resources to compute module
terraform state mv aws_instance.main module.compute.aws_instance.main
terraform state mv aws_key_pair.main 'module.compute.aws_key_pair.main[0]'

# Step 3: Handle networking module updates
# The networking module now uses lists, so we need to update state

# Move VPC subnets to list format
terraform state mv 'module.networking.aws_subnet.public' 'module.networking.aws_subnet.public[0]'
terraform state mv 'module.networking.aws_route_table_association.public' 'module.networking.aws_route_table_association.public[0]'

# Step 4: Verify plan shows minimal changes
terraform plan -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"

# Expected changes:
# - VPC: enable_dns_hostnames added
# - Subnets: additional tags
# - Instance: IMDSv2 metadata_options
# - Security group moved to module

# Step 5: Apply changes
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### Fresh Deployment (No Existing Resources)

If this is a fresh deployment:

```bash
cd environment/dev

# Initialize
terraform init

# Plan
terraform plan -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"

# Apply
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### Verify Deployment

```bash
# Get outputs
terraform output

# Test SSH access
terraform output -raw ssh_command | sh

# Verify IMDSv2
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].MetadataOptions' \
  --profile slime
```

---

## Staging Environment Deployment

### State Migration (Existing Resources)

```bash
cd environment/staging

# Step 1: Initialize with new modules
terraform init -upgrade

# Step 2: Move security group to security module
terraform state mv aws_security_group.main module.security.aws_security_group.main

# Step 3: Move compute resources to compute module
terraform state mv aws_instance.main module.compute.aws_instance.main
terraform state mv aws_key_pair.main 'module.compute.aws_key_pair.main[0]'

# Step 4: Handle networking module updates
terraform state mv 'module.networking.aws_subnet.public' 'module.networking.aws_subnet.public[0]'
terraform state mv 'module.networking.aws_route_table_association.public' 'module.networking.aws_route_table_association.public[0]'

# Step 5: Plan (will show new resources: private subnets, NAT gateway)
terraform plan -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"

# Expected new resources:
# + 2 private subnets
# + 1 NAT gateway
# + 1 Elastic IP
# + Private route tables

# Step 6: Apply
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### Fresh Deployment

```bash
cd environment/staging

terraform init
terraform plan -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
terraform apply -var="ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]"
```

### Verify Multi-AZ Setup

```bash
# Check subnets across AZs
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --profile slime

# Check NAT gateway
terraform output nat_gateway_ids
terraform output nat_eip_public_ips
```

---

## Production Environment Deployment

### Prerequisites

**IMPORTANT**: Production has strict validation:

1. SSH CIDR cannot be `0.0.0.0/0` (will fail validation)
2. Must specify at least one CIDR block
3. Recommended: Use VPN or office IP range

### Set SSH Access

Update `environment/prod/terraform.tfvars`:

```hcl
# Option 1: Specific IP
ssh_allowed_cidrs = ["203.0.113.50/32"]

# Option 2: Office network
ssh_allowed_cidrs = ["203.0.113.0/24"]

# Option 3: Multiple IPs
ssh_allowed_cidrs = [
  "203.0.113.50/32",  # Office
  "198.51.100.10/32"  # VPN
]
```

### Fresh Deployment

```bash
cd environment/prod

# Step 1: Initialize
terraform init

# Step 2: Plan (verify SSH CIDR is set correctly)
terraform plan

# Expected resources:
# - VPC with 3 AZs
# - 3 public subnets + 3 private subnets
# - 3 NAT gateways (HA)
# - VPC Flow Logs
# - Security group with validated SSH access
# - t3.small instance with detailed monitoring

# Step 3: Apply
terraform apply

# Deployment time: ~5-10 minutes (NAT gateways are slow to create)
```

### Verify Production Setup

```bash
# Check all outputs
terraform output

# Verify HA NAT gateways (should have 3)
terraform output nat_gateway_ids

# Verify VPC Flow Logs
terraform output flow_log_cloudwatch_log_group

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --profile slime

# Verify IMDSv2 and detailed monitoring
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].[MetadataOptions,Monitoring]' \
  --profile slime
```

### Monitor VPC Flow Logs

After deployment, query Flow Logs with CloudWatch Insights:

```bash
# Get log group name
terraform output flow_log_cloudwatch_log_group

# In CloudWatch Insights, run:
fields @timestamp, srcAddr, dstAddr, action
| filter action = "REJECT"
| stats count() as rejectedConnections by srcAddr
| sort rejectedConnections desc
| limit 20
```

---

## Post-Deployment Tasks

### 1. Update Documentation

Document your SSH CIDRs in a secure location (not in Git):

```bash
# Create a local documentation file (gitignored)
cat > ~/.ssh/devblog-access.txt <<EOF
Dev SSH CIDR: $(cd environment/dev && terraform output -raw ssh_allowed_cidrs || echo "Not set")
Staging SSH CIDR: $(cd environment/staging && terraform output -raw ssh_allowed_cidrs || echo "Not set")
Prod SSH CIDR: $(cd environment/prod && terraform output -raw ssh_allowed_cidrs || echo "Not set")
EOF
```

### 2. Test SSH Access

```bash
# Dev
cd environment/dev
$(terraform output -raw ssh_command)

# Staging
cd environment/staging
$(terraform output -raw ssh_command)

# Production
cd environment/prod
$(terraform output -raw ssh_command)
```

### 3. Set Up Monitoring

For production, set up CloudWatch alarms:

```bash
cd environment/prod

# Example: CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "devblog-prod-high-cpu" \
  --alarm-description "Alert on high CPU" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --profile slime
```

---

## Troubleshooting

### SSH CIDR Validation Error

**Error**: `SSH should not be open to 0.0.0.0/0`

**Solution**:
```bash
# Get your IP
MY_IP=$(curl -s ifconfig.me)

# Apply with correct CIDR
terraform apply -var="ssh_allowed_cidrs=[\"${MY_IP}/32\"]"
```

### State Migration Issues

**Error**: `Resource not found in state`

**Solution**:
```bash
# List all resources in state
terraform state list

# If resource exists but at wrong path, move it:
terraform state mv <old-path> <new-path>

# Example:
terraform state mv aws_instance.main module.compute.aws_instance.main
```

### Networking Module Errors

**Error**: `Subnet CIDR count doesn't match AZ count`

**Solution**: Ensure `public_subnet_cidrs` length matches `availability_zones` length.

### NAT Gateway Slow

NAT gateways take 3-5 minutes to create. This is normal AWS behavior.

---

## Rollback Plan

If deployment fails and you need to rollback:

### Dev/Staging (with existing resources)

```bash
# Option 1: Revert code changes
git checkout HEAD^ environment/dev/
git checkout HEAD^ environment/staging/

# Option 2: Destroy new resources
terraform destroy -target=module.networking.aws_nat_gateway.main
terraform destroy -target=module.networking.aws_subnet.private
```

### Production (fresh deployment)

```bash
cd environment/prod
terraform destroy
```

---

## Cost Monitoring

After deployment, monitor costs:

| Environment | Expected Monthly Cost |
|-------------|----------------------|
| Dev | $10-15 (t2.micro, no NAT) |
| Staging | $40-50 (t3.micro, 1 NAT) |
| Production | $150-200 (t3.small, 3 NATs, Flow Logs) |

### Cost Optimization Tips

1. **Dev**: Stop instance when not in use
2. **Staging**: Use single NAT gateway (already configured)
3. **Production**: Evaluate if 3 NAT gateways are needed (can reduce to 1)

---

## Next Steps

After successful deployment:

1. ✅ Verify all three environments are operational
2. ✅ Test SSH access to all instances
3. ✅ Set up monitoring and alerting (production)
4. ✅ Document SSH access CIDRs securely
5. 🔄 Plan for Auto Scaling Groups (future)
6. 🔄 Plan for Application Load Balancer (future)
7. 🔄 Plan for RDS module (future)

---

## Support

For issues or questions:
- Check module READMEs: `modules/*/README.md`
- Review Terraform docs: https://registry.terraform.io/providers/hashicorp/aws
- Check AWS service quotas: VPC, EC2, NAT Gateway limits

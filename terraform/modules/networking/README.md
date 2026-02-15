# Networking Module

This module creates a complete VPC infrastructure with support for multi-AZ deployment, public and private subnets, NAT gateways, and VPC Flow Logs for security monitoring.

## Features

- **Multi-AZ Support**: Deploy across 1-3 availability zones for high availability
- **Public Subnets**: Internet-accessible subnets with Internet Gateway
- **Private Subnets**: Isolated subnets with optional NAT gateway for outbound traffic
- **NAT Gateway Options**:
  - Single NAT (cost-optimized): All private subnets use one NAT gateway
  - HA NAT (production): One NAT gateway per availability zone
- **VPC Flow Logs**: Optional security monitoring and traffic analysis
- **DNS Support**: DNS hostnames and resolution enabled by default
- **Flexible Configuration**: Adapts from simple dev environments to complex production setups

## Architecture

### Development Environment (Single AZ, Public Only)
```
┌─────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                       │
│                                         │
│  ┌──────────────────────┐               │
│  │ Public Subnet        │               │
│  │ 10.0.1.0/24          │               │
│  │ (us-east-1a)         │               │
│  │                      │               │
│  │ ┌──────────────────┐ │               │
│  │ │ EC2 Instances    │ │               │
│  │ │ (Public IPs)     │ │               │
│  │ └──────────────────┘ │               │
│  └──────────┬───────────┘               │
│             │                           │
│   ┌─────────▼─────────┐                 │
│   │ Internet Gateway  │                 │
│   └───────────────────┘                 │
└─────────────────────────────────────────┘
                │
             Internet
```

### Production Environment (Multi-AZ with Private Subnets)
```
┌────────────────────────────────────────────────────────────────┐
│ VPC (10.2.0.0/16)                                              │
│                                                                │
│ AZ 1 (us-east-1a)         AZ 2 (us-east-1b)         AZ 3 (...)│
│ ┌─────────────────┐       ┌─────────────────┐       ┌────────┐│
│ │ Public Subnet   │       │ Public Subnet   │       │ Public ││
│ │ 10.2.1.0/24     │       │ 10.2.2.0/24     │       │ ...    ││
│ │  ┌────────┐     │       │  ┌────────┐     │       │        ││
│ │  │NAT GW 1│     │       │  │NAT GW 2│     │       │        ││
│ │  └────┬───┘     │       │  └────┬───┘     │       │        ││
│ └───────┼─────────┘       └───────┼─────────┘       └────────┘│
│         │                         │                            │
│ ┌───────▼─────────┐       ┌───────▼─────────┐       ┌────────┐│
│ │ Private Subnet  │       │ Private Subnet  │       │ Private││
│ │ 10.2.11.0/24    │       │ 10.2.12.0/24    │       │ ...    ││
│ │  ┌────────────┐ │       │  ┌────────────┐ │       │        ││
│ │  │ App Servers│ │       │  │ App Servers│ │       │        ││
│ │  └────────────┘ │       │  └────────────┘ │       │        ││
│ └─────────────────┘       └─────────────────┘       └────────┘│
│                                                                │
│   ┌──────────────────────┐                                    │
│   │  Internet Gateway    │                                    │
│   └──────────────────────┘                                    │
└────────────────────────────────────────────────────────────────┘
                   │
                Internet
```

## Usage

### Basic Example (Dev Environment)

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name = "devblog"
  environment  = "dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a"]
  public_subnet_cidrs = ["10.0.1.0/24"]

  # No private subnets, no NAT gateway
  private_subnet_cidrs = []
  enable_nat_gateway   = false
  enable_flow_logs     = false

  tags = {
    Project     = "DevBlog"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Staging Environment (Multi-AZ with Single NAT)

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name = "devblog"
  environment  = "staging"

  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]

  # Single NAT for cost optimization
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_logs = false

  tags = {
    Project     = "DevBlog"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
```

### Production Environment (HA with Flow Logs)

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name = "devblog"
  environment  = "prod"

  vpc_cidr           = "10.2.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs = [
    "10.2.1.0/24",
    "10.2.2.0/24",
    "10.2.3.0/24"
  ]

  private_subnet_cidrs = [
    "10.2.11.0/24",
    "10.2.12.0/24",
    "10.2.13.0/24"
  ]

  # HA NAT - One per AZ
  enable_nat_gateway = true
  single_nat_gateway = false

  # Security monitoring
  enable_flow_logs          = true
  flow_logs_retention_days  = 30
  flow_logs_traffic_type    = "ALL"

  tags = {
    Project     = "DevBlog"
    Environment = "production"
    ManagedBy   = "terraform"
    Compliance  = "required"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | - | yes |
| environment | Environment name (dev/staging/prod) | string | - | yes |
| vpc_cidr | VPC CIDR block | string | - | yes |
| availability_zones | List of AZs (1-3) | list(string) | - | yes |
| public_subnet_cidrs | Public subnet CIDRs (one per AZ) | list(string) | - | yes |
| private_subnet_cidrs | Private subnet CIDRs (empty = none) | list(string) | [] | no |
| enable_dns_hostnames | Enable DNS hostnames | bool | true | no |
| enable_dns_support | Enable DNS support | bool | true | no |
| map_public_ip_on_launch | Auto-assign public IPs | bool | true | no |
| enable_nat_gateway | Enable NAT gateway | bool | false | no |
| single_nat_gateway | Single NAT (true) vs HA NAT (false) | bool | true | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | false | no |
| flow_logs_retention_days | Flow Logs retention | number | 7 | no |
| flow_logs_traffic_type | Traffic type (ACCEPT/REJECT/ALL) | string | "ALL" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_arn | VPC ARN |
| vpc_cidr | VPC CIDR block |
| internet_gateway_id | Internet Gateway ID |
| public_subnet_ids | List of public subnet IDs |
| public_subnet_cidrs | List of public subnet CIDRs |
| public_subnet_availability_zones | List of public subnet AZs |
| private_subnet_ids | List of private subnet IDs |
| private_subnet_cidrs | List of private subnet CIDRs |
| private_subnet_availability_zones | List of private subnet AZs |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_eip_public_ips | List of NAT Gateway Elastic IPs |
| public_route_table_id | Public route table ID |
| private_route_table_ids | List of private route table IDs |
| flow_log_id | VPC Flow Log ID (if enabled) |
| flow_log_cloudwatch_log_group | CloudWatch Log Group for Flow Logs |

## Cost Considerations

### NAT Gateway Pricing (us-east-1, as of 2024)

- **NAT Gateway**: $0.045/hour (~$32.85/month per NAT)
- **Data Processing**: $0.045/GB processed
- **Single NAT**: ~$32.85/month + data
- **HA NAT (3 AZs)**: ~$98.55/month + data

**Cost Optimization Tips**:
1. **Dev**: No NAT gateway (use public subnets only) - $0
2. **Staging**: Single NAT gateway - ~$33/month
3. **Production**: HA NAT per AZ (required for reliability) - ~$99/month

### VPC Flow Logs Pricing

- **CloudWatch Logs Ingestion**: $0.50/GB
- **Storage**: $0.03/GB/month
- **Typical small app**: ~$5-10/month
- **High traffic app**: $50+/month

**Recommendation**: Enable Flow Logs only in production or during security investigations.

## Best Practices

### Subnet Sizing

Use appropriate CIDR sizes for your needs:

```hcl
# Small (251 usable IPs)
public_subnet_cidrs = ["10.0.1.0/24"]

# Medium (507 usable IPs)
public_subnet_cidrs = ["10.0.1.0/23"]

# Large (1019 usable IPs)
public_subnet_cidrs = ["10.0.1.0/22"]
```

**AWS reserves 5 IPs per subnet**: .0 (network), .1 (VPC router), .2 (DNS), .3 (future), .255 (broadcast)

### High Availability

For production, use at least 2 AZs:

```hcl
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### Security Layers

Proper tier separation:

```hcl
# Public tier: Load balancers, bastion hosts
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Private tier: Application servers, databases
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
```

### VPC Flow Logs

Enable in production for:
- Security incident investigation
- Network traffic analysis
- Compliance requirements

```hcl
enable_flow_logs         = true
flow_logs_retention_days = 30  # Compliance: 30-90 days
flow_logs_traffic_type   = "ALL"
```

Query Flow Logs with CloudWatch Insights:

```
# Top talkers
fields @timestamp, srcAddr, dstAddr, bytes
| filter action = "ACCEPT"
| stats sum(bytes) as totalBytes by srcAddr
| sort totalBytes desc
| limit 10

# Rejected connections (potential attacks)
fields @timestamp, srcAddr, dstAddr, dstPort
| filter action = "REJECT"
| stats count() as rejectedConnections by srcAddr, dstPort
| sort rejectedConnections desc
```

## Migration from Single-AZ to Multi-AZ

If you have an existing single-AZ setup, migrate carefully:

```hcl
# Step 1: Add new AZs and subnets
availability_zones = ["us-east-1a", "us-east-1b"]  # Add us-east-1b

public_subnet_cidrs = [
  "10.0.1.0/24",  # Existing
  "10.0.2.0/24"   # New
]

# Step 2: Deploy new subnets (no interruption)
terraform apply

# Step 3: Migrate workloads to use both AZs
# Step 4: Update Auto Scaling Groups, Load Balancers to use new subnets
```

## Troubleshooting

### NAT Gateway Not Working

**Symptom**: Private instances can't reach internet

**Check**:
1. NAT gateway is in public subnet: `aws ec2 describe-nat-gateways`
2. Route table has route to NAT: `aws ec2 describe-route-tables`
3. Security groups allow outbound traffic
4. Network ACLs allow traffic (default allows all)

### VPC Flow Logs Not Appearing

**Symptom**: No logs in CloudWatch

**Check**:
1. IAM role has correct permissions
2. Log group exists: `aws logs describe-log-groups`
3. Wait 10-15 minutes (Flow Logs have delay)
4. Generate traffic to create log entries

### Subnet CIDR Conflicts

**Symptom**: Terraform error about overlapping CIDRs

**Solution**: Ensure subnets don't overlap:

```hcl
# ❌ BAD - Overlapping
public_subnet_cidrs = ["10.0.1.0/24"]
private_subnet_cidrs = ["10.0.1.0/24"]  # Overlap!

# ✅ GOOD - Non-overlapping
public_subnet_cidrs = ["10.0.1.0/24"]
private_subnet_cidrs = ["10.0.11.0/24"]  # Different range
```

Use [subnet calculator](https://www.subnet-calculator.com/) for planning.

## Examples

See complete examples in the `examples/` directory:
- Single AZ development setup
- Multi-AZ staging with single NAT
- Production HA with Flow Logs
- VPC peering configuration
- Transit Gateway integration

## Notes

- **Backward Compatibility**: Deprecated outputs (`public_subnet_id`) maintained for existing deployments
- **Tagging**: All resources automatically tagged with Name, Environment, and custom tags
- **DNS**: Enabled by default for instance hostname resolution
- **Limits**: AWS default VPC limit is 5 per region (requestable increase to 100+)

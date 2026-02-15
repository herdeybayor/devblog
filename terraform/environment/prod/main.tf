# Production Environment - High Availability Multi-AZ Setup
# 3 AZs for maximum redundancy, HA NAT gateways, VPC Flow Logs

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
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

  # Production: HA NAT gateway (one per AZ)
  enable_nat_gateway = true
  single_nat_gateway = false

  # Security monitoring with VPC Flow Logs
  enable_flow_logs         = true
  flow_logs_retention_days = 30
  flow_logs_traffic_type   = "ALL"

  tags = var.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"

  # Predefined rules with strict SSH access
  enable_ssh_rule   = true
  ssh_cidr_blocks   = var.ssh_allowed_cidrs  # MUST be set, validated
  enable_http_rule  = true
  enable_https_rule = true

  tags = var.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_ids = [module.security.security_group_id]

  associate_public_ip_address = true

  # SSH Key Configuration
  create_key_pair     = true
  ssh_public_key_path = "~/.ssh/devblog.pub"

  # AMI Configuration - Ubuntu 24.04 LTS
  ami_filters = [
    {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    },
    {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  ]
  ami_owners = ["099720109477"] # Canonical

  # Storage Configuration - Production sizing
  root_volume_type      = "gp3"
  root_volume_size      = 50
  root_volume_encrypted = true

  # Security Best Practices
  require_imdsv2             = true
  enable_detailed_monitoring = true  # CloudWatch detailed monitoring

  tags = var.common_tags
}

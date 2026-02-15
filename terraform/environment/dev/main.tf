# Dev Environment - Refactored to use modular architecture
# Single AZ, public subnets only, no NAT gateway

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a"]
  public_subnet_cidrs = ["10.0.1.0/24"]

  # Dev environment: no private subnets, no NAT gateway
  private_subnet_cidrs = []
  enable_nat_gateway   = false
  enable_flow_logs     = false

  tags = var.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  security_group_name = "web-sg"

  # Predefined rules
  enable_ssh_rule  = true
  ssh_cidr_blocks  = var.ssh_allowed_cidrs
  enable_http_rule = true
  enable_https_rule = false  # HTTP only for dev

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

  # Storage Configuration
  root_volume_type      = "gp3"
  root_volume_size      = 20
  root_volume_encrypted = true

  # Security Best Practices
  require_imdsv2             = true
  enable_detailed_monitoring = false  # Not needed for dev

  tags = var.common_tags
}

#!/bin/bash
# Terraform State Migration Script
# Migrates existing resources to new module structure

set -e  # Exit on error

echo "================================================"
echo "Terraform State Migration Script"
echo "Migrates existing resources to module structure"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if resource exists in state
resource_exists() {
    terraform state list | grep -q "^$1$"
}

# Function to safely move state
safe_state_mv() {
    local old_path=$1
    local new_path=$2

    if resource_exists "$old_path"; then
        print_info "Moving $old_path -> $new_path"
        terraform state mv "$old_path" "$new_path"
    else
        print_warning "Resource $old_path not found in state, skipping"
    fi
}

# Determine environment
if [ -z "$1" ]; then
    print_error "Usage: $0 <environment>"
    print_error "Example: $0 dev"
    print_error "         $0 staging"
    exit 1
fi

ENV=$1
ENV_DIR="environment/$ENV"

if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory $ENV_DIR not found"
    exit 1
fi

print_info "Migrating state for environment: $ENV"
cd "$ENV_DIR"

# Step 1: Initialize with new modules
print_info "Step 1: Initializing Terraform with new modules..."
terraform init -upgrade

# Step 2: Create state backup
print_info "Step 2: Creating state backup..."
BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
terraform state pull > "$BACKUP_FILE"
print_info "State backed up to: $BACKUP_FILE"

# Step 3: Migrate security group
print_info "Step 3: Migrating security group to security module..."
safe_state_mv "aws_security_group.main" "module.security.aws_security_group.main"

# Step 4: Migrate compute resources
print_info "Step 4: Migrating compute resources to compute module..."
safe_state_mv "aws_instance.main" "module.compute.aws_instance.main"
safe_state_mv "aws_key_pair.main" "module.compute.aws_key_pair.main[0]"

# Step 5: Migrate networking resources
print_info "Step 5: Migrating networking resources to list format..."
safe_state_mv "module.networking.aws_subnet.public" "module.networking.aws_subnet.public[0]"
safe_state_mv "module.networking.aws_route_table_association.public" "module.networking.aws_route_table_association.public[0]"

# Step 6: Show current state
print_info "Step 6: Current state after migration:"
terraform state list

# Step 7: Validate plan
print_info "Step 7: Validating terraform plan..."
echo ""
print_warning "Please review the plan carefully!"
print_warning "You will need to provide ssh_allowed_cidrs variable"
echo ""
print_info "Example: terraform plan -var='ssh_allowed_cidrs=[\"$(curl -s ifconfig.me)/32\"]'"
echo ""

# Ask user if they want to run plan
read -p "Do you want to run terraform plan now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Getting your IP address..."
    MY_IP=$(curl -s ifconfig.me)
    print_info "Your IP: $MY_IP"

    terraform plan -var="ssh_allowed_cidrs=[\"${MY_IP}/32\"]"

    echo ""
    print_info "Plan complete! Review the changes above."
    print_info "Expected changes:"
    print_info "  - VPC: enable_dns_hostnames added"
    print_info "  - Subnets: additional tags (Tier, AZ)"
    print_info "  - Instance: IMDSv2 metadata_options"
    print_info "  - Security group: moved to module (no changes)"
    echo ""
    print_warning "If the plan looks correct, run:"
    print_warning "  terraform apply -var='ssh_allowed_cidrs=[\"${MY_IP}/32\"]'"
fi

echo ""
print_info "================================================"
print_info "State migration complete for $ENV environment!"
print_info "================================================"
print_info "Backup saved to: $BACKUP_FILE"
print_info ""
print_info "Next steps:"
print_info "1. Review the terraform plan output"
print_info "2. If plan looks correct, apply changes"
print_info "3. Test SSH access to instance"
print_info "4. Verify all resources are working"
echo ""

# Production Environment - Terraform and Provider Configuration

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31"
    }
  }

  # Backend configuration for state management
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
      Compliance  = "required"
    }
  }
}

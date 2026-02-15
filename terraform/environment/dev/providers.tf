terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.31.0"
    }
  }
  backend "s3" {
    bucket = "devblog-terraform-state"
    key = "dev-test.tfstate"
    region = "us-east-1"
    profile = "slime"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
  profile = "slime"
}
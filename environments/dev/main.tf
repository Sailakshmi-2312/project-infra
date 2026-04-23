terraform {
  required_version = ">= 1.6.0"

  # Backend will be configured in Story 3.1
  backend "s3" {
    bucket         = "project-devops-tfstate-c07989f5"
    key            = "environments/dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "project-devops-tflock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "project-devops"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  project_name = "project-devops"
  environment  = "dev"
}
# VPC Module (Story 3.1)
module "vpc" {
  source = "../../modules/vpc"

  project_name       = local.project_name
  environment        = local.environment
  single_nat_gateway = true
}

# EKS Module (Story 4.1)
# module "eks" {
#   source = "../../modules/eks"
#
#   project_name = "techitfactory"
#   environment  = "dev"
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = module.vpc.private_subnet_ids
# }
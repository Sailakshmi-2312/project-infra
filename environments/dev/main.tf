terraform {
  required_version = ">= 1.6.0"

  # Backend will be configured in Story 3.1
  # backend "s3" {
  #   bucket         = "<from-bootstrap>"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "<from-bootstrap>"
  # }

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
      Project     = "TechITFactory"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Module (Story 3.1)
# module "vpc" {
#   source = "../../modules/vpc"
#
#   project_name       = "techitfactory"
#   environment        = "dev"
#   single_nat_gateway = true
# }

# EKS Module (Story 4.1)
# module "eks" {
#   source = "../../modules/eks"
#
#   project_name = "techitfactory"
#   environment  = "dev"
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = module.vpc.private_subnet_ids
# }
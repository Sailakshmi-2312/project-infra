# Terraform Bootstrap - S3 + DynamoDB + KMS
# This will be implemented in Story 2.1
# new comment
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "project-devops"
  default_tags {
    tags = var.tags
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4 #8 hex characters
}

locals {
  #bucket_name: project-devops-tfstate-<random>
  bucket_name = "${var.project_name}-tfstate-${random_id.bucket_suffix.hex}"

  #dynamoDB table: project-devops-tflock
  table_name = "${var.project_name}-tflock"
}
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7    # Wait 7 days before permanent deletion
  enable_key_rotation     = true # Auto-rotate key annually

  tags = {
    Name = "${var.project_name}-tfstate-key"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.project_name}-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.bucket_name
  force_destroy = true # Terraform will remove all object versions/delete markers before deleting bucke
  lifecycle {
    prevent_destroy = false # Set to 'true' in production to prevent accidental deletion
  }
  tags = {
    name = local.bucket_name
  }
}


resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # recude the KMS calls : cost optimization
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# hash_key = primary key name
# attribute = aa key data type

resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Lock_ID"
  attribute {
    name = "Lock_ID"
    type = "S"
  }
  tags = {
    Name = local.table_name
  }
}
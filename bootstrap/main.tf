# Bootstrap: створює S3 bucket і DynamoDB table для Terraform remote state.
# Запусти ОДИН РАЗ вручну перед використанням основних Terraform конфігів.
#
#   cd bootstrap
#   terraform init
#   terraform apply
#

terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy  = "terraform-bootstrap"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name (used for bucket/table names)"
  type        = string
  default     = "terraform-aws-import"
}

locals {
  state_bucket_name = "${var.project}-terraform-state"
  lock_table_name  = "${var.project}-terraform-lock"
}

# --- S3 Bucket для Terraform State ---
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  tags = {
    Name = local.state_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- DynamoDB Table для State Locking ---
resource "aws_dynamodb_table" "lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.lock_table_name
  }
}

# --- Outputs ---
output "state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.lock.name
}

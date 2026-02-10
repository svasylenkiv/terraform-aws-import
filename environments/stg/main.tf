terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key     = "stg/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "stg"
}

# ---------------------------------------------------------------------------
# Імпортовані ресурси додаються нижче або в окремих *.tf файлах.
# Використовуйте import blocks для імпорту:
#
# import {
#   to = aws_instance.example
#   id = "i-1234567890abcdef0"
# }
#
# Потім: terraform plan -generate-config-out=generated.tf
# ---------------------------------------------------------------------------

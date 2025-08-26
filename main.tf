terraform {
  required_version = ">= 1.4.0"

  # Terraform Cloud / Enterprise remote backend
  backend "remote" {
    hostname     = "app.terraform.io"   # or your Terraform Enterprise hostname
    organization = "terraform-opa-testing"         # <-- replace with your org name

    workspaces {
      name = "terraform-opa-demo"              # <-- must match your TFC workspace name
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS provider – credentials are injected via Terraform Cloud workspace variables
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Variables that Terraform Cloud will supply (set in the workspace UI)
variable "aws_access_key_id" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

# Unique suffix so bucket name is globally unique each run
resource "random_id" "suffix" {
  byte_length = 4
}

# The bucket itself
resource "aws_s3_bucket" "example" {
  bucket = "opa-demo-bucket-${random_id.suffix.hex}"

  tags = {
    Name        = "opa-demo-bucket"
    Owner       = "platform"
    CostCenter  = "demo"
    Environment = "dev"
  }
}

# Best practice: block all public access on the bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption so we PASS the OPA policy
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

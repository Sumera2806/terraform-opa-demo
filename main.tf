terraform {
  cloud {
    organization = "terraform-opa-testing" 

    workspaces {
      name = "terraform-opa-demo" 
    }
  }

  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Example S3 bucket resource
resource "aws_s3_bucket" "example" {
  bucket = "my-terraform-demo-bucket-12345"

  tags = {
    Name        = "TerraformDemo"
    Environment = "Dev"
  }
}

# Optional: prevent public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0" # Latest stable version
    }
  }
}

provider "aws" {
  region = "us-east-2" # Must match your resources
}
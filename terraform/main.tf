terraform {
  backend "s3" {
    bucket         = "jotinha-dev-terraform-state-prod"
    key            = "global/infra-base/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jotinha-dev-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc" 

  vpc_cidr           = "10.10.0.0/16"
  public_subnets     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnets    = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}
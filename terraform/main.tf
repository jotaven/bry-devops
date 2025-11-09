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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "jotinha-eks-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids


  eks_managed_node_groups = {
    general_workers = {
      name           = "geral-workers"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5 
      desired_size = 2 

      subnet_ids = module.vpc.private_subnet_ids

      vpc_security_group_ids = [module.security.worker_sg_id]
    }
  }

  enable_irsa = true

  tags = {
    "Terraform" = "true"
    "Project"   = "Jotinha-Desafio"
  }
}
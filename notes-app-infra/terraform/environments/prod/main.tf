terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  project_name = var.project_name
  environment  = "prod"

  common_tags = {
    Project     = local.project_name
    environment = local.environment
    ManagedBy   = "terraform" 
  }
}

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  common_tags          = local.common_tags
}

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  project_name        = local.project_name
  environment         = local.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  kubernetes_version  = var.kubernetes_version
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  common_tags         = local.common_tags
}

# ──────────────────────────────────────────────
# ECR (shared across environments, deploy once)
# ──────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project_name     = local.project_name
  environment      = local.environment
  repository_names = ["frontend", "backend"]
  max_image_count  = 30
  common_tags      = local.common_tags
}

# ──────────────────────────────────────────────
# RDS — Production uses managed RDS for reliability
# ──────────────────────────────────────────────
#module "rds" {
#  source = "../../modules/rds"
#
#  project_name          = local.project_name
#  environment           = local.environment
#  vpc_id                = module.vpc.vpc_id
#  private_subnet_ids    = module.vpc.private_subnet_ids
#  eks_security_group_id = module.eks.cluster_security_group_id
#  instance_class        = "db.t3.small"
#  allocated_storage     = 50
#  max_allocated_storage = 100
#  common_tags           = local.common_tags
#}

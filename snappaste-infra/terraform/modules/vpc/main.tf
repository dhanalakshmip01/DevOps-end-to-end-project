module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # NAT Gateway — single for dev/staging (cost saving), per-AZ for prod (HA)
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment == "prod" ? false : true
  one_nat_gateway_per_az = var.environment == "prod" ? true : false

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS requires specific tags on subnets for auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.common_tags
}

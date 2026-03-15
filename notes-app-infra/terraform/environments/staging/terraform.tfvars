# Staging environment — mirrors prod but smaller
aws_region           = "us-east-1"
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
kubernetes_version   = "1.33"
node_instance_types  = ["t3.medium"]
node_min_size        = 1
node_max_size        = 3
node_desired_size    = 2

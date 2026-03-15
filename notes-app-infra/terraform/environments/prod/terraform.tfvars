# Production environment — high availability, multi-AZ
aws_region           = "us-east-1"
project-name         = "notes-app"
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]
kubernetes_version   = "1.34"
node_instance_types  = ["t3.medium"]
node_min_size        = 2
node_max_size        = 6
node_desired_size    = 2

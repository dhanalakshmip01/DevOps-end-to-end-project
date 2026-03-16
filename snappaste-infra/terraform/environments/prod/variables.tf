variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "snappaste"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.33"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  description = "Minimum nodes in node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes in node group"
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired nodes in node group"
  type        = number
  default     = 3
}

# ──────────────────────────────────────────────
# GitHub Actions Runner
# ──────────────────────────────────────────────
variable "runner_instance_type" {
  description = "EC2 instance type for the GitHub Actions runner"
  type        = string
  default     = "t3.medium"
}

variable "github_runner_url" {
  description = "GitHub org or repo URL for runner registration"
  type        = string
}

variable "github_runner_token" {
  description = "GitHub runner registration token — pass via TF_VAR_github_runner_token, never hardcode"
  type        = string
  sensitive   = true
}

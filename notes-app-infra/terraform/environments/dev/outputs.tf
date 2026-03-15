# ──────────────────────────────────────────────
# VPC Outputs
# ──────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# ──────────────────────────────────────────────
# EKS Outputs
# ──────────────────────────────────────────────
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_lb_controller_role_arn" {
  description = "IAM role ARN for AWS LB Controller"
  value       = module.eks.lb_controller_role_arn
}

# ──────────────────────────────────────────────
# ECR Outputs
# ──────────────────────────────────────────────
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

# ──────────────────────────────────────────────
# Bastion Outputs
# ──────────────────────────────────────────────
output "bastion_public_ip" {
  description = "Bastion host public IP (SSH jump box)"
  value       = module.bastion.bastion_public_ip
}

# ──────────────────────────────────────────────
# GitHub Runner Outputs
# ──────────────────────────────────────────────
/*
output "runner_instance_id" {
  description = "GitHub Actions runner EC2 instance ID"
  value       = module.github_runner.runner_instance_id
}

output "runner_private_ip" {
  description = "GitHub Actions runner private IP (SSH via bastion)"
  value       = module.github_runner.runner_private_ip
}

output "ssh_to_runner" {
  description = "Command to SSH to runner via bastion"
  value       = "ssh -J ec2-user@${module.bastion.bastion_public_ip} ubuntu@${module.github_runner.runner_private_ip}"
}
*/
# ──────────────────────────────────────────────
# Kubeconfig command
# ──────────────────────────────────────────────
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

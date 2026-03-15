output "runner_instance_id" {
  description = "EC2 instance ID of the runner"
  value       = aws_instance.runner.id
}

output "runner_private_ip" {
  description = "Private IP address of the runner"
  value       = aws_instance.runner.private_ip
}


output "runner_security_group_id" {
  description = "Security group ID of the runner"
  value       = aws_security_group.runner.id
}

output "runner_iam_role_arn" {
  description = "IAM role ARN of the runner"
  value       = aws_iam_role.runner.arn
}

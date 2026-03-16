output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "db_address" {
  description = "The hostname of the RDS instance"
  value       = module.rds.db_instance_address
}

output "db_port" {
  description = "The port of the RDS instance"
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "The name of the database"
  value       = module.rds.db_instance_name
}

output "db_username" {
  description = "The master username"
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.db_instance_identifier
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.rds.id
}

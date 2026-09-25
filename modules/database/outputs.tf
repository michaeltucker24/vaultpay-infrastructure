output "db_endpoint" {
  description = "The endpoint address of the RDS database instance."
  value       = aws_db_instance.vaultpay.endpoint
}

output "db_port" {
  description = "The port number of the RDS database instance."
  value       = aws_db_instance.vaultpay.port
}

output "db_name" {
  description = "The name of the PostgreSQL database inside the RDS instance."
  value       = aws_db_instance.vaultpay.db_name
}

output "db_security_group_id" {
  description = "The ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "db_master_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the master database credentials."
  value       = aws_db_instance.vaultpay.master_user_secret[0].secret_arn
}

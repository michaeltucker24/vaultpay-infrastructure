output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "app_private_subnet_ids" {
  description = "IDs of the app private subnets"
  value       = [aws_subnet.app_private_a.id, aws_subnet.app_private_b.id]
}

output "db_private_subnet_ids" {
  description = "IDs of the database private subnets"
  value       = [aws_subnet.db_private_a.id, aws_subnet.db_private_b.id]
}

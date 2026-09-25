variable "vpc_id" {
  description = "The ID of the VPC where the database will be deployed."
  type        = string
}

variable "db_subnet_ids" {
  description = "A list of subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for the app-private subnets. Used for the database security group ingress rule."
  type        = list(string)
}

variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create in the RDS instance."
  type        = string
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
}

variable "multi_az" {
  description = "Whether to deploy the RDS instance across multiple availability zones."
  type        = bool
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the RDS instance."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the instance is destroyed."
  type        = bool
}

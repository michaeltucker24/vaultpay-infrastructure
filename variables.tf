# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for the app private subnets"
  type        = list(string)
}

variable "db_private_subnet_cidrs" {
  description = "CIDR blocks for the database private subnets"
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
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

variable "ecr_force_delete" {
  description = "When true the ECR repository will be destroyed even if it has images in it."
  type        = bool
  default     = false
}

variable "s3_force_destroy" {
  description = "When true the S3 bucket will be destroyed even if it has objects in it."
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "The tag of the Vaultpay container image in ECR that the launch template tell instances to pull"
  type        = string
  default     = "latest"
}

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

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
variable "ecr_force_delete" {
  description = "When true, terraform destroy will delete the ECR repository even if it contains images. Production should leave this false; the default guard prevents accidental destruction of rollback image history."
  type        = bool
  default     = false
}

variable "s3_force_destroy" {
  description = "When true, terraform destroy will delete the runtime S3 bucket even if it contains objects. Production should leave this false; the default guard prevents accidental data loss."
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "Tag of the VaultPay container image in ECR that the launch template tells instances to pull. Defaults to 'latest'; CI/CD pipelines should pin to immutable digests or version tags in production."
  type        = string
  default     = "latest"
}

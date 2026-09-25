provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  app_private_subnet_cidrs = var.app_private_subnet_cidrs
  db_private_subnet_cidrs  = var.db_private_subnet_cidrs
}

module "database" {
  source = "./modules/database"

  vpc_id                   = module.vpc.vpc_id
  db_subnet_ids            = module.vpc.db_private_subnet_ids
  app_private_subnet_cidrs = var.app_private_subnet_cidrs
  project_name             = var.project_name
  db_name                  = var.db_name
  db_username              = var.db_username
  multi_az                 = var.multi_az
  backup_retention_period  = var.backup_retention_period
  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
}

resource "aws_ecr_repository" "vaultpay" {
  name         = var.project_name
  force_delete = var.ecr_force_delete


  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment = var.project_name
  }
}

resource "aws_s3_bucket" "runtime" {
  bucket        = "${data.aws_caller_identity.current.account_id}-${var.project_name}-runtime"
  force_destroy = var.s3_force_destroy

  tags = {
    Name        = "${var.project_name}-runtime"
    Environment = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "runtime" {
  bucket = aws_s3_bucket.runtime.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

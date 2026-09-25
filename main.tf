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

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-app-role"
  description        = "IAM role for Vaultpay application"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project_name}-app-role"
    Environment = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app_runtime" {
  name   = "${var.project_name}-app-runtime"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_runtime.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-instance-profile"
  role = aws_iam_role.app.name

  tags = {
    Name        = "${var.project_name}-app-instance-profile"
    Environment = var.project_name
  }
}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------------------------------------------
# Network
# ----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  app_private_subnet_cidrs = var.app_private_subnet_cidrs
  db_private_subnet_cidrs  = var.db_private_subnet_cidrs
}

# ----------------------------------------------------------------------------
# Shared application security group
#
# Stays at the root: both the database module (RDS ingress source) and the
# application module (EC2 instance SG) consume it. Moving it inside either
# module would create a circular module dependency.
#
# Egress is inline. Ingress from the ALB lives in a standalone rule resource
# below, because it needs to reference the ALB SG that's created inside the
# application module -- referencing a module output from an inline rule
# would create a module-level cycle.
# ----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow inbound HTTP from the ALB to the VaultPay app instances"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "All outbound (ECR, Secrets Manager, RDS, etc. via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-app-sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = module.application.alb_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP from the ALB"
}

# ----------------------------------------------------------------------------
# Database
# ----------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  vpc_id                  = module.vpc.vpc_id
  db_subnet_ids           = module.vpc.db_private_subnet_ids
  app_security_group_id   = aws_security_group.app.id
  project_name            = var.project_name
  db_name                 = var.db_name
  db_username             = var.db_username
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
}

# ----------------------------------------------------------------------------
# Application
# ----------------------------------------------------------------------------

module "application" {
  source = "./modules/application"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  app_private_subnet_ids = module.vpc.app_private_subnet_ids
  app_security_group_id  = aws_security_group.app.id
  db_master_secret_arn   = module.database.db_master_secret_arn
  db_endpoint            = module.database.db_endpoint
  db_port                = module.database.db_port
  db_name                = module.database.db_name
  ecr_force_delete       = var.ecr_force_delete
  s3_force_destroy       = var.s3_force_destroy
  image_tag              = var.image_tag
}


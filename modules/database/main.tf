resource "aws_db_subnet_group" "vaultpay" {
  name        = "vaultpay-db-subnet-group"
  description = "Subnets available for VaultPay RDS database placement"
  subnet_ids  = var.db_subnet_ids
  tags = {
    Name    = "vaultpay-db-subnet-group"
    Project = var.project_name
  }
}

resource "aws_security_group" "rds" {
  name        = "vaultpay-rds-sg"
  description = "Security group for the VaultPay RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.app_private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "vaultpay-rds-sg"
    Project = var.project_name
  }
}

resource "aws_db_instance" "vaultpay" {
  # General Settings
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  identifier        = "vaultpay-db"
  db_name           = var.db_name

  # Credentials
  username                    = var.db_username
  manage_master_user_password = true

  # Storage
  storage_type           = "gp3"
  storage_encrypted      = true

  # Network & Access
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.vaultpay.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Environment-aware settings: values come from .tfvars files
  multi_az               = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name    = "vaultpay-db-instance"
    Project = var.project_name
  }
}

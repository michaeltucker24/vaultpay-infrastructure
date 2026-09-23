#db subnet group for RDS to use private subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for RDS database"
  subnet_ids  = module.vpc.db_private_subnet_ids

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "${var.project_name}-db-security-group"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.app_private_subnet_cidrs[0], var.app_private_subnet_cidrs[1]]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-db-security-group"
    Project = var.project_name
  }
}

resource "aws_db_instance" "rds_instance" {
  #General settings
  identifier        = "vaultpay-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = "db.t4g.micro"
  db_name           = var.db_name

  #credentials
  username                    = var.db_username
  manage_master_user_password = true

  #storage
  storage_type      = "gp3"
  storage_encrypted = true

  #networking
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible    = false

  #environment settings (harcoded for now, can be changed to variables later)
  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true


  tags = {
    Name    = "${var.project_name}-rds-instance"
    Project = var.project_name
  }
}

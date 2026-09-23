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

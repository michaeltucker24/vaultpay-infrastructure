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
    Name    = "${var.project_name}-ecr"
    Project = var.project_name
  }
}

resource "aws_s3_bucket" "runtime" {
  bucket        = "${data.aws_caller_identity.current.account_id}-${var.project_name}-runtime"
  force_destroy = var.s3_force_destroy

  tags = {
    Name    = "${var.project_name}-runtime"
    Project = var.project_name
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
    Name    = "${var.project_name}-app-role"
    Project = var.project_name
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
    Name    = "${var.project_name}-app-instance-profile"
    Project = var.project_name
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP traffic from the internet to the vaultpay ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound (ALB to targets)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-alb-sg"
    Project = var.project_name
  }
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name    = "${var.project_name}-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow inbound traffic from the ALB to the vaultpay application instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound (app to anywhere)"
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

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ssm_parameter.al2023_arm.value
  instance_type = "t4g.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ecr_registry         = split("/", aws_ecr_repository.vaultpay.repository_url)[0]
    ecr_repository_url   = aws_ecr_repository.vaultpay.repository_url
    aws_region           = data.aws_region.current.region
    db_master_secret_arn = module.database.db_master_secret_arn
    db_host              = split(":", module.database.db_endpoint)[0]
    db_port              = module.database.db_port
    db_name              = var.db_name
    artifact_bucket_name = aws_s3_bucket.runtime.id
    image_tag            = var.image_tag
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "${var.project_name}-app"
      Project = var.project_name
    }
  }

  tags = {
    Name    = "${var.project_name}-app-lt"
    Project = var.project_name
  }

}

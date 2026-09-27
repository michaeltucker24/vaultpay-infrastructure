# ----------------------------------------------------------------------------
# Container image registry
# ----------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------
# Runtime data bucket
# ----------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------
# Instance identity
# ----------------------------------------------------------------------------

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-app-role"
  description        = "IAM role assumed by VaultPay application EC2 instances"
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
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app.name

  tags = {
    Name    = "${var.project_name}-app-profile"
    Project = var.project_name
  }
}

# ----------------------------------------------------------------------------
# Load balancer
# ----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP from the internet to the VaultPay ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound (ALB to targets)"
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
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  target_type = "instance"
  vpc_id      = var.vpc_id
  port        = 80
  protocol    = "HTTP"

  health_check {
    path                = "/health"
    matcher             = "200"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
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

# ----------------------------------------------------------------------------
# Compute fleet
# ----------------------------------------------------------------------------

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ssm_parameter.al2023_arm.value
  instance_type = "t4g.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    aws_region           = data.aws_region.current.region
    ecr_registry         = split("/", aws_ecr_repository.vaultpay.repository_url)[0]
    ecr_repository_url   = aws_ecr_repository.vaultpay.repository_url
    image_tag            = var.image_tag
    db_master_secret_arn = var.db_master_secret_arn
    # db_endpoint comes back in "host:port" form; the container wants the host only.
    db_host              = split(":", var.db_endpoint)[0]
    db_port              = var.db_port
    db_name              = var.db_name
    artifact_bucket_name = aws_s3_bucket.runtime.id
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

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  vpc_zone_identifier = var.app_private_subnet_ids
  desired_capacity    = 2
  min_size            = 2
  max_size            = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

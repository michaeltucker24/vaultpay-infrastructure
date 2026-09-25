data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "app_runtime" {
  statement {
    sid       = "readdatabasesecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.database.db_master_secret_arn]
  }
  statement {
    sid       = "writeruntimereports"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.runtime.arn}/reports/*"]
  }
}




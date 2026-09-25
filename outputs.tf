output "ecr_repository_url" {
  value       = aws_ecr_repository.vaultpay.repository_url
  description = "The URL of the ECR repository for the holding the vaultpay container image."
}

output "runtime_bucket_name" {
  value       = aws_s3_bucket.runtime.bucket
  description = "The name of the S3 bucket for holding vaultpay runtime files."
}

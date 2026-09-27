output "ecr_repository_url" {
  description = "URL of the ECR repository holding the VaultPay container image."
  value       = aws_ecr_repository.vaultpay.repository_url
}

output "runtime_bucket_name" {
  description = "Name of the S3 bucket holding VaultPay runtime data."
  value       = aws_s3_bucket.runtime.id
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB. The root configuration uses this to allow ingress to the app SG from the ALB."
  value       = aws_security_group.alb.id
}

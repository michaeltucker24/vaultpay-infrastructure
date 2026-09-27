output "ecr_repository_url" {
  description = "URL of the ECR repository holding the VaultPay container image. Use this when pushing images manually with docker push."
  value       = module.application.ecr_repository_url
}

output "runtime_bucket_name" {
  description = "Name of the S3 bucket holding VaultPay runtime data."
  value       = module.application.runtime_bucket_name
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = module.application.alb_dns_name
}

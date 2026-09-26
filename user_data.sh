#!/bin/bash
set -euo pipefail

# Install Docker (Amazon Linux 2023)
dnf install -y docker
systemctl enable --now docker

# Authenticate Docker to ECR using the instance role
aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${ecr_registry}

# Pull the VaultPay image
docker pull ${ecr_repository_url}:${image_tag}

# Run the container. The container listens on 8080 internally; we publish it
# on the host's port 80 so the ALB target group (which forwards to port 80)
# can reach it.
docker run -d \
  --restart=always \
  --name vaultpay \
  -p 80:8080 \
  -e DB_SECRET_ARN=${db_master_secret_arn} \
  -e DB_HOST=${db_host} \
  -e DB_PORT=${db_port} \
  -e DB_NAME=${db_name} \
  -e AWS_DEFAULT_REGION=${aws_region} \
  -e S3_BUCKET=${artifact_bucket_name} \
  ${ecr_repository_url}:${image_tag}

# Initialize the database schema and seed demo data (idempotent: CREATE TABLE
# IF NOT EXISTS plus a 'skip if data exists' guard in the seed step).
# Wait up to 60 seconds for the container to be running before exec'ing in.
for i in $(seq 1 30); do
  if [ "$(docker inspect -f '{{.State.Running}}' vaultpay 2>/dev/null)" = "true" ]; then
    docker exec vaultpay flask init-db || true
    break
  fi
  sleep 2
done
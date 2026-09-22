terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#AWS Provider configuration
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Name    = "vaultpay-vpc"
    Project = "VaultPay"
  }
}

# Create public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name    = "vaultpay-public-subnet-a"
    Project = "VaultPay"
  }
}
# Create public subnets
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[1]
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name    = "vaultpay-public-subnet-b"
    Project = "VaultPay"
  }
}

# Create private subnets
resource "aws_subnet" "app_private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_subnet_cidrs[0]
  availability_zone = "us-east-1a"

  tags = {
    Name    = "vaultpay-app-private-subnet-a"
    Project = "VaultPay"
  }
}

# Create private subnets
resource "aws_subnet" "app_private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_subnet_cidrs[1]
  availability_zone = "us-east-1b"

  tags = {
    Name    = "vaultpay-app-private-subnet-b"
    Project = "VaultPay"
  }
}

# Create private subnets
resource "aws_subnet" "db_private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_subnet_cidrs[0]
  availability_zone = "us-east-1a"

  tags = {
    Name    = "vaultpay-db-private-subnet-a"
    Project = "VaultPay"
  }
}

# Create private subnets
resource "aws_subnet" "db_private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_subnet_cidrs[1]
  availability_zone = "us-east-1b"

  tags = {
    Name    = "vaultpay-db-private-subnet-b"
    Project = "VaultPay"
  }
}

# Create an Internet Gateway for the VPC, lives in the public subnet to allow access to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "vaultpay-igw"
    Project = "VaultPay"
  }
}

# Create a public route table for the public subnets to access the internet via the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name    = "vaultpay-public-rt"
    Project = "VaultPay"
  }
}

# Associate the public route table with the public subnets to allow them to access the internet via the Internet Gateway
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Associate the public route table with the public subnets to allow them to access the internet via the Internet Gateway
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# EIP for NaT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "vaultpay-nat-eip"
    Project = "VaultPay"
  }
}

#NaT Gateway that must be in a public subnet to allow private subnets to access the internet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "vaultpay-nat-gateway"
    Project = "VaultPay"
  }
}

# Private Route Table for private subnets to access the internet via the NAT Gate way
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name    = "vaultpay-private-rt"
    Project = "VaultPay"
  }
}

# Associate the private route table with the private subnets to allow them to access the internet via the NAT Gateway
resource "aws_route_table_association" "app_private_a" {
  subnet_id      = aws_subnet.app_private_a.id
  route_table_id = aws_route_table.private.id
}

# Associate the private route table with the private subnets to allow them to access the internet via the NAT Gateway
resource "aws_route_table_association" "app_private_b" {
  subnet_id      = aws_subnet.app_private_b.id
  route_table_id = aws_route_table.private.id
}

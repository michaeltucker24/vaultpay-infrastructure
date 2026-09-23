project_name             = "vaultpay"
vpc_cidr                 = "10.0.0.0/20"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
app_private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
db_private_subnet_cidrs  = ["10.0.12.0/24", "10.0.13.0/24"]

db_name     = "vaultpay"
db_username = "vaultpay_admin"

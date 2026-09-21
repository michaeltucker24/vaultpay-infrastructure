variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)

}

variable "app_private_subnet_cidrs" {
  description = "CIDR block for app private subnet"
  type        = list(string)
}

variable "db_private_subnet_cidrs" {
  description = "CIDR block for db private subnet"
  type        = list(string)
}

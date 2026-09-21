terraform {
  backend "s3" {
    bucket       = "tucker-remotestatefile-terraform"
    key          = "vaultpay/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

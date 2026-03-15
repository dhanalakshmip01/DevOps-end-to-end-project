terraform {
  backend "s3" {
    bucket       = "notes-app-terraform-state-884337374668"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true   
  }
}
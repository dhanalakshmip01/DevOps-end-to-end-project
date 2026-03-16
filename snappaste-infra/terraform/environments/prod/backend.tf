terraform {
  backend "s3" {
    # bucket passed dynamically at init — no account ID hardcoded:
    # terraform init -backend-config="bucket=snappaste-terraform-state-$(aws sts get-caller-identity --query Account --output text)"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
terraform {
  backend "s3" {
    bucket         = "notes-app-terraform-state-ACCOUNT_ID" # Replace with actual account ID after bootstrap
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "notes-app-terraform-lock"
    encrypt        = true
  }
}

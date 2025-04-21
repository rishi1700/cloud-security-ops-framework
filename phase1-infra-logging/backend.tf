terraform {
  backend "s3" {
    bucket         = "rishi-tfstate-backend-e4503710" # Replace with your actual bucket name
    key            = "phase1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

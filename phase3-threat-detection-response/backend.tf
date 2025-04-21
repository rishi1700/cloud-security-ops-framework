terraform {
  backend "s3" {
    bucket         = "rishi-tfstate-backend-e4503710" # Same bucket
    key            = "phase3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

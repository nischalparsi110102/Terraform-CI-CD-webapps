# Configure remote backend (e.g., S3 for state storage)
 terraform {
   backend "s3" {
     bucket = "your-tfstate-bucket"
     key    = "webapplication/prod/terraform.tfstate"
     region = "us-east-1"
   }
}
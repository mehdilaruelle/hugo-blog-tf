terraform {
  backend "s3" {
    bucket = "laruelle-terraform-backend"
    key    = "hugo.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

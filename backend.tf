terraform {
  backend "s3" {
    bucket = "mlaruelle-terraform-backend"
    key    = "hugo.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

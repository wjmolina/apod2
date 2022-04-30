terraform {
  required_providers {
    aws = {
      version = "~> 4.12.1"
    }
  }
  backend "s3" {
    bucket = "apod2"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

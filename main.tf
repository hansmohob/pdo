terraform {
  required_providers {

    aws = {

      source  = "hashicorp/aws"
      version = "~> 3.70"

    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {

  profile = "default"
  region  = var.region

 default_tags {

   tags = {

    Customer    = var.customer_name
    Environment = var.env_name
    Provisioner = "Terraform"

   }
 }
  
}

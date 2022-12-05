#provider details
terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "3.62.0"
    }
  }
}

provider "aws" {
    region = var.region
    # default_tags {
    #   tags = {
    #     Environment = "Testing"
    #     Name = "Provider tag"
    #   }
    # }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

terraform {
  backend "remote" {
    organization = "CodeForFun"
    workspaces {
      name = "remote-state-test"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-086c142842468ba9d"
  instance_type = "t2.micro"
}
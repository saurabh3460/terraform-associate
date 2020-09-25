terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ip.txt"
  }
}






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


// Now Change Infrastructure 
// changing ami
resource "aws_instance" "example" {
  // ami           = "ami-0cda377a1b884a1bc" // Ubuntu Server 20.04 LTS
  ami           = "ami-052c08d70def0ac62" // Red Hat Enterprise Linux 8
  instance_type = "t2.micro"
}



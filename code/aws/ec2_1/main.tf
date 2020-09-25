terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.7.0"
        }
    }
}

// data "aws_ami" "west_ami" {
    
// }

provider "aws" {
    profile = "default"
    region  = "ap-south-1"
}

provider "aws" {
    region = "us-west-1"
    alias = "west"
}


resource "aws_instance" "example" {
    ami = "ami-830c94e3"
    instance_type = "t2.micro"
}

resource "aws_instance" "example-west" {
    provider = aws.west
    ami = "ami-0e65ed16c9bf1abc7"
    instance_type = "t2.micro"
}
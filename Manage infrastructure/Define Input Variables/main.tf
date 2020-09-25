terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>3.7.0"
        }
    }
}
provider "aws" {
    profile = "default"
    region = var.region
}

resource "aws_instance" "example" {
    ami = var.instance["ami"]
    instance_type = var.instance["instance_type"]
}


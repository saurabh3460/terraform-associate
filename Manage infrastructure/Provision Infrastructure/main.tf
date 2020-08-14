provider "aws" {
  profile = "saurabh"
  region  = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"  
  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}






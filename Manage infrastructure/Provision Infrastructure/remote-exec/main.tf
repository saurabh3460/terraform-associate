terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.7.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

resource "aws_key_pair" "example" {
  key_name   = "examplekey"
  public_key = file("./terraform.pub")
}


resource "aws_instance" "example" {
  key_name      = aws_key_pair.example.key_name
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"

  connection { // it will execute after example get provisioned and start connecting to it. 
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./terraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" { // it will execute after successfully connected to example
    inline = [
      "sudo yum -y install nginx",
      "sudo systemctl start nginx"
    ]
  }

}
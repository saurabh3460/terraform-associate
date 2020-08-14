provider "aws" {
  profile = "saurabh"
  region  = "ap-south-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-10"
  acl    = "private"
}

resource "aws_instance" "example" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"

  depends_on = [aws_s3_bucket.example]
}

// resource "aws_eip" "example_eip" {
//   vpc      = true
//   instance = aws_instance.example.id
// }





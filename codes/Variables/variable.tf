variable region {
  default = "ap-south-1"
}

variable "amis" {
  type = map
  default = {
    "us-east-1" = "ami-b374d5a5"
    "us-west-2" = "ami-fc0b939c"
    "ap-south-1" = "ami-001e484a60bb07f8d"
  }
}
variable "instance" {
  type = list
  default = [
    "t2.micro", "t2.large"
  ]
}

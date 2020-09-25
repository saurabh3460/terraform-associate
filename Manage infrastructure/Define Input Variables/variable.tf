/*
Note: The file can be named anything, since Terraform loads all 
files in the directory ending in .tf.
*/
variable "region" {
    default = "ap-south-1"
}
// This defines the region variable within your Terraform configuration.

variable "instance" {
    type = map
    default = {
        ami = "ami-052c08d70def0ac62"
        instance_type = "t2.micro"
    }
}
// other way is 
// terraform plan -var 'aws_instance={ami = "ami-052c08d70def0ac62", instance_type = "t2.micro"}'
// 
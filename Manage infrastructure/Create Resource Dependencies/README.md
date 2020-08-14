# Create Resource Dependencies

To understand How Dependencies work in terraform lets add an elastic ip.

```HCL
resource "aws_instance" "example" {
  ami = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
}

resource "aws_eip" "example_eip" {
  vpc = true
  instance = aws_instance.example.id
}
```

For attaching elastic ip we need to give ec2 instance's id via aws_instance.example.id so by this terraform know that before making aws_eip (dependencies of aws_instance) it need to make aws_instance resource.

### Implicit and Explicit Dependencies.

In the example above, **aws_instance.example.id** creates an implicit dependency on the **aws_instance** and terraform determine the correct order in which to create the different resources.

But there are some cases where dependencies between resources that are not visible to Terraform. In that case, we can use **depends_on** to explicitly declare the dependency.
For example, We need EC2 instance and S3 bucket but S3 bucket is not required by EC2, instead it's required by an app running inside EC2.

```HCL
resource "aws_s3_bucket" "example" {
  bucket = "example-10"
  acl = "private"
}

resource "aws_instance" "example" {
  ami = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
  depends_on = [aws_s3_bucket.example]
}
```

**depends_on = [aws_s3_bucket.example]** Tells Terraform that this EC2 instance must be created only after the S3 bucket has been created.

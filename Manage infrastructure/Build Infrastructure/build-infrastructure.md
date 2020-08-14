# Build Infrastructure

let's begin with a simple code

```HCL
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "saurabh"
  region  = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
}
```
### Terraform Block (new in v0.13)

This ``terraform {}`` block is required for Terraform to know which provider to download from the [Terraform Registry](https://registry.terraform.io/). ``hashicorp/aws`` is shorthand for ``registry.terraform.io/hashicorp/aws``.

We can also assign a veriosn to each provider defined in ``required_providers`` blocks. The ``version`` argument is optional, but recommended. It is used to constrain the provider to a specific version or a range of versions in order to prevent downloading a new provider that may possibly contain breaking changes. If the version isn't specified, Terraform will automatically download the most recent provider during initialization.

### Providers

A provider is a plugin that Terraform uses to translate the API interactions with the service. A provider is responsible for understanding API interactions and exposing resources. Because Terraform can interact with any API, you can represent almost any infrastructure type as a resource in Terraform.

The profile attribute in your provider block refers Terraform to the AWS credentials stored in your AWS Config File

## **Warning!**
HashiCorp recommends that you never hard-code credentials into ``*.tf ``configuration files. 

### Resources
The ``resource`` block defines a piece of infrastructure. A resource might be a physical component such as an EC2 instance, or it can be a logical resource such as a Heroku application.

Signature of resource block is ```resource <resource_type> <resource_name> {}```. In the example, the resource type is ``aws_instance`` and the name is ``example``. The prefix of the type maps to the provider. In our case "aws_instance" automatically tells Terraform that it is managed by the "aws" provider.

The arguments for the resources are generally specific to providers.

### Initialize the directory

When you create a new configuration — or check out an existing configuration from version control — you need to initialize the directory with ``terraform init``.

### Format and validate the configuration
It is recommended to use consistent formatting in files and modules written by different teams. The ``terraform fmt ``command automatically updates configurations in the current directory for easy readability and consistency.

For Validation there is a built in ``terraform validate`` command, will check and report errors within modules, attribute names, and value types.

### Finally Create infrastructure

In the same directory as the main.tf file we created, run ``terraform apply``.
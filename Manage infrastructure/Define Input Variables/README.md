# Define Input Variables

### Defining Variables:

```go
// variable.tf
variable "region" {
  default = "us-west-2"
}
```

```go
// use variable
provider "aws" {
- region = "us-west-2"
+ region = var.region
}
```

## Assigning variables:

**There are multiple ways to assign variables.**

**The order below is also the order in which variable values are chosen.**

### Command-line flags:

Set variables directly on the CLI with `-var`. Any command in Terraform that inspects the configuration accepts this flag, such as `apply`, `plan` and `refresh`.

```bash
terraform apply -var 'region=us-west-2'
```

### From a file:

To persist variable values, create file with `*.tfvars` Terraform automatically loads all files in the current directory with the exact name of `terraform.tfvars` or any variation of `*.auto.tfvars`.

If the file is named something else, you can use the `-var-file` flag to specify a file name.

```bash
terraform apply -var-file="secret.tfvars" -var-file="production.tfvars"
```

### From environment variables:

Terraform will read environment variables in the form of `TF_VAR_name` to find the value for a variable. For example, the `TF_VAR_region` variable can be set in the shell to set the region variable in Terraform.

Note: Environment variables can only populate string-type variables. List and map type variables must be populated via one of the other mechanisms.

**Variable defaults:**
If no value is assigned to a variable via any of these methods and the variable has a default key in its declaration, that value will be used for the variable.

## Rich data types:

[https://learn.hashicorp.com/tutorials/terraform/aws-variables#rich-data-types](https://learn.hashicorp.com/tutorials/terraform/aws-variables#rich-data-types)

### Maps:

```bash
variable "instance" {
	type = map
	default = {
		ami = "ami-dhdii3d"
		region = "ap-south-1"
	}
}
```

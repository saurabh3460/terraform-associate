# Terraform Interview Preparation Guide
## Advanced Questions and Answers

## 1. State Locking

**Question:** How would you handle state locking in a team environment, and what happens if state locking fails?

**Answer:** State locking prevents multiple team members from running Terraform operations on the same state simultaneously, which could cause corruption. In AWS, DynamoDB is commonly used for locking with an S3 backend. If state locking fails, Terraform operations will be aborted to prevent state corruption.

**Example:**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "path/to/my/key"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## 2. Remote State vs. Data Sources

**Question:** Explain the difference between `terraform_remote_state` and data sources, and when you would use each.

**Answer:** `terraform_remote_state` is specifically for accessing outputs from another Terraform state file, while data sources can query any resource attributes from providers. Use remote state for cross-project output sharing and data sources when you need current information about existing resources.

**Example:**

```hcl
# Remote state example
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "network/terraform.tfstate"
    region = "us-west-2"
  }
}

# Using remote state output
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.network.outputs.subnet_id
}

# Data source example
data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = ["main-subnet"]
  }
}

resource "aws_instance" "app2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.selected.id
}
```

## 3. Managing Sensitive Data

**Question:** How would you manage sensitive data in Terraform without exposing it in state files or version control?

**Answer:** Use environment variables, AWS Secrets Manager, or HashiCorp Vault to store sensitive values. Mark variables as sensitive in Terraform to prevent them from appearing in logs. For AWS, you can use SSM Parameter Store.

**Example:**

```hcl
variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/app/database/password"
  type  = "SecureString"
  value = var.db_password
}

# Later, reference it
data "aws_ssm_parameter" "db_password" {
  name = "/app/database/password"
  with_decryption = true
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = data.aws_ssm_parameter.db_password.value
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
```

## 4. Testing Terraform Modules

**Question:** Describe strategies for testing Terraform modules and infrastructure code.

**Answer:** Use tools like Terratest, kitchen-terraform, or terraform-compliance. Implement unit tests that validate your module's outputs, integration tests that deploy resources to isolated environments, and policy compliance tests.

**Example with Terratest (Go code):**

```go
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestS3Bucket(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/s3-bucket",
		Vars: map[string]interface{}{
			"bucket_name": "test-bucket-terratest",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	assert.Contains(t, bucketID, "test-bucket-terratest")
}
```

## 5. Circular Dependencies

**Question:** How would you handle circular dependencies in Terraform? Give an example.

**Answer:** Circular dependencies occur when resources depend on each other. Break the cycle by using intermediate resources, separating concerns into modules, or using the `depends_on` meta-argument for explicit dependency management.

**Example:**

```hcl
# Problem: Security group A needs Security group B's ID and vice versa
# Solution: Create both first with minimal config, then use aws_security_group_rule

resource "aws_security_group" "sg_a" {
  name        = "security-group-a"
  description = "Security Group A"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "sg_b" {
  name        = "security-group-b"
  description = "Security Group B"
  vpc_id      = aws_vpc.main.id
}

# Now add rules that reference each other
resource "aws_security_group_rule" "sg_a_to_b" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_b.id
  security_group_id        = aws_security_group.sg_a.id
}

resource "aws_security_group_rule" "sg_b_to_a" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_a.id
  security_group_id        = aws_security_group.sg_b.id
}
```

## 6. Zero-Downtime Deployments

**Question:** Explain the proper way to handle zero-downtime deployments with Terraform.

**Answer:** Use strategies like blue-green deployments with load balancer switching, create-before-destroy lifecycles, and AWS auto-scaling groups with rolling updates.

**Example:**

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                 = "app-asg-${aws_launch_template.app.latest_version}"
  max_size             = 5
  min_size             = 2
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.main.id]
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  target_group_arns    = [aws_lb_target_group.app.arn]
  health_check_type    = "ELB"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.main.id, aws_subnet.secondary.id]
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}
```

## 7. Count and For_Each Limitations

**Question:** What are the limitations of Terraform's count and for_each meta-arguments, and how would you work around them?

**Answer:** Count and for_each can't use resources that haven't been created yet, and they can't handle complex conditional logic. They also can't be used inside module blocks.

**Example and workaround:**

```hcl
# Problem: Can't use count/for_each based on a resource that doesn't exist yet
# Solution: Split into modules and use locals for pre-calculation

locals {
  subnet_ids = ["subnet-1234", "subnet-5678"]
  create_instances = length(local.subnet_ids) > 0 ? true : false
  instances = {
    for idx, subnet_id in local.subnet_ids : "instance-${idx}" => {
      subnet_id = subnet_id
    }
  }
}

# Using for_each with pre-calculated map
resource "aws_instance" "app" {
  for_each      = local.create_instances ? local.instances : {}
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = each.value.subnet_id
  
  tags = {
    Name = each.key
  }
}
```

## 8. Custom Variable Validation

**Question:** How would you implement custom validation for Terraform variables beyond basic type checking?

**Answer:** Terraform supports custom variable validations using condition checks and error messages. These allow you to enforce constraints beyond basic type checking.

**Example:**

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^t[23]\\..+$", var.instance_type))
    error_message = "Only t2 and t3 instance types are allowed."
  }
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "Must be a valid CIDR block."
  }
  
  validation {
    condition     = cidrnetmask(var.cidr_block) == "255.255.0.0"
    error_message = "CIDR block must be a /16 network."
  }
}
```

## 9. State Management During Cloud Provider Outage

**Question:** Describe strategies for managing Terraform state during a cloud provider outage.

**Answer:** Implement local state backups, use version-controlled state files, or maintain a secondary backend. Create a disaster recovery plan that includes state recovery procedures.

**Example:**

```hcl
# Setup with backup state capability
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "path/to/my/key"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# CLI command to create local backup before operations
# terraform state pull > terraform.tfstate.backup

# Script to manage state when S3 is down
# create backup-state.sh
#!/bin/bash
terraform state pull > terraform.tfstate.backup
echo "State backup created. During outage, use: terraform init -backend=false"
echo "Then: terraform apply -state=terraform.tfstate.backup"
```

## 10. Resource Drift Detection and Remediation

**Question:** How would you handle resource drift detection and remediation in a production environment?

**Answer:** Use `terraform plan` regularly to detect drift. For automated drift detection, implement CI/CD pipelines that run plan and alert on differences. Use AWS Config or Terraform Cloud drift detection.

**Example:**

```hcl
# Setup AWS Config to detect drift
resource "aws_config_configuration_recorder" "config" {
  name     = "terraform-config-recorder"
  role_arn = aws_iam_role.config.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
}

# CI/CD Script for detecting drift (shell script)
#!/bin/bash
terraform plan -detailed-exitcode -out=plan.out
EXITCODE=$?

if [ $EXITCODE -eq 2 ]; then
  echo "Drift detected in infrastructure"
  # Send alert to Slack/Email/etc.
  exit 1
fi
```

## 11. Workspaces vs. File-Based Environments

**Question:** Explain the differences between Terraform workspaces and file-based environments, and when you would choose one over the other.

**Answer:** Workspaces share the same code but use different state files, making them ideal for environment-agnostic code with minimal differences. File-based approaches (using separate directories) are better for environments with substantial configuration differences.

**Example:**

```hcl
# Workspace approach
# terraform workspace new dev
# terraform workspace new prod

variable "instance_type" {
  type = map(string)
  default = {
    default = "t2.micro"
    dev     = "t2.micro"
    staging = "t2.medium"
    prod    = "t2.large"
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = lookup(var.instance_type, terraform.workspace, var.instance_type["default"])
  
  tags = {
    Environment = terraform.workspace
  }
}

# File-based approach
# /environments/dev/main.tf
# /environments/prod/main.tf
# with a common module:
module "web_app" {
  source        = "../../modules/web_app"
  environment   = "prod"
  instance_type = "t2.large"
  replicas      = 5
}
```

## 12. Refactoring Monolithic Terraform Code

**Question:** How would you approach refactoring a large monolithic Terraform codebase into reusable modules?

**Answer:** Identify logical components, extract them into modules, ensure clean interfaces between modules, use output variables for cross-module communication, and implement gradual state migrations to avoid disruption.

**Example:**

```hcl
# Before: monolithic main.tf with everything
# After: structured modules

# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

# modules/compute/main.tf
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
}

# root main.tf
module "networking" {
  source      = "./modules/networking"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}

module "compute" {
  source        = "./modules/compute"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = module.networking.subnet_id
}
```

## 13. Blue-Green Deployment Strategy

**Question:** Describe how you would implement a blue-green deployment strategy using Terraform.

**Answer:** Create duplicate infrastructure (blue and green environments), deploy to the inactive environment, test, then switch traffic from active to inactive using load balancers or DNS.

**Example:**

```hcl
# Create blue and green environments
resource "aws_instance" "blue" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "blue-instance"
  }
}

resource "aws_instance" "green" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "green-instance"
  }
}

# Load balancer target groups
resource "aws_lb_target_group" "blue" {
  name     = "blue-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group" "green" {
  name     = "green-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Target group attachments
resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.green.id
  port             = 80
}

# ALB Listener - points to active environment
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }
}
```

## 14. Provider Bugs/Limitations

**Question:** How would you handle provider-specific bugs or limitations in Terraform?

**Answer:** Work around provider bugs by using direct API calls with `null_resource` and local-exec, checking provider issue trackers, using stable provider versions, or implementing alternative approaches like CloudFormation for specific resources.

**Example:**

```hcl
# Workaround for AWS provider bug using local-exec
resource "null_resource" "workaround" {
  triggers = {
    instance_id = aws_instance.app.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 modify-instance-attribute \
        --instance-id ${aws_instance.app.id} \
        --no-source-dest-check
    EOT
  }
}

# Alternative: Using data sources to repair state
data "aws_instance" "app" {
  instance_id = aws_instance.app.id
  
  depends_on = [null_resource.workaround]
}

# Pinning provider versions to avoid bugs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"  # Known good version
    }
  }
}
```

## 15. Managing Terraform Upgrades

**Question:** Explain strategies for managing Terraform upgrades across a large organization with many teams.

**Answer:** Use version constraints in configuration, implement CI/CD pipelines to test upgrades, maintain a testing environment, document upgrade paths, and gradually roll out upgrades team by team.

**Example:**

```hcl
# Strict version constraints
terraform {
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Upgrade testing script (example CI pipeline)
#!/bin/bash
# test-upgrade.sh
CURRENT_VERSION="1.3.7"
TARGET_VERSION="1.4.0"

# Test with current version
terraform version
terraform init -backend=false
terraform validate
terraform plan -out=current.plan

# Test with new version
rm -rf .terraform
export PATH=/path/to/terraform-${TARGET_VERSION}:$PATH
terraform version
terraform init -backend=false
terraform validate
terraform plan -out=new.plan

# Compare plans
terraform show -json current.plan > current.json
terraform show -json new.plan > new.json
diff current.json new.json
```


-------------------------------------------------------------------------

# terraform-associate

### :tada: Terraform v0.13 is here, updating to v0.13.

This Study Guide is based on official Study Guide - Terraform Associate Certification.

- Learn about IaC

  - understand Infrastructure as Code (IaC) concepts - (Objective #1)
  - understand Terraform's purpose (vs other IaC) - (Objective #2)

* [Manage infrastructure](https://github.com/saurabh3460/terraform-associate/tree/master/Manage%20infrastructure)
  - Install terraform
  - Build Infrastructure
  - Change Infrastructure
  - Destroy Infrastructure
  - Create Resource Dependencies
  - Provision Infrastructure
  - [Define Input Variables](https://github.com/saurabh3460/terraform-associate/tree/master/Manage%20infrastructure/Define%20Input%20Variables)
  - Query Data with Output Variables
  - Store remote state

### These additional resources to learn more about Terraform key concepts.

- [Providers](https://www.terraform.io/docs/configuration/providers.html) documentation
- [Purpose of Terraform State](https://www.terraform.io/docs/state/purpose.html) documentation
- [Terraform Settings](https://www.terraform.io/docs/configuration/terraform.html) documentation
- [Provisioners](https://www.terraform.io/docs/provisioners/#provisioners-are-a-last-resort) documentation

* [Master the workflow]()

#### [Sample Questions - Terraform Associate Certification](https://learn.hashicorp.com/terraform/certification/terraform-associate-sample-questions)

# Deploying Sourcegraph to AWS using Terraform

> NOTE: This guide assumes a basic understanding of Terraform and AWS and is not a total beginners guide.

## System requirements

- Terraform
- Make

> NOTE: If you've deleted the default VPC in the targeted region, you need to supply values for `vpc_id` and `subnet_id`.  

## Authentication

> NOTE: There are many ways to supply AWS credentials to Terraform . If you know what you're doing, skip this section.

If you don't have a `$HOME/.aws/credentials` file, then environment variables are required.

To export the variables without polluting your bash history:

- Copy `aws_auth.sh.sample` and rename to `aws_auth.sh`
- Add values to `aws_auth.sh`
- Execute using `source`

As an example, if you're in the `terraform/ec2` directory, you would run:

```shell
source ../bin/aws_auth.sh
``` 

## Terraform configuration

All Terraform plans have a `terraform.tfvars.sample` file. We recommend copying and renaming the file to `terraform.tfvars`, then filling in the blanks.

## Deployment commands

Each plan has a `Makefile` which takes care of most use cases. 

For example, in the `terraform/ec2` directory run `make plan` instead of `terraform plan -var-file terraform.tfvars`.

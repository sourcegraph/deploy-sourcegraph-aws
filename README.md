# Deploy Sourcegraph to AWS using Terraform

> NOTE: This guide assumes knowledge and experience using [AWS IAM](https://docs.aws.amazon.com/iam/index.html#lang/en_us) and Terraform.

## Prerequisites

The following is required to execute these Terraform plans:

- Make (installed if you're macOS and Linux)
- [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [mkcert](https://github.com/FiloSottile/mkcert) (optional but required for self-signed cert validation)


### AWS requirements

### Default VPC?

If the region does not have a default VPC, `vpc_id` must be set in the `terraform.tfvars` file.

### Authentication

You can authenticate with AWS using one of the methods described in the [Terraform AWS authentication docs](https://www.terraform.io/docs/providers/aws/#environment-variables).

If you haven't done this before, using environment vars is recommended.

## Configuration

These Terraform plans require the existence of a `terraform.tfvars` file. To create, copy the contents of `terraform.tfvars.sample` to a new `terraform.tfvars` file, then add values for any required variables.

## Deployment commands

Each plan has a `Makefile` which covers the common use-cases:

- `make init`
- `make plan`
- `make apply`
- `make destroy`
- `make output`

> NOTE: You are not required to use make, it's just included to make things easy and document what parameters to pass to Terraform.

## Troubleshooting

### No public IP or hostname assigned

If the instance has no public IP address, get the id of the subnet the instance is in, then in the AWS console, go to VPC > Subnets > Select the subnet > Actions: Modify auto-assign IP settings > check "Auto-assign IPv4", then save.

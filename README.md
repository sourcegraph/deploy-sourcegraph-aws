# Deploy Sourcegraph to AWS using Terraform

![Deploy Sourcegraph on AWS demo gif](https://user-images.githubusercontent.com/46826578/54791121-bfe46d80-4bf5-11e9-81c0-663599183b11.gif)

Deploying Sourcegraph on AWS now takes less than 5 minutes and a couple of commands with TLS preconfigured.

> NOTE: This guide assumes knowledge and experience using [AWS IAM](https://docs.aws.amazon.com/iam/index.html#lang/en_us) and Terraform.

## Prerequisites

- Make (installed if you're macOS and Linux)
- [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [mkcert](https://github.com/FiloSottile/mkcert) (optional but required for self-signed cert validation)

## AWS requirements

### Default VPC?

If the region does not have a default VPC, `vpc_id` must be set in the `terraform.tfvars` file.

### Authentication

You can authenticate with AWS using one of the methods described in the [Terraform AWS authentication docs](https://www.terraform.io/docs/providers/aws/#environment-variables).

If you haven't done this before, using environment vars is recommended.

## Configuration

These Terraform plans require the existence of a `terraform.tfvars` file. To create, copy the contents of `terraform.tfvars.sample` to a new `terraform.tfvars` file, then add values for any required variables.

## Commands

The `Makefile` has commands to cover the most common use-cases:

- `make init`: Download the required packages based on the resources used.
- `make plan`: Do we have everything required to deploy?
- `make apply`: Create the EC2 instance and other required resources
- `make sourcegraph`: Wait for Sourcegraph accept connections
- `make output`: Display the same output as when `make apply` completes.
- `make destroy`: Removes all created from resources from AWS

> NOTE: You are not required to use `make`, it's just included to make things easy and document what parameters to pass to Terraform.

## Troubleshooting

### No public IP or hostname assigned

If the instance has no public IP address, get the subnet id the instance belongs to, then in the AWS console:

1. VPC
1. Subnets
1. Select the subnet 
1. Actions: Modify auto-assign IP settings
1. check "Auto-assign IPv4" and save
1. Run `make destroy` to remove the current instance.
1. Run `make deploy` again to get a public hostname and IP


# Deploy Sourcegraph to AWS using Terraform

<!--A collection of [infrastructure as code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_code) examples for deploying Sourcegraph on AWS using Terraform.-->

> NOTE: This guide assumes knowledge and experience using [AWS IAM](https://docs.aws.amazon.com/iam/index.html#lang/en_us) and Terraform.

## Prerequisites

The following is required to execute these Terraform plans:

- Make (installed if you're macOS and Linux)
- [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [mkcert](https://github.com/FiloSottile/mkcert) (optional but required for self-signed cert validation)

## AWS VPC

If the region does not have a default VPC, `vpc_id` must be set.

## AWS Authentication

You can authenticate with AWS using one of the methods described in the [Terraform AWS authentication docs](https://www.terraform.io/docs/providers/aws/#environment-variables).

If you haven't done this before, using environment vars is recommended.

## Terraform variables

These Terraform plans require the existence of a `terraform.tfvars` file. To create, copy the contents of `terraform.tfvars.sample` to a new `terraform.tfvars` file, then add values for any required variables.

## Deployment commands

Each plan has a `Makefile` which covers the common use-cases:

- `make init`
- `make plan`
- `make apply`
- `make destroy`
- `make output`

> NOTE: You are not required to use make, it's just included to make things easy and document what parameters to pass to Terraform.

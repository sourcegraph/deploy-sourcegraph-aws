# Deploying Sourcegraph on EC2

This Terraform plan deploys Sourcegraph to an EC2 instance with SSL using a self-signed certificate.

This plan will create:

- An EC2 instance
- Security group with inbound ports `22`, `80`, and `443`
- IAM role and and IAM instance profile
- Depending upon configuration, a `key pair` (see [plan configuration](#terraform-plan-configuration))

See how it works by [watching this screencast on Vimeo.com](https://vimeo.com/327771524).

[![Sourcegraph on AWS using Terraform demo screencast](https://user-images.githubusercontent.com/133014/55365302-dcf02a80-5498-11e9-9bb8-f5ba4bfdb90d.png)](https://vimeo.com/327771524)

## Prerequisites

- Make (installed if you're macOS and Linux)
- [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [mkcert](https://github.com/FiloSottile/mkcert) (optional but required for self-signed cert validation)

> NOTE: A basic level of knowledge and experience using [AWS IAM](https://docs.aws.amazon.com/iam/index.html#lang/en_us) and [Terraform](https://www.terraform.io/intro/index.html) is required.

## Terraform AWS authentication

You can authenticate with AWS using one of the methods described in the [Terraform AWS authentication docs](https://www.terraform.io/docs/providers/aws/#environment-variables).

If you haven't done this before, using environment vars is recommended.

## Terraform plan configuration

The existence of a `terraform.tfvars` file is required. To create it, copy the contents of `terraform.tfvars.sample` to a new `terraform.tfvars` file and review to see which variables you'd like to set.

You'll likely set `key_name` (if you already have a key pair), or `public_key` and `key_name` which if both specified, will create the key . If neither are these are set, you can still deploy Sourcegraph, but you'll be unable to SSH to the instance.

> NOTE: If the region does not have a default VPC, `vpc_id` variable must be set in the `terraform.tfvars` file.

## Commands

The `Makefile` has commands to cover the most common use-cases. The easiest way to create your Droplet is to run:

```bash
make deploy
```

This will create all resources and and poll the server to let you know when Sourcegraph is ready.

Other commands include:

- `make init`: Download the required Terraform provider packages
- `make plan`: Anything to add, remove or change?
- `make apply`: Create the EC2 instance and other required resources
- `make sourcegraph`: Wait for Sourcegraph to be ready to accept connections
- `make output`: Display the same output as when `make apply` completes
- `make destroy`: Removes all created from resources

> WARNING: `make destroy` will destroy the Droplet so back-up the `/etc/sourcegraph` and `/var/opt/sourcegraph` directories first.

## Upgrading Sourcegraph

To upgrade Sourcegraph:

1. SSH into the EC2 instance
1. Run `./sourcegraph-upgrade`

The newer Docker image will be pulled and Sourcegraph will be restarted.

## Troubleshooting

### Default VPC error

If you get:

```shell
Error: Error refreshing state: 1 error(s) occurred:

* data.aws_vpc.default: 1 error(s) occurred:

* data.aws_vpc.default: data.aws_vpc.default: no matching VPC found

```

It means you don't have a default VPC in the currently specified region. Either choose a different region that has a default VPC or provide a `vpc_id` value in `terraform.tfvars`.

---

### No public IP or hostname assigned

If the instance has no public IP address, get the subnet id the instance belongs to, then in the AWS console:

1. VPC
1. Subnets
1. Select the subnet
1. Actions: Modify auto-assign IP settings
1. check "Auto-assign IPv4" and save
1. Run `make destroy` to remove the current instance
1. Run `make deploy` again to get a public hostname and IP
Hello World

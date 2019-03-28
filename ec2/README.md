# Deploying Sourcegraph on EC2

![Deploy Sourcegraph on AWS demo gif](https://user-images.githubusercontent.com/46826578/54791121-bfe46d80-4bf5-11e9-81c0-663599183b11.gif)


This Terraform plan deploys Sourcegraph to an EC2 instance with SSL using a self-signed certificate.

This plan will create:

- An EC2 instance
- Security group with inbound ports `22`, `80`, `443`, and `2633` (for the management console) exposed.
- IAM role and and IAM instance profile
- Depending upon configuration, a `key_pair` (see [plan configuration](#terraform-plan-configuration))

## Terraform AWS authentication

You can authenticate with AWS using one of the methods described in the [Terraform AWS authentication docs](https://www.terraform.io/docs/providers/aws/#environment-variables).

If you haven't done this before, using environment vars is recommended.

## Terraform plan configuration

The existence of a `terraform.tfvars` file is required. To create it, copy the contents of `terraform.tfvars.sample` to a new `terraform.tfvars` file and review to see which variables you'd like to set.

You'll likely set `key_name` (if you already have a key pair), or `public_key` and `key_name` which if both specified, will create the key . If neither are these are set, you can still deploy Sourcegraph, but you'll be unable to SSH to the instance.

> NOTE: If the region does not have a default VPC, `vpc_id` variable must be set in the `terraform.tfvars` file.

## Commands

The `Makefile` has commands to cover the most common use-cases:

- `make init`: Download the required packages based on the resources used
- `make plan`: Do we have everything required to deploy?
- `make apply`: Create the EC2 instance and other required resources
- `make sourcegraph`: Wait for Sourcegraph accept connections
- `make output`: Display the same output as when `make apply` completes
- `make destroy`: Removes all created from resources from AWS

> NOTE: You are not required to use `make`, it's just included to make things easy and document what parameters to pass to Terraform.

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

# Deploy Sourcegraph to AWS using Terraform

Instructions coming soon.

## Requirements

Terraform.

## AWS requirements

 - Key pair created

> NOTE: If you've deleted the default VPC, you need to supply the `vpc_id` and the `subnet_id`. 
 

## Usage


### AWS auth

If you don't have a `$HOME/.aws/credentials` file, then environment variables are required.

To export the variables without polluting your bash history:

 - Copy `aws_auth.sh.sample` and rename to `aws_auth.sh`
 - Add values to `aws_auth.sh`
 - Execute using `source`

## Terraform configuration

Copy `terraform.tfvars.sample` and rename to `terraform.tfvars` and fill in the required values.

## Deploying

See the `Makefile` for the Terraform commands.

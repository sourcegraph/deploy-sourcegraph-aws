# Deploying Sourcegraph on EC2

This Terraform plan deploys Sourcegraph on an EC2 instance with SSL using a self-signed certificate.

## Configuration

There are technically no required variables although the `terraform.tfvars` file still needs to exist.

The most likely variable you will want to specify is `key_name` and or `public_key` as without this, you can't SSH to the instance.

Take a look at `vars.tf` and `main.tf` which documents the variables used and what resources are createrd.

> NOTE: If you've deleted the default VPC in the targeted region, you'll need to supply a value for `vpc_id`.

## Troubleshooting

### Default VPC error

If you get:

```shell
Error: Error refreshing state: 1 error(s) occurred:

* data.aws_vpc.default: 1 error(s) occurred:

* data.aws_vpc.default: data.aws_vpc.default: no matching VPC found

```

It means you don't have a default VPC in the currently specified region. Either choose a different region that has a default VPC or provide a`vpc_id` value in `terraform.tfvars`.

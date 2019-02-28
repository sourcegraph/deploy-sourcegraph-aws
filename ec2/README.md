# Deploying Sourcegraph to a single EC2 instance

This EC2 Terraform plan is easy to use as there are no required variables, although the `terraform.tfvars` file still needs to exist.

The most likely variable you **will* want to specify is `key_name` as without this, you can't SSH to the instance.

Reading `vars.tf` and `main.tf` will help explain how the optional variables are used.

## Configuration

If no `vpc_id` value is set, the default VPC will be used but if the default VPC has been deleted, then you'll need to specify a value for `vpc_id`

## Troubleshooting

### Default VPC error

If you get:

```shell
Error: Error refreshing state: 1 error(s) occurred:

* data.aws_vpc.default: 1 error(s) occurred:

* data.aws_vpc.default: data.aws_vpc.default: no matching VPC found

```

It means you don't have a default VPC in the currently specified region. Either choose a different region that has a default VPC or provide a`vpc_id` value in `terraform.tfvars`.

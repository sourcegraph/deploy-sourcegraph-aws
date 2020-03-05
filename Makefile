SHELL := /bin/bash
HOSTNAME=$(shell make output | grep "server =" | sed -n 's/.*https:\/\/\(.*\)\//\1/p') # ]macOS users will need to `brew install coreutils` to get the `timeout` binary
URL="https://$(HOST_PORT)/"
INSTANCE_ID=$(shell terraform output -json | jq -r '.instance_id.value')

deploy: init validate plan apply sourcegraph

init:
	terraform init -upgrade

validate:
	terraform validate

plan: validate
	terraform plan -var-file terraform.tfvars

apply: validate
	terraform apply -auto-approve -var-file terraform.tfvars

destroy:
	terraform destroy -force -var-file terraform.tfvars

output:
	terraform output

ssh:
	$(shell terraform output -json | jq -r '.ssh.value')

start:
	aws ec2 start-instances --instance-ids $(INSTANCE_ID)
	$(MAKE) apply

stop:
	aws ec2 stop-instances --instance-ids $(INSTANCE_ID)

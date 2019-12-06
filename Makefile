SHELL := /bin/bash
HOSTNAME=$(shell make output | grep "server =" | sed -n 's/.*https:\/\/\(.*\)\//\1/p') # ]macOS users will need to `brew install coreutils` to get the `timeout` binary
URL="https://$(HOST_PORT)/"

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

sourcegraph:
	@echo "Waiting for Sourcegraph to be ready..."
	@./bin/wait-for-it.sh -t 240 -q -h $(HOSTNAME) -p 443	
	@echo "Ready at https://$(HOSTNAME)/"

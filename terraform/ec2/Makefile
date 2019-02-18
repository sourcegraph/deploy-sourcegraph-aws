init:
	terraform init -upgrade

validate:
	terraform validate -var-file terraform.tfvars

plan: validate
	terraform plan -var-file terraform.tfvars

apply: validate
	terraform apply -auto-approve -var-file terraform.tfvars

destroy:
	terraform destroy -force -var-file terraform.tfvars

output:
	terraform output -json

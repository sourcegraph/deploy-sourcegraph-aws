variable "ssh_cidr" {
  default = ""
  description = "By default, port 22 access is restricted to the external IP address of the machine running Terraform for restrictive access"
}

variable "vpc_id" {
  default = ""
  description = "Override instad of using the default VPC id"
}

variable "subnet_id" {
  default = ""
  description = "Override instad of using a randomly chosen subvnet"
}

variable "key_name" {
  default = ""
  description = "Set if you need SSH access"
}

variable "public_key" {
  description = "Set if you want to create a key pair"
  default = ""
}

variable "app_name" {
  default = "sourcegraph"
  description = "Sets the (tag) name of the instance"
}

variable "instance_type" {
  default = "t2.large"
  description = "Set the default instance type"
}

variable "delete_root_volume_on_termination" {
  default = true
  description = "Whether to keep the EBS root volume when the instance is terminated"
}

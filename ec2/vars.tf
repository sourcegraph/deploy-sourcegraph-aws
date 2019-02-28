variable "ssh_cidr" {
  default = ""
  description = "Is the external IP address of the workstation/gateway and used on the port 22 security group rule"
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
  description = "Override the default instance type"
}

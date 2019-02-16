variable "availability_zone" {}
variable "key_name" {}

variable "vpc_id" {
  default = ""
}

variable "subnet_id" {
  default = ""
}

variable "app_name" {
  default = "sourcegraph"
}


variable "instance_type" {
  default = "t2.large"
}

variable "ssh_cidr" {
  default = ""
}

variable "availability_zone" {
  default = ""
}

variable "ssh_cidr" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "subnet_id" {
  default = ""
}

variable "key_name" {}

variable "public_key" {
  description = "Set if you want to also create a public key when deploying Sourcegraph."
  default = ""
}

variable "app_name" {
  default = "sourcegraph"
}


variable "instance_type" {
  default = "t2.large"
}

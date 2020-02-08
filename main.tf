provider "aws" {}

# ------------------------------------------
# DATA SOURCES AND LOCALS
# ------------------------------------------

# Get the external IP address of the system executing this plan
data "http" "workstation_cidr" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_vpc" "default" {
  default = "${var.vpc_id == "" ? true : false}"
  id      = "${var.vpc_id}"
}

locals {
  workstation_cidr = "${chomp(data.http.workstation_cidr.body)}/32"
  vpc_id = "${data.aws_vpc.default.id}"
}

# We need the list of availability zones if a value for the  `subnet_id` var was not supplied.
data "aws_subnet_ids" "this" {
  vpc_id = local.vpc_id
}

# Get the latest Amazon  Linux 2 AMI
data "aws_ami" "this" {
  most_recent = true
  owners = ["amazon"]


  filter {
    name = "owner-alias"
    values = [
      "amazon"]
  }


  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm*"]
  }

  filter {
    name = "architecture"
    values = [
      "x86_64"]
  }
}

# ------------------------------------------
# NETWORKING
# ------------------------------------------

resource "aws_security_group" "this" {
  name = "${var.app_name}-sg"
  description = "Allow all inbound traffic on 80 and 443"
  vpc_id = local.vpc_id
    tags = {
      Name = "${var.app_name}-sg"
    }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${coalesce(var.ssh_cidr, local.workstation_cidr)}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}


# ------------------------------------------
# IAM
# ------------------------------------------

resource "aws_iam_role" "this" {
  name = "${var.app_name}-role"

  assume_role_policy = file("resources/iam-policy-instance-assume-role.json")
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.this.name
}


# ------------------------------------------
# EC2 INSTANCE
# ------------------------------------------

# Create the key pair if a value for `public_key` was supplied
resource "aws_key_pair" "this" {
  count = var.public_key == "" ? 0 : 1
  key_name   = var.key_name
  public_key = var.public_key
}

resource "aws_instance" "this" {
  ami = data.aws_ami.this.id
  instance_type = var.instance_type
  vpc_security_group_ids = [
    "${aws_security_group.this.id}"]
  subnet_id = var.subnet_id
  key_name = var.key_name

  iam_instance_profile = aws_iam_instance_profile.this.name

  root_block_device {
    volume_size = 240
    volume_type = "gp2"
    delete_on_termination = var.delete_root_volume_on_termination
  }
  
  user_data = file("resources/user-data.sh")

  tags = {
    Name = "${var.app_name}"
  }
}

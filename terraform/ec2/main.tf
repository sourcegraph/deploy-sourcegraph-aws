provider "aws" {}


# ------------------------------------------
# NETWORK
# ------------------------------------------

data "http" "workstation_cidr" {
  url = "http://ipv4.icanhazip.com"
}

# Override with variable or hardcoded value if necessary
locals {
  workstation_cidr = "${chomp(data.http.workstation_cidr.body)}/32"
}

resource "aws_default_subnet" "this" {
  availability_zone = "${var.availability_zone}"
}


# ------------------------------------------
# SECURITY GROUP
# ------------------------------------------

resource "aws_security_group" "this" {
  name = "${var.app_name}-sg"
  description = "Allow all inbound traffic to 22 and 8080"
  vpc_id = "${coalesce(var.vpc_id, aws_default_subnet.this.vpc_id)}"

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

  ingress {
    from_port = 7080
    to_port = 7080
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 2633
    to_port = 2633
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

  tags {
    Name = "${var.app_name}-sg"
  }
}


# ------------------------------------------
# IAM POLICY AND ROLE
# ------------------------------------------

resource "aws_iam_policy" "this" {
  name = "${var.app_name}-push-metrics-cloudwatch"
  path = "/"
  description = "Push Metrics to CloudWatch"

  policy = "${file("resources/iam-policy-push-metrics-cloud-watch.json")}"
}

resource "aws_iam_role" "this" {
  name = "${var.app_name}-role"

  assume_role_policy = "${file("resources/iam-policy-instance-assume-role.json")}"
}

resource "aws_iam_role_policy_attachment" "this" {
  role = "${aws_iam_role.this.name}"
  policy_arn = "${aws_iam_policy.this.arn}"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.app_name}-instance-profile"
  role = "${aws_iam_role.this.name}"
}


# ------------------------------------------
# EC2 INSTANCE
# ------------------------------------------

data "aws_ami" "this" {
  most_recent = true


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

resource "aws_instance" "this" {
  ami = "${data.aws_ami.this.id}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.this.id}"]
  subnet_id = "${coalesce(var.subnet_id, aws_default_subnet.this.id)}"
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.this.name}"

  user_data = "${file("resources/user-data.sh")}"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "${var.app_name}"
  }
}

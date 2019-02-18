provider "aws" {}


# ------------------------------------------
# DATA SOURCES AND LOCALS
# ------------------------------------------

# Get the external IP address of the system executing this plan
data "http" "workstation_cidr" {
  url = "http://ipv4.icanhazip.com"
}

# We need the list of availability zones if a value for the  `subnet_id` var was not supplied.
data "aws_subnet_ids" "this" {
  vpc_id = "${local.vpc_id}"
}

locals {
  workstation_cidr = "${chomp(data.http.workstation_cidr.body)}/32"
  vpc_id = "${coalesce(var.vpc_id, aws_default_vpc.this.id)}"
}

# Get the latest Amazon  Linux 2 AMI
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

# ------------------------------------------
# NETWORKING
# ------------------------------------------

resource "aws_default_vpc" "this" {}

resource "aws_security_group" "this" {
  name = "${var.app_name}-sg"
  description = "Allow all inbound traffic to 22 and 8080"
  vpc_id = "${local.vpc_id}"

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
# IAM POLICY AND ROLE FOR METRICS
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

# Create the key pair if a value for `public_key` was supplied
resource "aws_key_pair" "this" {
  count = "${var.public_key == "" ? 0 : 1}"
  key_name   = "${var.key_name}"
  public_key = "${var.public_key}"
}

resource "aws_instance" "this" {
  ami = "${data.aws_ami.this.id}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.this.id}"]
  subnet_id = "${coalesce(var.subnet_id, element(data.aws_subnet_ids.this.ids, 0))}"
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

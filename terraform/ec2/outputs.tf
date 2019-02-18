output "sourcegraph_url" {
  value = "${format("https://%s/", aws_instance.this.public_dns)}"
}

output "sourcegraph_ssh_access" {
  value = "${format("ssh ec2-user@%s", aws_instance.this.public_dns)}"
}

output "instance_id" {
  value = "${aws_instance.this.id}"
}

output "instance_name" {
  value = "${aws_instance.this.tags.Name}"
}

output "instance_private_ip" {
  value = "${aws_instance.this.private_ip}"
}

output "instance_hostname" {
  value = "${aws_instance.this.public_dns}"
}

output "instance_public_ip" {
  value = "${aws_instance.this.public_ip}"
}

output "instance_key" {
  value = "${aws_instance.this.key_name}"
}

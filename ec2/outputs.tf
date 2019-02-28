output "sourcegraph_url" {
  value = "${format("https://%s/", aws_instance.this.public_dns)}"
}

output "sourcegraph_ssh_access" {
  value = "${format("ssh ec2-user@%s", aws_instance.this.public_dns)}"
}

output "instance_public_ip" {
  value = "${aws_instance.this.public_ip}"
}

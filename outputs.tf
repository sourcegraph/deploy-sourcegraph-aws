output "instance_id" {
  value = "${aws_instance.this.id}"
}
output "server" {
  value = "${format("https://%s/", aws_instance.this.public_dns)}"
}

output "ip-address" {
  value = "${aws_instance.this.public_ip}"
}

output "ssh" {
  value = "${format("ssh ec2-user@%s", aws_instance.this.public_dns)}"
}

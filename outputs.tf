output "server" {
  value = "${format("https://%s/", aws_instance.this.public_dns)}"
}

output "ip-address" {
  value = "${aws_instance.this.public_ip}"
}

output "management-console" {
  value = "${format("https://%s:2633/", aws_instance.this.public_dns)}"
}

output "ssh" {
  value = "${format("ssh ec2-user@%s", aws_instance.this.public_dns)}"
}

output "trust-self-signed-cert" {
  value = "${format("scp ec2-user@%s", aws_instance.this.public_dns)}:~/sourcegraph-root-ca.zip ./ && unzip sourcegraph-root-ca.zip && mv ./rootCA* \"$(mkcert -CAROOT)\" && mkcert -install"
}

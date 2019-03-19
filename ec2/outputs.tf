output "Server" {
  value = "${format("https://%s/", aws_instance.this.public_dns)}"
}

output "IP address" {
  value = "${aws_instance.this.public_ip}"
}

output "Management (critical configuration) console" {
  value = "${format("https://%s:2633/", aws_instance.this.public_dns)}"
}

output "SSH" {
  value = "${format("ssh ec2-user@%s", aws_instance.this.public_dns)}"
}

output "Sourcegtraph CA Root files (downlaod and install)" {
  value = "${format("scp ec2-user@%s", aws_instance.this.public_dns)}:~/sourcegraph-root-ca.zip ./ && unzip sourcegraph-root-ca.zip && mv ./rootCA* \"$(mkcert -CAROOT)\" && mkcert -install"
}

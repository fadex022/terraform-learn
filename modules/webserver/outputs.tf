output "server" {
  value = aws_instance.myapp-server
}

output "ami" {
  value = data.aws_ami.latest-amazon-linux-version
}
output "ami_id" {
  value = module.myapp-server.ami.id
}

output "ec2_public_ip" {
  value = module.myapp-server.server.public_ip
}
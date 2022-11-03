provider "aws" {
    region = "us-east-1"
}

variable "subnet_cidr_block" {}
variable "vpc_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_file" {}
variable "private_key_file" {}
variable "key_pair" {}

resource "aws_vpc" "myapp-vpc"{
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc",
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_default_security_group" "myapp-default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
      cidr_blocks = [ var.my_ip ]
      from_port = 22
      protocol = "tcp"
      to_port = 22
    }

  ingress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    }
  

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    prefix_list_ids = []
    protocol = "-1"
    to_port = 0
  } 

  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-version" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# resource "aws_key_pair" "ssh-key" {
#   key_name = "server-key"
#   public_key = file(var.public_key_file)
# }

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-version.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.myapp-default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = "awskeypair"
  # key_name = aws_key_pair.ssh-key.key_name

  # user_data = file("entry-script.sh")

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.key_pair)
    # private_key = file(var.private_key_file)
  }

  provisioner "file" {
    source = file("entry-script.sh")
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  provisioner "remote-exec" {
    # inline = [
    #   "export ENV=dev",
    #   "mkdir newdir"
    # ]
    script = file("entry-script-on-ec2.sh")
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > public_ip.txt"
  }

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

output "ami_id" {
  value = data.aws_ami.latest-amazon-linux-version.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}


# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }

#   tags = {
#     Name: "${var.env_prefix}-rtb"
#   }
# }

# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }
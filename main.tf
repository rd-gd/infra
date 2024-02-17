terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

#create vpc
resource "aws_vpc" "yvn_vpc" {
  cidr_block = "${var.cidr-block-vpc}"

  tags = {
    Name    ="VPC${var.name-tag}"
    Owner   ="${var.owner-tag}"
    Project  ="${var.project-tag}"
  }
}

#create public subnet
resource "aws_subnet" "yvn_subnet" {
  vpc_id     = aws_vpc.yvn_vpc.id
  cidr_block = "10.20.1.0/24"
  availability_zone = var.azs

tags = {
    Name    ="PB_SUBNET${var.name-tag}"
    Owner   ="${var.owner-tag}"
    Project ="${var.project-tag}"
  }
}

#create private subnet
resource "aws_subnet" "yvn_private_subnet" {
  vpc_id     = aws_vpc.yvn_vpc.id
  cidr_block = "10.20.2.0/24"
  availability_zone = var.azs

  tags = {
    Name    ="PR_SUBNET${var.name-tag}"
    Owner   ="${var.owner-tag}"
    Project ="${var.project-tag}"
  }
}

#create gateway
resource "aws_internet_gateway" "yvn_gw" {
  vpc_id = aws_vpc.yvn_vpc.id

  tags = {
    Name    ="IntGW${var.name-tag}"
    Owner   ="${var.owner-tag}"
    Project ="${var.project-tag}"
  }
}

#create route table
resource "aws_route_table" "yvn_route_table" {
  vpc_id = aws_vpc.yvn_vpc.id

  route {
    cidr_block = "${var.cidr-block-route_tb}"
    gateway_id = aws_internet_gateway.yvn_gw.id
  }

    tags = {
        Name    ="RT${var.name-tag}"
        Owner   ="${var.owner-tag}"
        Project ="${var.project-tag}"
    }
}

#route table association with public subnet
resource "aws_route_table_association" "yvn_association" {
  subnet_id      = aws_subnet.yvn_subnet.id
  route_table_id = aws_route_table.yvn_route_table.id
} 

#create security group
resource "aws_security_group" "yvn_security_group" {
  name        = "allow_tls"
  description = "HTTP and SSH"
  vpc_id      = aws_vpc.yvn_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

    tags = {
        Name="ScGr${var.name-tag}"
        Owner="${var.owner-tag}"
        Project="${var.project-tag}"
    }
}

# create ssh key
resource "tls_private_key" "hw_create_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "yvn_key" {
  key_name   = "2024_YVN"
  public_key = tls_private_key.hw_create_key.public_key_openssh
  
  tags = {
        Name    ="key${var.name-tag}"
        Owner   ="${var.owner-tag}"
        Project ="${var.project-tag}"
    }

 # create a "terraform-key.pem" to your computer!!
  provisioner "local-exec" {
    command = "echo '${tls_private_key.hw_create_key.private_key_pem}' > ./terraform-key.pem"
  }
}

#create ec2 instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "web_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "${var.instance-type}"
  key_name      = aws_key_pair.yvn_key.id

  subnet_id                   = aws_subnet.yvn_subnet.id
  vpc_security_group_ids      = [aws_security_group.yvn_security_group.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  sudo mv /var/www/html/index.html /var/www/html/index.bak
  sudo echo "<h1> IP Address </h1>" >> /var/www/html/index.html
  echo "*** Completed Installing apache2"
  EOF

  tags = {
        Name    ="ec2${var.name-tag}"
        Owner   ="${var.owner-tag}"
        Project ="${var.project-tag}"
    }
}
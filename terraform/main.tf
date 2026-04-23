terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group
resource "aws_security_group" "devops_sg" {
  name        = "${var.app_name}-sg"
  description = "Security group for DevOps app"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.app_name}-sg"
    ManagedBy = "Terraform"
  }
}

# EC2 Instance
resource "aws_instance" "devops_server" {
  ami                    = "ami-0f58b397bc5c1f2e8"  # Amazon Linux 2 ap-south-1
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  user_data              = file("userdata.sh")

  tags = {
    Name        = "${var.app_name}-server"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Elastic IP — so public IP doesn't change
resource "aws_eip" "devops_eip" {
  instance = aws_instance.devops_server.id
  domain   = "vpc"

  tags = {
    Name      = "${var.app_name}-eip"
    ManagedBy = "Terraform"
  }
}
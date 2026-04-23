terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ────────────────────────────────────────────
# KEY PAIR
# ────────────────────────────────────────────
resource "tls_private_key" "devops_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "devops_keypair" {
  key_name   = "${var.app_name}-keypair"
  public_key = tls_private_key.devops_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.devops_key.private_key_pem
  filename        = "${path.module}/${var.app_name}-keypair.pem"
  file_permission = "0400"
}

# ────────────────────────────────────────────
# IAM ROLE (FIX FOR ECR ACCESS)
# ────────────────────────────────────────────
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ────────────────────────────────────────────
# SECURITY GROUP
# ────────────────────────────────────────────
resource "aws_security_group" "devops_sg" {
  name        = "${var.app_name}-sg"
  description = "DevOps security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# ────────────────────────────────────────────
# EC2 INSTANCE
# ────────────────────────────────────────────
resource "aws_instance" "devops_server" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_keypair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("userdata.sh")

  tags = {
    Name = "${var.app_name}-server"
  }
}

# ────────────────────────────────────────────
# ELASTIC IP
# ────────────────────────────────────────────
resource "aws_eip" "devops_eip" {
  instance = aws_instance.devops_server.id
  domain   = "vpc"
}
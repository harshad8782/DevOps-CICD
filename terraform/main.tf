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
# KEY PAIR — Auto-generated, saved locally
# ────────────────────────────────────────────
resource "tls_private_key" "devops_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "devops_keypair" {
  key_name   = "${var.app_name}-keypair"
  public_key = tls_private_key.devops_key.public_key_openssh

  tags = {
    Name      = "${var.app_name}-keypair"
    ManagedBy = "Terraform"
  }
}

# Save private key to local file automatically
resource "local_file" "private_key" {
  content         = tls_private_key.devops_key.private_key_pem
  filename        = "${path.module}/${var.app_name}-keypair.pem"
  file_permission = "0400"  # read-only, like real .pem files
}

# ────────────────────────────────────────────
# SECURITY GROUP
# ────────────────────────────────────────────
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

# ────────────────────────────────────────────
# EC2 INSTANCE
# ────────────────────────────────────────────
resource "aws_instance" "devops_server" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_keypair.key_name  # uses auto-created key
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  user_data              = file("userdata.sh")
  user_data_replace_on_change = true   # ← forces EC2 recreate when userdata changes

  tags = {
    Name        = "${var.app_name}-server"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ────────────────────────────────────────────
# ELASTIC IP
# ────────────────────────────────────────────
resource "aws_eip" "devops_eip" {
  instance = aws_instance.devops_server.id
  domain   = "vpc"

  tags = {
    Name      = "${var.app_name}-eip"
    ManagedBy = "Terraform"
  }
}
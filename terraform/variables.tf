variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "app_name" {
  default = "devops-demo"
}

# key_pair_name variable REMOVED — Terraform creates it automatically now
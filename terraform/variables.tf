variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t2.micro"    # free tier eligible
}

variable "app_name" {
  default = "devops-demo"
}

variable "key_pair_name" {
  description = "Name of your AWS key pair for SSH"
  type        = string
}
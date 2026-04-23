output "ec2_public_ip" {
  value = aws_eip.devops_eip.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.app_name}-keypair.pem ubuntu@${aws_eip.devops_eip.public_ip}"
}

output "app_url" {
  value = "http://${aws_eip.devops_eip.public_ip}:8080"
}
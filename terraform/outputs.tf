output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_eip.devops_eip.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${var.app_name}-keypair.pem ec2-user@${aws_eip.devops_eip.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.devops_eip.public_ip}:8080"
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.devops_keypair.key_name
}
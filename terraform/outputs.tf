output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_eip.devops_eip.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.devops_eip.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.devops_eip.public_ip}:8080"
}
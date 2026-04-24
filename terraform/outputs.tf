output "ec2_public_ip" {
  description = "Public IP of EC2 instance (Elastic IP)"
  value       = aws_eip.devops_eip.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i terraform/${var.app_name}-keypair.pem ubuntu@${aws_eip.devops_eip.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.devops_eip.public_ip}:8081"
}

output "key_pair_name" {
  description = "Key pair name registered in AWS"
  value       = aws_key_pair.devops_keypair.key_name
}

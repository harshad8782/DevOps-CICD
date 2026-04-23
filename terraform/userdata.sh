#!/bin/bash
# This script runs when EC2 starts for the first time

yum update -y
yum install -y docker curl git

# Start Docker
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

echo "EC2 setup complete — ready for deployment"
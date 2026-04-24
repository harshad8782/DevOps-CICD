#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=============================="
echo " Starting EC2 Setup"
echo "=============================="

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release unzip

# ────────────────────────────────
# Install Docker
# ────────────────────────────────
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | tee /etc/apt/keyrings/docker.asc > /dev/null
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker

# Allow ubuntu user to run docker without sudo
usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock

# ────────────────────────────────
# Install AWS CLI v2
# ────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# ────────────────────────────────
# Create reports directory
# (log_analyzer.sh writes stats here)
# ────────────────────────────────
mkdir -p /home/ubuntu/reports
chown ubuntu:ubuntu /home/ubuntu/reports

# ────────────────────────────────
# Verify
# ────────────────────────────────
echo "=============================="
echo " Setup Complete"
echo "=============================="
docker --version
aws --version
echo "✅ EC2 ready — Docker and AWS CLI installed"
echo "✅ Deployment will be triggered by GitHub Actions CD workflow"

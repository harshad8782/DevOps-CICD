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

# Wait until Docker daemon is fully ready
echo "⏳ Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
  sleep 2
done
echo "✅ Docker is ready"

# Allow ubuntu user to run docker
usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock

# ────────────────────────────────
# Install AWS CLI v2
# ────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"

unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Verify AWS CLI
aws --version

# ────────────────────────────────
# Create reports directory
# ────────────────────────────────
mkdir -p /home/ubuntu/reports
chown ubuntu:ubuntu /home/ubuntu/reports

# ────────────────────────────────
# FINAL READINESS SIGNAL (IMPORTANT)
# ────────────────────────────────
touch /home/ubuntu/userdata_done
chown ubuntu:ubuntu /home/ubuntu/userdata_done

echo "=============================="
echo " Setup Complete"
echo "=============================="
echo "✅ EC2 ready — Docker and AWS CLI installed"
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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/keyrings/docker.asc > /dev/null
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
usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock

# ────────────────────────────────
# Install AWS CLI
# ────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# ────────────────────────────────
# Run Jenkins as Docker container
# ────────────────────────────────
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Wait for Jenkins to fully start
sleep 30

# ────────────────────────────────
# Verify
# ────────────────────────────────
echo "=============================="
echo " Setup Complete"
echo "=============================="
docker --version
aws --version
docker ps
echo "✅ Jenkins running on port 8080"
echo "✅ Jenkins initial password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword || echo "Jenkins still starting — check after 2 mins"
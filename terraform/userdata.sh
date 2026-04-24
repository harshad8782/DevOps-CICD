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

# ────────────────────────────────
# Install AWS CLI
# ────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# ────────────────────────────────
# Install Java 17
# ────────────────────────────────
apt-get install -y fontconfig openjdk-17-jre

# ────────────────────────────────
# Install Jenkins — fixed GPG key method
# ────────────────────────────────
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | gpg --dearmor \
  | tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Add jenkins to docker group AFTER jenkins is installed
usermod -aG docker jenkins

# ────────────────────────────────
# Verify
# ────────────────────────────────
echo "=============================="
echo " Setup Complete"
echo "=============================="
docker --version
aws --version
java -version
systemctl status jenkins --no-pager
echo "✅ Jenkins available at port 8080"
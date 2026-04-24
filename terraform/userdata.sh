#!/bin/bash
set -ex
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

# Wait until Docker is ready (max 2 mins)
echo "⏳ Waiting for Docker..."
timeout 120 bash -c 'until docker info > /dev/null 2>&1; do sleep 2; done' \
  || echo "⚠️ Docker not ready in time"

echo "✅ Docker ready"

# Allow ubuntu user
usermod -aG docker ubuntu

if [ -S /var/run/docker.sock ]; then
  chmod 660 /var/run/docker.sock
fi

# ────────────────────────────────
# Install AWS CLI v2
# ────────────────────────────────
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

aws --version

# ────────────────────────────────
# Reports dir
# ────────────────────────────────
mkdir -p /home/ubuntu/reports
chown ubuntu:ubuntu /home/ubuntu/reports

# ────────────────────────────────
# FINAL SIGNAL (CRITICAL)
# ────────────────────────────────
touch /tmp/userdata_done
chmod 644 /tmp/userdata_done

echo "=============================="
echo " Setup Complete"
echo "=============================="
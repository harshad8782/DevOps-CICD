#!/bin/bash
# Run this ONCE after terraform apply to auto-configure Jenkins

EC2_IP=$1
JENKINS_URL="http://$EC2_IP:8080"

echo "Waiting for Jenkins at $JENKINS_URL ..."
until curl -s "$JENKINS_URL/login" > /dev/null; do
  sleep 10
  echo "Still waiting..."
done

# Get initial admin password
JENKINS_PASS=$(ssh -i devops-demo-keypair.pem -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
  "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword")

echo "Jenkins Password: $JENKINS_PASS"
echo "Jenkins URL: $JENKINS_URL"
echo ""
echo "Next steps:"
echo "1. Open $JENKINS_URL"
echo "2. Use password above"
echo "3. Pipeline job will be created automatically"
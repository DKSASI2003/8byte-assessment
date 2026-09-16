#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/user-data.log)
exec 2>&1

dnf update -y

dnf install -y \
  docker \
  rsyslog \
  unzip \
  wget

if ! rpm -q amazon-cloudwatch-agent; then
  wget -O /tmp/amazon-cloudwatch-agent.rpm \
    https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

  rpm -Uvh /tmp/amazon-cloudwatch-agent.rpm
fi

# Install SSM Agent

dnf install -y amazon-ssm-agent || true

# Fallback if package not found

if ! rpm -q amazon-ssm-agent; then
  wget -O /tmp/amazon-ssm-agent.rpm \
    https://s3.ap-south-1.amazonaws.com/amazon-ssm-ap-south-1/latest/linux_amd64/amazon-ssm-agent.rpm

  rpm -Uvh /tmp/amazon-ssm-agent.rpm
fi

systemctl daemon-reload

systemctl enable docker
systemctl start docker

systemctl enable rsyslog
systemctl start rsyslog

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

usermod -aG docker ec2-user

mkdir -p /opt/app

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'AGENT_CONFIG'
${cloudwatch_agent_config}
AGENT_CONFIG

systemctl enable amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "Bootstrap completed successfully"
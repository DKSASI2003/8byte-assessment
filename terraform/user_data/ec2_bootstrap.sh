#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/user-data.log)
exec 2>&1

dnf update -y

dnf install -y \
  docker \
  unzip \
  wget

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

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

usermod -aG docker ec2-user

mkdir -p /opt/app

echo "Bootstrap completed successfully"
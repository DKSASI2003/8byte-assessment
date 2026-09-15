#!/bin/bash

set -e

yum update -y

yum install -y docker unzip wget

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

mkdir -p /opt/app

echo "Bootstrap completed"
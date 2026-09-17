resource "aws_ssm_association" "cloudwatch_agent" {
  for_each = local.environment_subnets

  name             = "AWS-RunShellScript"
  association_name = "8byte-cloudwatch-agent-${each.key}"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.app[each.key].id]
  }

  parameters = {
    commands = join("\n", [
      "set -e",
      "dnf install -y rsyslog wget",
      "if ! rpm -q amazon-cloudwatch-agent; then wget -O /tmp/amazon-cloudwatch-agent.rpm https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm; rpm -Uvh /tmp/amazon-cloudwatch-agent.rpm; fi",
      "systemctl enable --now rsyslog",
      "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
      "echo '${base64encode(templatefile("${path.module}/../monitoring/cloudwatch/cloudwatch-agent.json", { aws_region = var.aws_region, system_log_group = var.system_log_group_name, access_log_group = var.access_log_group_name }))}' | base64 --decode > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "chmod 0644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
    ])
  }

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch,
    aws_iam_role_policy_attachment.ssm
  ]
}

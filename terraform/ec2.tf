data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

locals {
  environment_subnets = {
    staging    = aws_subnet.public_b.id
    production = aws_subnet.public_a.id
  }
}

resource "aws_instance" "app" {
  for_each = local.environment_subnets

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.ec2.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("${path.module}/user_data/ec2_bootstrap.sh", {
    cloudwatch_agent_config = templatefile("${path.module}/../monitoring/cloudwatch/cloudwatch-agent.json", {
      aws_region       = var.aws_region
      system_log_group = var.system_log_group_name
      access_log_group = var.access_log_group_name
    })
  })

  depends_on = [
    aws_cloudwatch_log_group.application,
    aws_cloudwatch_log_group.system,
    aws_cloudwatch_log_group.access
  ]

  tags = {
    Name        = "8byte-${each.key}-app"
    Environment = each.key
  }
}

moved {
  from = aws_instance.app
  to   = aws_instance.app["production"]
}
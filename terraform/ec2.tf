data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
   root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = file("${path.module}/user_data/ec2_bootstrap.sh")

  tags = {
    Name = "app-server"
  }
}
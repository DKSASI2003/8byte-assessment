resource "aws_lb" "app" {
  for_each = local.environment_subnets

  name               = each.key == "production" ? "8byte-alb" : "8byte-staging-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = each.key
    enabled = true
  }
}

resource "aws_lb_target_group" "app" {
  for_each = local.environment_subnets

  name     = each.key == "production" ? "app-tg" : "staging-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {

    path = "/health"

    healthy_threshold   = 2
    unhealthy_threshold = 2

    timeout  = 5
    interval = 30

    matcher = "200"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = local.environment_subnets

  target_group_arn = aws_lb_target_group.app[each.key].arn

  target_id = aws_instance.app[each.key].id

  port = 80
}

resource "aws_lb_listener" "http" {
  for_each = local.environment_subnets

  load_balancer_arn = aws_lb.app[each.key].arn

  port     = 80
  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.app[each.key].arn
  }
}

moved {
  from = aws_lb.app
  to   = aws_lb.app["production"]
}

moved {
  from = aws_lb_target_group.app
  to   = aws_lb_target_group.app["production"]
}

moved {
  from = aws_lb_target_group_attachment.app
  to   = aws_lb_target_group_attachment.app["production"]
}

moved {
  from = aws_lb_listener.http
  to   = aws_lb_listener.http["production"]
}
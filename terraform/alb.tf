resource "aws_lb" "app" {

  name               = "8byte-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

resource "aws_lb_target_group" "app" {

  name     = "app-tg"
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

  target_group_arn = aws_lb_target_group.app.arn

  target_id = aws_instance.app.id

  port = 80
}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }
}
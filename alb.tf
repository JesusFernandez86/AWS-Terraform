#ALB
resource "aws_alb_target_group" "tg-alb" {
  health_check {
    interval            = 10
    path                = "/api/utils/healthcheck"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name        = "tg-alb"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.final-vpc.id
}

resource "aws_alb" "web-alb" {
  name            = "web-alb"
  internal        = false
  subnets         = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  security_groups = [aws_security_group.lb-sg.id]
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.web-alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg-alb.id
    type             = "forward"
  }
}








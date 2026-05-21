resource "aws_lb" "frontend_alb" {
  name               = "${local.common_name_suffix}-frontend-alb" # stackly-dev-frontend-alb
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.frontend_alb_sg_id]
  # it should be private subnet ids
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false # prevents accidental deletion from UI

  tags = merge (
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-frontend-alb"
    }
  )
}

resource "aws_lb_listener" "frontend_alb" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  certificate_arn   = local.frontend_alb_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hi, I am from HTTPS frontend ALB</h1>"
      status_code  = "200"
    }
  }
}

resource "aws_route53_record" "frontend_alb" {
  zone_id = var.zone_id
  name    = "*.${var.domain_name}" # *.kriiishmatic.fun
  type    = "A"
  allow_overwrite = true

  alias {
    # These are ALB details, not our domain details
    name                   = aws_lb.frontend_alb.dns_name
    zone_id                = aws_lb.frontend_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = "${local.common_name_suffix}-frontend"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = local.vpc_id
  deregistration_delay = 60 # waiting period before deleting the instance

  health_check {
    healthy_threshold = 2
    interval = 10
    matcher = "200-299"
    path = "/"
    port = 8080
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.frontend_alb.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["${var.environment}.${var.domain_name}"] # dev.kriiishmatic.fun
    }
  }
}

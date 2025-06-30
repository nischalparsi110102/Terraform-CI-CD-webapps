provider "aws" {
  region = var.aws_region
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.main.id
}

resource "aws_security_group" "alb_sg" {
  name        = "webapp-stage-alb-sg"
  description = "Allow HTTP and HTTPS"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/webapp-stage"
  retention_in_days = 14
}

resource "aws_ecs_cluster" "main" {
  name = "webapp-stage-cluster"
}

resource "aws_iam_role" "ecs_execution" {
  name = "webapp-stage-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
}

data "aws_iam_policy_document" "ecs_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "web" {
  family                   = "webapp-stage-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "web" {
  name            = "webapp-stage-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = data.aws_subnet_ids.public.ids
    security_groups = [aws_security_group.alb_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_lb" "main" {
  name               = "webapp-stage-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "web" {
  name     = "webapp-stage-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_globalaccelerator_accelerator" "main" {
  name            = "webapp-stage-accelerator"
  enabled         = true
  ip_address_type = "IPV4"
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = "TCP"
  port_ranges {
    from_port = 80
    to_port   = 80
  }
  port_ranges {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "main" {
  listener_arn = aws_globalaccelerator_listener.main.id
  endpoint_configuration {
    endpoint_id = aws_lb.main.arn
    weight      = 128
  }
  health_check_port     = 80
  health_check_protocol = "HTTP"
}

resource "aws_route53_record" "webapp" {
  zone_id = aws_route53_zone.main.id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_globalaccelerator_accelerator.main.dns_name
    zone_id                = aws_globalaccelerator_accelerator.main.dns_zone_id
    evaluate_target_health = true
  }
}
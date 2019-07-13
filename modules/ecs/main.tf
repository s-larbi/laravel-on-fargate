data "aws_availability_zones" "available" {
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "lb" {
  name   = "ecs-alb-${var.stack_name}"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-tasks-${var.stack_name}"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name            = var.stack_name
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  name        = var.stack_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    interval          = 5
    healthy_threshold = 2
    timeout           = 4
    path              = "/"
    port              = 80
    matcher           = 200
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.app.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = var.stack_name
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = var.role

  container_definitions = templatefile("${path.module}/task-definitions.json", {
    log_group                  = aws_cloudwatch_log_group.logs.name,
    aws_region                 = data.aws_region.current.name
    ecr_laravel_repository_uri = var.ecr_laravel_repository_uri
    ecr_nginx_repository_uri   = var.ecr_nginx_repository_uri
    env_vars = {
      LOG_CHANNEL   = "stderr"
      APP_DEBUG     = false
      APP_URL       = "https://${var.hostname}"
      DB_CONNECTION = "mysql"
      DB_HOST       = var.aurora_endpoint
      DB_PORT       = var.aurora_port
      DB_DATABASE   = var.aurora_db_name
      DB_USERNAME   = var.aurora_db_username
      DB_PASSWORD   = var.aurora_master_password
    }
  })
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/ecs/${var.stack_name}-laravel"
}

resource "aws_ecs_service" "main" {
  name            = var.stack_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [aws_alb_listener.https]
}
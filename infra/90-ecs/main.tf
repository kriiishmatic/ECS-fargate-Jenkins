###############ECS CLUSTER ###############


resource "aws_ecs_cluster" "main" {

  name = "${local.common_name_suffix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {

    execute_command_configuration {

      logging = "OVERRIDE"

      log_configuration {

        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-cluster"
    }
  )
}

############## CLoudwatch Log Groups ###############
resource "aws_cloudwatch_log_group" "ecs_exec" {

  name = "/ecs/${local.common_name_suffix}/ecs-exec"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {

  name = "/ecs/${local.common_name_suffix}/frontend"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "catalogue" {

  name = "/ecs/${local.common_name_suffix}/catalogue"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "user" {

  name = "/ecs/${local.common_name_suffix}/user"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cart" {

  name = "/ecs/${local.common_name_suffix}/cart"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "shipping" {

  name = "/ecs/${local.common_name_suffix}/shipping"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "payment" {

  name = "/ecs/${local.common_name_suffix}/payment"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mongodb" {

  name = "/ecs/${local.common_name_suffix}/mongodb"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "redis" {

  name = "/ecs/${local.common_name_suffix}/redis"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mysql" {

  name = "/ecs/${local.common_name_suffix}/mysql"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "rabbitmq" {

  name = "/ecs/${local.common_name_suffix}/rabbitmq"

  retention_in_days = 7
}


############## Services namespace ###############
resource "aws_service_discovery_private_dns_namespace" "main" {

  name = "internal"

  vpc  = local.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-internal"
    }
  )
}
############# Service Discovery Services- Cloud map ###############
resource "aws_service_discovery_service" "services" {

  for_each = toset(local.cloudmap_services)

  name = each.key

  dns_config {

    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

################# IAM Role for ECS Task execution ###############


resource "aws_iam_role" "ecs_task_execution_role" {

  name = "${local.common_name_suffix}-ecs-execution-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role" {

  role = aws_iam_role.ecs_task_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


################## Task Role for ECS Tasks ###############

resource "aws_iam_role" "ecs_task_role" {

  name = "${local.common_name_suffix}-ecs-task-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-ecs-task-role"
    }
  )
}

resource "aws_iam_role_policy" "ecs_task_policy" {

  name = "${local.common_name_suffix}-ecs-task-policy"

  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]

        Resource = "*"
      }
    ]
  })
}

################# IAM Policy for ECS Exec ###############
resource "aws_iam_role_policy" "ecs_exec" {

  name = "${local.common_name_suffix}-ecs-exec"

  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]

        Resource = "*"
      }
    ]
  })
}

################### frontend setup #############

resource "aws_ecs_task_definition" "frontend" {

  family = "${local.common_name_suffix}-frontend"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn


  container_definitions = jsonencode([

    {
      name  = "frontend"

      image = var.frontend_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "frontend" {

  name = "${local.common_name_suffix}-frontend"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.frontend.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.frontend_sg_id
    ]

    assign_public_ip = false
  }

  load_balancer {

    target_group_arn = aws_lb_target_group.frontend.arn

    container_name = "frontend"

    container_port = 8080
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["frontend"].arn
  }

  depends_on = [
    aws_lb_listener.frontend_alb
  ]
}


resource "aws_appautoscaling_target" "frontend" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "frontend_cpu" {

  name = "${local.common_name_suffix}-frontend-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.frontend.resource_id

  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension

  service_namespace = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

########### catalogue setup #############

resource "aws_ecs_task_definition" "catalogue" {

  family = "${local.common_name_suffix}-catalogue"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([

    {
      name  = "catalogue"

      image = var.catalogue_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = MONGO_URL
          valueFrom = aws_ssm_parameter.mongo_url.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.catalogue.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "catalogue" {

  name = "${local.common_name_suffix}-catalogue"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.catalogue.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.catalogue_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["catalogue"].arn
  }
}


resource "aws_appautoscaling_target" "catalogue" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.catalogue.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "catalogue_cpu" {

  name = "${local.common_name_suffix}-catalogue-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.catalogue.resource_id

  scalable_dimension = aws_appautoscaling_target.catalogue.scalable_dimension

  service_namespace = aws_appautoscaling_target.catalogue.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

############ user setup #############

resource "aws_ecs_task_definition" "user" {

  family = "${local.common_name_suffix}-user"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "user"

      image = var.user_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "MONGO_URL"
          valueFrom = aws_ssm_parameter.mongo_url.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.user.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "user" {

  name = "${local.common_name_suffix}-user"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.user.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.user_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["user"].arn
  }
}


resource "aws_appautoscaling_target" "user" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.user.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "user_cpu" {

  name = "${local.common_name_suffix}-user-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.user.resource_id

  scalable_dimension = aws_appautoscaling_target.user.scalable_dimension

  service_namespace = aws_appautoscaling_target.user.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

############ cart setup #############


resource "aws_ecs_task_definition" "cart" {

  family = "${local.common_name_suffix}-cart"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([

    {
      name  = "cart"

      image = var.cart_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "REDIS_HOST"
          valueFrom = aws_ssm_parameter.redis_url.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.cart.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "cart" {

  name = "${local.common_name_suffix}-cart"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.cart.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.cart_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["cart"].arn
  }
}


resource "aws_appautoscaling_target" "cart" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.cart.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "cart_cpu" {

  name = "${local.common_name_suffix}-cart-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.cart.resource_id

  scalable_dimension = aws_appautoscaling_target.cart.scalable_dimension

  service_namespace = aws_appautoscaling_target.cart.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

############ shipping setup #############

resource "aws_ecs_task_definition" "shipping" {

  family = "${local.common_name_suffix}-shipping"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "shipping"

      image = var.shipping_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "MYSQL_HOST"
          valueFrom = aws_ssm_parameter.mysql_host.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.shipping.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "shipping" {

  name = "${local.common_name_suffix}-shipping"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.shipping.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 100

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.shipping_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["shipping"].arn
  }
}


resource "aws_appautoscaling_target" "shipping" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.shipping.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "shipping_cpu" {

  name = "${local.common_name_suffix}-shipping-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.shipping.resource_id

  scalable_dimension = aws_appautoscaling_target.shipping.scalable_dimension

  service_namespace = aws_appautoscaling_target.shipping.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

############ payment setup #############

resource "aws_ecs_task_definition" "payment" {

  family = "${local.common_name_suffix}-payment"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "payment"

      image = var.payment_image

      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "MYSQL_HOST"
          valueFrom = aws_ssm_parameter.mysql_host.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.payment.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "payment" {

  name = "${local.common_name_suffix}-payment"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.payment.arn

  desired_count = 2

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.payment_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["payment"].arn
  }
}


resource "aws_appautoscaling_target" "payment" {

  max_capacity = 10

  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.payment.name}"

  scalable_dimension = "ecs:service:DesiredCount"

  service_namespace = "ecs"
}


resource "aws_appautoscaling_policy" "payment_cpu" {

  name = "${local.common_name_suffix}-payment-cpu"

  policy_type = "TargetTrackingScaling"

  resource_id = aws_appautoscaling_target.payment.resource_id

  scalable_dimension = aws_appautoscaling_target.payment.scalable_dimension

  service_namespace = aws_appautoscaling_target.payment.service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {

      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

############# mongodb setup #############

resource "aws_ecs_task_definition" "mongodb" {

  family = "${local.common_name_suffix}-mongodb"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 1024
  memory = 2048

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "mongodb"

      image = var.mongodb_image

      essential = true

      portMappings = [
        {
          containerPort = 27017
          hostPort      = 27017
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MONGO_INITDB_DATABASE"
          value = "catalogue"
        }
      ]

      secrets = [
        {
          name      = "MONGO_INITDB_ROOT_USERNAME"
          valueFrom = aws_ssm_parameter.mongodb_username.arn
        },
        {
          name      = "MONGO_INITDB_ROOT_PASSWORD"
          valueFrom = aws_ssm_parameter.mongodb_password.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.mongodb.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "mongodb" {

  name = "${local.common_name_suffix}-mongodb"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.mongodb.arn

  desired_count = 1

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.mongodb_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["mongodb"].arn
  }
}


############# mysql setup #############

resource "aws_ecs_task_definition" "mysql" {

  family = "${local.common_name_suffix}-mysql"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 1024
  memory = 2048

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "mysql"

      image = var.mysql_image

      essential = true

      portMappings = [
        {
          containerPort = 3306
          hostPort      = 3306
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MYSQL_DATABASE"
          value = "shipping"
        }
      ]

      secrets = [
        {
          name      = "MYSQL_ROOT_PASSWORD"
          valueFrom = aws_ssm_parameter.mysql_root_password.arn
        },
        {
          name      = "MYSQL_USER"
          valueFrom = aws_ssm_parameter.mysql_user.arn
        },
        {
          name      = "MYSQL_PASSWORD"
          valueFrom = aws_ssm_parameter.mysql_password.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.mysql.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "mysql" {

  name = "${local.common_name_suffix}-mysql"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.mysql.arn

  desired_count = 1

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 100

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.mysql_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["mysql"].arn
  }
}


############## redis setup #############

resource "aws_ecs_task_definition" "redis" {

  family = "${local.common_name_suffix}-redis"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "redis"

      image = var.redis_image

      essential = true

      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }
      ]

      command = [
        "redis-server",
        "--appendonly",
        "yes"
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "redis" {

  name = "${local.common_name_suffix}-redis"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.redis.arn

  desired_count = 1

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.redis_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["redis"].arn
  }
}

############# rabbitmq setup #############

resource "aws_ecs_task_definition" "rabbitmq" {

  family = "${local.common_name_suffix}-rabbitmq"

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 1024
  memory = 2048

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([

    {
      name  = "rabbitmq"

      image = var.rabbitmq_image

      essential = true

      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
          protocol      = "tcp"
        },
        {
          containerPort = 15672
          hostPort      = 15672
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "RABBITMQ_DEFAULT_USER"
          valueFrom = aws_ssm_parameter.rabbitmq_user.arn
        },
        {
          name      = "RABBITMQ_DEFAULT_PASS"
          valueFrom = aws_ssm_parameter.rabbitmq_password.arn
        }
      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.rabbitmq.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "rabbitmq" {

  name = "${local.common_name_suffix}-rabbitmq"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.rabbitmq.arn

  desired_count = 1

  launch_type = "FARGATE"

  enable_execute_command = true

  health_check_grace_period_seconds = 60

  network_configuration {

    subnets = local.private_subnet_ids

    security_groups = [
      local.rabbitmq_sg_id
    ]

    assign_public_ip = false
  }

  service_registries {

    registry_arn = aws_service_discovery_service.services["rabbitmq"].arn
  }
}
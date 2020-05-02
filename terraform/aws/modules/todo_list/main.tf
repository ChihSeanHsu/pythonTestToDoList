# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  profile = var.profile
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# SSM
# ---------------------------------------------------------------------------------------------------------------------
module "email_password" {
  source = "git::https://github.com/tmknom/terraform-aws-ssm-parameter.git?ref=tags/2.0.0"
  name   = "email_password"
  value  = var.email_password

  type        = "SecureString"
  description = "email string"
  overwrite   = true
  enabled     = true

  tags = {
    Environment = var.name_preffix
    Name        = "email_password"
  }
}

module "mysql_password" {
  source = "git::https://github.com/tmknom/terraform-aws-ssm-parameter.git?ref=tags/2.0.0"
  name   = "mysql_password"
  value  = var.mysql_db_password

  type        = "SecureString"
  description = "mysql password"
  overwrite   = true
  enabled     = true

  tags = {
    Environment = var.name_preffix
    Name        = "mysql_password"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# DB
# ---------------------------------------------------------------------------------------------------------------------
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "${var.name_preffix}-demodb"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  name     = "django"
  username = "admin"
  password = var.mysql_db_password
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = var.security_groups

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "user"
    Environment = var.name_preffix
  }

  # DB subnet group
  subnet_ids = var.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.name_preffix}-demodb"

  # Database Deletion Protection
  deletion_protection = false

  create_db_option_group = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------------------------------------------------
module ecs-cluster {
  source  = "cn-terraform/ecs-cluster/aws"
  version = "1.0.3"
  name    = "${var.name_preffix}-todo-list-cluster"
  profile = var.profile
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS ECS Task Execution Role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "Role-${var.name_preffix}-todo-list-task-execution-${var.region}"
  assume_role_policy = file("${path.module}/policies/ecs-task-execution-role.json")
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name   = "Policy-${var.name_preffix}-todo-list-task-execution-role-${var.region}"
  policy = file("${path.module}/policies/ecs-task-execution-role-policy.json")
  role   = aws_iam_role.ecs_task_execution_role.id
}
# ---------------------------------------------------------------------------------------------------------------------
# ECS Task Definition
# ---------------------------------------------------------------------------------------------------------------------
locals {
  port_mappings = [
    {
      "containerPort" = 8888
      "hostPort"      = 8888
      "protocol"      = "HTTP"
    },
  ]
}

# Container Definition
module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.21.0"

  container_name               = "todo-list-app"
  container_image              = var.image_url_and_tag
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  port_mappings                = local.port_mappings
  container_cpu                = var.container_cpu
  essential                    = var.essential
  entrypoint                   = ["sh", "-c", "'/root/run.sh'"]
  working_directory            = "/root"
  environment = [
    {
      name  = "EMAIL_HOST"
      value = var.email_host
    },
    {
      name  = "EMAIL_USE_TLS"
      value = var.email_use_tls
    },
    {
      name  = "EMAIL_PORT"
      value = var.email_port
    },
    {
      name  = "EMAIL_HOST_USER"
      value = var.email_user
    },
    {
      name  = "DEBUG"
      value = var.debug
    },
    {
      name  = "MYSQL_HOSTNAME"
      value = module.db.this_db_instance_address
    },
    {
      name  = "MYSQL_PORT"
      value = module.db.this_db_instance_port
    },
    {
      name  = "MYSQL_DB_NAME"
      value = module.db.this_db_instance_name
    },
    {
      name  = "MYSQL_USERNAME"
      value = module.db.this_db_instance_username
    }
  ]
  secrets = [
    {
      name      = "EMAIL_HOST_PASSWORD"
      valueFrom = module.email_password.ssm_parameter_name
    },
    {
      name      = "MYSQL_PASSWORD"
      valueFrom = module.mysql_password.ssm_parameter_name
    }
  ]
}

# Task Definition
resource "aws_ecs_task_definition" "td" {
  family                = "${var.name_preffix}-todo-list-td"
  container_definitions = "[ ${module.container_definition.json_map} ]"
  task_role_arn         = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  network_mode          = "awsvpc"
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = ["FARGATE"]
  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration
    content {
      container_name = proxy_configuration.value.container_name
      properties     = lookup(proxy_configuration.value, "properties", null)
      type           = lookup(proxy_configuration.value, "type", null)
    }
  }
}




# ---------------------------------------------------------------------------------------------------------------------
# ECS Service
# ---------------------------------------------------------------------------------------------------------------------
module "ecs-fargate-service" {
  source          = "cn-terraform/ecs-fargate-service/aws"
  version         = "1.0.10"
  name_preffix    = "${var.name_preffix}-todo-list"
  profile         = var.profile
  region          = var.region
  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  security_groups = var.security_groups

  ecs_cluster_name                   = module.ecs-cluster.aws_ecs_cluster_cluster_name
  ecs_cluster_arn                    = module.ecs-cluster.aws_ecs_cluster_cluster_arn
  task_definition_arn                = aws_ecs_task_definition.td.arn
  container_name                     = "todo-list-app"
  container_port                     = 8888
  desired_count                      = var.desired_count
  platform_version                   = "LATEST"
  enable_ecs_managed_tags            = false
  propagate_tags                     = "SERVICE"
  assign_public_ip                   = true
  lb_health_check_path               = "/"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 80
}

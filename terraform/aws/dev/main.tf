terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">= 2.12.0"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

locals {
  env     = "dev"
  profile = "default"
}


data "aws_region" "current" {}

data "terraform_remote_state" "ecr" {
  backend = "local"

  config = {
    path = "${path.cwd}/../shared/ecr/terraform.tfstate"
  }
}

module "https_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 3.0"

  vpc_id              = module.networking.vpc_id
  name                = "${local.env}-https-sg"
  description         = "Security group with HTTPs ports open for everybody (IPv4 CIDR), egress ports are all world open"
  ingress_cidr_blocks = ["10.0.0.0/16"]
}

module "networking" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_private_dns_enabled = true
  ecr_api_endpoint_security_group_ids  = [module.https_sg.this_security_group_id]
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [module.https_sg.this_security_group_id]
  enable_s3_endpoint                   = true

  enable_ecs_endpoint                    = true
  ecs_endpoint_private_dns_enabled       = true
  ecs_endpoint_security_group_ids        = [module.https_sg.this_security_group_id]
  enable_ecs_agent_endpoint              = true
  ecs_agent_endpoint_private_dns_enabled = true
  ecs_agent_endpoint_security_group_ids  = [module.https_sg.this_security_group_id]

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = module.networking.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


module "ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=master"
  namespace             = "eg"
  stage                 = local.env
  name                  = "my_key_pair"
  ssh_public_key_path   = "./"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

module "bastion" {
  source = "../modules/bastion"
  vpc_id = module.networking.vpc_id

  subnet_ids        = module.networking.public_subnets
  security_groups   = [aws_default_security_group.default.id]
  ssh_key           = module.ssh_key_pair.key_name
  internal_networks = [module.networking.vpc_cidr_block]
  disk_size         = 10
  instance_type     = "t2.micro"
  project           = "todo_list"
}

module "todo_list" {
  source            = "../modules/todo_list"
  region            = data.aws_region.current.name
  name_preffix      = local.env
  profile           = local.profile
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnets
  public_subnets    = module.networking.public_subnets
  security_groups   = [aws_default_security_group.default.id]
  image_url_and_tag = "${data.terraform_remote_state.ecr.outputs.repository_url}:${local.env}"
  email_host        = "smtp.gmail.com"
  email_use_tls     = 1
  email_port        = 587
  email_user        = "just.test.for.something@gmail.com"
  email_password    = "dummy"

  mysql_db_password = "Password"
  debug             = 1
}

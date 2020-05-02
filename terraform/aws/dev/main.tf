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

module "networking" {
  source                                      = "cn-terraform/networking/aws"
  version                                     = "2.0.5"
  name_preffix                                = local.env
  profile                                     = local.profile
  region                                      = data.aws_region.current.name
  vpc_cidr_block                              = "192.168.0.0/16"
  availability_zones                          = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  public_subnets_cidrs_per_availability_zone  = ["192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19"]
  private_subnets_cidrs_per_availability_zone = ["192.168.128.0/19", "192.168.160.0/19", "192.168.192.0/19"]
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

  subnet_ids        = module.networking.public_subnets_ids
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
  private_subnets   = module.networking.private_subnets_ids
  public_subnets    = module.networking.public_subnets_ids
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

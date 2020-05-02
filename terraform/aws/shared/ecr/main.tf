provider "aws" {
  region = "ap-northeast-1"
}

module "ecr" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name   = "todo-list-app"
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = module.ecr.repository_name
  policy     = file("${path.cwd}/policies/list-app-ecr-lifecycle.json")
}

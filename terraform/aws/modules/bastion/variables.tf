variable "project" {
  description = "Project tag."
}

variable "vpc_id" {
  description = "VPC id"
}

variable "subnet_ids" {
  description = "The VPC Subnet IDs to launch in."
}

variable "security_groups" {
  description = "The security_groups to launch in."
}

variable "ssh_key" {
  description = "The key name of the Key Pair to use for the instance."
}

variable "allowed_hosts" {
  description = "CIDR blocks of trusted networks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "The type of instance to start."
  default     = "t3.micro"
}

variable "disk_size" {
  description = "The size of the root volume in gigabytes."
  default     = 10
}

variable "internal_networks" {
  type        = list(string)
  description = "Internal network CIDR blocks."
}

variable "ami" {
  default = ""
}


data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }

  owners = ["aws-marketplace"]
}

locals {
  vpc_id        = var.vpc_id
  project       = var.project
  ami_id        = var.ami != "" ? var.ami : data.aws_ami.centos.id
  disk_size     = var.disk_size
  subnet_ids    = var.subnet_ids
  ssh_key       = var.ssh_key
  instance_type = var.instance_type
}


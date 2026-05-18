variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "public_subnet_ids" { type = list(string) }
variable "instance_type" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_capacity" {}
variable "key_name" { sensitive = true }
variable "backend_image_tag" {}
variable "security_group_id" {}
variable "target_group_arn" {}
variable "log_group_name" {}
variable "redis_endpoint" {}
variable "mongodb_uri" { sensitive = true }
variable "aws_region" {}
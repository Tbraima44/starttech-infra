variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" {}
variable "node_type" {}
variable "num_cache_nodes" {}
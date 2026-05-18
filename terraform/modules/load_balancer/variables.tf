variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" {}
variable "certificate_arn" {
  description = "ARN of SSL certificate (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

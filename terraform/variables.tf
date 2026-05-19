variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "starttech"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 1
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  sensitive   = true
}

variable "backend_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
  default     = ""
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1
}

variable "alarm_email" {
  description = "Email for CloudWatch alarms"
  type        = string
  default     = "brahimtoyheeb@gmail.com"
}

variable "mongodb_uri" {
  description = "MongoDB Atlas URI"
  type        = string
  sensitive   = true
}

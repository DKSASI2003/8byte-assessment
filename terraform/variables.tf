variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "volume_type" {
  type = string
}

variable "db_name" {
  type = string
}

variable "alb_logs_bucket_name" {
  type = string
}

variable "my_ip_address" {
  type        = string
  description = "Public IPv4 address allowed to access the ALB and EC2 over SSH"
}

variable "application_log_group_name" {
  type = string
}

variable "system_log_group_name" {
  type = string
}

variable "access_log_group_name" {
  type = string
}
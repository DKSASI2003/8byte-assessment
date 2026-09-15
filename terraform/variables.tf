variable "aws_region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "volume_size" {
  default = 20
  
}

variable "volume_type" {
  default = "gp3"
}
variable "db_name" {
  default = "appdb"
}
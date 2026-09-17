aws_region           = "ap-south-1"
vpc_cidr             = "10.0.0.0/16"
instance_type        = "t3.micro"
volume_size          = 30
volume_type          = "gp3"
db_name              = "appdb"
alb_logs_bucket_name = "8byte-alb-logs-891377196933"

application_log_group_name = "8byte-app"
system_log_group_name      = "ec2-system"
access_log_group_name      = "access-logs"

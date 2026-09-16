resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "8Byte-Infrastructure-Dashboard"

  dashboard_body = templatefile("${path.module}/../monitoring/cloudwatch/infrastructure-dashboard.json", {
    aws_region                   = var.aws_region
    staging_instance_id          = aws_instance.app["staging"].id
    production_instance_id       = aws_instance.app["production"].id
    rds_instance_identifier      = aws_db_instance.postgres.identifier
    staging_target_group_arn     = aws_lb_target_group.app["staging"].arn_suffix
    staging_load_balancer_arn    = aws_lb.app["staging"].arn_suffix
    production_target_group_arn  = aws_lb_target_group.app["production"].arn_suffix
    production_load_balancer_arn = aws_lb.app["production"].arn_suffix
  })
}

resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "8Byte-Application-Dashboard"

  dashboard_body = templatefile("${path.module}/../monitoring/cloudwatch/application-dashboard.json", {
    aws_region                   = var.aws_region
    staging_load_balancer_arn    = aws_lb.app["staging"].arn_suffix
    production_load_balancer_arn = aws_lb.app["production"].arn_suffix
  })
}
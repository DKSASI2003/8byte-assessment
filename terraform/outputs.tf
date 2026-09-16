output "alb_dns" {
  value = aws_lb.app["production"].dns_name
}

output "staging_alb_dns" {
  value = aws_lb.app["staging"].dns_name
}

output "production_alb_dns" {
  value = aws_lb.app["production"].dns_name
}

output "instance_public_ip" {
  value = aws_instance.app["production"].public_ip
}

output "staging_instance_id" {
  value = aws_instance.app["staging"].id
}

output "production_instance_id" {
  value = aws_instance.app["production"].id
}

output "staging_instance_public_ip" {
  value = aws_instance.app["staging"].public_ip
}

output "production_instance_public_ip" {
  value = aws_instance.app["production"].public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_database_name" {
  value = aws_db_instance.postgres.db_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "alb_logs_bucket" {
  value = aws_s3_bucket.alb_logs.id
}

output "infrastructure_dashboard_name" {
  value = aws_cloudwatch_dashboard.infrastructure.dashboard_name
}

output "application_dashboard_name" {
  value = aws_cloudwatch_dashboard.application.dashboard_name
}
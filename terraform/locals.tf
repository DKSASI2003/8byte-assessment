locals {

  postgres_secret = jsondecode(
    data.aws_secretsmanager_secret_version.postgres.secret_string
  )

}
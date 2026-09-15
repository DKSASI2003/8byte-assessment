data "aws_secretsmanager_secret" "postgres" {
  name = "8byte-postgres-secret"
}

data "aws_secretsmanager_secret_version" "postgres" {
  secret_id = data.aws_secretsmanager_secret.postgres.id
}
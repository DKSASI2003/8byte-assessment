resource "aws_db_subnet_group" "db" {

  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {

  identifier = "postgres-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name = var.db_name

  username = local.postgres_secret.username
  password = local.postgres_secret.password
  db_subnet_group_name = aws_db_subnet_group.db.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  backup_retention_period = 7

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name = "postgres-db"
  }

  depends_on = [
    aws_db_subnet_group.db,
    data.aws_secretsmanager_secret_version.postgres
  ]
}
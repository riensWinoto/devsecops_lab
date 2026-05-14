ephemeral "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!@$"
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.environment}-data-processor-db-password"
  description = "Database password for data processor - ${var.environment}"
  kms_key_id  = var.kms_key_id
  tags = { environment = var.environment
  owner = "data-platform" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id                = aws_secretsmanager_secret.db_password.id
  secret_string_wo         = ephemeral.random_password.db_password.result
  secret_string_wo_version = 1
}
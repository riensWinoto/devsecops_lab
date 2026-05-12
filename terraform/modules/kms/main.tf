resource "aws_kms_key" "key" {
  description             = "KMS key for ${var.environment} data platform encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = 7
  tags = {
    environment = var.environment
  owner = "data-platform" }
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${var.environment}-data-platform"
  target_key_id = aws_kms_key.key.id
}

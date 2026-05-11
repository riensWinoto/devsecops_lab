resource "aws_s3_bucket" "bucket" {
  bucket = "${var.environment}-${var.bucket_name}"
  tags   = merge({ environment = var.environment }, var.tags)
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}
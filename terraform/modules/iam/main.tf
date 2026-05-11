resource "aws_iam_user" "user" {
  name = "${var.environment}-${var.username}"
  tags = merge({ environment = var.environment }, var.tags)
}
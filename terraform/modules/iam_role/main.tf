locals {
  role_name = "${var.environment}-${var.role_name}-role"
  tags = {
    Name        = local.role_name
    environment = var.environment
    owner       = "data-platform"
  }

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "this" {
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

resource "aws_iam_instance_profile" "this" {
  name = local.role_name
  role = aws_iam_role.this.id
  tags = local.tags
}

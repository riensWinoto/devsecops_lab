data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm.*"]
  }
}

locals {
  environment = basename(abspath(path.root))
  env_tags = {
    environment = local.environment
  }
  account_id = data.aws_caller_identity.current.account_id
  os         = data.aws_ami.amazon_linux_2.image_id
}

#========== Bucket ==========
resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_info

  bucket = "${local.environment}-${each.value.name}-${local.account_id}"
  tags   = merge(local.env_tags, each.value.tags)
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id
  versioning_configuration {
    status = var.bucket_info[each.key]["versioning"] ? "Enabled" : "Disabled"
  }
}

#========== Instance ==========
resource "aws_instance" "instance" {
  for_each = var.ec2_instance_info

  ami           = local.os
  instance_type = each.value.machine
  tags          = merge(local.env_tags, { Name = "${local.environment}-${each.value.name}" }, each.value.tags)
}

#========== IAM ==========
resource "aws_iam_user" "user" {
  for_each = var.iam_info

  name = "${local.environment}-${each.value.name}"
  tags = merge(local.env_tags, each.value.tags)
}
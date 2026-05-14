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

#========== KMS ==========
module "kms" {
  source      = "../../modules/kms"
  environment = local.environment
}

#========== Secret Manager ==========
module "secret" {
  source      = "../../modules/secrets"
  environment = local.environment
  kms_key_id  = module.kms.key_id
}

#========== Bucket ==========
module "bucket" {
  source = "../../modules/s3"

  for_each           = var.bucket_info
  bucket_name        = "${each.value.name}-${local.account_id}"
  versioning_enabled = each.value.versioning
  kms_key_id         = module.kms.key_id
  environment        = local.environment
  tags               = each.value.tags
}

#========== Instance ==========
module "instance" {
  source = "../../modules/ec2"

  for_each      = var.ec2_instance_info
  instance_name = each.value.name
  instance_type = each.value.machine
  ami           = local.os
  kms_key_id    = module.kms.key_id
  secret_arn    = each.value.name == "data-processor" ? module.secret.secret_arn : null
  environment   = local.environment
  tags          = each.value.tags
}

#========== IAM ==========
module "iam" {
  source = "../../modules/iam"

  for_each    = var.iam_info
  username    = each.value.name
  environment = local.environment
  tags        = each.value.tags
}
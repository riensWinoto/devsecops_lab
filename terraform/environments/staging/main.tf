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

  for_each             = var.ec2_instance_info
  instance_name        = each.value.name
  instance_type        = each.value.machine
  ami                  = local.os
  kms_key_id           = module.kms.key_id
  secret_arn           = each.value.name == "data-processor" ? module.secret.secret_arn : null
  instance_profile_name = module.iam_role[each.key].instance_profile_name
  environment          = local.environment
  tags                 = each.value.tags
}

#========== IAM ==========
module "iam" {
  source = "../../modules/iam"

  for_each    = var.iam_info
  username    = each.value.name
  environment = local.environment
  tags        = each.value.tags
}

#========== IAM Role ==========
module "iam_role" {
  source = "../../modules/iam_role"

  for_each    = var.ec2_instance_info
  role_name   = each.value.name
  environment = local.environment
  policy_json = templatefile("../../policies/${each.value.name}-role.json.tpl",
    each.value.name == "data-processor" ?
    (
      {
        raw_data_bucket_arn       = module.bucket["raw-data"].bucket_arn
        processed_data_bucket_arn = module.bucket["processed-data"].bucket_arn
        kms_key_arn               = module.kms.key_arn
        secret_arn                = module.secret.secret_arn
      }
    ) :
    (
      {
        raw_data_bucket_arn       = module.bucket["raw-data"].bucket_arn
        processed_data_bucket_arn = module.bucket["processed-data"].bucket_arn
        kms_key_arn               = module.kms.key_arn
      }
    )
  )
}

resource "aws_kms_key_policy" "this" {
  key_id = module.kms.key_id
  policy = templatefile("../../policies/kms-key.json.tpl", {
    account_id              = local.account_id
    data_processor_role_arn = module.iam_role["data-processor"].role_arn
    audit_server_role_arn   = module.iam_role["audit-server"].role_arn
    platform_admin_user_arn = module.iam["platform-admin"].user_arn
  })
}

resource "aws_iam_policy" "platform_admin" {
  name = "${local.environment}-platform-admin-policy"
  policy = templatefile("../../policies/platform-admin-user.json.tpl", {
    account_id = local.account_id
  })
  tags = {
    environment = local.environment
    owner       = "data-platform"
  }
}

resource "aws_iam_user_policy_attachment" "platform_admin" {
  user       = module.iam["platform-admin"].user_name
  policy_arn = aws_iam_policy.platform_admin.arn
}
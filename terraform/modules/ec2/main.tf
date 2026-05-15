resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type
  tags = merge({ Name = "${var.environment}-${var.instance_name}",
  environment = var.environment }, var.tags)

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
  }

  iam_instance_profile = var.instance_profile_name
  user_data = var.secret_arn != null ? (<<-EOF
#!/bin/bash
ENV_DIR=/opt/app
mkdir -p $ENV_DIR
aws secretsmanager get-secret-value --secret-id ${var.secret_arn} \
--query SecretString \
--output text > $ENV_DIR/db.env
chmod 600 $ENV_DIR/db.env
EOF
  ) : null
}
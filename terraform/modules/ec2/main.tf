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
}
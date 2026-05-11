resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type
  tags = merge({ Name = "${var.environment}-${var.instance_name}",
  environment = var.environment }, var.tags)
}
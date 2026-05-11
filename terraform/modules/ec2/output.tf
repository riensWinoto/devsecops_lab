output "instance_id" {
  value = aws_instance.instance.id
}

output "instance_arn" {
  value = aws_instance.instance.arn
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}
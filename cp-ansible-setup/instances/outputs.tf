output "instance_ids" {
  value = aws_instance.cp-private.*.private_dns
}

output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "instance" {
  value = aws_instance.instance.public_ip
}
output "instance_pri" {
  value = aws_instance.instance_pri.private_ip
}
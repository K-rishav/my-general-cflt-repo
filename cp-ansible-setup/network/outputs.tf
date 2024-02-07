output "vpc_id" {
  value = aws_vpc.demo-vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.demo-vpc-subnet-public.id
}

output "private_subnet_id" {
  value = aws_subnet.demo-vpc-subnet-private.id
}

output "bastion_sg_id" {
  value = aws_security_group.demo-vpc-bastion-sg.id
}

output "private_sg_id" {
  value = aws_security_group.demo-vpc-instances-sg-all.id
}

output "subnet_ids" {
  value = [    aws_subnet.demo-vpc-subnet-private.id,    aws_subnet.demo-vpc-subnet-public.id  ]
}
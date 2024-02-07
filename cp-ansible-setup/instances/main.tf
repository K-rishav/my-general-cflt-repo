resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name = aws_key_pair.key_pair.key_name
  tags = {
    Name = var.bastion_host_name
  }
}

resource "aws_instance" "cp-private" {
  count         = var.instance_count
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = false
  key_name = aws_key_pair.key_pair.key_name
  subnet_id     = var.private_subnet_id
  vpc_security_group_ids = [var.private_sg_id]

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.cp_host_name}-${count.index + 1}"
  }
}
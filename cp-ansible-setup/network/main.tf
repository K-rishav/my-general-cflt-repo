resource "aws_vpc" "demo-vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "demo-vpc-internet-gateway" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "demo-vpc-subnet-public" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = var.public_subnet_cidr_block
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

# Create a route table for the public subnet and associate it with the public subnet
resource "aws_route_table" "demo-vpc-public-rt" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-vpc-internet-gateway.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "demo-vpc-public-subnet-rt" {
  subnet_id      = aws_subnet.demo-vpc-subnet-public.id
  route_table_id = aws_route_table.demo-vpc-public-rt.id
}


# Private subnet for ec2 instances
resource "aws_subnet" "demo-vpc-subnet-private" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = var.private_subnet_cidr_block
  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}

resource "aws_eip" "demo-vpc-eip" {
  depends_on = [ aws_internet_gateway.demo-vpc-internet-gateway ]
}

resource "aws_nat_gateway" "demo-vpc-nat" {
  allocation_id = aws_eip.demo-vpc-eip.id
  subnet_id     = aws_subnet.demo-vpc-subnet-public.id

  tags = {
    Name = "${var.vpc_name}-nat"
  }
}


# Create a route table for the private subnet and associate it with the private subnet
resource "aws_route_table" "demo-vpc-private-rt" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo-vpc-nat.id
  }

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
  depends_on = [ aws_nat_gateway.demo-vpc-nat ]
}

resource "aws_route_table_association" "demo-vpc-private-subnet-rt" {
  subnet_id      = aws_subnet.demo-vpc-subnet-private.id
  route_table_id = aws_route_table.demo-vpc-private-rt.id
}

# Security Group for Bastion Host
resource "aws_security_group" "demo-vpc-bastion-sg" {
  name_prefix = "bastion-sg"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }


   # exposing control center to outside world
      ingress {
      from_port   = 9021
      to_port     = 9021
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
    }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-bastion-sg"
  }
  depends_on = [ aws_vpc.demo-vpc ]
}

# Security Group for all CP components
resource "aws_security_group" "demo-vpc-instances-sg-all" {
  name_prefix = "instances-"
  vpc_id      = aws_vpc.demo-vpc.id

  # Ingress Rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.demo-vpc-bastion-sg.id}"]
  }

  #ping
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = ["${aws_security_group.demo-vpc-bastion-sg.id}"]
  }

  #for kraft
  ingress {
      from_port   = 9093
      to_port     = 9093
      protocol    = "tcp"
      cidr_blocks = ["10.0.2.0/24"]
    }

  #for inter broker communication
  ingress {
      from_port   = 9091
      to_port     = 9091
      protocol    = "tcp"
      cidr_blocks = ["10.0.2.0/24"]
    }

    #for kafka adminclient api and custom applications
      ingress {
      from_port   = 9092
      to_port     = 9092
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
    }

    # for standalone REST Proxy (Optional)
    ingress {
          from_port   = 8082
          to_port     = 8082
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
        }


    # for kafka connect
    ingress {
          from_port   = 8083
          to_port     = 8083
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
        }

    # for ksql
    ingress {
          from_port   = 8088
          to_port     = 8088
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
        }

    #for Schema Registry
    ingress {
          from_port   = 8081
          to_port     = 8081
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
        }

    #for browser access to confluent control center
    ingress {
          from_port   = 9021
          to_port     = 9021
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
        }

    # for metadata service and embedded kafka REST
    ingress {
              from_port   = 8090
              to_port     = 8090
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]   #can be made more restrictive
            }


    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "${var.vpc_name}-instances-sg-all"
  }
}



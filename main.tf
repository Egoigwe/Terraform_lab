# Creating a tag for the id
locals {
  Name = "chinedu"
}

// Creating VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
  tags = {
    Name = "${local.Name}-vpc"
  }
}

// Creating Public_Subnet_1
resource "aws_subnet" "pub_sub_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr2
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.Name}-pub_subnet_1"
  }
}

// Creating Public_Subnet_2
resource "aws_subnet" "pub_sub_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr3
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.Name}-pub_subnet_2"
  }
}

// Creating Private_Subnet_1
resource "aws_subnet" "pri_sub_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr4
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.Name}-pri_subnet_1"
  }
}

// Creating Private_Subnet_2
resource "aws_subnet" "pri_sub_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr5
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.Name}-pri_subnet_2"
  }
}

// Creatig Elastic instance eip
resource "aws_eip" "elp" {
  instance = aws_instance.instance_pri.id
  domain   = "vpc"
}

// Creatig Elastic nat eip
resource "aws_eip" "nat_elp" {
  domain   = "vpc"
}

// Creating Nat gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_elp.id
  subnet_id     = aws_subnet.pub_sub_1.id

  tags = {
    Name = "${local.Name}-ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

// Creating Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.Name}-igw"
  }
}

// Create route tabble for public subnets
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.all-cidr
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.Name}-pub_rt"
  }
}

// Create route tabble for private subnets
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.all_pri-cidr
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${local.Name}-pri_rt"
  }
}

// Creating route table association for public_subnet_1
resource "aws_route_table_association" "ass-public_subnet_1" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.pub_rt.id
}

// Creating route table association for public_subnet_2
resource "aws_route_table_association" "ass-public_subnet_2" {
  subnet_id      = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.pub_rt.id
}

// Creating route table association for private_subnet_1
resource "aws_route_table_association" "ass-private_subnet_1" {
  subnet_id      = aws_subnet.pri_sub_1.id
  route_table_id = aws_route_table.pri_rt.id
}

// Creating route table association for private_subnet_2
resource "aws_route_table_association" "ass-Private_Subnet_2" {
  subnet_id      = aws_subnet.pri_sub_2.id
  route_table_id = aws_route_table.pri_rt.id
}

// Security Group for ssh
resource "aws_security_group" "sg" {
  name        = "${local.Name}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "${local.Name}-sg"
  }
}
resource "aws_security_group_rule" "rule1" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.all-cidr]
  security_group_id = aws_security_group.sg.id
}
resource "aws_security_group_rule" "rule2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.all-cidr]
  security_group_id = aws_security_group.sg.id
}

// Security Group for http
resource "aws_security_group" "sg_2" {
  name        = "${local.Name}-sg_2"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "${local.Name}-sg_2"
  }
}
resource "aws_security_group_rule" "rule3" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.all_pri-cidr]
  security_group_id = aws_security_group.sg_2.id
}
resource "aws_security_group_rule" "rule4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.all_pri-cidr]
  security_group_id = aws_security_group.sg_2.id
}

// Creating Key pair
resource "aws_key_pair" "key" {
  key_name   = "${local.Name}-key"
  public_key = file("./chinedu-key.pub")
}

// Creating EC2 Instance one
resource "aws_instance" "instance" {
  ami                         = "ami-08e592fbb0f535224" //red-hat
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.pub_sub_1.id
  associate_public_ip_address = true
  tags = {
    Name = "${local.Name}-instance"
  }
}

// Creating EC2 Instance
resource "aws_instance" "instance_pri" {
  ami                         = "ami-08e592fbb0f535224" //red-hat
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids      = [aws_security_group.sg_2.id]
  subnet_id                   = aws_subnet.pri_sub_1.id
  associate_public_ip_address = true
  tags = {
    Name = "${local.Name}-instance_pri"
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.25.0"
    }
  }
}

#VPC
resource "aws_vpc" "final-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "F-vpc"
  }
}

#Internet gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.final-vpc.id

  tags = {
    Name = "F-Igw"
  }
}

#Route tables
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.final-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }

  tags = {
    Name = "F-public-routeTable1"
  }
}

resource "aws_route_table" "private-rt1" {
  vpc_id = aws_vpc.final-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "F-private-routeTable1"
  }
}

resource "aws_route_table" "private-rt2" {
  vpc_id = aws_vpc.final-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "F-private-routeTable2"
  }
}

#Subnets
resource "aws_subnet" "public-subnet1" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "F-public-subnet1"
  }
}
resource "aws_subnet" "public-subnet2" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "F-public-subnet1"
  }
}
resource "aws_subnet" "private-subnet1" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "F-private-subnet1"
  }
}
resource "aws_subnet" "private-subnet2" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "F-private-subnet2"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.private-rt1.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.private-rt2.id
}

#Security groups
resource "aws_security_group" "DataBase-sg" {
  name   = "DataBase-sg"
  vpc_id = aws_vpc.final-vpc.id
  ingress {
    description = "SQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "F-DB-sg"
  }
}

resource "aws_security_group" "ec2-webServers-sg" {
  name   = "ec2-webServers-sg"
  vpc_id = aws_vpc.final-vpc.id
  ingress {
    description = "APP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }
  egress {
    description = "SQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "F-web-servers-sg"
  }
}

resource "aws_security_group" "lb-sg" {
  name   = "lb-sg"
  vpc_id = aws_vpc.final-vpc.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "F-lb-sg"
  }
}

#Elastic ip
resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "F-elasticip-natgw"
  }
}

#NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-subnet1.id
  depends_on    = [aws_internet_gateway.internet-gw]
  tags = {
    Name = "F-natgw"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "dev"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.tags_name}-vpc"
    env = var.env
  }
}


resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr) #2
  vpc_id     = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidr, count.index)

  tags = {
    Name = "${var.tags_name}-public-subnet"
    env = var.env
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidr, count.index)

  tags = {
    Name = "${var.tags_name}-private-subnet"
    env = var.env
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.tags_name}-public-rt"
    env = var.env
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.tags_name}-private-rt"
    env = var.env
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.tags_name}-igw"
    env = var.env
  }
}

resource "aws_route_table_association" "a" {
  count = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
count = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.tags_name}-NAT"
    env = var.env
  }
}

resource "aws_eip" "ip" {
  domain = "vpc"
}



# resource "aws_instance" "web" {
#   ami                         = "ami-0f403e3180720dd7e"
#   instance_type               = "t2.micro"
#   key_name                    = "pritam-terraform-nv"
#   subnet_id                   = aws_subnet.public.id
#   associate_public_ip_address = true
#   tags = {
#     Name = "HelloWorld"
#   }
# }
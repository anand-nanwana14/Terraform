provider "aws" {
  region = "us-east-1"
}
resource "aws_s3_bucket" "my-ff_bucket" {
  bucket ="my-upgrad-bucket1"

  tags = {
    Name = "my-upgrad-bucket123"
  }
}

resource "aws_vpc" "upgrad_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { 
    Name = "upgrad-vpc"
  }
}

resource "aws_internet_gateway" "upgrad_igw" {
  vpc_id = aws_vpc.upgrad_vpc.id
  tags = {
    Name = "my-upgrad-igw"
  }
}

# public subnet - AZ-a
resource "aws_subnet" "public_subnet_a" {
  vpc_id = aws_vpc.upgrad_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

# public subnet - AZ-b
resource "aws_subnet" "public_subnet_b" {
  vpc_id = aws_vpc.upgrad_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b"
  }
}

# private subnet-AZ-a
resource "aws_subnet" "private_subnet_a" {
  vpc_id = aws_vpc.upgrad_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-a"
  }
}

#Private Subnet - AZ-b
resource "aws_subnet" "private_subnet_b" {
  vpc_id = aws_vpc.upgrad_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_eip" "upgrad_a" {
  vpc = true
  tags = {
    Name = "upgrad-a"
  }
}

resource "aws_nat_gateway" "upgrad_a" {
  allocation_id = aws_eip.upgrad_a.id
  subnet_id = aws_subnet.public_subnet_a.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.upgrad_vpc.id
  tags = {
    Name = "public_rt"
  }
}

# route table with public subnet in AZ-a
resource "aws_route_table_association" "public_assoc_a" {
  subnet_id = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate public route table with public subnet in AZ-b
resource "aws_route_table_association" "public_assoc_b" {
  subnet_id = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a route to the internet gateway
resource "aws_route" "internet_gateway_route" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.upgrad_igw.id
}

# Create private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.upgrad_vpc.id
  tags = {
    Name = "private_rt"
}
}

# Associate private route table with private subnet in AZ-b
resource "aws_route_table_association" "private_assoc_a" {
  subnet_id = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate private route table with private subnet in AZ-b
resource "aws_route_table_association" "private_assoc_b" {
  subnet_id = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}
# Associate private route table with NAT-gateway in AZ-b
# Create a route to the NAT gateway in the private route table
resource "aws_route" "private_nat_gateway_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.upgrad_a.id
}

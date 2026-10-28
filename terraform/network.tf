
# Create VPC

resource "aws_vpc" "kube-monitor-vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kube-monitor-vpc"
  }
}

# Get Available Availability Zones data source

data "aws_availability_zones" "available" {
  state = "available"
}


# Create Public Subnets (Two AZs)

resource "aws_subnet" "public_sub_1" {
  vpc_id                  = aws_vpc.kube-monitor-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "kube-monitor-public-1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_sub_2" {
  vpc_id                  = aws_vpc.kube-monitor-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "kube-monitor-public-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# Create Private Subnets (Two AZs)

resource "aws_subnet" "private_sub_1" {
  vpc_id            = aws_vpc.kube-monitor-vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                              = "kube-monitor-private-1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_sub_2" {
  vpc_id            = aws_vpc.kube-monitor-vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                              = "kube-monitor-private-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# Internet Gateway

resource "aws_internet_gateway" "kube-monitor-igw" {

  vpc_id = aws_vpc.kube-monitor-vpc.id

  tags = {
    Name = "kube-monitor-igw"
  }
}


# Static public IP for NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "kube-monitor-nat-eip"
  }
}

# NAT Gateway

resource "aws_nat_gateway" "kube-monitor-nat" {

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_sub_1.id

  depends_on = [aws_internet_gateway.kube-monitor-igw]

  tags = {
    Name = "kube-monitor-nat"
  }
}

# Public Route Table

resource "aws_route_table" "public-rt" {

  vpc_id = aws_vpc.kube-monitor-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kube-monitor-igw.id
  }

  tags = {
    Name = "kube-monitor-public-rt"
  }
}

# Private Route Table

resource "aws_route_table" "private-rt" {

  vpc_id = aws_vpc.kube-monitor-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kube-monitor-nat.id
  }

  tags = {
    Name = "kube-monitor-private-rt"
  }
}


# Route Table Associations

resource "aws_route_table_association" "public_1" {

  subnet_id      = aws_subnet.public_sub_1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public_2" {

  subnet_id      = aws_subnet.public_sub_2.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private_1" {

  subnet_id      = aws_subnet.private_sub_1.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private_2" {

  subnet_id      = aws_subnet.private_sub_2.id
  route_table_id = aws_route_table.private-rt.id
}


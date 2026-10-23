
# ==========================================
# 1. AVAILABLE AVAILABILITY ZONES
# ==========================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ==========================================
# 2. VPC
# ==========================================

resource "aws_vpc" "main" {
  count = local.enable_network ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubemonitor-vpc"
  }
}

# ==========================================
# 3. PUBLIC SUBNETS (TWO AZs)
# ==========================================

resource "aws_subnet" "public" {
  count = local.enable_network ? 2 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "kubemonitor-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

# ==========================================
# 4. PRIVATE SUBNETS (TWO AZs)
# ==========================================

resource "aws_subnet" "private" {
  count = local.enable_network ? 2 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = local.private_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                              = "kubemonitor-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ==========================================
# 5. INTERNET GATEWAY
# ==========================================

resource "aws_internet_gateway" "main" {
  count = local.enable_network ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "kubemonitor-igw"
  }
}

# ==========================================
# 6. NAT GATEWAY
# ==========================================

# Static public IP for NAT Gateway
resource "aws_eip" "nat" {
  count = local.enable_network ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "kubemonitor-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count = local.enable_network ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "kubemonitor-nat"
  }
}

# ==========================================
# 7. PUBLIC ROUTE TABLE
# ==========================================

resource "aws_route_table" "public" {
  count = local.enable_network ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "kubemonitor-public-rt"
  }
}

# ==========================================
# 8. PRIVATE ROUTE TABLE
# ==========================================

resource "aws_route_table" "private" {
  count = local.enable_network ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "kubemonitor-private-rt"
  }
}

# ==========================================
# 9. ROUTE TABLE ASSOCIATIONS
# ==========================================

resource "aws_route_table_association" "public" {
  count = local.enable_network ? 2 : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = local.enable_network ? 2 : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

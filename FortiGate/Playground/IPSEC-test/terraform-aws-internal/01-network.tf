##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

// AWS VPC 
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "subnet1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_fgt_external["a"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-fgt-external-a"
  }
}

resource "aws_subnet" "subnet2a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_fgt_internal["a"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-fgt-internal-a"
  }
}

resource "aws_subnet" "subnet3a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_protected["a"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-protected-a"
  }
}

resource "aws_subnet" "subnet1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_fgt_external["b"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-fgt-external-b"
  }
}

resource "aws_subnet" "subnet2b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_fgt_internal["b"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-fgt-internal-b"
  }
}

resource "aws_subnet" "subnet3b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_protected["b"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet-protected-b"
  }
}

// Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}

// Route Table
resource "aws_route_table" "subnet1art" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet-fgt-external-a-rt"
  }
}
resource "aws_route" "subnet1atointernet" {
  route_table_id         = aws_route_table.subnet1art.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id   = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "subnet1artassociate" {
  subnet_id      = aws_subnet.subnet1a.id
  route_table_id = aws_route_table.subnet1art.id
}

resource "aws_route_table" "subnet3art" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet-protected-a-rt"
  }
}
resource "aws_route" "subnet3aroutetob" {
  depends_on             = [aws_instance.fgtavm]
  route_table_id         = aws_route_table.subnet3art.id
  destination_cidr_block = var.subnet_protected["b"]
  network_interface_id   = aws_network_interface.fgtaifcint.id
}
resource "aws_route" "subnet3atointernet" {
  route_table_id         = aws_route_table.subnet3art.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id   = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "subnet3artassociate" {
  subnet_id      = aws_subnet.subnet3a.id
  route_table_id = aws_route_table.subnet3art.id
}

resource "aws_route_table" "subnet1brt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet-fgt-external-b-rt"
  }
}
resource "aws_route" "subnet1btointernet" {
  route_table_id         = aws_route_table.subnet1brt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id   = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "subnet1brtassociate" {
  subnet_id      = aws_subnet.subnet1b.id
  route_table_id = aws_route_table.subnet1brt.id
}

resource "aws_route_table" "subnet3brt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet-protected-b-rt"
  }
}
resource "aws_route" "subnet3broutetoa" {
  depends_on             = [aws_instance.fgtbvm]
  route_table_id         = aws_route_table.subnet3brt.id
  destination_cidr_block = var.subnet_protected["a"]
  network_interface_id   = aws_network_interface.fgtbifcint.id
}
resource "aws_route" "subnet3btointernet" {
  route_table_id         = aws_route_table.subnet3brt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id   = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "subnet3brtassociate" {
  subnet_id      = aws_subnet.subnet3b.id
  route_table_id = aws_route_table.subnet3brt.id
}

// Security Group

resource "aws_security_group" "public_allow" {
  name        = "${var.prefix}-public-allow"
  description = "Public Allow traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-public-allow"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "${var.prefix}-allow-all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-allow-all"
  }
}

##############################################################################################################

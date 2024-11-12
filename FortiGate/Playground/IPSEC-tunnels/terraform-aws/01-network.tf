##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for AWS
#
##############################################################################################################
#
# Deployment of the virtual network
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

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet["1"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet["2"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet["3"]
  availability_zone = local.az1
  tags = {
    Name = "${var.prefix}-subnet3"
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
resource "aws_route_table" "mgmtrt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-mgmt-rt"
  }
}

resource "aws_route_table" "subnet2rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet2-rt"
  }
}

resource "aws_route_table" "subnet3rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-subnet3-rt"
  }
}

resource "aws_route" "mgmtroute" {
  route_table_id         = aws_route_table.mgmtrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "subnet2routetounderlay" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.subnet2rt.id
  destination_cidr_block = "10.1.0.0/16"
  network_interface_id   = aws_network_interface.lnxnicint.id
}

resource "aws_route" "subnet2routetosubnet3" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.subnet2rt.id
  destination_cidr_block = var.subnet["3"]
  network_interface_id   = aws_network_interface.fgtnicext.id
}

resource "aws_route" "subnet3routetosubnet2" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.subnet3rt.id
  destination_cidr_block = var.subnet["2"]
  network_interface_id   = aws_network_interface.fgtnicint.id
}

resource "aws_route" "subnet3routetounderlay" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.subnet3rt.id
  destination_cidr_block = "10.1.0.0/16"
  network_interface_id   = aws_network_interface.fgtnicint.id
}

resource "aws_route" "subnet3routetooverlay" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.subnet3rt.id
  destination_cidr_block = "10.2.0.0/16"
  network_interface_id   = aws_network_interface.fgtnicint.id
}

resource "aws_route_table_association" "mgmtrtassociate" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.mgmtrt.id
}

resource "aws_route_table_association" "subnet2rtassociate" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.subnet2rt.id
}

resource "aws_route_table_association" "subnet3rtassociate" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.subnet3rt.id
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

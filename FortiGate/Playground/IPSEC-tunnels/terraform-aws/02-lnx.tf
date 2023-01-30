##############################################################################################################
#
# Linux VM
# Terraform deployment template for AWS
#
##############################################################################################################

##############################################################################################################
# Linux VM
##############################################################################################################

resource "aws_eip" "lnxpip" {
  depends_on        = [aws_instance.lnxvm]
  vpc               = true
  network_interface = aws_network_interface.lnxnicmgmt.id
  tags = {
    Name = "${var.PREFIX}-lnx-pip"
  }
}

resource "aws_network_interface" "lnxnicmgmt" {
  description = "${var.PREFIX}-lnx-mgmt"
  subnet_id   = aws_subnet.subnet1.id
  private_ips = [var.lnx_ipaddress["1"]]
  tags = {
    Name = "${var.PREFIX}-lnx-nic-mgmt"
  }
}

resource "aws_network_interface" "lnxnicint" {
  description = "${var.PREFIX}-lnx-internal"
  subnet_id   = aws_subnet.subnet2.id
  private_ips = [var.lnx_ipaddress["2"]]
  source_dest_check = false
  tags = {
    Name = "${var.PREFIX}-lnx-nic-int"
  }
}

resource "aws_network_interface_sg_attachment" "lnxnicmgmtsg" {
  depends_on           = [aws_network_interface.lnxnicmgmt]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.lnxnicmgmt.id
}

resource "aws_network_interface_sg_attachment" "lnxnicintsg" {
  depends_on           = [aws_network_interface.lnxnicint]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.lnxnicint.id
}

resource "aws_instance" "lnxvm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.lnx_ami.id
  instance_type     = var.lnx_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data = templatefile("${path.module}/../templates/customdata-lnx.tftpl", {})

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  network_interface {
    network_interface_id = aws_network_interface.lnxnicmgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.lnxnicint.id
    device_index         = 1
  }

  tags = {
    Name = "${var.PREFIX}-lnx-vm"
  }
}

##############################################################################################################
# Linux VM 2
##############################################################################################################

resource "aws_eip" "lnx2pip" {
  depends_on        = [aws_instance.lnxvm]
  vpc               = true
  network_interface = aws_network_interface.lnx2nicmgmt.id
  tags = {
    Name = "${var.PREFIX}-lnx2-pip"
  }
}

resource "aws_network_interface" "lnx2nicmgmt" {
  description = "${var.PREFIX}-lnx2-mgmt"
  subnet_id   = aws_subnet.subnet1.id
  private_ips = [var.lnx2_ipaddress["1"]]
  tags = {
    Name = "${var.PREFIX}-lnx2-nic-mgmt"
  }
}

resource "aws_network_interface" "lnx2nicint" {
  description = "${var.PREFIX}-lnx2-internal"
  subnet_id   = aws_subnet.subnet3.id
  private_ips = [var.lnx2_ipaddress["2"]]
  source_dest_check = false
  tags = {
    Name = "${var.PREFIX}-lnx2-nic-int"
  }
}

resource "aws_network_interface_sg_attachment" "lnx2nicmgmtsg" {
  depends_on           = [aws_network_interface.lnx2nicmgmt]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.lnx2nicmgmt.id
}

resource "aws_network_interface_sg_attachment" "lnx2nicintsg" {
  depends_on           = [aws_network_interface.lnx2nicint]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.lnx2nicint.id
}

resource "aws_instance" "lnx2vm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.lnx_ami.id
  instance_type     = var.lnx_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data = templatefile("${path.module}/../templates/customdata-lnx2.tftpl", {})

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  network_interface {
    network_interface_id = aws_network_interface.lnx2nicmgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.lnx2nicint.id
    device_index         = 1
  }

  tags = {
    Name = "${var.PREFIX}-lnx2-vm"
  }
}

data "aws_network_interface" "lnxnicmgmt" {
  id = aws_network_interface.lnxnicmgmt.id
}

data "aws_network_interface" "lnx2nicmgmt" {
  id = aws_network_interface.lnx2nicmgmt.id
}

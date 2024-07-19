##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

##############################################################################################################
# Linux VM
##############################################################################################################

resource "aws_eip" "lnxbpip" {
  count             = var.lnx_count
  depends_on        = [aws_instance.lnxbvm]
  vpc               = true
  network_interface = aws_network_interface.lnxbifc[count.index].id
  tags = {
    Name = "${local.fgt_b_vm_name}-pip-${count.index}"
  }
}

resource "aws_network_interface" "lnxbifc" {
  count       = var.lnx_count
  description = "${local.fgt_b_vm_name}-ifc-${count.index}"
  subnet_id   = aws_subnet.subnet3b.id
  tags = {
    Name = "${local.fgt_b_vm_name}-ifc-${count.index}"
  }
}

resource "aws_network_interface_sg_attachment" "lnxbifcsg" {
  count                = var.lnx_count
  depends_on           = [aws_network_interface.lnxbifc]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.lnxbifc[count.index].id
}

resource "aws_instance" "lnxbvm" {
  count = var.lnx_count
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.lnx_ami.id
  instance_type     = var.lnx_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data         = templatefile("${path.module}/../templates/customdata-lnx.tftpl", {})

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  network_interface {
    network_interface_id = aws_network_interface.lnxbifc[count.index].id
    device_index         = 0
  }

  tags = {
    Name = "${local.fgt_b_vm_name}-${count.index}"
  }
}

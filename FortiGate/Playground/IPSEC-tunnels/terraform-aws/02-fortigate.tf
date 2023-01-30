##############################################################################################################
#
# FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "aws_eip" "fgtpip" {
  depends_on        = [aws_instance.fgtvm]
  vpc               = true
  network_interface = aws_network_interface.fgtnicmgmt.id
  tags = {
    Name = "${var.PREFIX}-fgt-pip"
  }
}

resource "aws_network_interface" "fgtnicmgmt" {
  description = "${var.PREFIX}-fgt-mgmt"
  subnet_id   = aws_subnet.subnet1.id
  private_ips = [var.fgt_ipaddress["1"]]
  tags = {
    Name = "${var.PREFIX}-fgt-nic-mgmt"
  }
}

resource "aws_network_interface" "fgtnicext" {
  description = "${var.PREFIX}-fgt-external"
  subnet_id   = aws_subnet.subnet2.id
  private_ips = [var.fgt_ipaddress["2"]]
  source_dest_check = false
  tags = {
    Name = "${var.PREFIX}-fgt-nic-ext"
  }
}

resource "aws_network_interface" "fgtnicint" {
  description = "${var.PREFIX}-fgt-internal"
  subnet_id   = aws_subnet.subnet3.id
  private_ips = [var.fgt_ipaddress["3"]]
  source_dest_check = false
  tags = {
    Name = "${var.PREFIX}-fgt-nic-int"
  }
}

resource "aws_network_interface_sg_attachment" "fgtnicmgmtsg" {
  depends_on           = [aws_network_interface.fgtnicmgmt]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.fgtnicmgmt.id
}

resource "aws_network_interface_sg_attachment" "fgtnicextsg" {
  depends_on           = [aws_network_interface.fgtnicext]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtnicext.id
}

resource "aws_network_interface_sg_attachment" "fgtnicintsg" {
  depends_on           = [aws_network_interface.fgtnicint]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtnicint.id
}

resource "aws_instance" "fgtvm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.fgt_ami.id
  instance_type     = var.fgt_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data = templatefile("${path.module}/../templates/customdata-fgt.tftpl", {
    fgt_csp             = "aws"
    fgt_vm_name         = "${var.PREFIX}-fgt-vm"
    fgt_license_file    = var.FGT_BYOL_LICENSE_FILE
    fgt_license_flexvm  = var.FGT_BYOL_FLEXVM_LICENSE
    fgt_username        = var.USERNAME
    fgt_password        = var.PASSWORD
    fgt_ssh_public_key  = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_mgmt_ipaddr     = var.fgt_ipaddress["1"]
    fgt_mgmt_mask       = var.subnetmask["1"]
    fgt_mgmt_gw         = var.gateway_ipaddress["1"]
    fgt_external_ipaddr = var.fgt_ipaddress["2"]
    fgt_external_mask   = var.subnetmask["2"]
    fgt_external_gw     = var.gateway_ipaddress["2"]
    fgt_internal_ipaddr = var.fgt_ipaddress["3"]
    fgt_internal_mask   = var.subnetmask["3"]
    fgt_internal_gw     = var.gateway_ipaddress["3"]
    virtual_network     = var.vpc
  })

  root_block_device {
    volume_type = "standard"
    volume_size = "2"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "30"
    volume_type = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.fgtnicmgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgtnicext.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.fgtnicint.id
    device_index         = 2
  }

  tags = {
    Name = "${var.PREFIX}-fgt-vm"
  }
}

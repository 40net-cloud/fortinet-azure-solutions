##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "aws_eip" "fgtapip" {
  depends_on        = [aws_instance.fgtavm]
  vpc               = true
  network_interface = aws_network_interface.fgtaifcext.id
  tags = {
    Name = "${local.fgt_a_prefix}-fgt-pip"
  }
}

resource "aws_network_interface" "fgtaifcext" {
  description = "${local.fgt_a_prefix}-ifc-ext"
  subnet_id   = aws_subnet.subnet1a.id
  private_ips = [local.fgt_a_private_ip_address_ext]
  source_dest_check = false
  tags = {
    Name = "${local.fgt_a_prefix}-ifc-ext"
  }
}

resource "aws_network_interface" "fgtaifcint" {
  description = "${local.fgt_a_prefix}-ifc-int"
  subnet_id   = aws_subnet.subnet2a.id
  private_ips = [local.fgt_a_private_ip_address_int]
  source_dest_check = false
  tags = {
    Name = "${local.fgt_a_prefix}-ifc-int"
  }
}

resource "aws_network_interface_sg_attachment" "fgtaifcextsg" {
  depends_on           = [aws_network_interface.fgtaifcext]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtaifcext.id
}

resource "aws_network_interface_sg_attachment" "fgtaifcintsg" {
  depends_on           = [aws_network_interface.fgtaifcint]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtaifcint.id
}

resource "aws_instance" "fgtavm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.fgt_ami.id
  instance_type     = var.fgt_a_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data = templatefile("${path.module}/../templates/customdata-fgt.tftpl", {
    fgt_vm_name              = "${local.fgt_a_vm_name}"
    fgt_license_file         = var.FGT_BYOL_LICENSE_FILE_A
    fgt_license_fortiflex    = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_A
    fgt_username             = var.username
    fgt_password             = var.password
    fgt_cpumask              = var.fgt_a_cpumask
    fgt_ssh_public_key       = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_network     = var.subnet_fgt_external["a"]
    fgt_external_ipaddress   = local.fgt_a_private_ip_address_ext
    fgt_external_ipcount     = local.fgt_external_ipcount
    fgt_external_mask        = "${cidrnetmask(var.subnet_fgt_external["a"])}"
    fgt_external_gateway     = "${cidrhost(var.subnet_fgt_external["a"], 1)}"
    fgt_internal_ipaddress   = local.fgt_a_private_ip_address_int
    fgt_internal_mask        = "${cidrnetmask(var.subnet_fgt_internal["a"])}"
    fgt_internal_gateway     = "${cidrhost(var.subnet_fgt_internal["a"], 1)}"
    fgt_protected_network    = var.subnet_protected["a"]
    vnet_network             = var.vpc
    remote_protected_network = var.subnet_protected["b"]
    remote_public_ip         = local.fgt_b_private_ip_address_ext
    ipsec_psk                = random_string.ipsec_psk.result
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
    network_interface_id = aws_network_interface.fgtaifcext.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgtaifcint.id
    device_index         = 1
  }

  tags = {
    Name = local.fgt_a_vm_name
  }
}

data "aws_network_interface" "fgtaifcext" {
  id = aws_network_interface.fgtaifcext.id
}

data "aws_network_interface" "fgtaifcint" {
  id = aws_network_interface.fgtaifcint.id
}

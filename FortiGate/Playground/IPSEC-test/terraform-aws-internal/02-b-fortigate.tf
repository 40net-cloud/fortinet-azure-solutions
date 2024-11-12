##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "aws_eip" "fgtbpip" {
  depends_on        = [aws_instance.fgtbvm]
  vpc               = true
  network_interface = aws_network_interface.fgtbifcext.id
  tags = {
    Name = "${local.fgt_b_prefix}-fgt-pip"
  }
}

resource "aws_network_interface" "fgtbifcext" {
  description = "${local.fgt_b_prefix}-ifc-ext"
  subnet_id   = aws_subnet.subnet1b.id
  private_ips = [local.fgt_b_private_ip_address_ext]
  source_dest_check = false
  tags = {
    Name = "${local.fgt_b_prefix}-ifc-ext"
  }
}

resource "aws_network_interface" "fgtbifcint" {
  description = "${local.fgt_b_prefix}-ifc-int"
  subnet_id   = aws_subnet.subnet2b.id
  private_ips = [local.fgt_b_private_ip_address_int]
  source_dest_check = false
  tags = {
    Name = "${local.fgt_b_prefix}-ifc-int"
  }
}

resource "aws_network_interface_sg_attachment" "fgtbifcextsg" {
  depends_on           = [aws_network_interface.fgtbifcext]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtbifcext.id
}

resource "aws_network_interface_sg_attachment" "fgtbifcintsg" {
  depends_on           = [aws_network_interface.fgtbifcint]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgtbifcint.id
}

resource "aws_instance" "fgtbvm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.fgt_ami.id
  instance_type     = var.fgt_b_vmsize
  availability_zone = local.az1
  key_name          = var.KEY_PAIR
  user_data = templatefile("${path.module}/../templates/customdata-fgt.tftpl", {
    fgt_vm_name              = "${local.fgt_b_vm_name}"
    fgt_license_file         = var.FGT_BYOL_LICENSE_FILE_B
    fgt_license_fortiflex    = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_B
    fgt_username             = var.username
    fgt_password             = var.password
    fgt_cpumask              = var.fgt_b_cpumask
    fgt_ssh_public_key       = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_network     = var.subnet_fgt_external["b"]
    fgt_external_ipaddress   = local.fgt_b_private_ip_address_ext
    fgt_external_ipcount     = local.fgt_external_ipcount
    fgt_external_mask        = "${cidrnetmask(var.subnet_fgt_external["b"])}"
    fgt_external_gateway     = "${cidrhost(var.subnet_fgt_external["b"], 1)}"
    fgt_internal_ipaddress   = local.fgt_b_private_ip_address_int
    fgt_internal_mask        = "${cidrnetmask(var.subnet_fgt_internal["b"])}"
    fgt_internal_gateway     = "${cidrhost(var.subnet_fgt_internal["b"], 1)}"
    fgt_protected_network    = var.subnet_protected["b"]
    vnet_network             = var.vpc
    remote_protected_network = var.subnet_protected["a"]
    remote_public_ip         = local.fgt_a_private_ip_address_ext
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
    network_interface_id = aws_network_interface.fgtbifcext.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgtbifcint.id
    device_index         = 1
  }

  tags = {
    Name = local.fgt_b_vm_name
  }
}

data "aws_network_interface" "fgtbifcext" {
  id = aws_network_interface.fgtbifcext.id
}

data "aws_network_interface" "fgtbifcint" {
  id = aws_network_interface.fgtbifcint.id
}

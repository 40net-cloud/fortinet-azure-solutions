###############################################################################################################
#
# Multi Cloud Deployment
# Cloud Security Services Hub
#
##############################################################################################################
#
# FortiGate Active Passive setup with Google Load Balaner (External and Internal)
#
##############################################################################################################

##############################################################################################################
# Load Balancer configuration using HA Groups
##############################################################################################################

resource "google_compute_instance_group" "hagroup0" {
  name = "${var.PREFIX}-hagroup-${random_string.random_name_post.result}"

  instances = [
    google_compute_instance.fgt-a.self_link
  ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = var.GCP_ZONE1
}

resource "google_compute_instance_group" "hagroup1" {
  name = "${var.PREFIX}-hagroup-${random_string.random_name_post.result}"

  instances = [
    google_compute_instance.fgt-b.self_link
  ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = var.GCP_ZONE2
}

resource "google_compute_health_check" "tcp-health-check" {
  name = "${var.PREFIX}-hagroup-probe-${random_string.random_name_post.result}"

  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "8008"
  }
}

##############################################################################################################
# Internal LoadBalancer
##############################################################################################################
resource "google_compute_forwarding_rule" "ilb-fwdrule" {
  name   = "${var.PREFIX}-ilb-fwd-rule-${random_string.random_name_post.result}"
  region = var.GCP_REGION

  load_balancing_scheme = "INTERNAL"
  ip_address            = var.gcp_lb_internal_ipaddress
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.ilb-backend.id
  all_ports             = true
  network               = google_compute_network.vpc_network2.name
  subnetwork            = google_compute_subnetwork.private_subnet.name
}

resource "google_compute_region_backend_service" "ilb-backend" {
  name          = "${var.PREFIX}-ilb-backend-${random_string.random_name_post.result}"
  provider      = google-beta
  region        = var.GCP_REGION
  health_checks = [google_compute_health_check.tcp-health-check.self_link]
  protocol      = "TCP"
  network       = google_compute_network.vpc_network2.name
  backend {
    group = google_compute_instance_group.hagroup0.self_link
  }
  backend {
    group = google_compute_instance_group.hagroup1.self_link
  }
}

##############################################################################################################
# FortiGate Log Disk
##############################################################################################################
# Create log disk for primary
resource "google_compute_disk" "logdisk" {
  name = "${var.PREFIX}-log-disk-${random_string.random_name_post.result}"
  size = 30
  type = "pd-standard"
  zone = var.GCP_ZONE1
}

# Create log disk for secondary
resource "google_compute_disk" "logdisk2" {
  name = "${var.PREFIX}-log-disk2-${random_string.random_name_post.result}"
  size = 30
  type = "pd-standard"
  zone = var.GCP_ZONE2
}

##############################################################################################################
# FortiGate Instances
##############################################################################################################
# Create static cluster ip
resource "google_compute_address" "static" {
  name = "${var.PREFIX}-cluster-ip-${random_string.random_name_post.result}"
}

# Create static primary instance management ip
resource "google_compute_address" "static2" {
  name = "${var.PREFIX}-primarymgmt-ip-${random_string.random_name_post.result}"
}

# Create static secondary instance management ip
resource "google_compute_address" "static3" {
  name = "${var.PREFIX}-secondarymgmt-ip-${random_string.random_name_post.result}"
}

# Create FGTVM compute primary instance
resource "google_compute_instance" "fgt-a" {
  name           = "${var.PREFIX}-fgt-a-${random_string.random_name_post.result}"
  machine_type   = var.machine
  zone           = var.GCP_ZONE1
  can_ip_forward = "true"

  tags = ["allow-fgt", "allow-internal", "allow-sync", "allow-mgmt"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  attached_disk {
    source = google_compute_disk.logdisk.name
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    network_ip = var.gcp_fgt_ipaddress_a["1"]
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
    network_ip = var.gcp_fgt_ipaddress_a["2"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ha_subnet.name
    network_ip = var.gcp_fgt_ipaddress_a["3"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt_subnet.name
    network_ip = var.gcp_fgt_ipaddress_a["4"]
    access_config {
      nat_ip = google_compute_address.static2.address
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/gcp_userdata.tpl", {
      fgt_vm_name         = "${var.PREFIX}-fgt-a-${random_string.random_name_post.result}",
      fgt_external_ipaddr = var.gcp_fgt_ipaddress_a["1"],
      fgt_external_mask   = var.gcp_subnetmask["1"],
      fgt_external_gw     = var.gcp_gateway_ipaddress["1"],
      fgt_internal_ipaddr = var.gcp_fgt_ipaddress_a["2"],
      fgt_internal_mask   = var.gcp_subnetmask["2"],
      fgt_internal_gw     = var.gcp_gateway_ipaddress["2"],
      fgt_hasync_ipaddr   = var.gcp_fgt_ipaddress_a["3"],
      fgt_hasync_mask     = var.gcp_subnetmask["3"],
      fgt_hasync_gw       = var.gcp_gateway_ipaddress["3"],
      fgt_mgmt_ipaddr     = var.gcp_fgt_ipaddress_a["4"],
      fgt_mgmt_mask       = var.gcp_subnetmask["4"],
      fgt_mgmt_gw         = var.gcp_gateway_ipaddress["4"],
      fgt_ha_peerip       = var.gcp_fgt_ipaddress_b["3"],
      fgt_ha_priority     = "255",
      vpc_network         = var.gcp_vpc,
      fgt_password        = var.PASSWORD,
      client_ip           = chomp(data.http.client_ip.body)
    })
    license = fileexists("${path.module}/${var.GCP_FGT_BYOL_LICENSE_FILE_A}") ? file(var.GCP_FGT_BYOL_LICENSE_FILE_A) : null
  }
  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro", "cloud-platform"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Create FGTVM compute secondary instance
resource "google_compute_instance" "fgt-b" {
  name           = "${var.PREFIX}-fgt-b-${random_string.random_name_post.result}"
  machine_type   = var.machine
  zone           = var.GCP_ZONE2
  can_ip_forward = "true"

  tags = ["allow-fgt", "allow-internal", "allow-sync", "allow-mgmt"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  attached_disk {
    source = google_compute_disk.logdisk2.name
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    network_ip = var.gcp_fgt_ipaddress_b["1"]
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
    network_ip = var.gcp_fgt_ipaddress_b["2"]
  }
  network_interface {
    subnetwork = google_compute_subnetwork.ha_subnet.name
    network_ip = var.gcp_fgt_ipaddress_b["3"]
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt_subnet.name
    network_ip = var.gcp_fgt_ipaddress_b["4"]
    access_config {
      nat_ip = google_compute_address.static3.address
    }
  }
  metadata = {
    user-data = templatefile("${path.module}/gcp_userdata.tpl", {
      fgt_vm_name         = "${var.PREFIX}-fgt-b-${random_string.random_name_post.result}",
      fgt_external_ipaddr = var.gcp_fgt_ipaddress_b["1"],
      fgt_external_mask   = var.gcp_subnetmask["1"],
      fgt_external_gw     = var.gcp_gateway_ipaddress["1"],
      fgt_internal_ipaddr = var.gcp_fgt_ipaddress_b["2"],
      fgt_internal_mask   = var.gcp_subnetmask["2"],
      fgt_internal_gw     = var.gcp_gateway_ipaddress["2"],
      fgt_hasync_ipaddr   = var.gcp_fgt_ipaddress_b["3"],
      fgt_hasync_mask     = var.gcp_subnetmask["3"],
      fgt_hasync_gw       = var.gcp_gateway_ipaddress["3"],
      fgt_mgmt_ipaddr     = var.gcp_fgt_ipaddress_b["4"],
      fgt_mgmt_mask       = var.gcp_subnetmask["4"],
      fgt_mgmt_gw         = var.gcp_gateway_ipaddress["4"],
      fgt_ha_peerip       = var.gcp_fgt_ipaddress_a["3"],
      fgt_ha_priority     = "100",
      vpc_network         = var.gcp_vpc,
      fgt_password        = var.PASSWORD,
      client_ip           = chomp(data.http.client_ip.body)
    })
    license = fileexists("${path.module}/${var.GCP_FGT_BYOL_LICENSE_FILE_B}") ? file(var.GCP_FGT_BYOL_LICENSE_FILE_B) : null
  }
  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro", "cloud-platform"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Output
output "FortiGate-HA-Cluster-IP" {
  value = google_compute_instance.fgt-a.network_interface.0.access_config.*.nat_ip
}
output "FortiGate-HA-Master-MGMT-IP" {
  value = google_compute_instance.fgt-a.network_interface.3.access_config.0.nat_ip
}
output "FortiGate-HA-Slave-MGMT-IP" {
  value = google_compute_instance.fgt-b.network_interface.3.access_config.0.nat_ip
}

output "FortiGate-Username" {
  value = "admin"
}
output "FortiGate-Password" {
  value = google_compute_instance.fgt-a.instance_id
}

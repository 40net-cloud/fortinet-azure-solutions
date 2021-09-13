###############################################################################################################
#
# Multi Cloud Deployment
#
##############################################################################################################
#
# Deployment of the Google Cloud HUB networks
#
##############################################################################################################
### VPC ###
resource "google_compute_network" "vpc_network" {
  name                    = "${var.PREFIX}-vpc-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

resource "google_compute_network" "vpc_network2" {
  name                            = "${var.PREFIX}-vpc2-${random_string.random_name_post.result}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "vpc_network3" {
  name                    = "${var.PREFIX}-vpc3-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

resource "google_compute_network" "vpc_network4" {
  name                    = "${var.PREFIX}-vpc4-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

### Public Subnet ###
resource "google_compute_subnetwork" "public_subnet" {
  name                     = "${var.PREFIX}-public-subnet-${random_string.random_name_post.result}"
  region                   = var.GCP_REGION
  network                  = google_compute_network.vpc_network.name
  ip_cidr_range            = var.gcp_subnet["1"]
  private_ip_google_access = true
}
### Private Subnet ###
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.PREFIX}-private-subnet-${random_string.random_name_post.result}"
  region        = var.GCP_REGION
  network       = google_compute_network.vpc_network2.name
  ip_cidr_range = var.gcp_subnet["2"]
}
### HA Sync Subnet ###
resource "google_compute_subnetwork" "ha_subnet" {
  name          = "${var.PREFIX}-sync-subnet-${random_string.random_name_post.result}"
  region        = var.GCP_REGION
  network       = google_compute_network.vpc_network3.name
  ip_cidr_range = var.gcp_subnet["3"]
}
### HA MGMT Subnet ###
resource "google_compute_subnetwork" "mgmt_subnet" {
  name          = "${var.PREFIX}-mgmt-subnet-${random_string.random_name_post.result}"
  region        = var.GCP_REGION
  network       = google_compute_network.vpc_network4.name
  ip_cidr_range = var.gcp_subnet["4"]
}

resource "google_compute_route" "internal" {
  name        = "${var.PREFIX}-internal-route-${random_string.random_name_post.result}"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.vpc_network2.name
  next_hop_ip = var.gcp_lb_internal_ipaddress
  priority    = 100
  depends_on  = [google_compute_subnetwork.private_subnet]
}

# Firewall Rule External
resource "google_compute_firewall" "allow-fgt" {
  name    = "${var.PREFIX}-allow-fgt-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8022"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  #  target_tags   = ["allow-fgt"]
}

# Firewall Rule Internal
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.PREFIX}-allow-internal-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network2.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  #  target_tags   = ["allow-internal"]
}

# Firewall Rule HA SYNC
resource "google_compute_firewall" "allow-sync" {
  name    = "${var.PREFIX}-allow-sync-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network3.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  #  target_tags   = ["allow-sync"]
}

# Firewall Rule HA MGMT
resource "google_compute_firewall" "allow-mgmt" {
  name    = "${var.PREFIX}-allow-mgmt-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network4.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  #  target_tags   = ["allow-mgmt"]
}

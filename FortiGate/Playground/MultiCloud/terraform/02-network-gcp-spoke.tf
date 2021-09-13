###############################################################################################################
#
# Multi Cloud Deployment
# Cloud Security Services Hub
#
##############################################################################################################
# FortiGate
# Spoke and VPC Peering configuration
# Terraform deployment template for Google Cloud
#
##############################################################################################################
# Variables
##############################################################################################################

##############################################################################################################
# Spoke VPC and subnet configuration
##############################################################################################################

resource "google_compute_network" "vpc_network_spoke1" {
  name                            = "${var.PREFIX}-vpc-spoke1-${random_string.random_name_post.result}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "vpc_network_spoke2" {
  name                            = "${var.PREFIX}-vpc-spoke2-${random_string.random_name_post.result}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "spoke1_subnet" {
  name                     = "${var.PREFIX}-spoke1-subnet-${random_string.random_name_post.result}"
  provider                 = google-beta
  region                   = var.GCP_REGION
  network                  = google_compute_network.vpc_network_spoke1.name
  ip_cidr_range            = var.spoke1_subnet
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "spoke2_subnet" {
  name                     = "${var.PREFIX}-spoke2-subnet-${random_string.random_name_post.result}"
  provider                 = google-beta
  region                   = var.GCP_REGION
  network                  = google_compute_network.vpc_network_spoke2.name
  ip_cidr_range            = var.spoke2_subnet
  private_ip_google_access = true
}

##############################################################################################################
# VPC Peering
##############################################################################################################

### VPC Peering connecting HUB and Spoke 1 ###
resource "google_compute_network_peering" "hub2spoke1" {
  name                 = "${var.PREFIX}-hub2spoke1-${random_string.random_name_post.result}"
  provider             = google-beta
  network              = google_compute_network.vpc_network2.self_link
  peer_network         = google_compute_network.vpc_network_spoke1.self_link
  export_custom_routes = true
  depends_on           = [google_compute_route.internal]
}

resource "google_compute_network_peering" "spoke12hub" {
  name                 = "${var.PREFIX}-spoke12hub-${random_string.random_name_post.result}"
  provider             = google-beta
  network              = google_compute_network.vpc_network_spoke1.self_link
  peer_network         = google_compute_network.vpc_network2.self_link
  import_custom_routes = true
  depends_on           = [google_compute_route.internal, google_compute_network_peering.hub2spoke1]
}

### VPC Peering connecting HUB and Spoke 2 ###
resource "google_compute_network_peering" "hub2spoke2" {
  name                 = "${var.PREFIX}-hub2spoke2-${random_string.random_name_post.result}"
  provider             = google-beta
  network              = google_compute_network.vpc_network2.self_link
  peer_network         = google_compute_network.vpc_network_spoke2.self_link
  export_custom_routes = true
  depends_on           = [google_compute_route.internal, google_compute_network_peering.spoke12hub]
}

resource "google_compute_network_peering" "spoke22hub" {
  name                 = "${var.PREFIX}-spoke22hub-${random_string.random_name_post.result}"
  provider             = google-beta
  network              = google_compute_network.vpc_network_spoke2.self_link
  peer_network         = google_compute_network.vpc_network2.self_link
  import_custom_routes = true
  depends_on           = [google_compute_route.internal, google_compute_network_peering.hub2spoke2]
}

##############################################################################################################
# Google Cloud Firewall
##############################################################################################################
# Firewall Rule Spoke 1
resource "google_compute_firewall" "allow-spoke1" {
  name    = "${var.PREFIX}-allow-spoke1-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network_spoke1.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# Firewall Rule Spoke 2
resource "google_compute_firewall" "allow-spoke2" {
  name    = "${var.PREFIX}-allow-spoke2-${random_string.random_name_post.result}"
  network = google_compute_network.vpc_network_spoke2.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}
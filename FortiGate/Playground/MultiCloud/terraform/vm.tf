##############################################################################################################
#
# FortiGate
# Deploy a test VM
#
##############################################################################################################
# VM
##############################################################################################################

// A single Compute Engine instance
resource "google_compute_instance" "vm" {
  name         = "${var.PREFIX}-vm-${random_string.random_name_post.result}"
  machine_type = "f1-micro"
  zone         = var.GCP_ZONE1

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  // Make sure flask is installed on all new instances for later steps
  metadata_startup_script = "sudo apt update; sudo apt upgrade; sudo apt install nginx"

  network_interface {
    subnetwork = google_compute_subnetwork.spoke1_subnet.name
    network_ip = "172.16.149.2"
  }

  metadata = {
    ssh-keys = "jvhoof:${file("~/.ssh/id_ed2519.pub")}"
  }
}

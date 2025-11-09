terraform {
  backend "gcs" {
    bucket = "quickhire-state"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "${var.environment}-${var.project_name}-network"
}

resource "google_compute_firewall" "firewall" {
  name    = "${var.environment}-${var.project_name}-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  # Allow traffic from anywhere (public)
  source_ranges = ["0.0.0.0/0"]

  target_tags = ["server"]
}

resource "google_compute_instance" "vm" {
  name                      = "${var.environment}-${var.project_name}-vm"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  tags = ["server"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates
    sudo snap install docker
	sudo groupadd docker
	sudo usermod -aG docker $USER
	sudo chmod 666 /var/run/docker.sock

    echo "[startup] Done!"
  EOT

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {} # Enables external IP
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

terraform {
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
    ports    = ["80"]
  }

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
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y docker.io google-cloud-sdk
    systemctl enable docker
    systemctl start docker

    # Authenticate Docker to Artifact Registry
    gcloud auth configure-docker us-central1-docker.pkg.dev -q

    # Pull and run your container
    docker pull us-central1-docker.pkg.dev/${var.project_id}/echo-repo/echo:latest
    docker run -d --restart always -p 80:8080 \
      us-central1-docker.pkg.dev/${var.project_id}/echo-repo/echo:latest
  EOT

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {} # Enables external IP
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

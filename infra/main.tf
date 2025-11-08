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
    ports    = ["80", "22"]
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
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    echo "[startup] Updating system and installing Docker + GCloud SDK..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Add the Google Cloud SDK repo
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
      | tee /etc/apt/sources.list.d/google-cloud-sdk.list

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

    apt-get update -y
    apt-get install -y google-cloud-sdk

	snap install docker
	sleep 3
	sudo chmod 666 /var/run/docker.sock
	-sudo groupadd docker
	sudo usermod -aG docker $(USER)

    echo "[startup] Authenticating Docker to Artifact Registry..."
    gcloud auth configure-docker us-central1-docker.pkg.dev -q || true

    echo "[startup] Pulling and running container..."
    docker pull us-central1-docker.pkg.dev/${var.project_id}/echo-repo/echo:latest || exit 1

    # Stop previous container if exists
    docker ps -q --filter "name=echo" | xargs -r docker stop || true
    docker ps -aq --filter "name=echo" | xargs -r docker rm || true

    docker run -d --name echo --restart always -p 80:8080 \
      us-central1-docker.pkg.dev/${var.project_id}/echo-repo/echo:latest

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

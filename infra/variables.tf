variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project or application. Used as a base for naming all resources."
  type        = string
  default     = "demo"
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "credential_file" {
  description = "Path to your GCP service account JSON key"
  type        = string
}

variable "region" {
  description = "Region for the VM"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone within the region"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "f1-micro"
}

variable "image" {
  description = "The image from which to initialize the VM"
  type        = string
  default     = "cos-cloud/cos-stable"
}

# "ubuntu-os-cloud/ubuntu-2204-lts"
# "debian-cloud/debian-12"
# "cos-cloud/cos-stable"

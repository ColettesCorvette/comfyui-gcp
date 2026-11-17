# =============================================================================
# ComfyUI on GCP - Terraform Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# =============================================================================
# ENABLE REQUIRED APIS
# =============================================================================

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# =============================================================================
# COMPUTE INSTANCE
# =============================================================================

resource "google_compute_instance" "comfy_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  # Tag for firewall rules
  tags = ["comfyui"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  attached_disk {
    source      = google_compute_disk.comfy_data.id
    device_name = var.data_disk_name
  }

  network_interface {
    network = var.network
    # Ephemeral public IP, used only for outbound traffic (apt, Docker Hub).
    # No inbound port is open to the internet, see firewall.tf.
    access_config {}
  }

  # Spot instance for cost savings
  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  # Read by scripts/startup.sh from the metadata server
  metadata = {
    docker_compose_content = file("${path.module}/docker-compose.yml")
    data_disk_device_name  = var.data_disk_name
  }

  # Idempotent startup script
  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  labels = {
    purpose = "comfyui"
    managed = "terraform"
  }

  depends_on = [
    google_project_service.compute,
    google_compute_disk.comfy_data
  ]
}

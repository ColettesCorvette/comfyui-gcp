# =============================================================================
# PERSISTENT DATA DISK
# =============================================================================

resource "google_compute_disk" "comfy_data" {
  name = var.data_disk_name
  type = var.data_disk_type
  size = var.data_disk_size
  zone = var.zone

  description = "Persistent storage for ComfyUI models, outputs, and custom nodes"

  labels = {
    purpose = "comfyui-data"
    managed = "terraform"
  }

  # CRITICAL: Prevent accidental deletion of data
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.compute]
}

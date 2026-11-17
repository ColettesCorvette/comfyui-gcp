# =============================================================================
# PROJECT VARIABLES
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west4-c"
}

# =============================================================================
# COMPUTE VARIABLES
# =============================================================================

variable "machine_type" {
  description = "Machine type for the VM (must have GPU for ComfyUI)"
  type        = string
  default     = "g2-standard-8"
}

variable "vm_name" {
  description = "Name of the compute instance"
  type        = string
  default     = "comfy-waifu-spot"
}

variable "boot_disk_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 100
}

variable "boot_disk_type" {
  description = "Type of the boot disk"
  type        = string
  default     = "pd-balanced"
}

variable "boot_disk_image" {
  description = "Image for the boot disk (Deep Learning VM with CUDA)"
  type        = string
  default     = "projects/deeplearning-platform-release/global/images/family/common-cu128-ubuntu-2204-nvidia-570"
}

# =============================================================================
# STORAGE VARIABLES
# =============================================================================

variable "data_disk_name" {
  description = "Name of the persistent data disk"
  type        = string
  default     = "comfy-data-persist"
}

variable "data_disk_size" {
  description = "Size of the persistent data disk in GB"
  type        = number
  default     = 100
}

variable "data_disk_type" {
  description = "Type of the persistent data disk"
  type        = string
  default     = "pd-balanced"
}

# =============================================================================
# NETWORK VARIABLES
# =============================================================================

variable "network" {
  description = "VPC Network to use"
  type        = string
  default     = "default"
}

variable "comfyui_port" {
  description = "Port for ComfyUI web interface"
  type        = number
  default     = 8188
}

# =============================================================================
# IAP (IDENTITY-AWARE PROXY) VARIABLES
# =============================================================================

variable "iap_tunnel_users" {
  description = "List of users/service accounts allowed to use IAP tunnels. Format: 'user:email@example.com' or 'serviceAccount:sa@project.iam.gserviceaccount.com'"
  type        = list(string)
  default     = []
}

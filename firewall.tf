# =============================================================================
# FIREWALL RULES - IAP (Identity-Aware Proxy) SECURED
# =============================================================================
# 
# This configuration uses Google IAP for secure access instead of public IPs.
# Access requires: gcloud compute start-iap-tunnel <vm> <port>
#
# =============================================================================

# -----------------------------------------------------------------------------
# IAP TCP Forwarding - Allows Google's IAP service to connect to the VM
# -----------------------------------------------------------------------------
resource "google_compute_firewall" "iap_tunnel" {
  name        = "allow-iap-tunnel"
  network     = var.network
  description = "Allow IAP TCP forwarding to ComfyUI instance"

  allow {
    protocol = "tcp"
    ports    = [tostring(var.comfyui_port), "22"]
  }

  # Google's IAP IP range - required for IAP tunneling
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["comfyui"]

  depends_on = [google_project_service.compute]
}

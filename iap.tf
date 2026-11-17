# =============================================================================
# IAP (Identity-Aware Proxy) CONFIGURATION
# =============================================================================

# Enable IAP API
resource "google_project_service" "iap" {
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# IAM binding for IAP tunnel access
# -----------------------------------------------------------------------------
# This grants the specified users/service accounts permission to use IAP tunnels
#
# To add users, update the variable and run terraform apply:
#   iap_tunnel_users = ["user:your-email@gmail.com"]
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "iap_tunnel_users" {
  for_each = toset(var.iap_tunnel_users)

  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = each.value
}

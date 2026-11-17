# =============================================================================
# TERRAFORM BACKEND CONFIGURATION
# =============================================================================
# 
# Uncomment the block below to use GCS as a remote backend for state storage.
# This is recommended for production use to:
# - Enable team collaboration
# - Prevent state file loss
# - Enable state locking
#
# Prerequisites:
# 1. Create a GCS bucket:
#    gsutil mb -l europe-west4 gs://YOUR_BUCKET_NAME
# 2. Enable versioning (recommended):
#    gsutil versioning set on gs://YOUR_BUCKET_NAME
# 3. Update the bucket name below
# 4. Run: terraform init -migrate-state
#
# =============================================================================

# terraform {
#   backend "gcs" {
#     bucket = "YOUR_TERRAFORM_STATE_BUCKET"
#     prefix = "comfyui/state"
#   }
# }

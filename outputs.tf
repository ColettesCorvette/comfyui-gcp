# =============================================================================
# OUTPUTS
# =============================================================================

output "instance_ip" {
  description = "Public IP address of the ComfyUI instance (for reference only - use IAP tunnel)"
  value       = google_compute_instance.comfy_vm.network_interface.0.access_config.0.nat_ip
}

output "iap_tunnel_command" {
  description = "Command to start IAP tunnel for ComfyUI access"
  value       = "gcloud compute start-iap-tunnel ${var.vm_name} ${var.comfyui_port} --local-host-port=localhost:${var.comfyui_port} --zone=${var.zone} --project=${var.project_id}"
}

output "comfyui_url" {
  description = "URL to access ComfyUI (after starting IAP tunnel)"
  value       = "http://localhost:${var.comfyui_port}"
}

output "ssh_command" {
  description = "Command to SSH into the instance via IAP"
  value       = "gcloud compute ssh ${var.vm_name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "disk_id" {
  description = "ID of the persistent data disk"
  value       = google_compute_disk.comfy_data.id
}

output "vm_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.comfy_vm.name
}

output "destroy_vm_command" {
  description = "Command to destroy only the VM (keeps disk)"
  value       = "terraform destroy -target=google_compute_instance.comfy_vm"
}

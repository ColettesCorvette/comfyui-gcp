# ComfyUI on GCP

Terraform configuration that runs [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on a Google Cloud GPU Spot VM. The web UI is never exposed to the internet: it is reached through an Identity-Aware Proxy (IAP) TCP tunnel. Models, outputs and custom nodes live on a separate persistent disk, so the VM can be destroyed between sessions to stop GPU billing.

## Architecture

| Component | Choice |
|-----------|--------|
| Compute | `g2-standard-8` (1x NVIDIA L4), Spot provisioning, stopped on preemption |
| OS | Deep Learning VM image (Ubuntu 22.04, CUDA 12.8, NVIDIA driver 570) |
| Storage | 100 GB `pd-balanced` data disk, independent from the VM and protected by `prevent_destroy` |
| Access | IAP TCP forwarding on ports 8188 and 22, granted per user through IAM |
| Application | ComfyUI in Docker with GPU passthrough (NVIDIA Container Toolkit) |

```
Your machine ── gcloud start-iap-tunnel ──> IAP (35.235.240.0/20) ──> VM :8188 ──> ComfyUI container
                                                                       │
                                                                       └── /mnt/comfy-data (persistent disk)
```

The VM keeps an ephemeral public IP for outbound traffic only (apt, Docker Hub, model downloads). The firewall accepts inbound connections from Google's IAP range exclusively.

### How the VM is provisioned

`scripts/startup.sh` runs on every boot and is idempotent:

1. Mounts the persistent disk (formats it only if it has no filesystem).
2. Checks the NVIDIA driver.
3. Installs Docker and the NVIDIA Container Toolkit if they are missing.
4. Fetches `docker-compose.yml` from the instance metadata (Terraform puts it there) and runs `docker compose up -d`.

Since the compose file is delivered through metadata, a change to `docker-compose.yml` takes effect at the next boot of the VM.

## Repository layout

```
main.tf                   Provider, Compute API, VM
disk.tf                   Persistent data disk
firewall.tf               IAP ingress rule
iap.tf                    IAP API and IAM bindings for tunnel users
variables.tf              Inputs and their defaults
outputs.tf                Tunnel, SSH and destroy commands
backend.tf                Optional GCS remote state (commented out)
docker-compose.yml        ComfyUI container definition
scripts/startup.sh        VM startup script
terraform.tfvars.example  Example inputs
```

## Prerequisites

- A GCP project with billing enabled and GPU quota for L4 in the chosen region
- [`gcloud`](https://cloud.google.com/sdk/docs/install), authenticated (`gcloud auth application-default login`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0

## Usage

### 1. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

```hcl
project_id = "your-gcp-project-id"

iap_tunnel_users = [
  "user:you@example.com",
]
```

Every variable in `variables.tf` can be overridden here (zone, machine type, disk size, VM name, etc.).

### 2. Deploy

```bash
terraform init
terraform apply
```

The first boot installs the container runtime and pulls the image; allow a few minutes before ComfyUI answers.

### 3. Open ComfyUI

```bash
$(terraform output -raw iap_tunnel_command)
```

Keep the tunnel running and open http://localhost:8188.

## Cost management

GPU instances are expensive. Destroy the VM when you are done; the data disk is kept.

```bash
terraform destroy -target=google_compute_instance.comfy_vm
```

This stops compute billing. Only the disk remains billed (roughly 10 USD/month for 100 GB `pd-balanced`, check current pricing). Run `terraform apply` to resume with the same models and outputs.

A plain `terraform destroy` fails on purpose because the data disk has `prevent_destroy = true`. To delete everything, remove that lifecycle block first.

## Access control

- Only identities listed in `iap_tunnel_users` receive `roles/iap.tunnelResourceAccessor`.
- Accepted formats: `user:email`, `group:email`, `serviceAccount:email`.
- Tunnel connections are recorded in Cloud Audit Logs.

## Remote state

State is local by default. To store it in GCS, create a versioned bucket, uncomment the block in `backend.tf`, then run `terraform init -migrate-state`.

## Troubleshooting

```bash
# SSH through IAP
$(terraform output -raw ssh_command)

# On the VM
sudo cat /var/log/comfyui-startup.log
sudo docker ps
sudo docker logs comfyui
```

If the tunnel fails:

1. Make sure your account is listed in `iap_tunnel_users` and that `terraform apply` has run since.
2. Check that the `iap.googleapis.com` API is enabled.
3. Check that the VM is running (Spot VMs can be stopped by preemption: `gcloud compute instances start <vm_name> --zone=<zone>`).

## License

[MIT](LICENSE)

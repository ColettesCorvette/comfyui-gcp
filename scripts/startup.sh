#!/bin/bash
# =============================================================================
# ComfyUI Startup Script
# =============================================================================
# This script is idempotent - safe to run multiple times without side effects
# =============================================================================

set -e
exec > /var/log/comfyui-startup.log 2>&1

echo "=== COMFYUI STARTUP SCRIPT ==="
echo "Started at: $(date)"

# =============================================================================
# 1. MOUNT PERSISTENT DISK
# =============================================================================
# The device name is passed by Terraform (var.data_disk_name) via instance metadata
METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
DISK_DEVICE_NAME=$(curl -sfH "Metadata-Flavor: Google" "$METADATA_URL/data_disk_device_name")
DISK_DEVICE="/dev/disk/by-id/google-$DISK_DEVICE_NAME"
MOUNT_DIR="/mnt/comfy-data" # Must match the host paths in docker-compose.yml

echo "[1/5] Checking disk mount..."

mkdir -p "$MOUNT_DIR"

# Wait for the disk to be attached
while [ ! -e "$DISK_DEVICE" ]; do
    echo "  → Waiting for $DISK_DEVICE..."
    sleep 1
done

# Check if already mounted
if mountpoint -q "$MOUNT_DIR"; then
    echo "  → Disk already mounted at $MOUNT_DIR"
else
    # Format if needed (new disk)
    if ! blkid "$DISK_DEVICE" > /dev/null 2>&1; then
        echo "  → Formatting new disk..."
        mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DISK_DEVICE"
    fi
    
    echo "  → Mounting disk..."
    mount -o discard,defaults "$DISK_DEVICE" "$MOUNT_DIR"
    chmod -R 777 "$MOUNT_DIR"
    echo "  → Disk mounted successfully"
fi

# =============================================================================
# 2. VERIFY NVIDIA DRIVERS
# =============================================================================
echo "[2/5] Checking NVIDIA drivers..."

if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    echo "  → NVIDIA drivers OK"
else
    echo "  → ERROR: nvidia-smi not found! GPU may not work."
fi

# =============================================================================
# 3. INSTALL DOCKER (IF NEEDED)
# =============================================================================
echo "[3/5] Checking Docker installation..."

if command -v docker &> /dev/null && docker --version | grep -q "Docker version"; then
    echo "  → Docker already installed: $(docker --version)"
else
    echo "  → Installing Docker..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "  → Docker installed successfully"
fi

# =============================================================================
# 4. INSTALL NVIDIA CONTAINER TOOLKIT (IF NEEDED)
# =============================================================================
echo "[4/5] Checking NVIDIA Container Toolkit..."

if dpkg -l | grep -q nvidia-container-toolkit; then
    echo "  → NVIDIA Container Toolkit already installed"
else
    echo "  → Installing NVIDIA Container Toolkit..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    apt-get update
    apt-get install -y nvidia-container-toolkit
    
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker
    echo "  → NVIDIA Container Toolkit installed and configured"
fi

# =============================================================================
# 5. FETCH AND LAUNCH COMFYUI
# =============================================================================
echo "[5/5] Launching ComfyUI..."

# Fetch docker-compose from instance metadata
echo "  → Fetching docker-compose.yml from metadata..."
curl -sH "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker_compose_content" \
    > /root/docker-compose.yml

# Launch ComfyUI
cd /root
docker compose pull
docker compose up -d

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "Finished at: $(date)"
echo "ComfyUI is listening on port 8188 (reach it through an IAP tunnel)"

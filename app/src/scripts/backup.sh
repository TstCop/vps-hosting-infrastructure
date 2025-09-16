#!/bin/bash

# Backup directory
BACKUP_DIR="/path/to/backup/directory"

# Date format for backup filename
DATE=$(date +"%Y%m%d%H%M")

# Function to create a backup of a VM
backup_vm() {
    VM_NAME=$1
    echo "Backing up VM: $VM_NAME"
    # Command to create a backup (this is a placeholder, replace with actual command)
    virsh dumpxml $VM_NAME > "$BACKUP_DIR/${VM_NAME}_backup_$DATE.xml"
}

# List of VMs to backup (replace with actual VM names)
VM_LIST=("vm1" "vm2" "vm3")

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Loop through each VM and create a backup
for VM in "${VM_LIST[@]}"; do
    backup_vm $VM
done

echo "Backup completed."
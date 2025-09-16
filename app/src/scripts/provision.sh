#!/bin/bash

# Provisioning script for the server environment

# Update package lists
echo "Updating package lists..."
apt-get update -y

# Install necessary packages
echo "Installing necessary packages..."
apt-get install -y \
    build-essential \
    libvirt-dev \
    qemu-kvm \
    vagrant \
    git \
    curl \
    wget

# Start and enable libvirt service
echo "Starting and enabling libvirt service..."
systemctl start libvirtd
systemctl enable libvirtd

# Additional provisioning steps can be added here

echo "Provisioning completed successfully."
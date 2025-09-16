#!/bin/bash

# Cleanup script for unused resources

# Remove unused VMs
echo "Cleaning up unused VMs..."
vagrant global-status --prune | awk '/^id/{print $1}' | xargs -r vagrant destroy -f

# Remove old backups
echo "Removing old backups..."
find /path/to/backups -type f -mtime +30 -exec rm {} \;

# Remove temporary files
echo "Cleaning up temporary files..."
rm -rf /tmp/vagrant*

echo "Cleanup completed."
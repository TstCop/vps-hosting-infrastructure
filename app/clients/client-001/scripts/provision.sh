#!/bin/bash

# Provisioning script for client 001's VM

# Update package lists
apt-get update

# Install necessary packages
apt-get install -y nginx git

# Clone the client's repository (if applicable)
# git clone https://github.com/client-001/repo.git /var/www/client-001

# Set up Nginx configuration
cat <<EOL > /etc/nginx/sites-available/client-001
server {
    listen 80;
    server_name client-001.example.com;

    location / {
        root /var/www/client-001;
        index index.html index.htm;
    }
}
EOL

# Enable the Nginx configuration
ln -s /etc/nginx/sites-available/client-001 /etc/nginx/sites-enabled/

# Restart Nginx to apply changes
systemctl restart nginx

echo "Provisioning for client 001 completed."
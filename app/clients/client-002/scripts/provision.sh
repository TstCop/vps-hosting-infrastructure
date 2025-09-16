#!/bin/bash

# Provisioning script for client 002's VM

# Update package lists
apt-get update

# Install necessary packages
apt-get install -y nginx git

# Clone the client's repository (if applicable)
# git clone https://github.com/client-002/repository.git /var/www/client-002

# Set up Nginx configuration for the client
cat <<EOL > /etc/nginx/sites-available/client-002
server {
    listen 80;
    server_name client-002.example.com;

    location / {
        root /var/www/client-002;
        index index.html index.htm;
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
EOL

# Enable the Nginx configuration
ln -s /etc/nginx/sites-available/client-002 /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t

# Restart Nginx to apply changes
systemctl restart nginx

# Additional provisioning steps can be added here

echo "Provisioning for client 002 completed."
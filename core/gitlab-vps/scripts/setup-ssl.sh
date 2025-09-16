#!/bin/bash
# setup-ssl.sh - SSL/TLS configuration script for GitLab VPS
# File: /opt/xcloud/vps-hosting-infrastructure/core/gitlab-vps/scripts/setup-ssl.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN="gitlab.xcloud.local"
PUBLIC_IP="136.243.208.130"
EMAIL="admin@xcloud.local"
CERT_PATH="/etc/ssl/certs"
KEY_PATH="/etc/ssl/private"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to generate self-signed certificate
generate_self_signed() {
    log "🔐 Generating self-signed SSL certificate..."

    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout "$KEY_PATH/gitlab.key" \
        -out "$CERT_PATH/gitlab.crt" \
        -subj "/C=US/ST=State/L=City/O=XCloud/OU=IT/CN=$DOMAIN/emailAddress=$EMAIL" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:gitlab-vps.internal,IP:$PUBLIC_IP,IP:10.0.0.10"

    # Generate certificate for Container Registry
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout "$KEY_PATH/registry.key" \
        -out "$CERT_PATH/registry.crt" \
        -subj "/C=US/ST=State/L=City/O=XCloud/OU=IT/CN=registry.$DOMAIN/emailAddress=$EMAIL" \
        -addext "subjectAltName=DNS:registry.$DOMAIN,IP:$PUBLIC_IP:5050"

    chmod 600 "$KEY_PATH"/*.key
    chmod 644 "$CERT_PATH"/*.crt

    success "Self-signed certificates generated"
}

# Function to setup Let's Encrypt
setup_letsencrypt() {
    log "🔒 Setting up Let's Encrypt..."

    # Install Certbot
    apt-get update -q
    apt-get install -y snapd
    snap install core; snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot

    # Create webroot directory
    mkdir -p /var/www/letsencrypt
    chown -R www-data:www-data /var/www/letsencrypt

    # Configure Nginx for ACME challenge (temporary)
    cat > /etc/nginx/sites-available/letsencrypt << 'EOF'
server {
    listen 80;
    server_name gitlab.xcloud.local registry.xcloud.local;

    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
        try_files $uri $uri/ =404;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/letsencrypt /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx

    # Get certificates
    certbot certonly --webroot \
        -w /var/www/letsencrypt \
        -d "$DOMAIN" \
        -d "registry.$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive

    # Copy certificates to GitLab paths
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_PATH/gitlab.crt"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$KEY_PATH/gitlab.key"
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_PATH/registry.crt"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$KEY_PATH/registry.key"

    chmod 600 "$KEY_PATH"/*.key
    chmod 644 "$CERT_PATH"/*.crt

    success "Let's Encrypt certificates obtained"
}

# Function to configure SSL security
configure_ssl_security() {
    log "🔒 Configuring SSL security settings..."

    # Generate DH parameters
    if [ ! -f "$CERT_PATH/dhparam.pem" ]; then
        log "Generating DH parameters (this may take several minutes)..."
        openssl dhparam -out "$CERT_PATH/dhparam.pem" 2048
    fi

    # Create SSL configuration for Nginx
    cat > /etc/nginx/conf.d/ssl.conf << 'EOF'
# SSL Configuration for GitLab VPS
# Based on Mozilla Modern configuration

# SSL protocols
ssl_protocols TLSv1.2 TLSv1.3;

# SSL ciphers
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';

# SSL preferences
ssl_prefer_server_ciphers off;

# ECDH curve
ssl_ecdh_curve X25519:prime256v1:secp384r1;

# SSL session
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# DH parameters
ssl_dhparam /etc/ssl/certs/dhparam.pem;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# Security headers
add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload' always;
add_header X-Frame-Options SAMEORIGIN always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection '1; mode=block' always;
add_header Referrer-Policy 'strict-origin-when-cross-origin' always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self';" always;

# Hide Nginx version
server_tokens off;
EOF

    success "SSL security configuration completed"
}

# Function to test SSL configuration
test_ssl_configuration() {
    log "🧪 Testing SSL configuration..."

    # Test certificate validity
    if openssl x509 -in "$CERT_PATH/gitlab.crt" -text -noout > /dev/null 2>&1; then
        success "GitLab certificate is valid"

        # Show certificate details
        echo "Certificate details:"
        openssl x509 -in "$CERT_PATH/gitlab.crt" -text -noout | grep -E "(Subject:|DNS:|IP Address:|Not After)"
    else
        error "GitLab certificate is invalid"
        return 1
    fi

    # Test Nginx configuration
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration is valid"
    else
        error "Nginx configuration has errors"
        nginx -t
        return 1
    fi

    # Test SSL connection
    log "Testing SSL connection..."
    if timeout 10 openssl s_client -connect localhost:443 -servername "$DOMAIN" < /dev/null > /dev/null 2>&1; then
        success "SSL connection test passed"
    else
        warning "SSL connection test failed (this is normal if GitLab is not fully configured yet)"
    fi
}

# Function to setup SSL monitoring
setup_ssl_monitoring() {
    log "📊 Setting up SSL monitoring..."

    cat > /usr/local/bin/ssl-monitor.sh << 'EOF'
#!/bin/bash
# SSL certificate monitoring script

CERT_PATH="/etc/ssl/certs/gitlab.crt"
WARNING_DAYS=30
CRITICAL_DAYS=7

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "🔒 SSL Certificate Monitor"
echo "========================="

if [ ! -f "$CERT_PATH" ]; then
    echo -e "${RED}❌ Certificate not found: $CERT_PATH${NC}"
    exit 1
fi

# Get certificate expiry date
EXPIRY_DATE=$(openssl x509 -in "$CERT_PATH" -enddate -noout | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_REMAINING=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))

echo "Certificate: $CERT_PATH"
echo "Expires: $EXPIRY_DATE"
echo "Days remaining: $DAYS_REMAINING"

if [ "$DAYS_REMAINING" -le "$CRITICAL_DAYS" ]; then
    echo -e "${RED}🚨 CRITICAL: Certificate expires in $DAYS_REMAINING days!${NC}"
    exit 2
elif [ "$DAYS_REMAINING" -le "$WARNING_DAYS" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Certificate expires in $DAYS_REMAINING days${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Certificate is valid for $DAYS_REMAINING days${NC}"
fi

# Test SSL Labs grade (if online)
if command -v curl > /dev/null && curl -s --connect-timeout 5 https://api.ssllabs.com/api/v3/info > /dev/null; then
    echo -e "\n🔍 SSL Labs Grade Check:"
    echo "Visit: https://www.ssllabs.com/ssltest/analyze.html?d=gitlab.xcloud.local"
fi
EOF

    chmod +x /usr/local/bin/ssl-monitor.sh

    # Add SSL monitoring to cron
    (crontab -l 2>/dev/null; echo "0 6 * * * /usr/local/bin/ssl-monitor.sh >> /var/log/ssl-monitor.log 2>&1") | crontab -

    success "SSL monitoring configured"
}

# Function to setup SSL renewal
setup_ssl_renewal() {
    log "🔄 Setting up SSL certificate renewal..."

    cat > /usr/local/bin/ssl-renew.sh << 'EOF'
#!/bin/bash
# SSL certificate renewal script

LOG_FILE="/var/log/ssl-renewal.log"

echo "$(date): Starting SSL certificate renewal" | tee -a "$LOG_FILE"

if command -v certbot > /dev/null; then
    # Let's Encrypt renewal
    certbot renew --quiet --post-hook "systemctl reload nginx && gitlab-ctl restart nginx" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "$(date): Let's Encrypt renewal completed successfully" | tee -a "$LOG_FILE"

        # Copy renewed certificates to GitLab paths
        DOMAIN="gitlab.xcloud.local"
        if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/etc/ssl/certs/gitlab.crt"
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "/etc/ssl/private/gitlab.key"
            gitlab-ctl restart nginx
        fi
    else
        echo "$(date): Let's Encrypt renewal failed" | tee -a "$LOG_FILE"
    fi
else
    echo "$(date): Certbot not found, skipping renewal" | tee -a "$LOG_FILE"
fi

echo "$(date): SSL certificate renewal process completed" | tee -a "$LOG_FILE"
EOF

    chmod +x /usr/local/bin/ssl-renew.sh

    # Add renewal to cron (daily check)
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/ssl-renew.sh") | crontab -

    success "SSL renewal configured"
}

# Main script execution
log "🚀 Starting SSL/TLS configuration for GitLab VPS..."

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Create SSL directories
mkdir -p "$CERT_PATH" "$KEY_PATH"
chmod 755 "$CERT_PATH"
chmod 700 "$KEY_PATH"

# Check if Let's Encrypt should be used
if [ "${1:-}" == "--letsencrypt" ]; then
    warning "⚠️ Let's Encrypt requires:"
    warning "  1. Domain name pointing to this server"
    warning "  2. Port 80 accessible from internet"
    warning "  3. Valid email address"

    read -p "Continue with Let's Encrypt? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_letsencrypt
    else
        log "Falling back to self-signed certificate"
        generate_self_signed
    fi
else
    log "Using self-signed certificate (use --letsencrypt for Let's Encrypt)"
    generate_self_signed
fi

# Configure SSL security
configure_ssl_security

# Test configuration
test_ssl_configuration

# Setup monitoring and renewal
setup_ssl_monitoring
setup_ssl_renewal

# Update GitLab configuration to use new certificates
log "🔄 Updating GitLab SSL configuration..."
if [ -f /etc/gitlab/gitlab.rb ]; then
    # Backup current configuration
    cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.backup.ssl

    # Update SSL paths in GitLab config
    sed -i "s|nginx\['ssl_certificate'\].*|nginx['ssl_certificate'] = \"$CERT_PATH/gitlab.crt\"|" /etc/gitlab/gitlab.rb
    sed -i "s|nginx\['ssl_certificate_key'\].*|nginx['ssl_certificate_key'] = \"$KEY_PATH/gitlab.key\"|" /etc/gitlab/gitlab.rb

    # Reconfigure GitLab
    gitlab-ctl reconfigure
    gitlab-ctl restart nginx
fi

# Create SSL documentation
cat > /opt/gitlab-ssl-docs.md << 'EOF'
# GitLab SSL/TLS Configuration

## Current Configuration
- **Certificate Path**: /etc/ssl/certs/gitlab.crt
- **Private Key Path**: /etc/ssl/private/gitlab.key
- **Type**: Self-signed / Let's Encrypt

## Management Commands

### Monitor SSL Status
```bash
ssl-monitor.sh
```

### Renew Certificates
```bash
ssl-renew.sh
```

### Test SSL Configuration
```bash
nginx -t
openssl x509 -in /etc/ssl/certs/gitlab.crt -text -noout
```

### Check Certificate Details
```bash
openssl x509 -in /etc/ssl/certs/gitlab.crt -text -noout | grep -E "(Subject:|DNS:|Not After)"
```

## Let's Encrypt Setup
To switch to Let's Encrypt:
```bash
./setup-ssl.sh --letsencrypt
```

## SSL Security Grade
Test your SSL configuration:
- https://www.ssllabs.com/ssltest/
- https://observatory.mozilla.org/

## Troubleshooting
1. Check Nginx config: `nginx -t`
2. Check GitLab config: `gitlab-ctl configtest`
3. View logs: `gitlab-ctl tail nginx`
4. Restart services: `gitlab-ctl restart nginx`
EOF

success "✅ SSL/TLS configuration completed!"

log "📋 SSL Summary:"
echo "==============="
echo "Certificate: $CERT_PATH/gitlab.crt"
echo "Private Key: $KEY_PATH/gitlab.key"
echo "Monitoring: ssl-monitor.sh"
echo "Renewal: ssl-renew.sh (automated)"
echo "Documentation: /opt/gitlab-ssl-docs.md"
echo ""

warning "⚠️ Important notes:"
warning "1. Change default passwords after setup"
warning "2. Configure DNS for your domain"
warning "3. Test SSL configuration with SSL Labs"
warning "4. Monitor certificate expiry dates"

log "🔍 Running SSL monitor..."
/usr/local/bin/ssl-monitor.sh

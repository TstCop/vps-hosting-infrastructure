#!/bin/bash

# Nginx Installation and Configuration Script
# Installs and configures Nginx as reverse proxy for Node.js applications

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

log "🌐 Starting Nginx installation and configuration..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Install Nginx
log "📦 Installing Nginx..."
apt-get update
apt-get install -y nginx nginx-extras

# Stop Nginx for configuration
systemctl stop nginx

# Backup default configuration
log "💾 Backing up default configuration..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
cp -r /etc/nginx/sites-available /etc/nginx/sites-available.backup 2>/dev/null || true

# Create main Nginx configuration
log "⚙️ Creating main Nginx configuration..."
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    server_tokens off;

    ##
    # MIME Types
    ##
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    ##
    # Logging Settings
    ##
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    ##
    # Rate Limiting
    ##
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

    ##
    # Security Headers
    ##
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self';" always;

    ##
    # Upstream Definitions
    ##
    upstream nodejs_app {
        least_conn;
        server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
        # Add more backend servers here for load balancing
        # server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream api_backend {
        least_conn;
        server 127.0.0.1:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create default HTTP site (redirects to HTTPS)
log "🔄 Creating default HTTP site..."
cat > /etc/nginx/sites-available/default-http << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Acme challenge for Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    # Redirect all HTTP traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Create main application site
log "🚀 Creating main application site..."
cat > /etc/nginx/sites-available/app << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.vps.local;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/app.vps.local/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.vps.local/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/app.vps.local/chain.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Rate limiting
    limit_req zone=general burst=20 nodelay;
    limit_conn conn_limit_per_ip 20;

    # Proxy settings
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;

    # Proxy timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # Main application
    location / {
        proxy_pass http://nodejs_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        proxy_redirect off;
    }

    # Static files
    location /static/ {
        alias /opt/app/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        gzip_static on;
    }

    # Uploads
    location /uploads/ {
        alias /opt/app/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Health check
    location /health {
        access_log off;
        proxy_pass http://nodejs_app/health;
    }

    # Error pages
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
    }
}
EOF

# Create API site
log "🔌 Creating API site..."
cat > /etc/nginx/sites-available/api << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.app.vps.local;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/app.vps.local/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.vps.local/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/app.vps.local/chain.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # API rate limiting (more restrictive)
    limit_req zone=api burst=10 nodelay;
    limit_conn conn_limit_per_ip 10;

    # Proxy settings
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;

    # Proxy timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # API endpoints
    location / {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        proxy_redirect off;
    }

    # Authentication endpoints (more restrictive)
    location /auth/ {
        limit_req zone=auth burst=5 nodelay;
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
    }

    # Health check
    location /health {
        access_log off;
        proxy_pass http://api_backend/health;
    }

    # Block sensitive endpoints from external access
    location /admin/ {
        allow 10.0.0.0/24;
        deny all;
        proxy_pass http://api_backend;
    }

    # Error pages
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
    }
}
EOF

# Create monitoring site (internal access only)
log "📊 Creating monitoring site..."
cat > /etc/nginx/sites-available/monitoring << 'EOF'
server {
    listen 127.0.0.1:8090;
    server_name localhost;

    # Allow only local access
    allow 127.0.0.1;
    allow 10.0.0.0/24;
    deny all;

    # Netdata
    location /netdata/ {
        proxy_pass http://127.0.0.1:19999/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Node Exporter
    location /node-exporter/ {
        proxy_pass http://127.0.0.1:9100/;
        proxy_http_version 1.1;
    }

    # Health checks
    location /health {
        access_log off;
        return 200 "monitoring-ok\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable sites
log "✅ Enabling sites..."
ln -sf /etc/nginx/sites-available/default-http /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/monitoring /etc/nginx/sites-enabled/

# Create necessary directories
log "📁 Creating directories..."
mkdir -p /var/www/certbot
mkdir -p /opt/app/public
mkdir -p /var/cache/nginx
mkdir -p /var/log/nginx

# Set proper permissions
chown -R www-data:www-data /var/www/certbot
chown -R www-data:www-data /opt/app/public
chown -R www-data:www-data /var/cache/nginx
chown -R www-data:www-data /var/log/nginx

# Create a simple index page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS Hosting Infrastructure</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 8px 0; border-bottom: 1px solid #eee; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 VPS Hosting Infrastructure</h1>

        <div class="status success">
            <strong>✅ Nginx Successfully Configured</strong><br>
            Reverse proxy and load balancer ready for Node.js applications
        </div>

        <div class="status info">
            <h3>📋 System Information</h3>
            <ul>
                <li><strong>Server:</strong> Nginx/App VPS</li>
                <li><strong>IP Address:</strong> 136.243.208.131</li>
                <li><strong>Environment:</strong> Production</li>
                <li><strong>Status:</strong> Active</li>
            </ul>
        </div>

        <div class="status info">
            <h3>🔗 Available Services</h3>
            <ul>
                <li><strong>Main App:</strong> https://app.vps.local</li>
                <li><strong>API:</strong> https://api.app.vps.local</li>
                <li><strong>Monitoring:</strong> http://localhost:8090/netdata/</li>
                <li><strong>Health Check:</strong> /health</li>
            </ul>
        </div>

        <div class="footer">
            <p>VPS Hosting Infrastructure v1.0 | $(date)</p>
        </div>
    </div>
</body>
</html>
EOF

# Create error page
cat > /var/www/html/50x.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Service Temporarily Unavailable</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; }
        h1 { color: #e74c3c; }
        p { color: #666; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚧 Service Temporarily Unavailable</h1>
        <p>The application is currently experiencing technical difficulties.</p>
        <p>Please try again in a few moments.</p>
        <p>If the problem persists, please contact the system administrator.</p>
    </div>
</body>
</html>
EOF

# Test Nginx configuration
log "🧪 Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    log "✅ Nginx configuration test passed"
else
    error "❌ Nginx configuration test failed"
fi

# Enable and start Nginx
log "🔄 Starting Nginx..."
systemctl enable nginx
systemctl start nginx

# Check Nginx status
if systemctl is-active --quiet nginx; then
    log "✅ Nginx is running successfully"
else
    error "❌ Failed to start Nginx"
fi

# Create Nginx management script
log "🔧 Creating Nginx management script..."
cat > /opt/app/scripts/nginx-manager.sh << 'EOF'
#!/bin/bash

# Nginx Management Script
# Provides common nginx management operations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

show_help() {
    echo "Nginx Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      Show nginx status and sites"
    echo "  reload      Reload nginx configuration"
    echo "  restart     Restart nginx service"
    echo "  test        Test nginx configuration"
    echo "  logs        Show nginx logs"
    echo "  sites       List available and enabled sites"
    echo "  enable      Enable a site"
    echo "  disable     Disable a site"
    echo "  ssl-renew   Renew SSL certificates"
    echo "  help        Show this help message"
}

nginx_status() {
    log "Nginx Service Status:"
    systemctl status nginx --no-pager || true

    echo ""
    log "Nginx Processes:"
    ps aux | grep nginx | grep -v grep || true

    echo ""
    log "Listening Ports:"
    netstat -tuln | grep -E ':80|:443|:8090' || true

    echo ""
    log "Recent Access Logs:"
    tail -5 /var/log/nginx/access.log 2>/dev/null || echo "No access logs found"
}

nginx_logs() {
    log "Recent Nginx Error Logs:"
    tail -20 /var/log/nginx/error.log 2>/dev/null || echo "No error logs found"

    echo ""
    log "Recent Nginx Access Logs:"
    tail -20 /var/log/nginx/access.log 2>/dev/null || echo "No access logs found"
}

list_sites() {
    log "Available Sites:"
    ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "No sites available"

    echo ""
    log "Enabled Sites:"
    ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "No sites enabled"
}

enable_site() {
    if [ -z "$2" ]; then
        error "Please specify a site name"
    fi

    SITE="$2"
    if [ ! -f "/etc/nginx/sites-available/$SITE" ]; then
        error "Site $SITE not found in sites-available"
    fi

    ln -sf "/etc/nginx/sites-available/$SITE" "/etc/nginx/sites-enabled/"
    log "Site $SITE enabled"

    nginx -t && systemctl reload nginx
}

disable_site() {
    if [ -z "$2" ]; then
        error "Please specify a site name"
    fi

    SITE="$2"
    if [ ! -L "/etc/nginx/sites-enabled/$SITE" ]; then
        error "Site $SITE is not enabled"
    fi

    rm "/etc/nginx/sites-enabled/$SITE"
    log "Site $SITE disabled"

    nginx -t && systemctl reload nginx
}

ssl_renew() {
    log "Renewing SSL certificates..."
    certbot renew --quiet --no-self-upgrade

    if [ $? -eq 0 ]; then
        log "SSL certificates renewed successfully"
        systemctl reload nginx
    else
        error "Failed to renew SSL certificates"
    fi
}

case "$1" in
    status)
        nginx_status
        ;;
    reload)
        log "Reloading Nginx..."
        nginx -t && systemctl reload nginx
        ;;
    restart)
        log "Restarting Nginx..."
        systemctl restart nginx
        ;;
    test)
        log "Testing Nginx configuration..."
        nginx -t
        ;;
    logs)
        nginx_logs
        ;;
    sites)
        list_sites
        ;;
    enable)
        enable_site "$@"
        ;;
    disable)
        disable_site "$@"
        ;;
    ssl-renew)
        ssl_renew
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
EOF

chmod +x /opt/app/scripts/nginx-manager.sh
chown vagrant:vagrant /opt/app/scripts/nginx-manager.sh

# Display status
log "📋 Nginx Installation Summary:"
echo "======================================"
echo "Status: $(systemctl is-active nginx)"
echo "Configuration: /etc/nginx/nginx.conf"
echo "Sites Available: /etc/nginx/sites-available/"
echo "Sites Enabled: /etc/nginx/sites-enabled/"
echo "Logs: /var/log/nginx/"
echo "Management Script: /opt/app/scripts/nginx-manager.sh"
echo ""
echo "Enabled Sites:"
ls -1 /etc/nginx/sites-enabled/ 2>/dev/null || echo "  None"
echo ""
echo "Listening Ports:"
netstat -tuln | grep -E ':80|:443|:8090' || echo "  None"
echo "======================================"

log "✅ Nginx installation and configuration completed successfully!"
log "🌐 Next steps:"
echo "  1. Configure SSL certificates with Let's Encrypt"
echo "  2. Install and configure Node.js application"
echo "  3. Test reverse proxy functionality"
echo "  4. Monitor logs: tail -f /var/log/nginx/access.log"
echo "  5. Use management script: /opt/app/scripts/nginx-manager.sh status"

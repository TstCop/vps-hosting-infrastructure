#!/bin/bash

# Nginx/App VPS Main Provisioning Script
# Configures Ubuntu 22.04 LTS for production hosting with Nginx, Node.js, and Docker

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

log "🚀 Starting Nginx/App VPS provisioning..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# System information
log "📊 System Information:"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "CPU: $(nproc) cores"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"

# Update system packages
log "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install essential packages
log "🔧 Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    rsync \
    cron \
    logrotate \
    net-tools \
    dnsutils \
    telnet \
    tcpdump \
    iotop \
    iftop \
    ncdu \
    jq \
    yq

# Configure timezone
log "🕐 Configuring timezone..."
timedatectl set-timezone UTC
log "Timezone set to: $(timedatectl show --property=Timezone --value)"

# Configure hostname and hosts
log "🌐 Configuring hostname and hosts..."
hostnamectl set-hostname nginx-app-vps

# Update /etc/hosts
cat > /etc/hosts << 'EOF'
127.0.0.1       localhost nginx-app-vps
127.0.1.1       nginx-app-vps.app.vps.local nginx-app-vps

# Private network
10.0.0.10       gitlab-vps gitlab.vps.local registry.gitlab.vps.local
10.0.0.20       nginx-app-vps app.vps.local api.app.vps.local

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

# Network configuration
log "🔗 Configuring network settings..."

# Create netplan configuration
cat > /etc/netplan/50-vagrant.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: false
      addresses:
        - 136.243.208.131/29
      gateway4: 136.243.208.129
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 1.1.1.1
        search:
          - vps.local
    enp2s0:
      dhcp4: false
      addresses:
        - 10.0.0.20/24
EOF

# Apply network configuration
netplan apply || warn "Network configuration will be applied on next boot"

# Configure kernel parameters for network optimization
cat > /etc/sysctl.d/99-network-performance.conf << 'EOF'
# Network performance optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.route.flush = 1

# Security settings
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-network-performance.conf

# Create directory structure
log "📁 Creating directory structure..."
mkdir -p /opt/app/{data,logs,uploads,scripts,config}
mkdir -p /opt/nginx/{cache,logs,sites-available,sites-enabled}
mkdir -p /opt/redis/data
mkdir -p /opt/letsencrypt/{certs,www}
mkdir -p /backup/nginx-app
mkdir -p /var/log/app

# Set proper ownership
chown -R vagrant:vagrant /opt/app
chown -R www-data:www-data /opt/nginx
chown -R vagrant:vagrant /opt/redis
chown -R vagrant:vagrant /opt/letsencrypt
chown -R vagrant:vagrant /backup

# Create application user (non-root)
log "👤 Creating application user..."
if ! id "appuser" &>/dev/null; then
    useradd -r -s /bin/bash -m -d /home/appuser appuser
    usermod -aG docker appuser 2>/dev/null || true  # Will work after Docker is installed
fi

# Configure SSH security
log "🔐 Configuring SSH security..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# SSH hardening
cat >> /etc/ssh/sshd_config << 'EOF'

# Security hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers vagrant appuser
Protocol 2
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no
EOF

# Setup basic firewall rules
log "🔥 Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp comment 'SSH'

# Allow HTTP/HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Allow internal network access to app ports
ufw allow from 10.0.0.0/24 to any port 3000 comment 'Node.js app internal'
ufw allow from 10.0.0.0/24 to any port 8080 comment 'API internal'

# Enable firewall
ufw --force enable

# Configure fail2ban
log "🛡️ Configuring Fail2ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

cat > /etc/fail2ban/jail.d/nginx-app.conf << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 6

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

# Create log rotation configuration
log "📝 Configuring log rotation..."
cat > /etc/logrotate.d/nginx-app << 'EOF'
/var/log/app/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 vagrant vagrant
    postrotate
        /bin/systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}

/opt/app/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 vagrant vagrant
}
EOF

# Install monitoring tools
log "📊 Installing monitoring tools..."

# Install Netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --disable-telemetry

# Configure Netdata
cat > /etc/netdata/netdata.conf << 'EOF'
[global]
    run as user = netdata
    web files owner = root
    web files group = netdata
    bind socket to IP = 127.0.0.1
    default port = 19999
    access log = none
    error log = /var/log/netdata/error.log
    debug log = /var/log/netdata/debug.log

[web]
    mode = static-threaded
    listen backlog = 4096
    disconnect idle clients after seconds = 60
    timeout for first request = 60
    accept a streaming request every seconds = 2
    respect do not track policy = no
    x-frame-options response header =
    allow connections from = localhost 127.0.0.1 10.0.0.*
    allow dashboard from = localhost 127.0.0.1 10.0.0.*
    allow badges from = *
    allow streaming from = 10.0.0.*
    allow netdata.conf from = localhost 127.0.0.1 10.0.0.*
EOF

# Create environment file for sensitive data
log "🔑 Creating environment configuration..."
cat > /opt/app/.env << 'EOF'
# Environment Configuration
NODE_ENV=production
PORT=3000
API_PORT=8080

# Database
DATABASE_URL=postgresql://app_user:CHANGE_ME@10.0.0.10:5432/app_production?sslmode=require

# Redis
REDIS_URL=redis://:CHANGE_ME@10.0.0.10:6379/0
REDIS_PASSWORD=CHANGE_ME

# Security
JWT_SECRET=CHANGE_ME
SESSION_SECRET=CHANGE_ME

# GitLab Integration
GITLAB_API_URL=https://gitlab.vps.local/api/v4
GITLAB_TOKEN=CHANGE_ME

# SSL/TLS
SSL_CERT_PATH=/etc/letsencrypt/live/app.vps.local/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/app.vps.local/privkey.pem

# Monitoring
NETDATA_URL=http://127.0.0.1:19999
NODE_EXPORTER_URL=http://127.0.0.1:9100
EOF

chown vagrant:vagrant /opt/app/.env
chmod 600 /opt/app/.env

# Create health check script
log "🏥 Creating health check script..."
cat > /opt/app/scripts/health-check.sh << 'EOF'
#!/bin/bash

# Health check script for Nginx/App VPS
# Checks all critical services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check system resources
check_resources() {
    log "Checking system resources..."

    # Memory usage
    MEMORY_USAGE=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$MEMORY_USAGE > 85.0" | bc -l) )); then
        warn "High memory usage: ${MEMORY_USAGE}%"
    else
        log "Memory usage: ${MEMORY_USAGE}%"
    fi

    # Disk usage
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 85 ]; then
        warn "High disk usage: ${DISK_USAGE}%"
    else
        log "Disk usage: ${DISK_USAGE}%"
    fi

    # Load average
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
    log "Load average: ${LOAD_AVG}"
}

# Check services
check_services() {
    log "Checking services..."

    services=("nginx" "fail2ban" "ufw" "netdata")

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "✅ $service is running"
        else
            error "❌ $service is not running"
        fi
    done
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."

    # Check if we can reach GitLab VPS
    if ping -c 1 10.0.0.10 >/dev/null 2>&1; then
        log "✅ GitLab VPS reachable"
    else
        warn "❌ Cannot reach GitLab VPS"
    fi

    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Internet connectivity OK"
    else
        error "❌ No internet connectivity"
    fi
}

# Check application ports
check_ports() {
    log "Checking application ports..."

    ports=(80 443 22)

    for port in "${ports[@]}"; do
        if netstat -tuln | grep ":$port " >/dev/null; then
            log "✅ Port $port is listening"
        else
            warn "❌ Port $port is not listening"
        fi
    done
}

# Check SSL certificates
check_ssl() {
    log "Checking SSL certificates..."

    if [ -f "/etc/letsencrypt/live/app.vps.local/fullchain.pem" ]; then
        CERT_EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/app.vps.local/fullchain.pem" | cut -d= -f2)
        CERT_EXPIRY_EPOCH=$(date -d "$CERT_EXPIRY" +%s)
        CURRENT_EPOCH=$(date +%s)
        DAYS_UNTIL_EXPIRY=$(( (CERT_EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))

        if [ "$DAYS_UNTIL_EXPIRY" -lt 30 ]; then
            warn "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
        else
            log "✅ SSL certificate valid for $DAYS_UNTIL_EXPIRY days"
        fi
    else
        warn "❌ SSL certificate not found"
    fi
}

# Main health check
main() {
    log "🏥 Starting health check for Nginx/App VPS..."

    check_resources
    check_services
    check_network
    check_ports
    check_ssl

    log "✅ Health check completed"
}

main "$@"
EOF

chmod +x /opt/app/scripts/health-check.sh
chown vagrant:vagrant /opt/app/scripts/health-check.sh

# Create backup script
log "💾 Creating backup script..."
cat > /opt/app/scripts/backup.sh << 'EOF'
#!/bin/bash

# Backup script for Nginx/App VPS
# Creates compressed backups of critical data

set -e

BACKUP_DIR="/backup/nginx-app"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="nginx-app-backup-$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Create backup directory
mkdir -p "$BACKUP_PATH"

log "Starting backup: $BACKUP_NAME"

# Backup configurations
log "Backing up configurations..."
tar -czf "$BACKUP_PATH/config.tar.gz" \
    /etc/nginx \
    /opt/app/config \
    /etc/letsencrypt \
    2>/dev/null || true

# Backup application data
log "Backing up application data..."
tar -czf "$BACKUP_PATH/app-data.tar.gz" \
    /opt/app/data \
    /opt/app/uploads \
    2>/dev/null || true

# Backup logs (last 7 days)
log "Backing up recent logs..."
find /var/log/nginx /opt/app/logs -name "*.log*" -mtime -7 -exec tar -rf "$BACKUP_PATH/logs.tar" {} \; 2>/dev/null || true
gzip "$BACKUP_PATH/logs.tar" 2>/dev/null || true

# Create backup info file
cat > "$BACKUP_PATH/backup_info.txt" << EOL
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
System: $(lsb_release -d | cut -f2)
Backup Path: $BACKUP_PATH

Contents:
- config.tar.gz: System and application configurations
- app-data.tar.gz: Application data and uploads
- logs.tar.gz: Recent log files (last 7 days)

Restore Instructions:
1. Extract configuration files to their original locations
2. Restore application data to /opt/app/
3. Restart services: nginx, docker, pm2
EOL

# Create final compressed backup
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -name "nginx-app-backup-*.tar.gz" -mtime +30 -delete

log "Backup completed: $BACKUP_NAME.tar.gz"
log "Backup size: $(du -h $BACKUP_DIR/$BACKUP_NAME.tar.gz | cut -f1)"
EOF

chmod +x /opt/app/scripts/backup.sh
chown vagrant:vagrant /opt/app/scripts/backup.sh

# Setup cron jobs
log "⏰ Setting up cron jobs..."
crontab -u vagrant << 'EOF'
# Nginx/App VPS Cron Jobs

# Daily backup at 2 AM
0 2 * * * /opt/app/scripts/backup.sh >> /var/log/app/backup.log 2>&1

# Health check every 15 minutes
*/15 * * * * /opt/app/scripts/health-check.sh >> /var/log/app/health.log 2>&1

# SSL certificate renewal check (daily)
0 3 * * * /usr/bin/certbot renew --quiet --no-self-upgrade

# Log rotation
0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf

# System updates check (weekly)
0 4 * * 0 /usr/bin/apt list --upgradable >> /var/log/app/updates.log 2>&1
EOF

# Enable and start services
log "🔄 Enabling and starting services..."
systemctl enable ufw
systemctl enable fail2ban
systemctl enable netdata

systemctl start ufw
systemctl start fail2ban
systemctl start netdata

# Restart SSH with new configuration
systemctl restart ssh

# Final system cleanup
log "🧹 Performing final cleanup..."
apt-get autoremove -y
apt-get autoclean

# Display system status
log "📋 System Status Summary:"
echo "======================================"
echo "Hostname: $(hostname)"
echo "IP Addresses:"
echo "  Public:  136.243.208.131"
echo "  Private: 10.0.0.20"
echo "Services Status:"
systemctl is-active nginx 2>/dev/null && echo "  ✅ Nginx: Active" || echo "  ❌ Nginx: Inactive"
systemctl is-active fail2ban && echo "  ✅ Fail2ban: Active" || echo "  ❌ Fail2ban: Inactive"
systemctl is-active ufw && echo "  ✅ UFW: Active" || echo "  ❌ UFW: Inactive"
systemctl is-active netdata && echo "  ✅ Netdata: Active" || echo "  ❌ Netdata: Inactive"
echo "Memory Usage: $(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "Disk Usage: $(df / | tail -1 | awk '{print $5}')"
echo "======================================"

log "✅ Nginx/App VPS provisioning completed successfully!"
log "🌐 Next steps:"
echo "  1. Run: vagrant ssh nginx-app-vps"
echo "  2. Install Nginx: /vagrant/scripts/install-nginx.sh"
echo "  3. Install Node.js: /vagrant/scripts/install-nodejs.sh"
echo "  4. Install Docker: /vagrant/scripts/install-docker.sh"
echo "  5. Deploy application: /vagrant/scripts/deploy-app.sh"
echo "  6. Configure SSL: Set up Let's Encrypt certificates"
echo "  7. Monitor: Access Netdata at http://127.0.0.1:19999"

#!/bin/bash
# install-gitlab.sh - GitLab CE installation script
# File: /opt/xcloud/vps-hosting-infrastructure/core/gitlab-vps/scripts/install-gitlab.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITLAB_EXTERNAL_URL="https://136.243.208.130"
GITLAB_SSH_PORT="2222"
PUBLIC_IP="136.243.208.130"
PRIVATE_IP="10.0.0.10"

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

log "🦊 Starting GitLab CE installation..."

# Add GitLab repository
log "📦 Adding GitLab repository..."
curl -fsSL https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

# Install GitLab CE
log "📦 Installing GitLab CE (this may take several minutes)..."
EXTERNAL_URL="$GITLAB_EXTERNAL_URL" apt-get install -y gitlab-ce

# Wait for GitLab to be ready
log "⏳ Waiting for GitLab to initialize..."
sleep 30

# Create GitLab configuration
log "⚙️ Configuring GitLab..."
cat > /etc/gitlab/gitlab.rb << EOF
# GitLab CE Configuration for Production VPS
# Generated: $(date)

# External URL configuration
external_url '$GITLAB_EXTERNAL_URL'

# Network configuration
gitlab_rails['gitlab_host'] = '$PUBLIC_IP'
gitlab_rails['gitlab_port'] = 443
gitlab_rails['gitlab_https'] = true

# SSH configuration
gitlab_rails['gitlab_ssh_host'] = '$PUBLIC_IP'
gitlab_rails['gitlab_shell_ssh_port'] = $GITLAB_SSH_PORT

# Email configuration
gitlab_rails['smtp_enable'] = false  # Disabled for now
gitlab_rails['gitlab_email_enabled'] = false
gitlab_rails['gitlab_email_from'] = 'gitlab@xcloud.local'

# Security settings
gitlab_rails['initial_root_password'] = nil  # Will be auto-generated
gitlab_rails['store_git_keys_in_db'] = true

# Session settings
gitlab_rails['session_expire_delay'] = 10080  # 1 week

# GitLab Shell configuration
gitlab_shell['auth_file'] = "/var/opt/gitlab/.ssh/authorized_keys"

# NGINX configuration
nginx['enable'] = true
nginx['listen_port'] = 80
nginx['listen_https'] = true
nginx['ssl_certificate'] = "/etc/ssl/certs/gitlab.crt"
nginx['ssl_certificate_key'] = "/etc/ssl/private/gitlab.key"
nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"
nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
nginx['ssl_prefer_server_ciphers'] = "off"
nginx['ssl_session_cache'] = "shared:SSL:10m"
nginx['ssl_session_timeout'] = "5m"

# Security headers
nginx['custom_gitlab_server_config'] = "
  add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload' always;
  add_header X-Frame-Options SAMEORIGIN always;
  add_header X-Content-Type-Options nosniff always;
  add_header X-XSS-Protection '1; mode=block' always;
  add_header Referrer-Policy 'strict-origin-when-cross-origin' always;
"

# Registry configuration
registry_external_url 'https://$PUBLIC_IP:5050'
gitlab_rails['registry_enabled'] = true
registry['enable'] = true
registry_nginx['enable'] = true
registry_nginx['listen_port'] = 5050
registry_nginx['listen_https'] = true

# Performance tuning for 4GB RAM
puma['worker_processes'] = 2
puma['worker_timeout'] = 60
puma['min_threads'] = 4
puma['max_threads'] = 4

# Database configuration
postgresql['shared_preload_libraries'] = 'pg_stat_statements'
postgresql['max_connections'] = 200
postgresql['work_mem'] = "8MB"
postgresql['effective_cache_size'] = "1GB"

# Redis configuration
redis['maxmemory'] = "256MB"
redis['maxmemory_policy'] = "allkeys-lru"

# Backup configuration
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_archive_permissions'] = 0600
gitlab_rails['backup_keep_time'] = 604800  # 7 days

# Monitoring configuration (disabled to save resources)
prometheus_monitoring['enable'] = false
grafana['enable'] = false
alertmanager['enable'] = false

# Gitaly configuration
gitaly['auth_token'] = '$(openssl rand -hex 32)'

# GitLab Pages (disabled)
pages_external_url 'http://pages.xcloud.local'
gitlab_pages['enable'] = false

# Mattermost (disabled)
mattermost['enable'] = false

# Container Registry storage
registry['storage'] = {
  's3' => {
    'accesskey' => '',
    'secretkey' => '',
    'bucket' => '',
    'region' => '',
  },
  'filesystem' => {
    'rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry'
  }
}

# Rate limiting
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => ["127.0.0.1", "10.0.0.0/24"],
  'maxretry' => 10,
  'findtime' => 60,
  'bantime' => 3600
}

# LDAP (disabled for now)
gitlab_rails['ldap_enabled'] = false

# Time zone
gitlab_rails['time_zone'] = 'UTC'

# Git configuration
gitlab_rails['gitlab_default_projects_features_issues'] = true
gitlab_rails['gitlab_default_projects_features_merge_requests'] = true
gitlab_rails['gitlab_default_projects_features_wiki'] = true
gitlab_rails['gitlab_default_projects_features_snippets'] = true
gitlab_rails['gitlab_default_projects_features_builds'] = true
gitlab_rails['gitlab_default_projects_features_container_registry'] = true

# Package registry
gitlab_rails['packages_enabled'] = true

# Dependency proxy
gitlab_rails['dependency_proxy_enabled'] = true

# Usage ping (disabled for privacy)
gitlab_rails['usage_ping_enabled'] = false

# SSH settings
gitlab_shell['custom_hooks_dir'] = "/opt/gitlab/embedded/service/gitlab-shell/hooks"

# Logging
logging['logrotate_frequency'] = "daily"
logging['logrotate_size'] = "200MB"
logging['logrotate_rotate'] = 30

# Custom settings for production
nginx['worker_processes'] = 2
nginx['worker_connections'] = 1024
EOF

# Generate self-signed SSL certificate for initial setup
log "🔐 Generating self-signed SSL certificate..."
mkdir -p /etc/ssl/certs /etc/ssl/private

openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/ssl/private/gitlab.key \
    -out /etc/ssl/certs/gitlab.crt \
    -subj "/C=US/ST=State/L=City/O=XCloud/OU=IT/CN=gitlab.xcloud.local/emailAddress=admin@xcloud.local" \
    -addext "subjectAltName=DNS:gitlab.xcloud.local,DNS:$PUBLIC_IP,IP:$PUBLIC_IP,IP:$PRIVATE_IP"

chmod 600 /etc/ssl/private/gitlab.key
chmod 644 /etc/ssl/certs/gitlab.crt

# Reconfigure GitLab
log "🔄 Reconfiguring GitLab (this may take several minutes)..."
gitlab-ctl reconfigure

# Start GitLab services
log "🚀 Starting GitLab services..."
gitlab-ctl restart

# Wait for services to be ready
log "⏳ Waiting for GitLab services to be ready..."
timeout 300 bash -c 'until gitlab-ctl status | grep -q "run: "; do sleep 10; echo "Waiting for GitLab..."; done'

# Get initial root password
log "🔑 Retrieving initial root password..."
if [ -f /etc/gitlab/initial_root_password ]; then
    INITIAL_PASSWORD=$(grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')
    echo "Initial root password: $INITIAL_PASSWORD" > /root/gitlab_initial_password.txt
    chmod 600 /root/gitlab_initial_password.txt
    success "Initial root password saved to /root/gitlab_initial_password.txt"
fi

# Configure GitLab SSH
log "🔧 Configuring GitLab SSH..."
mkdir -p /var/opt/gitlab/.ssh
touch /var/opt/gitlab/.ssh/authorized_keys
chmod 700 /var/opt/gitlab/.ssh
chmod 600 /var/opt/gitlab/.ssh/authorized_keys
chown -R git:git /var/opt/gitlab/.ssh

# Configure SSH for GitLab on port 2222
cat >> /etc/ssh/sshd_config << 'EOF'

# GitLab SSH configuration
Match User git
    Port 2222
    PasswordAuthentication no
    PubkeyAuthentication yes
    AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
    AuthorizedKeysCommandUser git
EOF

# Add SSH port to firewall
ufw allow 2222/tcp comment 'GitLab SSH'

# Restart SSH service
systemctl restart sshd

# Create health check script
log "📊 Creating health check script..."
cat > /usr/local/bin/gitlab-health-check.sh << 'EOF'
#!/bin/bash
# GitLab health check script

echo "🏥 GitLab Health Check"
echo "====================="

# Check GitLab services
echo -e "\n🔧 GitLab Services:"
gitlab-ctl status

# Check web interface
echo -e "\n🌐 Web Interface Check:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|302"; then
    echo "✅ Web interface: OK"
else
    echo "❌ Web interface: FAILED"
fi

# Check SSH
echo -e "\n🔑 SSH Check:"
if ss -tuln | grep -q ":2222"; then
    echo "✅ GitLab SSH (port 2222): OK"
else
    echo "❌ GitLab SSH (port 2222): FAILED"
fi

# Check disk space
echo -e "\n💿 Disk Space:"
df -h | grep -E "(Filesystem|/dev/)"

# Check memory usage
echo -e "\n💾 Memory Usage:"
free -h

# Check recent logs
echo -e "\n📝 Recent GitLab Logs (last 10 lines):"
gitlab-ctl tail gitlab-rails/production.log 2>/dev/null | tail -10 || echo "No logs available"
EOF

chmod +x /usr/local/bin/gitlab-health-check.sh

# Create backup script
log "💾 Creating backup script..."
cat > /usr/local/bin/gitlab-backup.sh << 'EOF'
#!/bin/bash
# GitLab backup script

BACKUP_DIR="/var/opt/gitlab/backups"
LOG_FILE="/var/log/gitlab-backup.log"

echo "$(date): Starting GitLab backup" | tee -a $LOG_FILE

# Create GitLab backup
gitlab-backup create CRON=1 2>&1 | tee -a $LOG_FILE

# Remove old backups (keep last 7 days)
find $BACKUP_DIR -name "*_gitlab_backup.tar" -mtime +7 -delete 2>&1 | tee -a $LOG_FILE

echo "$(date): GitLab backup completed" | tee -a $LOG_FILE

# Send backup status (implement notification here if needed)
EOF

chmod +x /usr/local/bin/gitlab-backup.sh

# Add backup cron job
log "⏰ Setting up backup cron job..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/gitlab-backup.sh") | crontab -

# Configure log rotation
log "📄 Configuring log rotation..."
cat > /etc/logrotate.d/gitlab-backup << 'EOF'
/var/log/gitlab-backup.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    copytruncate
}
EOF

# Test GitLab configuration
log "🧪 Testing GitLab configuration..."
gitlab-ctl configtest

# Display installation summary
log "📋 GitLab Installation Summary"
echo "================================"
echo "GitLab URL: $GITLAB_EXTERNAL_URL"
echo "GitLab SSH: git@$PUBLIC_IP:$GITLAB_SSH_PORT"
echo "Registry URL: https://$PUBLIC_IP:5050"
echo "Initial root password: /root/gitlab_initial_password.txt"
echo ""
echo "🔧 Useful commands:"
echo "  gitlab-ctl status          - Check service status"
echo "  gitlab-ctl restart         - Restart all services"
echo "  gitlab-ctl tail             - View logs"
echo "  gitlab-health-check.sh      - Run health check"
echo "  gitlab-backup.sh            - Manual backup"
echo ""

success "✅ GitLab CE installation completed successfully!"

# Final health check
log "🏥 Running initial health check..."
sleep 10
/usr/local/bin/gitlab-health-check.sh

warning "⚠️ Important: Change the initial root password after first login!"
warning "⚠️ Configure Let's Encrypt SSL in production using setup-ssl.sh"

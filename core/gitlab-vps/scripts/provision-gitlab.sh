#!/bin/bash
# provision-gitlab.sh - Main provisioning script for GitLab VPS
# File: /opt/xcloud/vps-hosting-infrastructure/core/gitlab-vps/scripts/provision-gitlab.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOSTNAME="gitlab-vps"
PUBLIC_IP="136.243.208.130"
PRIVATE_IP="10.0.0.10"
GITLAB_DOMAIN="gitlab.xcloud.local"

# Logging function
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

log "🚀 Starting GitLab VPS provisioning..."

# Update system
log "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get upgrade -y -q

# Install basic packages
log "📦 Installing basic packages..."
apt-get install -y \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    net-tools \
    dnsutils \
    git \
    vim \
    tree \
    rsync \
    unzip \
    jq \
    openssl

# Configure hostname
log "🏷️ Configuring hostname..."
hostnamectl set-hostname "$HOSTNAME"
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
echo "$PUBLIC_IP $GITLAB_DOMAIN" >> /etc/hosts
echo "$PRIVATE_IP gitlab-vps.internal" >> /etc/hosts

# Configure network interfaces
log "🌐 Configuring network interfaces..."
cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - $PUBLIC_IP/29
      gateway4: 136.243.208.129
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 1.1.1.1
        search:
          - xcloud.local
    eth1:
      dhcp4: false
      addresses:
        - $PRIVATE_IP/24
EOF

# Apply network configuration
netplan apply
sleep 5

# Configure UFW firewall
log "🔥 Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow ssh comment 'SSH access'

# Allow HTTP/HTTPS for GitLab
ufw allow 80/tcp comment 'HTTP GitLab web'
ufw allow 443/tcp comment 'HTTPS GitLab web'

# Allow GitLab SSH (custom port)
ufw allow 2222/tcp comment 'GitLab SSH'

# Allow Container Registry
ufw allow 5050/tcp comment 'Docker Registry'

# Allow private network
ufw allow from 10.0.0.0/24 comment 'Private network'

# Enable UFW
ufw --force enable

# Configure SSH hardening
log "🔐 Configuring SSH hardening..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat > /etc/ssh/sshd_config << 'EOF'
# SSH Configuration for GitLab VPS
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Security settings
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Network settings
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Rate limiting
MaxAuthTries 3
MaxStartups 10:30:100
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable weak algorithms
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
EOF

systemctl restart sshd

# Configure Fail2Ban
log "🛡️ Configuring Fail2Ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log

[gitlab]
enabled = true
port = http,https
filter = gitlab
logpath = /var/log/gitlab/gitlab-rails/application.log
maxretry = 5
bantime = 1800
findtime = 300
EOF

# Create GitLab filter for Fail2Ban
mkdir -p /etc/fail2ban/filter.d
cat > /etc/fail2ban/filter.d/gitlab.conf << 'EOF'
[Definition]
failregex = Started POST "/users/sign_in".*IP: <HOST>
            Started POST "/users/password".*IP: <HOST>
            \[INFO\].*IP: <HOST>.*Failed Login
ignoreregex =
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Install Docker (required for GitLab Runner)
log "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -q
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Configure Docker
usermod -aG docker vagrant 2>/dev/null || true
systemctl enable docker
systemctl start docker

# Install Docker Compose
log "🐳 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.21.0"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create GitLab directories
log "📁 Creating GitLab directories..."
mkdir -p /etc/gitlab
mkdir -p /var/opt/gitlab
mkdir -p /var/log/gitlab
mkdir -p /opt/gitlab/embedded/service/gitlab-rails/
mkdir -p /var/opt/gitlab/backups
mkdir -p /etc/ssl/certs
mkdir -p /etc/ssl/private

# Set proper permissions
chmod 700 /etc/ssl/private
chmod 755 /etc/ssl/certs
chmod 700 /var/opt/gitlab/backups

# Configure automatic security updates
log "🔄 Configuring automatic security updates..."
apt-get install -y unattended-upgrades apt-listchanges

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Configure system limits for GitLab
log "⚙️ Configuring system limits..."
cat >> /etc/security/limits.conf << 'EOF'

# GitLab system limits
*               soft    nofile          65536
*               hard    nofile          65536
*               soft    nproc           65536
*               hard    nproc           65536
git             soft    nofile          65536
git             hard    nofile          65536
EOF

# Configure sysctl for GitLab
cat > /etc/sysctl.d/90-gitlab.conf << 'EOF'
# GitLab performance tuning
kernel.shmmax = 17179869184
kernel.shmall = 4194304
kernel.sem = 250 32000 100 128
fs.file-max = 65536
vm.swappiness = 10
vm.overcommit_memory = 2
vm.overcommit_ratio = 80
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
EOF

sysctl -p /etc/sysctl.d/90-gitlab.conf

# Configure timezone
log "🕐 Configuring timezone..."
timedatectl set-timezone UTC

# Configure NTP
log "🕐 Configuring NTP..."
apt-get install -y chrony

cat > /etc/chrony/chrony.conf << 'EOF'
# NTP servers
pool 0.ubuntu.pool.ntp.org iburst
pool 1.ubuntu.pool.ntp.org iburst
pool 2.ubuntu.pool.ntp.org iburst
pool 3.ubuntu.pool.ntp.org iburst

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can't be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3
EOF

systemctl enable chrony
systemctl start chrony

# Create monitoring script
log "📊 Creating monitoring script..."
cat > /usr/local/bin/gitlab-monitor.sh << 'EOF'
#!/bin/bash
# GitLab monitoring script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 GitLab VPS System Status"
echo "=========================="

# System info
echo -e "\n📊 System Information:"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

# Memory usage
echo -e "\n💾 Memory Usage:"
free -h

# Disk usage
echo -e "\n💿 Disk Usage:"
df -h | grep -E "^(/dev/|Filesystem)"

# Network status
echo -e "\n🌐 Network Status:"
ip addr show | grep -E "(eth0|eth1)" -A 3

# GitLab services (if installed)
if command -v gitlab-ctl &> /dev/null; then
    echo -e "\n🦊 GitLab Services:"
    gitlab-ctl status
fi

# Docker status
if systemctl is-active --quiet docker; then
    echo -e "\n🐳 Docker Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

# Security status
echo -e "\n🔒 Security Status:"
ufw status | head -10
systemctl is-active fail2ban && echo -e "${GREEN}Fail2Ban: Active${NC}" || echo -e "${RED}Fail2Ban: Inactive${NC}"
EOF

chmod +x /usr/local/bin/gitlab-monitor.sh

# Create MOTD
log "📢 Creating MOTD..."
cat > /etc/motd << 'EOF'

███████╗██╗████████╗██╗      █████╗ ██████╗     ██╗   ██╗██████╗ ███████╗
██╔════╝██║╚══██╔══╝██║     ██╔══██╗██╔══██╗    ██║   ██║██╔══██╗██╔════╝
██║  ███║██║   ██║   ██║     ███████║██████╔╝    ██║   ██║██████╔╝███████╗
██║   ██║██║   ██║   ██║     ██╔══██║██╔══██╗    ╚██╗ ██╔╝██╔═══╝ ╚════██║
╚██████╔╝██║   ██║   ███████╗██║  ██║██████╔╝     ╚████╔╝ ██║     ███████║
 ╚═════╝ ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═════╝       ╚═══╝  ╚═╝     ╚══════╝

🌐 GitLab VPS Production Environment
📍 IP: 136.243.208.130 | 🔗 Private: 10.0.0.10
💻 Resources: 4GB RAM | 2 CPU | 100GB Storage

🔧 Quick Commands:
  sudo gitlab-ctl status     - Check GitLab services
  sudo gitlab-ctl tail       - View GitLab logs
  gitlab-monitor.sh          - System status
  docker ps                  - Docker containers

📚 Documentation: /vagrant/README.md

EOF

success "✅ GitLab VPS basic provisioning completed!"
log "📝 Next steps: Run install-gitlab.sh to install GitLab"

# Clean up
apt-get autoremove -y
apt-get autoclean

log "🎉 Provisioning completed successfully!"

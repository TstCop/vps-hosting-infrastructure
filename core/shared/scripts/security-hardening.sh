#!/bin/bash

# Common Security Hardening Script
# Applies security configurations across all VPS instances

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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

log "🔒 Starting security hardening..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Get server information
HOSTNAME=$(hostname)
CURRENT_USER=${SUDO_USER:-$USER}

log "📊 System Information:"
echo "Hostname: $HOSTNAME"
echo "User: $CURRENT_USER"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"

# Update system packages
log "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install security packages
log "🛡️ Installing security packages..."
apt-get install -y \
    ufw \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis \
    aide \
    acct \
    psacct \
    auditd \
    apparmor \
    apparmor-utils \
    unattended-upgrades \
    apt-listchanges

# Configure automatic security updates
log "🔄 Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF

# SSH hardening
log "🔐 Hardening SSH configuration..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Create hardened SSH config
cat > /etc/ssh/sshd_config << 'EOF'
# SSH Configuration - Security Hardened

# Basic settings
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
AuthenticationMethods publickey
MaxAuthTries 3
MaxSessions 10
MaxStartups 10:30:100

# User restrictions
AllowUsers vagrant appuser
DenyUsers root

# Security settings
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Crypto
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Banner
Banner /etc/ssh/banner.txt
EOF

# Create SSH banner
cat > /etc/ssh/banner.txt << 'EOF'
***************************************************************************
                       AUTHORIZED ACCESS ONLY
***************************************************************************

This system is for the use of authorized users only. Individuals using
this computer system without authority, or in excess of their authority,
are subject to having all of their activities on this system monitored
and recorded by system personnel.

In the course of monitoring individuals improperly using this system, or
in the course of system maintenance, the activities of authorized users
may also be monitored.

Anyone using this system expressly consents to such monitoring and is
advised that if such monitoring reveals possible evidence of criminal
activity, system personnel may provide the evidence to law enforcement
officials.

***************************************************************************
EOF

# Kernel security parameters
log "⚙️ Configuring kernel security parameters..."
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# Kernel security configuration

# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# IPv6 security (disable if not needed)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Memory protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.exec-shield = 1
kernel.randomize_va_space = 2

# File system security
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Process security
kernel.core_uses_pid = 1
kernel.ctrl-alt-del = 0
EOF

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-security.conf

# Configure firewall (UFW)
log "🔥 Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp comment 'SSH'

# Allow HTTP/HTTPS (will be configured per server)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Allow private network communication
ufw allow from 10.0.0.0/24 comment 'Private network'

# Enable logging
ufw logging on

# Enable firewall
ufw --force enable

# Configure fail2ban
log "🛡️ Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd
destemail = admin@vps.local
sendername = Fail2Ban
mta = sendmail
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[apache-auth]
enabled = false

[apache-badbots]
enabled = false

[apache-noscript]
enabled = false

[apache-overflows]
enabled = false

[apache-nohome]
enabled = false

[apache-botsearch]
enabled = false

[php-url-fopen]
enabled = false

[nginx-http-auth]
enabled = false
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 6

[nginx-limit-req]
enabled = false
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10

[postfix]
enabled = false

[couriersmtp]
enabled = false

[courierauth]
enabled = false

[postfix-sasl]
enabled = false

[dovecot]
enabled = false

[asterisk]
enabled = false

[freeswitch]
enabled = false
EOF

# File system security
log "📁 Configuring file system security..."

# Set file permissions
chmod 700 /root
chmod 700 /home/*/
chmod 644 /etc/passwd
chmod 640 /etc/shadow
chmod 644 /etc/group
chmod 640 /etc/gshadow

# Remove unnecessary SUID binaries
log "🔧 Removing unnecessary SUID binaries..."
for binary in /usr/bin/at /usr/bin/wall /usr/bin/write /usr/bin/chfn /usr/bin/chsh /usr/bin/newgrp; do
    if [ -f "$binary" ]; then
        chmod u-s "$binary" 2>/dev/null || true
    fi
done

# Configure log monitoring
log "📝 Configuring log monitoring..."
cat > /etc/logrotate.d/security << 'EOF'
/var/log/auth.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}

/var/log/fail2ban.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    postrotate
        /bin/systemctl reload fail2ban > /dev/null 2>&1 || true
    endscript
}
EOF

# Configure audit system
log "📊 Configuring audit system..."
cat > /etc/audit/rules.d/security.rules << 'EOF'
# Security audit rules

# Monitor authentication events
-w /etc/passwd -p wa -k auth
-w /etc/group -p wa -k auth
-w /etc/shadow -p wa -k auth
-w /etc/gshadow -p wa -k auth
-w /etc/sudoers -p wa -k auth
-w /etc/sudoers.d/ -p wa -k auth

# Monitor SSH configuration
-w /etc/ssh/sshd_config -p wa -k ssh

# Monitor system configuration
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
-w /etc/resolv.conf -p wa -k network

# Monitor critical files
-w /etc/crontab -p wa -k cron
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron

# Monitor privileged commands
-a always,exit -F arch=b64 -S execve -F euid=0 -k privileged
-a always,exit -F arch=b32 -S execve -F euid=0 -k privileged

# Monitor file deletions
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete

# Monitor network connections
-a always,exit -F arch=b64 -S socket -F a0=10 -k network
-a always,exit -F arch=b32 -S socket -F a0=10 -k network
EOF

# Create security monitoring script
log "🔍 Creating security monitoring script..."
cat > /opt/security-monitor.sh << 'EOF'
#!/bin/bash

# Security Monitoring Script
# Performs regular security checks and reports

LOGFILE="/var/log/security-monitor.log"
ALERT_EMAIL="admin@vps.local"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Check for rootkits
check_rootkits() {
    log "Checking for rootkits..."

    # Run rkhunter
    rkhunter --update --quiet
    if rkhunter --check --quiet --report-warnings-only; then
        log "✅ No rootkits detected by rkhunter"
    else
        log "⚠️ Potential rootkit detected by rkhunter"
    fi

    # Run chkrootkit
    if chkrootkit -q; then
        log "✅ No rootkits detected by chkrootkit"
    else
        log "⚠️ Potential rootkit detected by chkrootkit"
    fi
}

# Check for suspicious processes
check_processes() {
    log "Checking for suspicious processes..."

    # Check for processes running as root
    ROOT_PROCS=$(ps aux | awk '$1 == "root" && $11 !~ /^\[/ {count++} END {print count+0}')
    log "Root processes: $ROOT_PROCS"

    # Check for network connections
    CONNECTIONS=$(netstat -tuln | grep LISTEN | wc -l)
    log "Listening ports: $CONNECTIONS"

    # Check for failed login attempts
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | tail -20 | wc -l)
    if [ "$FAILED_LOGINS" -gt 10 ]; then
        log "⚠️ High number of failed login attempts: $FAILED_LOGINS"
    else
        log "✅ Failed login attempts: $FAILED_LOGINS"
    fi
}

# Check file integrity
check_integrity() {
    log "Checking file integrity..."

    # Initialize AIDE if needed
    if [ ! -f "/var/lib/aide/aide.db" ]; then
        log "Initializing AIDE database..."
        aide --init
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi

    # Check file integrity
    if aide --check; then
        log "✅ File integrity check passed"
    else
        log "⚠️ File integrity check failed - files may have been modified"
    fi
}

# Check system updates
check_updates() {
    log "Checking for system updates..."

    apt-get update -qq
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

    if [ "$UPDATES" -gt 0 ]; then
        log "⚠️ $UPDATES package updates available"
    else
        log "✅ System is up to date"
    fi

    # Check for security updates
    SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c security)
    if [ "$SECURITY_UPDATES" -gt 0 ]; then
        log "🚨 $SECURITY_UPDATES security updates available - please apply immediately"
    fi
}

# Main monitoring function
main() {
    log "Starting security monitoring..."

    check_rootkits
    check_processes
    check_integrity
    check_updates

    log "Security monitoring completed"
}

main
EOF

chmod +x /opt/security-monitor.sh

# Setup security monitoring cron job
log "⏰ Setting up security monitoring cron job..."
cat > /etc/cron.d/security-monitor << 'EOF'
# Security monitoring cron job
0 2 * * * root /opt/security-monitor.sh
EOF

# Configure AppArmor
log "🛡️ Configuring AppArmor..."
systemctl enable apparmor
systemctl start apparmor

# Load AppArmor profiles
aa-enforce /etc/apparmor.d/*

# Install additional security tools
log "🔧 Installing additional security tools..."
apt-get install -y \
    clamav \
    clamav-daemon \
    clamav-freshclam \
    tripwire \
    tiger \
    debsums

# Update ClamAV definitions
log "🦠 Updating antivirus definitions..."
freshclam || true

# Enable and start services
log "🔄 Enabling and starting security services..."
systemctl enable ufw
systemctl enable fail2ban
systemctl enable auditd
systemctl enable apparmor
systemctl enable unattended-upgrades

systemctl start ufw
systemctl start fail2ban
systemctl start auditd
systemctl start apparmor

# Restart SSH with new configuration
systemctl restart ssh

# Create security report
log "📊 Creating security report..."
cat > /root/security-report.txt << EOF
Security Hardening Report
========================
Date: $(date)
Hostname: $HOSTNAME
User: $CURRENT_USER

Services Enabled:
- UFW Firewall: $(systemctl is-active ufw)
- Fail2ban: $(systemctl is-active fail2ban)
- Auditd: $(systemctl is-active auditd)
- AppArmor: $(systemctl is-active apparmor)
- Unattended Upgrades: $(systemctl is-active unattended-upgrades)

SSH Configuration:
- Root login disabled
- Password authentication disabled
- Key-based authentication only
- Connection limits configured

Firewall Rules:
$(ufw status numbered)

Kernel Security Parameters:
$(sysctl net.ipv4.ip_forward net.ipv4.conf.all.send_redirects kernel.randomize_va_space)

Next Steps:
1. Review and customize fail2ban configuration
2. Set up log monitoring and alerting
3. Configure intrusion detection system
4. Schedule regular security audits
5. Set up automated vulnerability scanning

EOF

# Display summary
log "📋 Security Hardening Summary:"
echo "======================================"
echo "✅ System packages updated"
echo "✅ SSH hardened"
echo "✅ Firewall configured"
echo "✅ Fail2ban enabled"
echo "✅ Kernel security parameters set"
echo "✅ File permissions hardened"
echo "✅ Audit system configured"
echo "✅ Security monitoring enabled"
echo "✅ AppArmor configured"
echo "✅ Automatic updates enabled"
echo ""
echo "🔍 Security Tools Installed:"
echo "  - rkhunter (rootkit detection)"
echo "  - chkrootkit (rootkit detection)"
echo "  - lynis (security auditing)"
echo "  - aide (file integrity)"
echo "  - clamav (antivirus)"
echo "  - tripwire (file integrity)"
echo ""
echo "📊 Security Report: /root/security-report.txt"
echo "📝 Security Monitor: /opt/security-monitor.sh"
echo "📋 Monitor Logs: /var/log/security-monitor.log"
echo "======================================"

log "✅ Security hardening completed successfully!"
log "🔒 System is now hardened according to security best practices"
log "⚠️ Please review the security report and customize settings as needed"

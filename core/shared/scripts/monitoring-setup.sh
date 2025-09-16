#!/bin/bash

# Infrastructure Monitoring Setup Script
# Configures comprehensive monitoring for VPS infrastructure

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

log "📊 Starting infrastructure monitoring setup..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Install monitoring packages
log "📦 Installing monitoring packages..."
apt-get update
apt-get install -y \
    htop \
    iotop \
    iftop \
    nethogs \
    nload \
    vnstat \
    sysstat \
    lsof \
    strace \
    tcpdump \
    wireshark-common \
    prometheus-node-exporter \
    collectd \
    collectd-utils

# Install Netdata
log "📊 Installing Netdata..."
if ! command -v netdata &> /dev/null; then
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --disable-telemetry
fi

# Configure Netdata
log "⚙️ Configuring Netdata..."
HOSTNAME=$(hostname)
cp /opt/xcloud/vps-hosting-infrastructure/core/shared/monitoring/netdata.conf /etc/netdata/netdata.conf
sed -i "s/__HOSTNAME__/$HOSTNAME/g" /etc/netdata/netdata.conf

# Create Netdata application groups
cat > /etc/netdata/apps_groups.conf << 'EOF'
# VPS Infrastructure Application Groups

# System processes
system: systemd* init* kernel* kthread* ksoftirq* migration* rcu_* watchdog*

# Web servers
nginx: nginx*
apache: apache* httpd*

# Databases
postgresql: postgres* postmaster*
mysql: mysql* mysqld*
redis: redis*

# Application servers
nodejs: node* npm*
python: python*
docker: docker* containerd* runc*

# GitLab processes
gitlab: gitlab* gitlab-* sidekiq* gitaly* gitlab-runner*
gitaly: gitaly*
sidekiq: sidekiq*

# Monitoring
monitoring: netdata* prometheus* grafana* alertmanager*

# Security
security: fail2ban* aide* rkhunter* clamav*

# Network
network: ssh* sshd*

# Backup
backup: rsync* tar* gzip* backup*

# Mail
mail: postfix* dovecot* sendmail*

# Other
other: *
EOF

# Configure Node Exporter
log "🔧 Configuring Node Exporter..."
cat > /etc/default/prometheus-node-exporter << 'EOF'
# Node Exporter configuration
ARGS="--web.listen-address=127.0.0.1:9100 --collector.systemd --collector.processes --collector.interrupts"
EOF

systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter

# Create monitoring dashboard script
log "🖥️ Creating monitoring dashboard..."
cat > /opt/monitoring-dashboard.sh << 'EOF'
#!/bin/bash

# Monitoring Dashboard Script
# Displays real-time system metrics

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Clear screen
clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    VPS Infrastructure Monitor                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# System information
echo -e "${GREEN}📊 System Information:${NC}"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Users: $(who | wc -l) logged in"
echo ""

# CPU usage
echo -e "${GREEN}💻 CPU Usage:${NC}"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
echo "CPU Usage: ${cpu_usage}%"
echo ""

# Memory usage
echo -e "${GREEN}🧠 Memory Usage:${NC}"
free -h | grep -E "Mem|Swap"
echo ""

# Disk usage
echo -e "${GREEN}💾 Disk Usage:${NC}"
df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev'
echo ""

# Network interfaces
echo -e "${GREEN}🌐 Network Interfaces:${NC}"
ip -brief addr show | grep -v lo
echo ""

# Active connections
echo -e "${GREEN}🔗 Network Connections:${NC}"
echo "Active connections: $(netstat -tuln | grep LISTEN | wc -l)"
echo "TCP connections: $(netstat -tn | grep ESTABLISHED | wc -l)"
echo ""

# Top processes
echo -e "${GREEN}🔄 Top Processes:${NC}"
ps aux --sort=-%cpu | head -6
echo ""

# Services status
echo -e "${GREEN}🔧 Service Status:${NC}"
services=("nginx" "postgresql" "redis" "docker" "netdata" "fail2ban" "ufw")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "  ✅ $service: ${GREEN}Active${NC}"
    else
        echo -e "  ❌ $service: ${RED}Inactive${NC}"
    fi
done
echo ""

# Quick system health check
echo -e "${GREEN}🏥 Health Check:${NC}"

# Check disk space
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 80 ]; then
    echo -e "  ⚠️  Disk usage: ${YELLOW}${disk_usage}%${NC}"
else
    echo -e "  ✅ Disk usage: ${GREEN}${disk_usage}%${NC}"
fi

# Check memory usage
mem_usage=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
mem_usage_int=${mem_usage%.*}
if [ "$mem_usage_int" -gt 80 ]; then
    echo -e "  ⚠️  Memory usage: ${YELLOW}${mem_usage}%${NC}"
else
    echo -e "  ✅ Memory usage: ${GREEN}${mem_usage}%${NC}"
fi

# Check load average
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
cpu_cores=$(nproc)
if (( $(echo "$load_avg > $cpu_cores" | bc -l) )); then
    echo -e "  ⚠️  Load average: ${YELLOW}${load_avg}${NC}"
else
    echo -e "  ✅ Load average: ${GREEN}${load_avg}${NC}"
fi

echo ""
echo -e "${BLUE}Last updated: $(date)${NC}"
echo "Press Ctrl+C to exit, or run 'watch -n 5 /opt/monitoring-dashboard.sh' for auto-refresh"
EOF

chmod +x /opt/monitoring-dashboard.sh

# Create system health check script
log "🏥 Creating system health check script..."
cat > /opt/health-check.sh << 'EOF'
#!/bin/bash

# System Health Check Script
# Comprehensive health monitoring for VPS infrastructure

LOGFILE="/var/log/health-check.log"
ALERT_THRESHOLD_DISK=85
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_LOAD=4.0

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Check disk usage
check_disk_usage() {
    log "Checking disk usage..."

    while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        partition=$(echo "$line" | awk '{print $6}')

        if [ "$usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
            log "⚠️ WARNING: Disk usage on $partition is ${usage}%"
        else
            log "✅ Disk usage on $partition: ${usage}%"
        fi
    done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev' | awk '$5 != "0%"')
}

# Check memory usage
check_memory_usage() {
    log "Checking memory usage..."

    memory_usage=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
    memory_usage_int=${memory_usage%.*}

    if [ "$memory_usage_int" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        log "⚠️ WARNING: Memory usage is ${memory_usage}%"
    else
        log "✅ Memory usage: ${memory_usage}%"
    fi

    # Check swap usage
    swap_usage=$(free | grep '^Swap:' | awk '{if ($2 > 0) printf "%.1f", $3/$2 * 100.0; else print "0"}')
    if (( $(echo "$swap_usage > 50.0" | bc -l) )); then
        log "⚠️ WARNING: Swap usage is ${swap_usage}%"
    else
        log "✅ Swap usage: ${swap_usage}%"
    fi
}

# Check CPU and load average
check_cpu_load() {
    log "Checking CPU and load average..."

    # Load average
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    cpu_cores=$(nproc)

    if (( $(echo "$load_avg > $ALERT_THRESHOLD_LOAD" | bc -l) )); then
        log "⚠️ WARNING: Load average is $load_avg (CPUs: $cpu_cores)"
    else
        log "✅ Load average: $load_avg (CPUs: $cpu_cores)"
    fi

    # CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    log "CPU usage: ${cpu_usage}%"
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."

    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Internet connectivity: OK"
    else
        log "❌ Internet connectivity: FAILED"
    fi

    # Check private network
    if ping -c 1 10.0.0.1 >/dev/null 2>&1; then
        log "✅ Private network: OK"
    else
        log "❌ Private network: FAILED"
    fi

    # Check inter-VPS connectivity
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" == *"gitlab"* ]]; then
        target_ip="10.0.0.20"
        target_name="nginx-app-vps"
    else
        target_ip="10.0.0.10"
        target_name="gitlab-vps"
    fi

    if ping -c 1 "$target_ip" >/dev/null 2>&1; then
        log "✅ $target_name connectivity: OK"
    else
        log "❌ $target_name connectivity: FAILED"
    fi
}

# Check critical services
check_services() {
    log "Checking critical services..."

    # Define services based on hostname
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" == *"gitlab"* ]]; then
        services=("postgresql" "redis" "gitlab-runsvdir" "netdata" "fail2ban" "ufw")
    else
        services=("nginx" "netdata" "fail2ban" "ufw")
    fi

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "✅ $service: Active"
        else
            log "❌ $service: Inactive"
        fi
    done
}

# Check file system
check_filesystem() {
    log "Checking file system..."

    # Check for read-only file systems
    if mount | grep -q "ro,"; then
        log "⚠️ WARNING: Read-only file systems detected"
        mount | grep "ro,"
    else
        log "✅ File systems: All writable"
    fi

    # Check inode usage
    df -i | awk 'NR>1 && $5 != "-" {
        usage = substr($5, 1, length($5)-1);
        if (usage > 85) print "⚠️ WARNING: Inode usage on " $6 " is " $5;
        else print "✅ Inode usage on " $6 ": " $5
    }' | while read -r line; do
        log "$line"
    done
}

# Check log files
check_logs() {
    log "Checking log files..."

    # Check for large log files
    find /var/log -name "*.log" -size +100M 2>/dev/null | while read -r file; do
        size=$(du -h "$file" | cut -f1)
        log "⚠️ Large log file: $file ($size)"
    done

    # Check for disk space in /var/log
    log_usage=$(df /var/log | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$log_usage" -gt 80 ]; then
        log "⚠️ WARNING: /var/log disk usage is ${log_usage}%"
    else
        log "✅ /var/log disk usage: ${log_usage}%"
    fi
}

# Check security
check_security() {
    log "Checking security status..."

    # Check for failed login attempts
    failed_logins=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
    if [ "$failed_logins" -gt 10 ]; then
        log "⚠️ WARNING: $failed_logins failed login attempts today"
    else
        log "✅ Failed login attempts today: $failed_logins"
    fi

    # Check firewall status
    if ufw status | grep -q "Status: active"; then
        log "✅ Firewall: Active"
    else
        log "❌ Firewall: Inactive"
    fi

    # Check fail2ban status
    if systemctl is-active --quiet fail2ban; then
        banned_ips=$(fail2ban-client status | grep "Jail list" | awk -F: '{print $2}' | xargs -n1 fail2ban-client status | grep "Currently banned" | awk '{sum+=$4} END {print sum+0}')
        log "✅ Fail2ban: Active (${banned_ips} IPs banned)"
    else
        log "❌ Fail2ban: Inactive"
    fi
}

# Main health check function
main() {
    log "🏥 Starting comprehensive health check..."

    check_disk_usage
    check_memory_usage
    check_cpu_load
    check_network
    check_services
    check_filesystem
    check_logs
    check_security

    log "✅ Health check completed"
}

main
EOF

chmod +x /opt/health-check.sh

# Create alert notification script
log "📢 Creating alert notification script..."
cat > /opt/netdata-alarm.sh << 'EOF'
#!/bin/bash

# Netdata Alert Script
# Handles alerts from Netdata monitoring

# Alert parameters (passed by Netdata)
HOSTNAME="$1"
UNIQUE_ID="$2"
ALARM_ID="$3"
ALARM_EVENT_ID="$4"
WHEN="$5"
NAME="$6"
CHART="$7"
FAMILY="$8"
STATUS="$9"
OLD_STATUS="${10}"
VALUE="${11}"
OLD_VALUE="${12}"
SRC="${13}"
DURATION="${14}"
NON_CLEAR_DURATION="${15}"
UNITS="${16}"
INFO="${17}"

LOGFILE="/var/log/netdata-alerts.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Format alert message
format_alert() {
    cat << ALERT_EOF
🚨 NETDATA ALERT 🚨

Host: $HOSTNAME
Alert: $NAME
Status: $STATUS (was: $OLD_STATUS)
Value: $VALUE $UNITS (was: $OLD_VALUE $UNITS)
Chart: $CHART
Family: $FAMILY
Duration: $DURATION seconds
Info: $INFO

Time: $(date -d "@$WHEN")
Alert ID: $UNIQUE_ID
ALERT_EOF
}

# Log the alert
log "Alert received: $NAME on $HOSTNAME - Status: $STATUS"

# Handle different alert types
case "$STATUS" in
    "CRITICAL")
        log "🚨 CRITICAL ALERT: $NAME"
        format_alert
        ;;
    "WARNING")
        log "⚠️ WARNING ALERT: $NAME"
        format_alert
        ;;
    "CLEAR")
        log "✅ ALERT CLEARED: $NAME"
        ;;
    *)
        log "ℹ️ ALERT INFO: $NAME - Status: $STATUS"
        ;;
esac

# Send to syslog
logger -t netdata-alert "[$STATUS] $NAME on $HOSTNAME: $VALUE $UNITS"

# You can add additional notification methods here:
# - Email notifications
# - Slack/Discord webhooks
# - SMS alerts
# - Custom integrations
EOF

chmod +x /opt/netdata-alarm.sh

# Configure collectd for additional metrics
log "📊 Configuring collectd..."
cat > /etc/collectd/collectd.conf << 'EOF'
# Collectd configuration for VPS infrastructure

Hostname "localhost"
FQDNLookup true
BaseDir "/var/lib/collectd"
PluginDir "/usr/lib/collectd"
TypesDB "/usr/share/collectd/types.db"

# Logging
LoadPlugin syslog
<Plugin syslog>
    LogLevel info
</Plugin>

# CPU monitoring
LoadPlugin cpu
<Plugin cpu>
    ReportByCpu true
    ReportByState true
    ValuesPercentage true
</Plugin>

# Memory monitoring
LoadPlugin memory
<Plugin memory>
    ValuesAbsolute true
    ValuesPercentage false
</Plugin>

# Disk monitoring
LoadPlugin disk
<Plugin disk>
    Disk "sda"
    Disk "vda"
    IgnoreSelected false
</Plugin>

# Network monitoring
LoadPlugin interface
<Plugin interface>
    Interface "enp1s0"
    Interface "enp2s0"
    IgnoreSelected false
</Plugin>

# Load average
LoadPlugin load

# Processes
LoadPlugin processes

# Network connections
LoadPlugin netlink
<Plugin netlink>
    Interface "enp1s0"
    Interface "enp2s0"
    VerboseInterface "enp1s0"
    VerboseInterface "enp2s0"
    QDisc "enp1s0"
    QDisc "enp2s0"
    Class "enp1s0"
    Class "enp2s0"
    Filter "enp1s0"
    Filter "enp2s0"
    IgnoreSelected false
</Plugin>

# Write to CSV files
LoadPlugin csv
<Plugin csv>
    DataDir "/var/lib/collectd/csv"
    StoreRates false
</Plugin>

# Write to RRD files
LoadPlugin rrdtool
<Plugin rrdtool>
    DataDir "/var/lib/collectd/rrd"
    CacheTimeout 120
    CacheFlush 900
    WritesPerSecond 30
</Plugin>
EOF

# Setup monitoring cron jobs
log "⏰ Setting up monitoring cron jobs..."

# Health check every 15 minutes
cat > /etc/cron.d/health-check << 'EOF'
# System health check
*/15 * * * * root /opt/health-check.sh
EOF

# Daily monitoring report
cat > /etc/cron.d/monitoring-report << 'EOF'
# Daily monitoring report
0 6 * * * root /opt/monitoring-dashboard.sh > /var/log/daily-report.log 2>&1
EOF

# Enable and start services
log "🔄 Enabling and starting monitoring services..."
systemctl enable netdata
systemctl enable prometheus-node-exporter
systemctl enable collectd

systemctl restart netdata
systemctl restart prometheus-node-exporter
systemctl restart collectd

# Create monitoring access control
log "🔐 Configuring monitoring access control..."
ufw allow from 10.0.0.0/24 to any port 19999 comment 'Netdata monitoring'
ufw allow from 127.0.0.1 to any port 9100 comment 'Node Exporter'

# Display monitoring summary
log "📋 Monitoring Setup Summary:"
echo "======================================"
echo "✅ Netdata: http://localhost:19999"
echo "✅ Node Exporter: http://localhost:9100"
echo "✅ System Dashboard: /opt/monitoring-dashboard.sh"
echo "✅ Health Check: /opt/health-check.sh"
echo ""
echo "📊 Monitoring Services:"
systemctl is-active netdata && echo "  ✅ Netdata: Active" || echo "  ❌ Netdata: Inactive"
systemctl is-active prometheus-node-exporter && echo "  ✅ Node Exporter: Active" || echo "  ❌ Node Exporter: Inactive"
systemctl is-active collectd && echo "  ✅ Collectd: Active" || echo "  ❌ Collectd: Inactive"
echo ""
echo "📝 Log Files:"
echo "  Health Check: /var/log/health-check.log"
echo "  Netdata Alerts: /var/log/netdata-alerts.log"
echo "  Daily Report: /var/log/daily-report.log"
echo ""
echo "⏰ Scheduled Tasks:"
echo "  Health Check: Every 15 minutes"
echo "  Daily Report: 6 AM daily"
echo "  Network Monitor: Every 10 minutes"
echo "======================================"

log "✅ Infrastructure monitoring setup completed successfully!"
log "📊 Access monitoring dashboard: /opt/monitoring-dashboard.sh"
log "🌐 Netdata web interface: http://localhost:19999"

#!/bin/bash

# Network Configuration Script
# Configures network settings for VPS infrastructure

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

# Function to show help
show_help() {
    echo "Network Configuration Script"
    echo ""
    echo "Usage: $0 [SERVER_TYPE]"
    echo ""
    echo "SERVER_TYPE:"
    echo "  gitlab-vps     Configure GitLab VPS network (136.243.208.130/10.0.0.10)"
    echo "  nginx-app-vps  Configure Nginx/App VPS network (136.243.208.131/10.0.0.20)"
    echo "  auto           Auto-detect server type"
    echo ""
    echo "Examples:"
    echo "  $0 gitlab-vps"
    echo "  $0 nginx-app-vps"
    echo "  $0 auto"
}

# Auto-detect server type
auto_detect_server() {
    HOSTNAME=$(hostname)

    case "$HOSTNAME" in
        *gitlab*)
            echo "gitlab-vps"
            ;;
        *nginx*|*app*)
            echo "nginx-app-vps"
            ;;
        *)
            warn "Could not auto-detect server type from hostname: $HOSTNAME"
            echo "unknown"
            ;;
    esac
}

# Configure network for GitLab VPS
configure_gitlab_network() {
    log "🌐 Configuring network for GitLab VPS..."

    PUBLIC_IP="136.243.208.130"
    PRIVATE_IP="10.0.0.10"
    HOSTNAME="gitlab-vps"

    configure_network_common "$PUBLIC_IP" "$PRIVATE_IP" "$HOSTNAME"
}

# Configure network for Nginx/App VPS
configure_nginx_network() {
    log "🌐 Configuring network for Nginx/App VPS..."

    PUBLIC_IP="136.243.208.131"
    PRIVATE_IP="10.0.0.20"
    HOSTNAME="nginx-app-vps"

    configure_network_common "$PUBLIC_IP" "$PRIVATE_IP" "$HOSTNAME"
}

# Common network configuration
configure_network_common() {
    local PUBLIC_IP="$1"
    local PRIVATE_IP="$2"
    local SERVER_HOSTNAME="$3"

    log "📊 Network Configuration:"
    echo "  Public IP: $PUBLIC_IP"
    echo "  Private IP: $PRIVATE_IP"
    echo "  Hostname: $SERVER_HOSTNAME"

    # Set hostname
    log "🏷️ Setting hostname..."
    hostnamectl set-hostname "$SERVER_HOSTNAME"

    # Configure /etc/hosts
    log "📝 Configuring /etc/hosts..."
    cat > /etc/hosts << EOF
127.0.0.1       localhost $SERVER_HOSTNAME
127.0.1.1       $SERVER_HOSTNAME.vps.local $SERVER_HOSTNAME

# Public network
136.243.208.130 gitlab-vps gitlab.vps.local registry.gitlab.vps.local
136.243.208.131 nginx-app-vps app.vps.local api.app.vps.local

# Private network
10.0.0.10       gitlab-vps-private
10.0.0.20       nginx-app-vps-private

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

    # Create netplan configuration
    log "⚙️ Creating netplan configuration..."
    cat > /etc/netplan/50-vps-config.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
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
          - vps.local
          - infra.local
      mtu: 1500

    enp2s0:
      dhcp4: false
      addresses:
        - $PRIVATE_IP/24
      mtu: 1500
      routes:
        - to: 10.0.0.0/24
          via: 10.0.0.1
          metric: 200
EOF

    # Apply network configuration
    log "🔄 Applying network configuration..."
    netplan apply || warn "Network configuration will be applied on next boot"

    # Configure DNS resolution
    log "🔍 Configuring DNS resolution..."
    cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=1.0.0.1 9.9.9.9
Domains=vps.local infra.local
LLMNR=yes
MulticastDNS=yes
DNSSEC=allow-downgrade
DNSOverTLS=opportunistic
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
EOF

    systemctl restart systemd-resolved

    # Configure network optimization
    log "⚡ Configuring network optimization..."
    cat > /etc/sysctl.d/99-network-optimization.conf << 'EOF'
# Network optimization parameters

# TCP settings
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

# Connection tracking
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# Buffer sizes
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.optmem_max = 25165824

# Queue lengths
net.core.netdev_budget = 600
net.core.netdev_max_backlog = 5000

# TCP congestion control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# TCP keepalive
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10

# TCP reuse
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 8192
EOF

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-network-optimization.conf

    # Configure network monitoring
    setup_network_monitoring "$PUBLIC_IP" "$PRIVATE_IP"

    log "✅ Network configuration completed for $SERVER_HOSTNAME"
}

# Setup network monitoring
setup_network_monitoring() {
    local PUBLIC_IP="$1"
    local PRIVATE_IP="$2"

    log "📊 Setting up network monitoring..."

    # Create network monitoring script
    cat > /opt/network-monitor.sh << 'EOF'
#!/bin/bash

# Network Monitoring Script
# Monitors network connectivity and performance

LOGFILE="/var/log/network-monitor.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Check connectivity
check_connectivity() {
    log "Checking network connectivity..."

    # Check gateway
    if ping -c 1 136.243.208.129 >/dev/null 2>&1; then
        log "✅ Gateway reachable"
    else
        log "❌ Gateway unreachable"
    fi

    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Internet connectivity OK"
    else
        log "❌ No internet connectivity"
    fi

    # Check private network
    if ping -c 1 10.0.0.1 >/dev/null 2>&1; then
        log "✅ Private network OK"
    else
        log "❌ Private network unreachable"
    fi

    # Check other VPS
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" == *"gitlab"* ]]; then
        TARGET_IP="10.0.0.20"
        TARGET_NAME="nginx-app-vps"
    else
        TARGET_IP="10.0.0.10"
        TARGET_NAME="gitlab-vps"
    fi

    if ping -c 1 "$TARGET_IP" >/dev/null 2>&1; then
        log "✅ $TARGET_NAME reachable"
    else
        log "❌ $TARGET_NAME unreachable"
    fi
}

# Check network performance
check_performance() {
    log "Checking network performance..."

    # Check interface statistics
    for interface in enp1s0 enp2s0; do
        if [ -d "/sys/class/net/$interface" ]; then
            RX_BYTES=$(cat /sys/class/net/$interface/statistics/rx_bytes)
            TX_BYTES=$(cat /sys/class/net/$interface/statistics/tx_bytes)
            RX_ERRORS=$(cat /sys/class/net/$interface/statistics/rx_errors)
            TX_ERRORS=$(cat /sys/class/net/$interface/statistics/tx_errors)

            log "$interface: RX=${RX_BYTES}B TX=${TX_BYTES}B RX_ERR=${RX_ERRORS} TX_ERR=${TX_ERRORS}"
        fi
    done

    # Check connection count
    CONNECTIONS=$(netstat -tuln | grep LISTEN | wc -l)
    log "Active listening ports: $CONNECTIONS"

    # Check bandwidth usage
    BANDWIDTH=$(vnstat -i enp1s0 --json | jq -r '.interfaces[0].traffic.day[0].tx' 2>/dev/null || echo "N/A")
    log "Daily bandwidth usage: $BANDWIDTH"
}

# Check DNS resolution
check_dns() {
    log "Checking DNS resolution..."

    # Test domain resolution
    if nslookup google.com >/dev/null 2>&1; then
        log "✅ DNS resolution working"
    else
        log "❌ DNS resolution failed"
    fi

    # Test internal resolution
    if nslookup gitlab.vps.local >/dev/null 2>&1; then
        log "✅ Internal DNS working"
    else
        log "❌ Internal DNS failed"
    fi
}

# Main monitoring function
main() {
    log "Starting network monitoring..."

    check_connectivity
    check_performance
    check_dns

    log "Network monitoring completed"
}

main
EOF

    chmod +x /opt/network-monitor.sh

    # Create network test script
    cat > /opt/network-test.sh << EOF
#!/bin/bash

# Network Test Script
# Comprehensive network testing

echo "🌐 Network Test for $(hostname)"
echo "================================"

echo ""
echo "📊 Interface Information:"
ip addr show

echo ""
echo "🔀 Routing Table:"
ip route show

echo ""
echo "🔍 DNS Configuration:"
cat /etc/resolv.conf

echo ""
echo "🌐 Connectivity Tests:"
echo "Gateway (136.243.208.129):"
ping -c 3 136.243.208.129 | tail -3

echo ""
echo "Internet (8.8.8.8):"
ping -c 3 8.8.8.8 | tail -3

echo ""
echo "Private Gateway (10.0.0.1):"
ping -c 3 10.0.0.1 | tail -3

echo ""
echo "Other VPS:"
if [[ "\$(hostname)" == *"gitlab"* ]]; then
    echo "nginx-app-vps (10.0.0.20):"
    ping -c 3 10.0.0.20 | tail -3
else
    echo "gitlab-vps (10.0.0.10):"
    ping -c 3 10.0.0.10 | tail -3
fi

echo ""
echo "🔍 DNS Resolution Tests:"
echo "External DNS:"
nslookup google.com

echo ""
echo "Internal DNS:"
nslookup gitlab.vps.local

echo ""
echo "📊 Network Statistics:"
ss -tuln | head -20

echo ""
echo "⚡ Network Performance:"
cat /proc/net/dev | head -10

echo ""
echo "✅ Network test completed"
EOF

    chmod +x /opt/network-test.sh

    # Setup network monitoring cron job
    cat > /etc/cron.d/network-monitor << 'EOF'
# Network monitoring cron job
*/10 * * * * root /opt/network-monitor.sh
EOF

    log "✅ Network monitoring configured"
}

# Main function
main() {
    log "🚀 Starting network configuration..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root"
    fi

    # Parse command line arguments
    SERVER_TYPE="${1:-auto}"

    case "$SERVER_TYPE" in
        "gitlab-vps")
            configure_gitlab_network
            ;;
        "nginx-app-vps")
            configure_nginx_network
            ;;
        "auto")
            DETECTED_TYPE=$(auto_detect_server)
            if [ "$DETECTED_TYPE" = "unknown" ]; then
                error "Could not auto-detect server type. Please specify manually."
            fi
            log "🔍 Auto-detected server type: $DETECTED_TYPE"
            main "$DETECTED_TYPE"
            return
            ;;
        "help"|"--help"|"-h")
            show_help
            exit 0
            ;;
        *)
            error "Unknown server type: $SERVER_TYPE. Use --help for usage information."
            ;;
    esac

    # Install network utilities
    log "📦 Installing network utilities..."
    apt-get update
    apt-get install -y \
        net-tools \
        dnsutils \
        traceroute \
        mtr \
        tcpdump \
        nmap \
        iftop \
        nethogs \
        vnstat \
        speedtest-cli \
        jq

    # Configure vnstat
    log "📊 Configuring vnstat..."
    systemctl enable vnstat
    systemctl start vnstat
    vnstat --add -i enp1s0
    vnstat --add -i enp2s0

    # Test network configuration
    log "🧪 Testing network configuration..."
    if /opt/network-test.sh > /tmp/network-test.log 2>&1; then
        log "✅ Network test completed successfully"
    else
        warn "⚠️ Network test had some issues - check /tmp/network-test.log"
    fi

    # Display network summary
    log "📋 Network Configuration Summary:"
    echo "======================================"
    echo "Hostname: $(hostname)"
    echo "Public IP: $(ip route get 8.8.8.8 | grep -oP 'src \K\S+' | head -1)"
    echo "Private IP: $(ip route get 10.0.0.1 | grep -oP 'src \K\S+' | head -1 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Active Interfaces:"
    ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':'
    echo ""
    echo "DNS Servers:"
    grep nameserver /etc/resolv.conf | awk '{print $2}'
    echo ""
    echo "Default Route:"
    ip route show default
    echo ""
    echo "🔧 Management Scripts:"
    echo "  Network Monitor: /opt/network-monitor.sh"
    echo "  Network Test: /opt/network-test.sh"
    echo "  Monitor Log: /var/log/network-monitor.log"
    echo "======================================"

    log "✅ Network configuration completed successfully!"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

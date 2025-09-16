#!/bin/bash

# Infrastructure Management Utility
# Central management script for VPS infrastructure operations

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Infrastructure paths
INFRASTRUCTURE_ROOT="/opt/xcloud/vps-hosting-infrastructure"
SHARED_DIR="$INFRASTRUCTURE_ROOT/core/shared"
GITLAB_VPS_DIR="$INFRASTRUCTURE_ROOT/core/gitlab-vps"
NGINX_VPS_DIR="$INFRASTRUCTURE_ROOT/core/nginx-app-vps"

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

success() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

# Display banner
show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║    🌐 VPS Infrastructure Management Utility                                   ║
║                                                                               ║
║    GitLab VPS + Nginx App VPS + Shared Infrastructure                        ║
║    Production-grade virtualization with Vagrant + KVM                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."

    local missing_deps=()

    # Required commands
    local required_commands=("vagrant" "virsh" "docker" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
    fi

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for system operations"
    fi

    # Check infrastructure directory
    if [[ ! -d "$INFRASTRUCTURE_ROOT" ]]; then
        error "Infrastructure directory not found: $INFRASTRUCTURE_ROOT"
    fi

    success "Prerequisites check passed"
}

# Show infrastructure status
show_status() {
    log "📊 Infrastructure Status Overview"
    echo ""

    # VPS Status
    echo -e "${PURPLE}🖥️  VPS Virtual Machines:${NC}"
    if command -v vagrant &> /dev/null; then
        cd "$INFRASTRUCTURE_ROOT"
        vagrant global-status | grep -E "(gitlab-vps|nginx-app-vps)" || echo "  No VPS instances found"
    fi
    echo ""

    # GitLab VPS Status
    echo -e "${PURPLE}🦊 GitLab VPS Status:${NC}"
    if virsh list --all | grep -q "gitlab-vps"; then
        gitlab_status=$(virsh list --all | grep "gitlab-vps" | awk '{print $3}')
        if [[ "$gitlab_status" == "running" ]]; then
            echo -e "  ✅ GitLab VPS: ${GREEN}Running${NC}"

            # Check GitLab services if VPS is accessible
            if ping -c 1 10.0.0.10 >/dev/null 2>&1; then
                echo "  🔗 Network: Accessible"
                # Could add more service checks here
            fi
        else
            echo -e "  ❌ GitLab VPS: ${RED}Stopped${NC}"
        fi
    else
        echo "  ⚪ GitLab VPS: Not created"
    fi
    echo ""

    # Nginx App VPS Status
    echo -e "${PURPLE}🌐 Nginx App VPS Status:${NC}"
    if virsh list --all | grep -q "nginx-app-vps"; then
        nginx_status=$(virsh list --all | grep "nginx-app-vps" | awk '{print $3}')
        if [[ "$nginx_status" == "running" ]]; then
            echo -e "  ✅ Nginx App VPS: ${GREEN}Running${NC}"

            # Check Nginx services if VPS is accessible
            if ping -c 1 10.0.0.20 >/dev/null 2>&1; then
                echo "  🔗 Network: Accessible"
            fi
        else
            echo -e "  ❌ Nginx App VPS: ${RED}Stopped${NC}"
        fi
    else
        echo "  ⚪ Nginx App VPS: Not created"
    fi
    echo ""

    # Network Status
    echo -e "${PURPLE}🌐 Network Configuration:${NC}"
    echo "  Production Network: 136.243.208.128/29"
    echo "  Private Network: 10.0.0.0/24"

    # Check bridge networks
    if ip link show | grep -q "virbr"; then
        echo -e "  ✅ Virtual Bridge: ${GREEN}Available${NC}"
    else
        echo -e "  ❌ Virtual Bridge: ${RED}Not configured${NC}"
    fi
    echo ""

    # Monitoring Status
    echo -e "${PURPLE}📊 Monitoring Services:${NC}"
    services=("netdata" "prometheus-node-exporter" "collectd")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ✅ $service: ${GREEN}Active${NC}"
        elif systemctl list-unit-files | grep -q "$service"; then
            echo -e "  ❌ $service: ${RED}Inactive${NC}"
        else
            echo -e "  ⚪ $service: ${YELLOW}Not installed${NC}"
        fi
    done
    echo ""

    # Storage Status
    echo -e "${PURPLE}💾 Storage Usage:${NC}"
    df -h | grep -E "^/dev" | head -3
    echo ""

    # Recent Backups
    echo -e "${PURPLE}📦 Recent Backups:${NC}"
    if [[ -d "/backup/archives/daily" ]]; then
        latest_backup=$(find /backup/archives/daily -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [[ -n "$latest_backup" ]]; then
            backup_date=$(stat -c %y "$latest_backup" | cut -d' ' -f1)
            backup_size=$(du -h "$latest_backup" | cut -f1)
            echo "  📦 Latest: $backup_date ($backup_size)"
        else
            echo "  ⚪ No recent backups found"
        fi
    else
        echo "  ⚪ Backup directory not configured"
    fi
}

# Deploy GitLab VPS
deploy_gitlab_vps() {
    log "🚀 Deploying GitLab VPS..."

    if [[ ! -d "$GITLAB_VPS_DIR" ]]; then
        error "GitLab VPS configuration not found: $GITLAB_VPS_DIR"
    fi

    cd "$GITLAB_VPS_DIR"

    info "Starting GitLab VPS deployment..."
    vagrant up --provider=libvirt

    info "Waiting for GitLab VPS to be ready..."
    sleep 30

    # Verify deployment
    if ping -c 3 10.0.0.10 >/dev/null 2>&1; then
        success "GitLab VPS deployed successfully and is accessible"
    else
        warn "GitLab VPS deployed but may not be fully ready"
    fi
}

# Deploy Nginx App VPS
deploy_nginx_vps() {
    log "🚀 Deploying Nginx App VPS..."

    if [[ ! -d "$NGINX_VPS_DIR" ]]; then
        error "Nginx VPS configuration not found: $NGINX_VPS_DIR"
    fi

    cd "$NGINX_VPS_DIR"

    info "Starting Nginx App VPS deployment..."
    vagrant up --provider=libvirt

    info "Waiting for Nginx App VPS to be ready..."
    sleep 30

    # Verify deployment
    if ping -c 3 10.0.0.20 >/dev/null 2>&1; then
        success "Nginx App VPS deployed successfully and is accessible"
    else
        warn "Nginx App VPS deployed but may not be fully ready"
    fi
}

# Deploy full infrastructure
deploy_full_infrastructure() {
    log "🚀 Deploying Full VPS Infrastructure..."

    info "Phase 1: Deploying GitLab VPS..."
    deploy_gitlab_vps

    info "Phase 2: Deploying Nginx App VPS..."
    deploy_nginx_vps

    info "Phase 3: Configuring shared services..."
    setup_shared_infrastructure

    success "Full infrastructure deployment completed!"

    echo ""
    echo "🌐 Access Information:"
    echo "  GitLab VPS:     https://136.243.208.130"
    echo "  Nginx App VPS:  https://136.243.208.131"
    echo "  Private GitLab: http://10.0.0.10"
    echo "  Private Nginx:  http://10.0.0.20"
    echo ""
    echo "📊 Monitoring:"
    echo "  GitLab Netdata: http://10.0.0.10:19999"
    echo "  Nginx Netdata:  http://10.0.0.20:19999"
}

# Setup shared infrastructure
setup_shared_infrastructure() {
    log "⚙️ Setting up shared infrastructure..."

    # Run security hardening
    if [[ -x "$SHARED_DIR/scripts/security-hardening.sh" ]]; then
        info "Applying security hardening..."
        bash "$SHARED_DIR/scripts/security-hardening.sh"
    fi

    # Configure monitoring
    if [[ -x "$SHARED_DIR/scripts/monitoring-setup.sh" ]]; then
        info "Setting up monitoring..."
        bash "$SHARED_DIR/scripts/monitoring-setup.sh"
    fi

    # Setup backup system
    if [[ -x "$SHARED_DIR/scripts/backup-management.sh" ]]; then
        info "Configuring backup system..."
        bash "$SHARED_DIR/scripts/backup-management.sh" --verify
    fi

    success "Shared infrastructure setup completed"
}

# Stop infrastructure
stop_infrastructure() {
    log "⏹️ Stopping VPS Infrastructure..."

    # Stop Nginx VPS
    if [[ -d "$NGINX_VPS_DIR" ]]; then
        cd "$NGINX_VPS_DIR"
        vagrant halt 2>/dev/null || true
        info "Nginx App VPS stopped"
    fi

    # Stop GitLab VPS
    if [[ -d "$GITLAB_VPS_DIR" ]]; then
        cd "$GITLAB_VPS_DIR"
        vagrant halt 2>/dev/null || true
        info "GitLab VPS stopped"
    fi

    success "Infrastructure stopped"
}

# Restart infrastructure
restart_infrastructure() {
    log "🔄 Restarting VPS Infrastructure..."

    stop_infrastructure
    sleep 10
    deploy_full_infrastructure
}

# Destroy infrastructure
destroy_infrastructure() {
    warn "🗑️ This will completely destroy the VPS infrastructure!"
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log "Infrastructure destruction cancelled"
        return
    fi

    log "💥 Destroying VPS Infrastructure..."

    # Destroy Nginx VPS
    if [[ -d "$NGINX_VPS_DIR" ]]; then
        cd "$NGINX_VPS_DIR"
        vagrant destroy -f 2>/dev/null || true
        info "Nginx App VPS destroyed"
    fi

    # Destroy GitLab VPS
    if [[ -d "$GITLAB_VPS_DIR" ]]; then
        cd "$GITLAB_VPS_DIR"
        vagrant destroy -f 2>/dev/null || true
        info "GitLab VPS destroyed"
    fi

    success "Infrastructure destroyed"
}

# Run backup
run_backup() {
    log "📦 Running infrastructure backup..."

    if [[ -x "$SHARED_DIR/scripts/backup-management.sh" ]]; then
        bash "$SHARED_DIR/scripts/backup-management.sh" "$@"
    else
        error "Backup script not found or not executable"
    fi
}

# Show monitoring dashboard
show_monitoring() {
    log "📊 Opening monitoring dashboard..."

    if [[ -x "/opt/monitoring-dashboard.sh" ]]; then
        /opt/monitoring-dashboard.sh
    else
        warn "Monitoring dashboard not installed"
        info "Run 'infrastructure-mgmt.sh setup' to install monitoring"
    fi
}

# Run health check
run_health_check() {
    log "🏥 Running infrastructure health check..."

    if [[ -x "/opt/health-check.sh" ]]; then
        /opt/health-check.sh
    else
        warn "Health check script not installed"
        info "Run 'infrastructure-mgmt.sh setup' to install health checks"
    fi
}

# Show logs
show_logs() {
    log "📝 Infrastructure Logs"
    echo ""

    # Show recent system logs
    echo -e "${PURPLE}Recent System Events:${NC}"
    journalctl --since "1 hour ago" --lines=20 --no-pager | head -10
    echo ""

    # Show backup logs
    if [[ -f "/var/log/backup.log" ]]; then
        echo -e "${PURPLE}Recent Backup Activity:${NC}"
        tail -10 /var/log/backup.log
        echo ""
    fi

    # Show health check logs
    if [[ -f "/var/log/health-check.log" ]]; then
        echo -e "${PURPLE}Recent Health Checks:${NC}"
        tail -10 /var/log/health-check.log
        echo ""
    fi

    # Show Netdata alerts
    if [[ -f "/var/log/netdata-alerts.log" ]]; then
        echo -e "${PURPLE}Recent Monitoring Alerts:${NC}"
        tail -10 /var/log/netdata-alerts.log
        echo ""
    fi
}

# Show help
show_help() {
    cat << EOF
Infrastructure Management Utility
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    status              Show infrastructure status overview
    deploy              Deploy full infrastructure
    deploy-gitlab       Deploy GitLab VPS only
    deploy-nginx        Deploy Nginx App VPS only
    setup               Setup shared infrastructure (monitoring, security, backups)
    start               Start stopped VPS instances
    stop                Stop running VPS instances
    restart             Restart infrastructure
    destroy             Destroy all VPS instances
    backup              Run infrastructure backup
    restore             Interactive backup restore
    monitor             Show monitoring dashboard
    health              Run health check
    logs                Show infrastructure logs
    help                Show this help message

EXAMPLES:
    $0 status           # Check infrastructure status
    $0 deploy           # Deploy complete infrastructure
    $0 backup --full    # Run full backup
    $0 monitor          # Open monitoring dashboard
    $0 health           # Run health check

BACKUP OPTIONS:
    --full              Complete backup (default)
    --system           System configurations only
    --gitlab           GitLab data only
    --databases        Database backups only
    --apps             Application data only
    --monitoring       Monitoring data only
    --cleanup          Clean old backups

EOF
}

# Main function
main() {
    case "${1:-}" in
        "status")
            show_banner
            check_prerequisites
            show_status
            ;;
        "deploy")
            show_banner
            check_prerequisites
            deploy_full_infrastructure
            ;;
        "deploy-gitlab")
            show_banner
            check_prerequisites
            deploy_gitlab_vps
            ;;
        "deploy-nginx")
            show_banner
            check_prerequisites
            deploy_nginx_vps
            ;;
        "setup")
            show_banner
            check_prerequisites
            setup_shared_infrastructure
            ;;
        "start")
            show_banner
            check_prerequisites
            deploy_full_infrastructure
            ;;
        "stop")
            show_banner
            check_prerequisites
            stop_infrastructure
            ;;
        "restart")
            show_banner
            check_prerequisites
            restart_infrastructure
            ;;
        "destroy")
            show_banner
            check_prerequisites
            destroy_infrastructure
            ;;
        "backup")
            shift
            run_backup "$@"
            ;;
        "restore")
            run_backup --restore
            ;;
        "monitor")
            show_monitoring
            ;;
        "health")
            run_health_check
            ;;
        "logs")
            show_logs
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            show_banner
            show_help
            ;;
        *)
            error "Unknown command: $1. Use 'help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"

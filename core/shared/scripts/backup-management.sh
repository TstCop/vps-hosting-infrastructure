#!/bin/bash

# Backup Management Script
# Automated backup system for VPS infrastructure

set -e

# Configuration
BACKUP_BASE_DIR="/backup"
LOG_FILE="/var/log/backup.log"
RETENTION_DAYS=30
GITLAB_BACKUP_DAYS=7
COMPRESSION_LEVEL=6

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Initialize backup environment
init_backup() {
    log "🚀 Initializing backup environment..."

    # Create backup directories
    mkdir -p "$BACKUP_BASE_DIR"/{system,gitlab,configs,databases,apps,monitoring}
    mkdir -p "$BACKUP_BASE_DIR"/archives/{daily,weekly,monthly}

    # Set permissions
    chmod 755 "$BACKUP_BASE_DIR"
    chmod 700 "$BACKUP_BASE_DIR"/{gitlab,databases}

    log "✅ Backup environment initialized"
}

# Backup system configurations
backup_system_configs() {
    log "🔧 Backing up system configurations..."

    local backup_dir="$BACKUP_BASE_DIR/system/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Important system files
    local configs=(
        "/etc/hosts"
        "/etc/hostname"
        "/etc/resolv.conf"
        "/etc/fstab"
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/sudoers"
        "/etc/sudoers.d"
        "/etc/ssh"
        "/etc/ufw"
        "/etc/fail2ban"
        "/etc/nginx"
        "/etc/systemd/system"
        "/etc/cron.d"
        "/etc/crontab"
        "/etc/logrotate.d"
        "/etc/netdata"
        "/etc/collectd"
        "/var/spool/cron"
    )

    for config in "${configs[@]}"; do
        if [[ -e "$config" ]]; then
            info "Backing up: $config"
            cp -r "$config" "$backup_dir/" 2>/dev/null || warn "Failed to backup $config"
        fi
    done

    # Package lists
    dpkg --get-selections > "$backup_dir/package-selections.txt"
    apt-mark showmanual > "$backup_dir/manual-packages.txt"

    # Network configuration
    ip addr show > "$backup_dir/network-interfaces.txt"
    ip route show > "$backup_dir/routing-table.txt"

    # Service status
    systemctl list-units --state=enabled > "$backup_dir/enabled-services.txt"

    # Create archive
    cd "$BACKUP_BASE_DIR/system"
    tar -czf "$backup_dir.tar.gz" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"

    log "✅ System configuration backup completed"
}

# Backup GitLab data
backup_gitlab() {
    log "🦊 Backing up GitLab data..."

    if ! command -v gitlab-backup &> /dev/null; then
        warn "GitLab not installed on this server, skipping GitLab backup"
        return
    fi

    local backup_dir="$BACKUP_BASE_DIR/gitlab"

    # Create GitLab backup
    info "Creating GitLab backup..."
    gitlab-backup create BACKUP=gitlab_backup_$(date +%Y%m%d_%H%M%S)

    # Copy GitLab backups to our backup directory
    if [[ -d "/var/opt/gitlab/backups" ]]; then
        cp /var/opt/gitlab/backups/gitlab_backup_*.tar "$backup_dir/" 2>/dev/null || true
    fi

    # Backup GitLab configuration
    if [[ -f "/etc/gitlab/gitlab.rb" ]]; then
        cp "/etc/gitlab/gitlab.rb" "$backup_dir/gitlab.rb.$(date +%Y%m%d_%H%M%S)"
    fi

    # Backup GitLab secrets
    if [[ -f "/etc/gitlab/gitlab-secrets.json" ]]; then
        cp "/etc/gitlab/gitlab-secrets.json" "$backup_dir/gitlab-secrets.json.$(date +%Y%m%d_%H%M%S)"
    fi

    log "✅ GitLab backup completed"
}

# Backup databases
backup_databases() {
    log "🗄️ Backing up databases..."

    local backup_dir="$BACKUP_BASE_DIR/databases/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # PostgreSQL backup
    if command -v pg_dumpall &> /dev/null; then
        info "Backing up PostgreSQL databases..."

        # Get list of databases
        databases=$(sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

        for db in $databases; do
            if [[ "$db" != "postgres" ]]; then
                info "Backing up database: $db"
                sudo -u postgres pg_dump "$db" | gzip > "$backup_dir/${db}.sql.gz"
            fi
        done

        # Full cluster backup
        sudo -u postgres pg_dumpall | gzip > "$backup_dir/postgres_full.sql.gz"
    fi

    # Redis backup
    if command -v redis-cli &> /dev/null; then
        info "Backing up Redis data..."
        redis-cli BGSAVE
        sleep 5  # Wait for backup to complete
        if [[ -f "/var/lib/redis/dump.rdb" ]]; then
            cp "/var/lib/redis/dump.rdb" "$backup_dir/redis_dump.rdb"
        fi
    fi

    # Create archive
    cd "$BACKUP_BASE_DIR/databases"
    tar -czf "$backup_dir.tar.gz" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"

    log "✅ Database backup completed"
}

# Backup application data
backup_applications() {
    log "📱 Backing up application data..."

    local backup_dir="$BACKUP_BASE_DIR/apps/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Application directories to backup
    local app_dirs=(
        "/opt/app"
        "/var/www"
        "/home/*/app"
        "/opt/custom"
    )

    for app_dir in "${app_dirs[@]}"; do
        if [[ -d "$app_dir" ]]; then
            info "Backing up application directory: $app_dir"
            cp -r "$app_dir" "$backup_dir/" 2>/dev/null || warn "Failed to backup $app_dir"
        fi
    done

    # Docker volumes (if Docker is installed)
    if command -v docker &> /dev/null; then
        info "Backing up Docker volumes..."
        docker volume ls -q > "$backup_dir/docker-volumes.txt"

        # Backup each volume
        for volume in $(docker volume ls -q); do
            info "Backing up Docker volume: $volume"
            docker run --rm -v "$volume":/volume -v "$backup_dir":/backup alpine \
                tar -czf "/backup/docker-volume-${volume}.tar.gz" -C /volume .
        done
    fi

    # Create archive if directory is not empty
    if [[ "$(ls -A "$backup_dir")" ]]; then
        cd "$BACKUP_BASE_DIR/apps"
        tar -czf "$backup_dir.tar.gz" "$(basename "$backup_dir")"
        rm -rf "$backup_dir"
    else
        rm -rf "$backup_dir"
        warn "No application data found to backup"
    fi

    log "✅ Application backup completed"
}

# Backup monitoring data
backup_monitoring() {
    log "📊 Backing up monitoring data..."

    local backup_dir="$BACKUP_BASE_DIR/monitoring/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Netdata configuration and data
    if [[ -d "/etc/netdata" ]]; then
        cp -r "/etc/netdata" "$backup_dir/"
    fi

    if [[ -d "/var/lib/netdata" ]]; then
        cp -r "/var/lib/netdata" "$backup_dir/"
    fi

    # Collectd data
    if [[ -d "/var/lib/collectd" ]]; then
        cp -r "/var/lib/collectd" "$backup_dir/"
    fi

    # Prometheus data
    if [[ -d "/var/lib/prometheus" ]]; then
        cp -r "/var/lib/prometheus" "$backup_dir/"
    fi

    # Log files
    mkdir -p "$backup_dir/logs"
    cp /var/log/health-check.log "$backup_dir/logs/" 2>/dev/null || true
    cp /var/log/netdata-alerts.log "$backup_dir/logs/" 2>/dev/null || true
    cp /var/log/backup.log "$backup_dir/logs/" 2>/dev/null || true

    # Create archive
    cd "$BACKUP_BASE_DIR/monitoring"
    tar -czf "$backup_dir.tar.gz" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"

    log "✅ Monitoring backup completed"
}

# Create daily archive
create_daily_archive() {
    log "📦 Creating daily backup archive..."

    local date_str=$(date +%Y%m%d)
    local archive_dir="$BACKUP_BASE_DIR/archives/daily"
    local archive_file="$archive_dir/backup_${date_str}.tar.gz"

    mkdir -p "$archive_dir"

    # Create comprehensive backup archive
    cd "$BACKUP_BASE_DIR"
    tar -czf "$archive_file" \
        --exclude="archives" \
        --exclude="*.log" \
        system/ configs/ databases/ apps/ monitoring/ 2>/dev/null || true

    if [[ -f "$archive_file" ]]; then
        local size=$(du -h "$archive_file" | cut -f1)
        log "✅ Daily archive created: $archive_file ($size)"
    else
        error "Failed to create daily archive"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "🧹 Cleaning up old backups..."

    # Remove old system backups
    find "$BACKUP_BASE_DIR/system" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Remove old database backups
    find "$BACKUP_BASE_DIR/databases" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Remove old application backups
    find "$BACKUP_BASE_DIR/apps" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Remove old monitoring backups
    find "$BACKUP_BASE_DIR/monitoring" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Remove old GitLab backups
    find "$BACKUP_BASE_DIR/gitlab" -name "*.tar" -mtime +$GITLAB_BACKUP_DAYS -delete 2>/dev/null || true

    # Remove old daily archives
    find "$BACKUP_BASE_DIR/archives/daily" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Remove old weekly archives
    find "$BACKUP_BASE_DIR/archives/weekly" -name "*.tar.gz" -mtime +$((RETENTION_DAYS * 2)) -delete 2>/dev/null || true

    # Remove old monthly archives
    find "$BACKUP_BASE_DIR/archives/monthly" -name "*.tar.gz" -mtime +$((RETENTION_DAYS * 6)) -delete 2>/dev/null || true

    log "✅ Cleanup completed"
}

# Create weekly archive
create_weekly_archive() {
    local day_of_week=$(date +%u)  # Monday = 1, Sunday = 7

    if [[ "$day_of_week" == "7" ]]; then  # Sunday
        log "📦 Creating weekly backup archive..."

        local date_str=$(date +%Y_week_%U)
        local archive_dir="$BACKUP_BASE_DIR/archives/weekly"
        local archive_file="$archive_dir/backup_${date_str}.tar.gz"

        mkdir -p "$archive_dir"

        # Copy the latest daily archive as weekly
        local latest_daily=$(find "$BACKUP_BASE_DIR/archives/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

        if [[ -n "$latest_daily" && -f "$latest_daily" ]]; then
            cp "$latest_daily" "$archive_file"
            log "✅ Weekly archive created: $archive_file"
        fi
    fi
}

# Create monthly archive
create_monthly_archive() {
    local day_of_month=$(date +%d)

    if [[ "$day_of_month" == "01" ]]; then  # First day of month
        log "📦 Creating monthly backup archive..."

        local date_str=$(date +%Y_%m)
        local archive_dir="$BACKUP_BASE_DIR/archives/monthly"
        local archive_file="$archive_dir/backup_${date_str}.tar.gz"

        mkdir -p "$archive_dir"

        # Copy the latest daily archive as monthly
        local latest_daily=$(find "$BACKUP_BASE_DIR/archives/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

        if [[ -n "$latest_daily" && -f "$latest_daily" ]]; then
            cp "$latest_daily" "$archive_file"
            log "✅ Monthly archive created: $archive_file"
        fi
    fi
}

# Backup verification
verify_backups() {
    log "🔍 Verifying backup integrity..."

    # Check if archives exist and are valid
    local archives_dir="$BACKUP_BASE_DIR/archives/daily"
    local latest_archive=$(find "$archives_dir" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

    if [[ -n "$latest_archive" && -f "$latest_archive" ]]; then
        if tar -tzf "$latest_archive" >/dev/null 2>&1; then
            log "✅ Latest backup archive is valid"
        else
            error "Latest backup archive is corrupted: $latest_archive"
        fi
    else
        warn "No recent backup archives found"
    fi

    # Check backup sizes
    local total_size=$(du -sh "$BACKUP_BASE_DIR" | cut -f1)
    log "📊 Total backup size: $total_size"

    # Check disk space
    local backup_disk_usage=$(df "$BACKUP_BASE_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ "$backup_disk_usage" -gt 85 ]]; then
        warn "Backup disk usage is high: ${backup_disk_usage}%"
    else
        log "✅ Backup disk usage: ${backup_disk_usage}%"
    fi
}

# Send backup report
send_backup_report() {
    log "📊 Generating backup report..."

    local report_file="/tmp/backup_report_$(date +%Y%m%d).txt"

    cat > "$report_file" << EOF
BACKUP REPORT - $(date)
=====================================

Hostname: $(hostname)
Backup Start Time: $(date)

BACKUP SUMMARY:
- System Configuration: $(find "$BACKUP_BASE_DIR/system" -name "*.tar.gz" -mtime -1 | wc -l) backups
- Database Backups: $(find "$BACKUP_BASE_DIR/databases" -name "*.tar.gz" -mtime -1 | wc -l) backups
- Application Backups: $(find "$BACKUP_BASE_DIR/apps" -name "*.tar.gz" -mtime -1 | wc -l) backups
- Monitoring Backups: $(find "$BACKUP_BASE_DIR/monitoring" -name "*.tar.gz" -mtime -1 | wc -l) backups
- GitLab Backups: $(find "$BACKUP_BASE_DIR/gitlab" -name "*.tar" -mtime -1 | wc -l) backups

STORAGE USAGE:
- Total Backup Size: $(du -sh "$BACKUP_BASE_DIR" | cut -f1)
- Disk Usage: $(df "$BACKUP_BASE_DIR" | tail -1 | awk '{print $5}')
- Available Space: $(df -h "$BACKUP_BASE_DIR" | tail -1 | awk '{print $4}')

RETENTION POLICY:
- Daily Backups: $RETENTION_DAYS days
- GitLab Backups: $GITLAB_BACKUP_DAYS days
- Weekly Backups: $((RETENTION_DAYS * 2)) days
- Monthly Backups: $((RETENTION_DAYS * 6)) days

LATEST BACKUPS:
$(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -o -name "*.tar" | sort -r | head -10)

=====================================
EOF

    # Log the report
    cat "$report_file" >> "$LOG_FILE"

    # Clean up report file
    rm -f "$report_file"

    log "✅ Backup report generated"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

VPS Infrastructure Backup Management Script

OPTIONS:
    --full              Run complete backup (default)
    --system           Backup system configurations only
    --gitlab           Backup GitLab data only
    --databases        Backup databases only
    --apps             Backup applications only
    --monitoring       Backup monitoring data only
    --cleanup          Cleanup old backups only
    --verify           Verify backup integrity only
    --restore          Interactive restore mode
    --help             Show this help message

EXAMPLES:
    $0                 # Run full backup
    $0 --system        # Backup system configs only
    $0 --cleanup       # Clean up old backups
    $0 --verify        # Verify backups

EOF
}

# Restore function (interactive)
restore_backup() {
    log "🔄 Starting interactive restore mode..."

    echo "Available backup archives:"
    find "$BACKUP_BASE_DIR/archives" -name "*.tar.gz" | sort -r | head -20

    echo ""
    read -p "Enter the full path of the backup to restore: " backup_file

    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
    fi

    echo "WARNING: This will restore system configurations and may overwrite current settings."
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log "Restore cancelled by user"
        exit 0
    fi

    # Create restore directory
    local restore_dir="/tmp/restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$restore_dir"

    # Extract backup
    log "Extracting backup archive..."
    tar -xzf "$backup_file" -C "$restore_dir"

    log "Backup extracted to: $restore_dir"
    log "Please manually review and restore the required files"
    log "Restore directory will be cleaned up in 24 hours"
}

# Main backup function
main() {
    local start_time=$(date +%s)
    log "🚀 Starting VPS infrastructure backup..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi

    # Initialize backup environment
    init_backup

    case "${1:-}" in
        --system)
            backup_system_configs
            ;;
        --gitlab)
            backup_gitlab
            ;;
        --databases)
            backup_databases
            ;;
        --apps)
            backup_applications
            ;;
        --monitoring)
            backup_monitoring
            ;;
        --cleanup)
            cleanup_old_backups
            ;;
        --verify)
            verify_backups
            ;;
        --restore)
            restore_backup
            ;;
        --help)
            show_usage
            exit 0
            ;;
        --full|"")
            # Full backup
            backup_system_configs
            backup_gitlab
            backup_databases
            backup_applications
            backup_monitoring
            create_daily_archive
            create_weekly_archive
            create_monthly_archive
            verify_backups
            cleanup_old_backups
            send_backup_report
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            ;;
    esac

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "✅ Backup completed successfully in ${duration} seconds"
}

# Run main function with all arguments
main "$@"

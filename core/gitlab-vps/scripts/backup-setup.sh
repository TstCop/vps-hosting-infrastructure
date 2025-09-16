#!/bin/bash
# backup-setup.sh - GitLab backup configuration and automation script
# File: /opt/xcloud/vps-hosting-infrastructure/core/gitlab-vps/scripts/backup-setup.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/var/opt/gitlab/backups"
EXTERNAL_BACKUP_DIR="/backup/gitlab"
LOG_FILE="/var/log/gitlab-backup.log"
RETENTION_DAYS=7
EXTERNAL_RETENTION_DAYS=30

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

log "💾 Setting up GitLab backup system..."

# Create backup directories
log "📁 Creating backup directories..."
mkdir -p "$BACKUP_DIR"
mkdir -p "$EXTERNAL_BACKUP_DIR"
mkdir -p "$(dirname $LOG_FILE)"

# Set proper permissions
chown git:git "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
chmod 755 "$EXTERNAL_BACKUP_DIR"

# Create main backup script
log "📝 Creating GitLab backup script..."
cat > /usr/local/bin/gitlab-backup.sh << 'EOF'
#!/bin/bash
# GitLab automated backup script

# Configuration
BACKUP_DIR="/var/opt/gitlab/backups"
EXTERNAL_BACKUP_DIR="/backup/gitlab"
LOG_FILE="/var/log/gitlab-backup.log"
RETENTION_DAYS=7
EXTERNAL_RETENTION_DAYS=30
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_message() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success_message() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if GitLab is running
check_gitlab_status() {
    if ! gitlab-ctl status > /dev/null 2>&1; then
        error_message "GitLab is not running properly!"
        return 1
    fi
    return 0
}

# Create GitLab backup
create_gitlab_backup() {
    log_message "🚀 Starting GitLab backup..."

    if ! check_gitlab_status; then
        error_message "Cannot proceed with backup - GitLab is not running"
        return 1
    fi

    # Create GitLab backup
    if gitlab-backup create CRON=1 BACKUP="$TIMESTAMP" 2>&1 | tee -a "$LOG_FILE"; then
        success_message "GitLab backup created successfully"

        # Find the created backup file
        BACKUP_FILE=$(find "$BACKUP_DIR" -name "*${TIMESTAMP}_gitlab_backup.tar" -type f 2>/dev/null | head -1)

        if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
            BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
            log_message "Backup file: $BACKUP_FILE (Size: $BACKUP_SIZE)"
            echo "$BACKUP_FILE" > /tmp/latest_gitlab_backup.txt
        else
            warning_message "Backup file not found with timestamp $TIMESTAMP"
            # Find the latest backup
            BACKUP_FILE=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
            if [ -n "$BACKUP_FILE" ]; then
                log_message "Using latest backup: $BACKUP_FILE"
                echo "$BACKUP_FILE" > /tmp/latest_gitlab_backup.txt
            fi
        fi

        return 0
    else
        error_message "GitLab backup creation failed"
        return 1
    fi
}

# Backup GitLab configuration
backup_gitlab_config() {
    log_message "⚙️ Backing up GitLab configuration..."

    CONFIG_BACKUP_DIR="$EXTERNAL_BACKUP_DIR/config/$TIMESTAMP"
    mkdir -p "$CONFIG_BACKUP_DIR"

    # Backup GitLab configuration
    if [ -f /etc/gitlab/gitlab.rb ]; then
        cp /etc/gitlab/gitlab.rb "$CONFIG_BACKUP_DIR/"
        success_message "GitLab configuration backed up"
    fi

    # Backup GitLab secrets
    if [ -f /etc/gitlab/gitlab-secrets.json ]; then
        cp /etc/gitlab/gitlab-secrets.json "$CONFIG_BACKUP_DIR/"
        success_message "GitLab secrets backed up"
    fi

    # Backup SSL certificates
    if [ -d /etc/ssl/certs ] && [ -d /etc/ssl/private ]; then
        mkdir -p "$CONFIG_BACKUP_DIR/ssl"
        cp /etc/ssl/certs/gitlab.* "$CONFIG_BACKUP_DIR/ssl/" 2>/dev/null || true
        cp /etc/ssl/private/gitlab.* "$CONFIG_BACKUP_DIR/ssl/" 2>/dev/null || true
        success_message "SSL certificates backed up"
    fi

    # Create archive of configuration backup
    cd "$(dirname $CONFIG_BACKUP_DIR)"
    tar -czf "gitlab-config-$TIMESTAMP.tar.gz" "$(basename $CONFIG_BACKUP_DIR)"
    rm -rf "$CONFIG_BACKUP_DIR"

    success_message "Configuration backup archived: gitlab-config-$TIMESTAMP.tar.gz"
}

# Copy backup to external location
copy_to_external() {
    if [ ! -f /tmp/latest_gitlab_backup.txt ]; then
        warning_message "No backup file reference found"
        return 1
    fi

    BACKUP_FILE=$(cat /tmp/latest_gitlab_backup.txt)

    if [ ! -f "$BACKUP_FILE" ]; then
        error_message "Backup file not found: $BACKUP_FILE"
        return 1
    fi

    log_message "📋 Copying backup to external location..."

    # Copy GitLab backup
    if cp "$BACKUP_FILE" "$EXTERNAL_BACKUP_DIR/"; then
        success_message "Backup copied to external location"
    else
        error_message "Failed to copy backup to external location"
        return 1
    fi

    # Verify copied file
    COPIED_FILE="$EXTERNAL_BACKUP_DIR/$(basename $BACKUP_FILE)"
    if [ -f "$COPIED_FILE" ]; then
        ORIGINAL_SIZE=$(stat -c%s "$BACKUP_FILE")
        COPIED_SIZE=$(stat -c%s "$COPIED_FILE")

        if [ "$ORIGINAL_SIZE" -eq "$COPIED_SIZE" ]; then
            success_message "Backup integrity verified"
        else
            error_message "Backup integrity check failed - size mismatch"
            return 1
        fi
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log_message "🧹 Cleaning up old backups..."

    # Clean up local backups (keep last N days)
    if [ -d "$BACKUP_DIR" ]; then
        OLD_LOCAL_COUNT=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime +$RETENTION_DAYS -type f | wc -l)
        if [ "$OLD_LOCAL_COUNT" -gt 0 ]; then
            find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime +$RETENTION_DAYS -type f -delete
            log_message "Deleted $OLD_LOCAL_COUNT old local backup(s)"
        else
            log_message "No old local backups to clean up"
        fi
    fi

    # Clean up external backups (keep last N days)
    if [ -d "$EXTERNAL_BACKUP_DIR" ]; then
        OLD_EXTERNAL_COUNT=$(find "$EXTERNAL_BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime +$EXTERNAL_RETENTION_DAYS -type f | wc -l)
        if [ "$OLD_EXTERNAL_COUNT" -gt 0 ]; then
            find "$EXTERNAL_BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime +$EXTERNAL_RETENTION_DAYS -type f -delete
            log_message "Deleted $OLD_EXTERNAL_COUNT old external backup(s)"
        else
            log_message "No old external backups to clean up"
        fi

        # Clean up old config backups
        OLD_CONFIG_COUNT=$(find "$EXTERNAL_BACKUP_DIR" -name "gitlab-config-*.tar.gz" -mtime +$EXTERNAL_RETENTION_DAYS -type f | wc -l)
        if [ "$OLD_CONFIG_COUNT" -gt 0 ]; then
            find "$EXTERNAL_BACKUP_DIR" -name "gitlab-config-*.tar.gz" -mtime +$EXTERNAL_RETENTION_DAYS -type f -delete
            log_message "Deleted $OLD_CONFIG_COUNT old config backup(s)"
        fi
    fi
}

# Generate backup report
generate_backup_report() {
    log_message "📊 Generating backup report..."

    REPORT_FILE="/tmp/gitlab-backup-report-$TIMESTAMP.txt"

    cat > "$REPORT_FILE" << EOL
GitLab Backup Report
===================
Date: $(date)
Timestamp: $TIMESTAMP

Backup Status:
$([ $BACKUP_SUCCESS -eq 0 ] && echo "✅ SUCCESS" || echo "❌ FAILED")

Local Backups:
$(ls -lh $BACKUP_DIR/*_gitlab_backup.tar 2>/dev/null | tail -5 || echo "No backups found")

External Backups:
$(ls -lh $EXTERNAL_BACKUP_DIR/*_gitlab_backup.tar 2>/dev/null | tail -5 || echo "No backups found")

Disk Usage:
Local: $(du -sh $BACKUP_DIR 2>/dev/null || echo "N/A")
External: $(du -sh $EXTERNAL_BACKUP_DIR 2>/dev/null || echo "N/A")

System Info:
$(df -h | grep -E "(Filesystem|/dev/)" | head -2)
$(free -h | head -2)

Recent Log Entries:
$(tail -10 $LOG_FILE)
EOL

    log_message "Backup report generated: $REPORT_FILE"

    # Optional: Send report via email or notification service
    # Example: mail -s "GitLab Backup Report" admin@example.com < "$REPORT_FILE"
}

# Main backup execution
main() {
    log_message "🚀 Starting GitLab backup process..."

    BACKUP_SUCCESS=0

    # Create GitLab backup
    if create_gitlab_backup; then
        success_message "GitLab backup creation completed"
    else
        error_message "GitLab backup creation failed"
        BACKUP_SUCCESS=1
    fi

    # Backup configuration
    if backup_gitlab_config; then
        success_message "Configuration backup completed"
    else
        warning_message "Configuration backup failed"
    fi

    # Copy to external location
    if copy_to_external; then
        success_message "External backup copy completed"
    else
        warning_message "External backup copy failed"
    fi

    # Cleanup old backups
    cleanup_old_backups

    # Generate report
    generate_backup_report

    # Clean up temporary files
    rm -f /tmp/latest_gitlab_backup.txt

    if [ $BACKUP_SUCCESS -eq 0 ]; then
        success_message "🎉 GitLab backup process completed successfully!"
    else
        error_message "❌ GitLab backup process completed with errors"
    fi

    return $BACKUP_SUCCESS
}

# Execute main function
main "$@"
EOF

chmod +x /usr/local/bin/gitlab-backup.sh

# Create backup restoration script
log "📝 Creating backup restoration script..."
cat > /usr/local/bin/gitlab-restore.sh << 'EOF'
#!/bin/bash
# GitLab backup restoration script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success_message() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

usage() {
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Example:"
    echo "  $0 /var/opt/gitlab/backups/1234567890_gitlab_backup.tar"
    echo ""
    echo "Available backups:"
    ls -la /var/opt/gitlab/backups/*_gitlab_backup.tar 2>/dev/null || echo "  No backups found"
    exit 1
}

# Check arguments
if [ $# -eq 0 ]; then
    usage
fi

BACKUP_FILE="$1"

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    error_message "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Extract timestamp from backup file
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
BACKUP_TIMESTAMP=${BACKUP_FILENAME%_gitlab_backup.tar}

log_message "🔄 Starting GitLab restoration from backup: $BACKUP_FILENAME"

warning_message "⚠️  WARNING: This will overwrite current GitLab data!"
warning_message "⚠️  Make sure GitLab is stopped and you have a recent backup!"

read -p "Continue with restoration? (yes/no): " -r
if [ "$REPLY" != "yes" ]; then
    log_message "Restoration cancelled by user"
    exit 0
fi

# Stop GitLab services
log_message "🛑 Stopping GitLab services..."
gitlab-ctl stop unicorn
gitlab-ctl stop puma
gitlab-ctl stop sidekiq

# Verify services are stopped
sleep 5
if pgrep -f "unicorn\|puma\|sidekiq" > /dev/null; then
    error_message "GitLab services are still running. Please stop them manually."
    exit 1
fi

# Restore GitLab backup
log_message "📦 Restoring GitLab backup..."
if gitlab-backup restore BACKUP="$BACKUP_TIMESTAMP" force=yes; then
    success_message "GitLab backup restored successfully"
else
    error_message "GitLab backup restoration failed"
    exit 1
fi

# Restart GitLab services
log_message "🚀 Starting GitLab services..."
gitlab-ctl start

# Wait for services to be ready
log_message "⏳ Waiting for GitLab services to be ready..."
sleep 30

# Check GitLab status
log_message "🏥 Checking GitLab status..."
gitlab-ctl status

# Run GitLab check
log_message "🔍 Running GitLab health check..."
gitlab-rake gitlab:check

success_message "✅ GitLab restoration completed!"
warning_message "⚠️  Please verify your GitLab instance is working correctly"
EOF

chmod +x /usr/local/bin/gitlab-restore.sh

# Create backup verification script
log "📝 Creating backup verification script..."
cat > /usr/local/bin/gitlab-backup-verify.sh << 'EOF'
#!/bin/bash
# GitLab backup verification script

BACKUP_DIR="/var/opt/gitlab/backups"
EXTERNAL_BACKUP_DIR="/backup/gitlab"

echo "🔍 GitLab Backup Verification"
echo "============================="

# Check local backups
echo -e "\n📁 Local Backups ($BACKUP_DIR):"
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f | wc -l)
    echo "Total backups: $BACKUP_COUNT"

    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo -e "\nRecent backups:"
        find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f -printf '%T@ %TY-%Tm-%Td %TH:%TM %s %p\n' | sort -nr | head -5 | while read timestamp date time size file; do
            size_mb=$((size / 1024 / 1024))
            echo "  $(basename "$file") - $date $time (${size_mb}MB)"
        done

        # Verify latest backup integrity
        LATEST_BACKUP=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2)
        if [ -n "$LATEST_BACKUP" ]; then
            echo -e "\n🔍 Verifying latest backup integrity..."
            if tar -tf "$LATEST_BACKUP" > /dev/null 2>&1; then
                echo "✅ Latest backup integrity: OK"
            else
                echo "❌ Latest backup integrity: FAILED"
            fi
        fi
    else
        echo "❌ No local backups found"
    fi
else
    echo "❌ Local backup directory not found"
fi

# Check external backups
echo -e "\n📁 External Backups ($EXTERNAL_BACKUP_DIR):"
if [ -d "$EXTERNAL_BACKUP_DIR" ]; then
    EXTERNAL_COUNT=$(find "$EXTERNAL_BACKUP_DIR" -name "*_gitlab_backup.tar" -type f | wc -l)
    echo "Total external backups: $EXTERNAL_COUNT"

    if [ "$EXTERNAL_COUNT" -gt 0 ]; then
        echo -e "\nRecent external backups:"
        find "$EXTERNAL_BACKUP_DIR" -name "*_gitlab_backup.tar" -type f -printf '%T@ %TY-%Tm-%Td %TH:%TM %s %p\n' | sort -nr | head -5 | while read timestamp date time size file; do
            size_mb=$((size / 1024 / 1024))
            echo "  $(basename "$file") - $date $time (${size_mb}MB)"
        done
    else
        echo "❌ No external backups found"
    fi
else
    echo "❌ External backup directory not found"
fi

# Check configuration backups
echo -e "\n⚙️ Configuration Backups:"
CONFIG_COUNT=$(find "$EXTERNAL_BACKUP_DIR" -name "gitlab-config-*.tar.gz" -type f 2>/dev/null | wc -l)
echo "Total config backups: $CONFIG_COUNT"

# Check disk space
echo -e "\n💿 Disk Space:"
echo "Local backup directory:"
du -sh "$BACKUP_DIR" 2>/dev/null || echo "  N/A"
echo "External backup directory:"
du -sh "$EXTERNAL_BACKUP_DIR" 2>/dev/null || echo "  N/A"

# Check backup log
echo -e "\n📝 Recent Backup Log Entries:"
if [ -f "/var/log/gitlab-backup.log" ]; then
    tail -10 /var/log/gitlab-backup.log
else
    echo "No backup log found"
fi

# Check cron jobs
echo -e "\n⏰ Backup Cron Jobs:"
crontab -l | grep gitlab-backup || echo "No backup cron jobs found"

echo -e "\n✅ Backup verification completed"
EOF

chmod +x /usr/local/bin/gitlab-backup-verify.sh

# Configure cron job for automated backups
log "⏰ Setting up automated backup cron job..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/gitlab-backup.sh >> /var/log/gitlab-backup.log 2>&1") | crontab -

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
    notifempty
}
EOF

# Update GitLab configuration for backups
log "⚙️ Updating GitLab backup configuration..."
if [ -f /etc/gitlab/gitlab.rb ]; then
    # Backup current config
    cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.backup.prebackup

    # Update backup settings
    cat >> /etc/gitlab/gitlab.rb << 'EOF'

# Backup configuration
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_archive_permissions'] = 0600
gitlab_rails['backup_keep_time'] = 604800  # 7 days
gitlab_rails['backup_upload_connection'] = {}
gitlab_rails['backup_upload_remote_directory'] = 'gitlab-backups'
gitlab_rails['backup_multipart_chunk_size'] = 104857600  # 100MB

# Backup gitaly_address
gitlab_rails['backup_gitaly_backup_id'] = 'default'
EOF

    # Reconfigure GitLab to apply backup settings
    gitlab-ctl reconfigure
fi

# Create backup documentation
log "📚 Creating backup documentation..."
cat > /opt/gitlab-backup-docs.md << 'EOF'
# GitLab Backup System Documentation

## Overview
Automated backup system for GitLab VPS with local and external storage.

## Backup Components
- **GitLab Data**: Repositories, database, uploads, etc.
- **Configuration Files**: GitLab config, secrets, SSL certificates
- **Local Storage**: /var/opt/gitlab/backups (7 days retention)
- **External Storage**: /backup/gitlab (30 days retention)

## Management Commands

### Manual Backup
```bash
sudo gitlab-backup.sh
```

### Restore Backup
```bash
sudo gitlab-restore.sh /path/to/backup_file.tar
```

### Verify Backups
```bash
sudo gitlab-backup-verify.sh
```

### List Available Backups
```bash
ls -la /var/opt/gitlab/backups/
ls -la /backup/gitlab/
```

## Automated Backups
- **Schedule**: Daily at 2:00 AM
- **Cron Job**: `/usr/local/bin/gitlab-backup.sh`
- **Log File**: `/var/log/gitlab-backup.log`

## Backup Process
1. Create GitLab application backup
2. Backup configuration files and SSL certificates
3. Copy backups to external location
4. Verify backup integrity
5. Clean up old backups
6. Generate backup report

## Restoration Process
1. Stop GitLab services
2. Restore from backup file
3. Restart GitLab services
4. Verify restoration

## Monitoring
- Check backup logs: `tail -f /var/log/gitlab-backup.log`
- Verify backup integrity: `gitlab-backup-verify.sh`
- Monitor disk space: `df -h`

## Troubleshooting
1. **Backup fails**: Check GitLab status and disk space
2. **Permission errors**: Verify backup directory permissions
3. **Restore fails**: Ensure GitLab services are stopped
4. **Missing backups**: Check cron job and log files

## Best Practices
1. Test restoration process regularly
2. Monitor backup logs daily
3. Verify backup integrity weekly
4. Keep multiple backup copies
5. Document restoration procedures
EOF

# Test backup system
log "🧪 Testing backup system..."
if /usr/local/bin/gitlab-backup-verify.sh > /dev/null 2>&1; then
    success "Backup system verification passed"
else
    warning "Backup system verification had issues - check configuration"
fi

success "✅ GitLab backup system setup completed!"

log "📋 Backup System Summary:"
echo "========================"
echo "Backup Script: /usr/local/bin/gitlab-backup.sh"
echo "Restore Script: /usr/local/bin/gitlab-restore.sh"
echo "Verify Script: /usr/local/bin/gitlab-backup-verify.sh"
echo "Local Backups: $BACKUP_DIR (${RETENTION_DAYS} days retention)"
echo "External Backups: $EXTERNAL_BACKUP_DIR (${EXTERNAL_RETENTION_DAYS} days retention)"
echo "Schedule: Daily at 2:00 AM"
echo "Log File: $LOG_FILE"
echo "Documentation: /opt/gitlab-backup-docs.md"
echo ""

warning "⚠️ Important notes:"
warning "1. Test the restoration process to ensure backups work"
warning "2. Monitor backup logs regularly"
warning "3. Verify external backup storage is accessible"
warning "4. Consider offsite backup storage for disaster recovery"

log "🔍 Running backup verification..."
/usr/local/bin/gitlab-backup-verify.sh

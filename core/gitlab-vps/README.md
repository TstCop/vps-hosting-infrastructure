# GitLab VPS - Production Infrastructure

🦊 **GitLab Community Edition** VPS for VPS Hosting Infrastructure

## 📋 Overview

This directory contains the complete configuration for a production GitLab VPS instance with:

- **GitLab CE/EE** with Container Registry
- **GitLab Runner** with Docker executor
- **SSL/TLS** security configuration
- **Automated backup** system
- **Network security** with firewall and fail2ban

## 🌐 Network Configuration

- **Public IP**: `136.243.208.130`
- **Private IP**: `10.0.0.10`
- **Subnet**: `136.243.208.128/29`
- **Gateway**: `136.243.208.129`

### Ports and Services

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | System administration |
| 80 | HTTP | GitLab web (redirects to HTTPS) |
| 443 | HTTPS | GitLab web interface |
| 2222 | SSH | GitLab SSH for Git operations |
| 5050 | HTTPS | Container Registry |

## 🖥️ System Requirements

- **RAM**: 4GB minimum
- **CPU**: 2 cores minimum
- **Storage**: 100GB minimum
- **OS**: Ubuntu 22.04 LTS
- **Virtualization**: Libvirt/QEMU

## 🚀 Quick Start

### 1. Deploy VM

```bash
# From core/gitlab-vps/ directory
vagrant up

# Check status
vagrant status

# SSH into VM
vagrant ssh gitlab-vps
```

### 2. Verify Installation

```bash
# Check GitLab services
sudo gitlab-ctl status

# Check GitLab health
sudo gitlab-health-check.sh

# View GitLab logs
sudo gitlab-ctl tail
```

### 3. Initial Setup

1. **Access GitLab**: <https://136.243.208.130>
2. **Get root password**: `sudo cat /root/gitlab_initial_password.txt`
3. **Login** with username `root` and the initial password
4. **Change password** immediately after login
5. **Configure** your GitLab instance

## 📁 Directory Structure

```
gitlab-vps/
├── Vagrantfile                 # VM configuration
├── config/                     # Configuration files
│   ├── gitlab.yaml            # GitLab settings
│   ├── network.yaml           # Network configuration
│   └── ssl.yaml               # SSL/TLS settings
├── scripts/                    # Provisioning scripts
│   ├── provision-gitlab.sh    # Main provisioning
│   ├── install-gitlab.sh      # GitLab installation
│   ├── configure-runner.sh    # GitLab Runner setup
│   ├── setup-ssl.sh          # SSL/TLS configuration
│   └── backup-setup.sh       # Backup automation
└── README.md                   # This file
```

## ⚙️ Configuration Scripts

### Main Provisioning

```bash
# System update, firewall, SSH hardening
./scripts/provision-gitlab.sh
```

### GitLab Installation

```bash
# Install and configure GitLab CE
./scripts/install-gitlab.sh
```

### GitLab Runner Setup

```bash
# Install and configure GitLab Runner
./scripts/configure-runner.sh

# Register runner (requires token from GitLab)
sudo /root/register-gitlab-runner.sh <TOKEN>
```

### SSL/TLS Setup

```bash
# Generate self-signed certificate
./scripts/setup-ssl.sh

# Or setup Let's Encrypt (requires domain)
./scripts/setup-ssl.sh --letsencrypt
```

### Backup System

```bash
# Setup automated backups
./scripts/backup-setup.sh

# Manual backup
sudo gitlab-backup.sh

# Restore backup
sudo gitlab-restore.sh /path/to/backup.tar
```

## 🔒 Security Features

### SSH Hardening

- Password authentication disabled
- Root login disabled
- Custom SSH configuration
- Fail2ban protection

### Firewall (UFW)

- Default deny incoming
- Only required ports open
- Private network access allowed
- Rate limiting configured

### SSL/TLS

- TLS 1.2/1.3 only
- Strong cipher suites
- Security headers configured
- HSTS enabled
- Certificate monitoring

### Access Control

- GitLab authentication required
- Rate limiting enabled
- Audit logging active
- Session timeout configured

## 📊 Monitoring and Management

### Health Checks

```bash
# System and GitLab status
sudo gitlab-health-check.sh

# SSL certificate status
sudo ssl-monitor.sh

# Runner status
sudo gitlab-runner-monitor.sh

# Backup verification
sudo gitlab-backup-verify.sh
```

### Log Monitoring

```bash
# GitLab application logs
sudo gitlab-ctl tail

# System logs
sudo journalctl -f

# Backup logs
sudo tail -f /var/log/gitlab-backup.log

# Security logs
sudo tail -f /var/log/auth.log
```

### System Resources

```bash
# Resource usage
sudo htop

# Disk usage
sudo df -h

# GitLab specific metrics
sudo gitlab-ctl status
```

## 💾 Backup System

### Automated Backups

- **Schedule**: Daily at 2:00 AM
- **Local retention**: 7 days
- **External retention**: 30 days
- **Components**: Application data + configuration + SSL certificates

### Manual Operations

```bash
# Create backup
sudo gitlab-backup.sh

# List backups
ls -la /var/opt/gitlab/backups/

# Restore backup
sudo gitlab-restore.sh <backup_file>

# Verify backups
sudo gitlab-backup-verify.sh
```

## 🏃 GitLab Runner

### Configuration

- **Executor**: Docker
- **Concurrent jobs**: 2
- **Tags**: docker, ubuntu, vps, production
- **Default image**: ubuntu:22.04

### Management

```bash
# Check runner status
sudo gitlab-runner status

# Monitor runner
sudo gitlab-runner-monitor.sh

# Cleanup resources
sudo gitlab-runner-cleanup.sh

# View runner logs
sudo journalctl -u gitlab-runner -f
```

## 🌐 Container Registry

- **URL**: <https://136.243.208.130:5050>
- **Authentication**: GitLab credentials
- **Storage**: Local filesystem
- **SSL**: Enabled with same certificate

## 🔧 Maintenance

### Regular Tasks

```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update GitLab
sudo apt update && sudo apt install gitlab-ce

# Check GitLab version
sudo gitlab-rake gitlab:env:info

# Reconfigure GitLab
sudo gitlab-ctl reconfigure

# Restart GitLab
sudo gitlab-ctl restart
```

### Performance Tuning

```bash
# Check resource usage
sudo gitlab-ctl tail

# View configuration
sudo cat /etc/gitlab/gitlab.rb

# Monitor PostgreSQL
sudo gitlab-ctl tail postgresql

# Monitor Redis
sudo gitlab-ctl tail redis
```

## 🚨 Troubleshooting

### Common Issues

#### GitLab won't start

```bash
# Check status
sudo gitlab-ctl status

# Check logs
sudo gitlab-ctl tail

# Reconfigure
sudo gitlab-ctl reconfigure

# Restart services
sudo gitlab-ctl restart
```

#### SSL issues

```bash
# Check certificate
sudo ssl-monitor.sh

# Regenerate certificate
sudo ./scripts/setup-ssl.sh

# Check Nginx config
sudo nginx -t
```

#### Runner issues

```bash
# Check runner status
sudo gitlab-runner status

# Re-register runner
sudo gitlab-runner unregister --all-runners
sudo /root/register-gitlab-runner.sh <TOKEN>

# Check Docker
sudo docker info
```

#### Backup issues

```bash
# Check backup logs
sudo tail -f /var/log/gitlab-backup.log

# Verify backup integrity
sudo gitlab-backup-verify.sh

# Manual backup test
sudo gitlab-backup.sh
```

### Log Locations

- GitLab logs: `/var/log/gitlab/`
- System logs: `/var/log/syslog`, `/var/log/auth.log`
- Backup logs: `/var/log/gitlab-backup.log`
- Nginx logs: `/var/log/nginx/`

## 📞 Support and Documentation

### Internal Documentation

- Configuration files: `./config/`
- Script documentation: `./scripts/`
- Backup docs: `/opt/gitlab-backup-docs.md`
- SSL docs: `/opt/gitlab-ssl-docs.md`

### External Resources

- [GitLab Documentation](https://docs.gitlab.com/)
- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitLab Administration](https://docs.gitlab.com/ee/administration/)

### Getting Help

```bash
# GitLab help
sudo gitlab-ctl help

# Check GitLab status
sudo gitlab-rake gitlab:check

# Environment info
sudo gitlab-rake gitlab:env:info
```

## 🔄 Updates and Upgrades

### GitLab Updates

```bash
# Backup before update
sudo gitlab-backup.sh

# Update GitLab
sudo apt update
sudo apt install gitlab-ce

# Reconfigure after update
sudo gitlab-ctl reconfigure
```

### System Updates

```bash
# Update system (automated via unattended-upgrades)
sudo apt update && sudo apt upgrade

# Reboot if required
sudo reboot
```

---

## 📝 Quick Reference

### Essential Commands

```bash
# GitLab status
sudo gitlab-ctl status

# GitLab logs
sudo gitlab-ctl tail

# System monitor
sudo gitlab-health-check.sh

# Manual backup
sudo gitlab-backup.sh

# SSL check
sudo ssl-monitor.sh
```

### Important Paths

- GitLab config: `/etc/gitlab/gitlab.rb`
- GitLab data: `/var/opt/gitlab/`
- Backups: `/var/opt/gitlab/backups/`
- SSL certificates: `/etc/ssl/certs/gitlab.crt`
- Scripts: `/usr/local/bin/gitlab-*`

### Network Access

- GitLab Web: <https://136.243.208.130>
- GitLab SSH: `git@136.243.208.130:2222`
- Container Registry: <https://136.243.208.130:5050>

---

**⚠️ Production Environment** - Always test changes in development first!

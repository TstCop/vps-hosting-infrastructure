# VPS Infrastructure Documentation

## Overview

This documentation covers the complete VPS hosting infrastructure setup for GitLab and Nginx application servers using Vagrant, KVM/QEMU virtualization, and production-grade configurations.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Network Configuration](#network-configuration)
3. [VPS Instances](#vps-instances)
4. [Deployment Guide](#deployment-guide)
5. [Configuration Reference](#configuration-reference)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Security](#security)
8. [Troubleshooting](#troubleshooting)
9. [API Reference](#api-reference)

## Architecture Overview

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPS Infrastructure                           │
├─────────────────────────────────────────────────────────────────┤
│  Production Network: 136.243.208.128/29                       │
│  Private Network: 10.0.0.0/24                                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐         ┌─────────────────┐              │
│  │   GitLab VPS    │◄──────► │ Nginx App VPS   │              │
│  │ 136.243.208.130 │         │ 136.243.208.131 │              │
│  │   10.0.0.10     │         │   10.0.0.20     │              │
│  ├─────────────────┤         ├─────────────────┤              │
│  │ GitLab CE/EE    │         │ Nginx Proxy     │              │
│  │ Container Reg   │         │ Node.js Apps    │              │
│  │ CI/CD Runner    │         │ Docker Platform │              │
│  │ PostgreSQL      │         │ Redis Cache     │              │
│  │ Redis           │         │ PM2 Manager     │              │
│  └─────────────────┘         └─────────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                    Shared Infrastructure                       │
│  • Security Hardening     • Backup Management                 │
│  • Network Configuration  • Monitoring (Netdata)              │
│  • Infrastructure Mgmt    • Log Aggregation                   │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Virtualization**: Vagrant + Libvirt/QEMU
- **Operating System**: Ubuntu 22.04 LTS
- **Containerization**: Docker + Docker Compose
- **Web Server**: Nginx (reverse proxy + static files)
- **Application Runtime**: Node.js + PM2
- **Database**: PostgreSQL + Redis
- **CI/CD**: GitLab CI/CD + GitLab Runner
- **Monitoring**: Netdata + Prometheus Node Exporter + Collectd
- **Security**: UFW Firewall + Fail2ban + SSH hardening
- **Backup**: Automated backup system with retention policies

## Network Configuration

### IP Address Allocation

| Component | Public IP | Private IP | Purpose |
|-----------|-----------|------------|---------|
| GitLab VPS | 136.243.208.130 | 10.0.0.10 | GitLab platform, Container Registry, CI/CD |
| Nginx App VPS | 136.243.208.131 | 10.0.0.20 | Web server, Application hosting |
| Gateway | 136.243.208.129 | 10.0.0.1 | Network gateway |

### Network Topology

```
Internet
    │
    ▼
Production Network (136.243.208.128/29)
    │
    ├─ GitLab VPS (130) ◄─┐
    │                     │
    └─ Nginx VPS (131) ◄──┤
                          │
Private Network (10.0.0.0/24)
    │                     │
    ├─ GitLab VPS (10) ◄──┘
    └─ Nginx VPS (20)
```

### Port Configuration

#### GitLab VPS (10.0.0.10)

- **22**: SSH (restricted)
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS (GitLab Web UI)
- **5050**: GitLab Container Registry
- **8080**: GitLab Runner API
- **19999**: Netdata monitoring
- **9100**: Prometheus Node Exporter

#### Nginx App VPS (10.0.0.20)

- **22**: SSH (restricted)
- **80**: HTTP (Nginx, redirects to HTTPS)
- **443**: HTTPS (Nginx reverse proxy)
- **3000**: Node.js application
- **6379**: Redis (internal)
- **19999**: Netdata monitoring
- **9100**: Prometheus Node Exporter

## VPS Instances

### GitLab VPS

**Purpose**: Complete GitLab platform with Container Registry and CI/CD capabilities

**Specifications**:

- **CPU**: 4 cores
- **Memory**: 8 GB
- **Storage**: 100 GB
- **OS**: Ubuntu 22.04 LTS

**Services**:

- GitLab Community Edition
- GitLab Container Registry
- GitLab CI/CD Runner
- PostgreSQL database
- Redis cache
- Nginx (GitLab integrated)

**Key Features**:

- Git repository hosting
- Issue tracking and project management
- CI/CD pipelines
- Container registry
- User authentication and authorization
- Integrated monitoring

### Nginx App VPS

**Purpose**: High-performance web server and application hosting platform

**Specifications**:

- **CPU**: 2 cores
- **Memory**: 4 GB
- **Storage**: 50 GB
- **OS**: Ubuntu 22.04 LTS

**Services**:

- Nginx reverse proxy
- Node.js applications
- PM2 process manager
- Docker platform
- Redis cache

**Key Features**:

- SSL termination
- Load balancing
- Static file serving
- Application proxy
- Container orchestration
- Process management

## Deployment Guide

### Prerequisites

1. **Host System Requirements**:
   - Ubuntu 22.04 LTS or compatible Linux distribution
   - 16 GB RAM minimum (32 GB recommended)
   - 200 GB available storage
   - KVM/QEMU virtualization support
   - Root access

2. **Required Software**:

   ```bash
   # Install Vagrant
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install vagrant

   # Install KVM/QEMU
   sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

   # Install Vagrant Libvirt plugin
   vagrant plugin install vagrant-libvirt

   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```

### Quick Start

1. **Clone the repository**:

   ```bash
   git clone https://github.com/TstCop/vps-hosting-infrastructure.git
   cd vps-hosting-infrastructure
   ```

2. **Deploy the infrastructure**:

   ```bash
   sudo ./core/shared/scripts/infrastructure-mgmt.sh deploy
   ```

3. **Check status**:

   ```bash
   sudo ./core/shared/scripts/infrastructure-mgmt.sh status
   ```

### Manual Deployment

#### 1. Deploy GitLab VPS

```bash
cd core/gitlab-vps
vagrant up --provider=libvirt
```

Wait for deployment to complete (approximately 10-15 minutes).

#### 2. Deploy Nginx App VPS

```bash
cd ../nginx-app-vps
vagrant up --provider=libvirt
```

Wait for deployment to complete (approximately 5-10 minutes).

#### 3. Configure Shared Infrastructure

```bash
cd ../shared
sudo ./scripts/security-hardening.sh
sudo ./scripts/monitoring-setup.sh
sudo ./scripts/backup-management.sh --verify
```

### Post-Deployment Configuration

1. **Access GitLab**:
   - Web UI: <https://136.243.208.130>
   - Default admin user: `root`
   - Password: Check `/etc/gitlab/initial_root_password` on GitLab VPS

2. **Configure GitLab**:
   - Set admin password
   - Configure external URL
   - Enable Container Registry
   - Set up CI/CD runners

3. **Configure Applications**:
   - Deploy applications to Nginx VPS
   - Configure Nginx virtual hosts
   - Set up SSL certificates
   - Configure monitoring

## Configuration Reference

### Infrastructure Configuration

Main configuration file: `core/shared/config/infrastructure.yaml`

```yaml
# Network Configuration
network:
  production:
    subnet: "136.243.208.128/29"
    gateway: "136.243.208.129"
    gitlab_ip: "136.243.208.130"
    nginx_ip: "136.243.208.131"

  private:
    subnet: "10.0.0.0/24"
    gateway: "10.0.0.1"
    gitlab_ip: "10.0.0.10"
    nginx_ip: "10.0.0.20"

# VPS Specifications
vps:
  gitlab:
    cpu: 4
    memory: 8192
    storage: 100

  nginx:
    cpu: 2
    memory: 4096
    storage: 50

# Services Configuration
services:
  gitlab:
    external_url: "https://136.243.208.130"
    registry_url: "136.243.208.130:5050"

  nginx:
    ssl_enabled: true
    proxy_timeout: 60
```

### Environment Variables

Copy and customize environment templates:

```bash
# For applications
cp core/shared/templates/.env.template /opt/app/.env

# For GitLab
cp core/gitlab-vps/config/gitlab.rb.template /etc/gitlab/gitlab.rb
```

### SSL Certificates

Generate or install SSL certificates:

```bash
# Self-signed certificates (development)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/your-domain.key \
  -out /etc/nginx/ssl/your-domain.crt

# Let's Encrypt (production)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Monitoring & Maintenance

### Monitoring Services

1. **Netdata** (Real-time monitoring):
   - GitLab VPS: <http://10.0.0.10:19999>
   - Nginx VPS: <http://10.0.0.20:19999>

2. **Prometheus Node Exporter** (Metrics collection):
   - GitLab VPS: <http://10.0.0.10:9100/metrics>
   - Nginx VPS: <http://10.0.0.20:9100/metrics>

3. **System Dashboard**:

   ```bash
   sudo /opt/monitoring-dashboard.sh
   ```

### Health Checks

Run comprehensive health checks:

```bash
sudo /opt/health-check.sh
```

Automated health checks run every 15 minutes via cron.

### Backup Management

#### Manual Backup

```bash
# Full backup
sudo ./core/shared/scripts/backup-management.sh --full

# Specific components
sudo ./core/shared/scripts/backup-management.sh --gitlab
sudo ./core/shared/scripts/backup-management.sh --databases
sudo ./core/shared/scripts/backup-management.sh --system
```

#### Backup Schedule

- **Daily backups**: 2 AM (automated)
- **Weekly backups**: Sunday (automated)
- **Monthly backups**: 1st of month (automated)

#### Backup Locations

- Base directory: `/backup`
- Daily archives: `/backup/archives/daily`
- Weekly archives: `/backup/archives/weekly`
- Monthly archives: `/backup/archives/monthly`

#### Backup Retention

- Daily backups: 30 days
- GitLab backups: 7 days
- Weekly backups: 60 days
- Monthly backups: 180 days

### Log Management

#### Log Locations

- System logs: `/var/log/`
- Application logs: `/opt/app/logs/`
- Backup logs: `/var/log/backup.log`
- Health check logs: `/var/log/health-check.log`
- Netdata alerts: `/var/log/netdata-alerts.log`

#### Log Rotation

Logs are automatically rotated using logrotate configuration.

## Security

### Security Features

1. **Network Security**:
   - UFW firewall with restrictive rules
   - Fail2ban for intrusion prevention
   - Private network isolation
   - Rate limiting

2. **SSH Security**:
   - Key-based authentication only
   - Root login disabled
   - Non-standard port (configurable)
   - Connection limits

3. **Application Security**:
   - HTTPS enforcement
   - Security headers
   - Input validation
   - CORS configuration

4. **System Security**:
   - Automatic security updates
   - File integrity monitoring
   - Process monitoring
   - Resource limits

### Security Hardening

Run security hardening script:

```bash
sudo ./core/shared/scripts/security-hardening.sh
```

This script configures:

- SSH security settings
- Firewall rules
- Fail2ban protection
- System security parameters
- Audit logging
- File permissions

### Security Monitoring

Security events are monitored via:

- Fail2ban logs
- Authentication logs
- Netdata security alerts
- System audit logs

## Troubleshooting

### Common Issues

#### 1. VPS Won't Start

**Symptoms**: Vagrant up fails or VPS doesn't respond

**Solutions**:

```bash
# Check virtualization support
sudo virt-host-validate

# Check available resources
free -h
df -h

# Restart libvirt
sudo systemctl restart libvirtd

# Destroy and recreate
vagrant destroy -f
vagrant up --provider=libvirt
```

#### 2. Network Connectivity Issues

**Symptoms**: VPS instances can't communicate

**Solutions**:

```bash
# Check network bridges
ip link show
brctl show

# Restart networking
sudo systemctl restart networking

# Check firewall rules
sudo ufw status verbose

# Test connectivity
ping 10.0.0.10
ping 10.0.0.20
```

#### 3. GitLab Won't Start

**Symptoms**: GitLab services fail to start

**Solutions**:

```bash
# Check GitLab status
sudo gitlab-ctl status

# Reconfigure GitLab
sudo gitlab-ctl reconfigure

# Check logs
sudo gitlab-ctl tail

# Restart GitLab
sudo gitlab-ctl restart
```

#### 4. Nginx Configuration Issues

**Symptoms**: Web server returns errors

**Solutions**:

```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# Reload configuration
sudo systemctl reload nginx
```

### Diagnostic Commands

```bash
# Infrastructure status
sudo ./core/shared/scripts/infrastructure-mgmt.sh status

# Health check
sudo /opt/health-check.sh

# Monitor resources
sudo /opt/monitoring-dashboard.sh

# Check services
sudo systemctl status nginx postgresql redis docker

# Network diagnostics
sudo netstat -tlnp
sudo ss -tlnp
```

### Log Analysis

```bash
# System logs
sudo journalctl -f

# Application logs
sudo tail -f /opt/app/logs/combined.log

# Security logs
sudo tail -f /var/log/auth.log
sudo fail2ban-client status

# Monitoring alerts
sudo tail -f /var/log/netdata-alerts.log
```

## API Reference

### Health Check Endpoints

#### Application Health

```
GET /health
```

Response:

```json
{
  "status": "OK",
  "timestamp": "2024-01-15T10:00:00.000Z",
  "uptime": 3600,
  "environment": "production",
  "version": "1.0.0",
  "memory": {
    "rss": 52428800,
    "heapTotal": 41943040,
    "heapUsed": 28123456
  }
}
```

#### Readiness Check

```
GET /ready
```

Response:

```json
{
  "status": "Ready",
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

#### System Metrics

```
GET /metrics
```

Response:

```json
{
  "timestamp": "2024-01-15T10:00:00.000Z",
  "process": {
    "pid": 1234,
    "uptime": 3600,
    "memory": {...},
    "cpu": {...}
  },
  "system": {
    "platform": "linux",
    "arch": "x64",
    "nodeVersion": "v18.17.0"
  }
}
```

### Infrastructure API

#### Infrastructure Status

```
GET /api/infrastructure
```

Response:

```json
{
  "vps": {
    "gitlab": {
      "ip": "10.0.0.10",
      "publicIp": "136.243.208.130",
      "status": "running"
    },
    "nginx": {
      "ip": "10.0.0.20",
      "publicIp": "136.243.208.131",
      "status": "running"
    }
  },
  "monitoring": {
    "netdata": "http://10.0.0.20:19999",
    "prometheus": "http://localhost:9100"
  },
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

#### GitLab Integration

```
GET /api/gitlab/status
```

Response:

```json
{
  "gitlab": {
    "status": "connected",
    "endpoint": "http://10.0.0.10",
    "lastCheck": "2024-01-15T10:00:00.000Z"
  }
}
```

### Management Commands

All management commands are available through the infrastructure management script:

```bash
# Status and monitoring
sudo ./core/shared/scripts/infrastructure-mgmt.sh status
sudo ./core/shared/scripts/infrastructure-mgmt.sh monitor
sudo ./core/shared/scripts/infrastructure-mgmt.sh health

# Deployment and lifecycle
sudo ./core/shared/scripts/infrastructure-mgmt.sh deploy
sudo ./core/shared/scripts/infrastructure-mgmt.sh start
sudo ./core/shared/scripts/infrastructure-mgmt.sh stop
sudo ./core/shared/scripts/infrastructure-mgmt.sh restart

# Backup and maintenance
sudo ./core/shared/scripts/infrastructure-mgmt.sh backup
sudo ./core/shared/scripts/infrastructure-mgmt.sh backup --gitlab
sudo ./core/shared/scripts/infrastructure-mgmt.sh restore
```

---

## Support and Maintenance

For support and maintenance:

1. **Documentation**: Check this documentation and inline comments
2. **Logs**: Review system and application logs
3. **Monitoring**: Use Netdata and health check tools
4. **Community**: GitLab community documentation and forums

## License

This infrastructure is provided under the MIT License. See LICENSE file for details.

---

*Last Updated: January 2024*

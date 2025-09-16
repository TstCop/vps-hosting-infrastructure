# Nginx/App VPS Infrastructure

Complete production-ready infrastructure for hosting Node.js applications with Nginx reverse proxy, Docker containerization, and comprehensive monitoring.

## 📋 Overview

This VPS serves as the application and reverse proxy server in the VPS hosting infrastructure, providing:

- **Nginx Reverse Proxy**: Load balancing and SSL termination
- **Node.js Applications**: High-performance JavaScript runtime with PM2
- **Docker Platform**: Containerized application deployment
- **Security Features**: Firewall, fail2ban, and SSL/TLS encryption
- **Monitoring**: Netdata, health checks, and logging
- **Automated Backups**: Scheduled data protection

## 🏗️ Architecture

### Network Configuration

- **Public IP**: 136.243.208.131/29
- **Private IP**: 10.0.0.20/24
- **Gateway**: 136.243.208.129
- **DNS**: 8.8.8.8, 8.8.4.4, 1.1.1.1

### Service Stack

```
┌─────────────────────────────────────────┐
│           Internet Traffic             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Nginx Reverse Proxy            │
│    (Port 80/443 → SSL Termination)     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Load Balancer                  │
│     (Round Robin / Least Conn)          │
└─────┬───────────────────────────────┬───┘
      │                               │
┌─────▼──────┐                 ┌─────▼──────┐
│ Node.js App│                 │    API     │
│  (Port 3000)│                 │ (Port 8080)│
│   PM2 x2   │                 │   PM2 x1   │
└────────────┘                 └────────────┘
      │                               │
┌─────▼───────────────────────────────▼───┐
│         Docker Containers              │
│  (Redis, Monitoring, Services)         │
└─────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Ubuntu 22.04 LTS
- Vagrant + Libvirt (configured)
- Network access to GitLab VPS (10.0.0.10)

### Deployment

```bash
# 1. Navigate to the nginx-app-vps directory
cd /opt/xcloud/vps-hosting-infrastructure/core/nginx-app-vps

# 2. Start the VM
vagrant up

# 3. SSH into the VM
vagrant ssh nginx-app-vps

# 4. Run the installation scripts (automatically executed by Vagrant)
# Scripts are run in this order:
# - provision-nginx-app.sh (system setup)
# - install-nginx.sh (web server)
# - install-nodejs.sh (runtime)
# - install-docker.sh (containers)
# - deploy-app.sh (application)
```

## 📁 Directory Structure

```
nginx-app-vps/
├── Vagrantfile                 # VM configuration
├── README.md                   # This documentation
├── config/                     # Configuration files
│   ├── nginx.yaml             # Nginx/application config
│   ├── docker-compose.yml     # Container orchestration
│   └── network.yaml           # Network settings
└── scripts/                    # Installation and management
    ├── provision-nginx-app.sh  # Main provisioning
    ├── install-nginx.sh        # Nginx setup
    ├── install-nodejs.sh       # Node.js setup
    ├── install-docker.sh       # Docker setup
    └── deploy-app.sh           # Application deployment
```

## ⚙️ Configuration

### Environment Variables

```bash
# /opt/app/.env
NODE_ENV=production
PORT=3000
API_PORT=8080

# Database (GitLab VPS PostgreSQL)
DATABASE_URL=postgresql://app_user:password@10.0.0.10:5432/app_production

# Redis (GitLab VPS)
REDIS_URL=redis://:password@10.0.0.10:6379/0

# Security
JWT_SECRET=your-secret-key
SESSION_SECRET=your-session-secret

# GitLab Integration
GITLAB_API_URL=https://gitlab.vps.local/api/v4
GITLAB_TOKEN=your-gitlab-token
```

### Nginx Configuration

The Nginx configuration includes:

- SSL/TLS termination with modern ciphers
- Rate limiting and security headers
- Upstream load balancing
- Static file serving with caching
- Health check endpoints

### PM2 Configuration

```javascript
// /opt/app/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'vps-hosting-app',
      script: './dist/app.js',
      instances: 2,
      exec_mode: 'cluster',
      max_memory_restart: '500M'
    },
    {
      name: 'vps-hosting-api',
      script: './dist/api.js',
      instances: 1,
      exec_mode: 'fork',
      max_memory_restart: '300M'
    }
  ]
};
```

## 🌐 Service Endpoints

### Application URLs

- **Main Application**: <https://app.vps.local> (or <http://136.243.208.131>)
- **API**: <https://api.app.vps.local> (or <http://136.243.208.131:8080>)
- **Health Check**: /health
- **System Status**: /api/status

### Development URLs (Port Forwarding)

- **Main App**: <http://localhost:8081>
- **API**: <http://localhost:8080>
- **HTTPS**: <https://localhost:8444>

### Monitoring

- **Netdata**: <http://localhost:8090/netdata/>
- **Node Exporter**: <http://localhost:8090/node-exporter/>
- **Dashboard**: <http://localhost:3000/monitoring.html>

## 🔧 Management Commands

### Application Management

```bash
# Application control
/opt/app/scripts/app-manager.sh start|stop|restart|status

# View logs
/opt/app/scripts/app-manager.sh logs

# Health check
/opt/app/scripts/app-manager.sh health

# Deploy new version
/opt/app/scripts/app-manager.sh deploy
```

### Nginx Management

```bash
# Nginx control
/opt/app/scripts/nginx-manager.sh reload|restart|status

# View logs
/opt/app/scripts/nginx-manager.sh logs

# Manage sites
/opt/app/scripts/nginx-manager.sh enable|disable [site-name]

# SSL renewal
/opt/app/scripts/nginx-manager.sh ssl-renew
```

### Docker Management

```bash
# Container control
/opt/app/scripts/docker-manager.sh up|down|restart

# View status
/opt/app/scripts/docker-manager.sh status

# Build images
/opt/app/scripts/docker-manager.sh build

# Deploy from registry
/opt/app/scripts/docker-manager.sh deploy
```

### System Management

```bash
# Health check
/opt/app/scripts/health-check.sh

# Backup
/opt/app/scripts/backup.sh

# View system status
systemctl status nginx docker pm2-vagrant
```

## 🐳 Docker Integration

### Docker Compose Services

- **app**: Node.js application container
- **redis**: Redis cache/session store
- **nginx**: Reverse proxy container
- **certbot**: SSL certificate management
- **node-exporter**: Metrics collection
- **promtail**: Log aggregation

### Container Management

```bash
# Start all containers
docker-compose -f /opt/app/config/docker-compose.yml up -d

# View container status
docker ps

# View logs
docker-compose logs -f

# Scale application
docker-compose up -d --scale app=3
```

## 🔒 Security Features

### Firewall Configuration

```bash
# UFW rules automatically configured:
Port 22  - SSH access
Port 80  - HTTP traffic
Port 443 - HTTPS traffic
Port 3000 - Node.js (internal network only)
Port 8080 - API (internal network only)
```

### Fail2ban Protection

- SSH brute force protection
- Nginx rate limiting violations
- HTTP authentication failures

### SSL/TLS Security

- TLS 1.2 and 1.3 only
- Strong cipher suites
- HSTS headers
- OCSP stapling

## 📊 Monitoring and Logging

### System Monitoring

- **Netdata**: Real-time system metrics
- **Node Exporter**: Prometheus-compatible metrics
- **Health Checks**: Automated endpoint monitoring

### Log Files

```bash
# Application logs
/opt/app/logs/pm2-*.log
/var/log/app/

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs
/var/log/syslog
/var/log/auth.log
```

### Log Rotation

Automatic log rotation configured for:

- Application logs (daily, 30 days retention)
- Nginx logs (daily, 52 weeks retention)
- Docker logs (100MB max size, 5 files)

## 💾 Backup and Recovery

### Automated Backups

Daily backups at 2 AM include:

- Application configuration files
- User data and uploads
- SSL certificates
- Recent log files

### Backup Locations

- **Local**: /backup/nginx-app/
- **Remote**: 10.0.0.10:/backup/remote/nginx-app/ (GitLab VPS)

### Recovery Procedure

```bash
# 1. Stop services
sudo systemctl stop nginx
pm2 stop all

# 2. Restore from backup
cd /backup/nginx-app
tar -xzf nginx-app-backup-YYYYMMDD_HHMMSS.tar.gz

# 3. Restore configurations
sudo cp backup/etc/nginx/* /etc/nginx/
cp backup/opt/app/* /opt/app/

# 4. Restart services
sudo systemctl start nginx
pm2 start ecosystem.config.js
```

## 🔧 Troubleshooting

### Common Issues

#### Application Won't Start

```bash
# Check PM2 status
pm2 status
pm2 logs

# Check Node.js process
ps aux | grep node

# Check application health
curl http://localhost:3000/health
```

#### Nginx Issues

```bash
# Test configuration
sudo nginx -t

# Check status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log
```

#### Docker Problems

```bash
# Check Docker daemon
sudo systemctl status docker

# View container status
docker ps -a

# Check container logs
docker logs container-name
```

#### Network Connectivity

```bash
# Test internal connectivity
ping 10.0.0.10  # GitLab VPS

# Check port availability
netstat -tuln | grep -E ':80|:443|:3000|:8080'

# Test external connectivity
curl -I http://google.com
```

### Performance Optimization

#### Application Performance

```bash
# Monitor PM2 processes
pm2 monit

# Check memory usage
free -h
top -p $(pgrep node)

# Monitor I/O
iotop
```

#### Nginx Optimization

```bash
# Check connection limits
nginx -T | grep worker_connections

# Monitor active connections
curl http://localhost/nginx_status
```

## 📈 Scaling Considerations

### Horizontal Scaling

- Add more PM2 instances
- Scale Docker containers
- Load balance across multiple VPS instances

### Vertical Scaling

- Increase VM memory (current: 2GB)
- Add CPU cores (current: 2)
- Expand storage (current: 50GB)

### Database Scaling

- Use GitLab VPS PostgreSQL with connection pooling
- Implement Redis for session storage and caching
- Consider read replicas for high-traffic scenarios

## 🔄 Maintenance

### Regular Maintenance Tasks

#### Daily

- Health check monitoring
- Log review
- Backup verification

#### Weekly

- Security updates
- Certificate renewal check
- Performance review

#### Monthly

- Full system backup
- Log rotation cleanup
- Security audit

### Update Procedures

#### Application Updates

```bash
# 1. Pull latest code
cd /opt/app
git pull origin main

# 2. Install dependencies
npm install

# 3. Build application
npm run build

# 4. Zero-downtime reload
pm2 reload ecosystem.config.js
```

#### System Updates

```bash
# 1. Update package lists
sudo apt update

# 2. Upgrade packages
sudo apt upgrade

# 3. Reboot if required
sudo reboot
```

## 📞 Support and Documentation

### Configuration Files

- `/opt/app/.env` - Environment variables
- `/etc/nginx/nginx.conf` - Nginx configuration
- `/opt/app/ecosystem.config.js` - PM2 configuration
- `/opt/app/config/docker-compose.yml` - Docker services

### Management Scripts

All management scripts are located in `/opt/app/scripts/`:

- `app-manager.sh` - Application lifecycle
- `nginx-manager.sh` - Web server management
- `docker-manager.sh` - Container management
- `health-check.sh` - System health monitoring
- `backup.sh` - Data backup operations

### Log Locations

- Applications: `/opt/app/logs/`
- Web server: `/var/log/nginx/`
- System: `/var/log/`
- PM2: `~/.pm2/logs/`

For additional support, refer to the main project documentation in the root directory.

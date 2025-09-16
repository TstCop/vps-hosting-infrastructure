#!/bin/bash

# Docker Installation and Configuration Script
# Installs Docker Engine, Docker Compose, and configures for VPS hosting

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

log "🐳 Starting Docker installation and configuration..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Remove old Docker installations
log "🧹 Removing old Docker installations..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Update package index
log "📦 Updating package index..."
apt-get update

# Install prerequisites
log "🔧 Installing prerequisites..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Add Docker's official GPG key
log "🔑 Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
log "📚 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker packages
apt-get update

# Install Docker Engine
log "🐳 Installing Docker Engine..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
DOCKER_VERSION=$(docker --version)
log "✅ Docker installed: $DOCKER_VERSION"

# Install Docker Compose standalone (for compatibility)
log "🔗 Installing Docker Compose standalone..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

COMPOSE_VERSION_INSTALLED=$(docker-compose --version)
log "✅ Docker Compose installed: $COMPOSE_VERSION_INSTALLED"

# Add vagrant user to docker group
log "👤 Adding vagrant user to docker group..."
usermod -aG docker vagrant

# Add appuser to docker group
usermod -aG docker appuser 2>/dev/null || true

# Configure Docker daemon
log "⚙️ Configuring Docker daemon..."
mkdir -p /etc/docker

cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "iptables": true,
  "ip-forward": true,
  "dns": ["8.8.8.8", "8.8.4.4"],
  "default-address-pools": [
    {
      "base": "172.16.0.0/12",
      "size": 24
    }
  ],
  "insecure-registries": ["registry.gitlab.vps.local:5050"],
  "registry-mirrors": []
}
EOF

# Create docker directories
log "📁 Creating Docker directories..."
mkdir -p /opt/docker/{data,logs,registry}
mkdir -p /var/lib/docker-registry

# Set proper ownership
chown -R vagrant:vagrant /opt/docker

# Configure log rotation for Docker
log "📝 Configuring Docker log rotation..."
cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Enable and start Docker
log "🔄 Enabling and starting Docker..."
systemctl enable docker
systemctl enable containerd
systemctl start docker
systemctl start containerd

# Verify Docker is running
if systemctl is-active --quiet docker; then
    log "✅ Docker is running successfully"
else
    error "❌ Failed to start Docker"
fi

# Create Docker networks
log "🌐 Creating Docker networks..."
docker network create app-network --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 2>/dev/null || warn "Network app-network may already exist"

# Create Docker volumes
log "💾 Creating Docker volumes..."
docker volume create app_data 2>/dev/null || warn "Volume app_data may already exist"
docker volume create redis_data 2>/dev/null || warn "Volume redis_data may already exist"
docker volume create nginx_cache 2>/dev/null || warn "Volume nginx_cache may already exist"

# Setup Docker registry authentication (for GitLab registry)
log "🔐 Setting up Docker registry authentication..."
su - vagrant -c "mkdir -p ~/.docker"

cat > /home/vagrant/.docker/config.json << 'EOF'
{
  "auths": {
    "registry.gitlab.vps.local:5050": {
      "auth": ""
    }
  },
  "credHelpers": {}
}
EOF

chown vagrant:vagrant /home/vagrant/.docker/config.json

# Create Docker management scripts
log "🛠️ Creating Docker management scripts..."

# Docker management script
cat > /opt/app/scripts/docker-manager.sh << 'EOF'
#!/bin/bash

# Docker Management Script
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

show_help() {
    echo "Docker Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      Show Docker status and containers"
    echo "  up          Start all containers"
    echo "  down        Stop all containers"
    echo "  restart     Restart all containers"
    echo "  logs        Show container logs"
    echo "  ps          List running containers"
    echo "  images      List Docker images"
    echo "  networks    List Docker networks"
    echo "  volumes     List Docker volumes"
    echo "  clean       Clean unused containers and images"
    echo "  build       Build application images"
    echo "  deploy      Deploy from GitLab registry"
    echo "  backup      Backup container data"
    echo "  help        Show this help message"
}

docker_status() {
    log "Docker System Status:"
    docker system info --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || docker info

    echo ""
    log "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"

    echo ""
    log "Docker Resources:"
    docker system df
}

container_logs() {
    if [ -z "$2" ]; then
        log "All container logs:"
        docker-compose -f /opt/app/config/docker-compose.yml logs --tail=50
    else
        log "Logs for container: $2"
        docker logs --tail=50 "$2"
    fi
}

docker_clean() {
    log "Cleaning unused Docker resources..."

    # Remove stopped containers
    docker container prune -f

    # Remove unused images
    docker image prune -f

    # Remove unused networks
    docker network prune -f

    # Remove unused volumes (be careful!)
    read -p "Remove unused volumes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume prune -f
    fi

    log "Docker cleanup completed"
}

build_images() {
    log "Building application images..."
    cd /opt/app

    if [ -f "Dockerfile" ]; then
        docker build -t vps-hosting-app:latest .
        log "Application image built successfully"
    else
        warn "No Dockerfile found in /opt/app"
    fi
}

deploy_from_registry() {
    log "Deploying from GitLab registry..."

    # Login to GitLab registry (requires token)
    if [ -n "$GITLAB_TOKEN" ]; then
        echo "$GITLAB_TOKEN" | docker login registry.gitlab.vps.local:5050 -u gitlab-ci-token --password-stdin
    fi

    # Pull latest images
    docker-compose -f /opt/app/config/docker-compose.yml pull

    # Restart containers with new images
    docker-compose -f /opt/app/config/docker-compose.yml up -d

    log "Deployment completed"
}

backup_data() {
    log "Backing up container data..."

    BACKUP_DIR="/backup/docker/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup volumes
    for volume in app_data redis_data nginx_cache; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            log "Backing up volume: $volume"
            docker run --rm -v "$volume":/data -v "$BACKUP_DIR":/backup alpine \
                tar czf "/backup/${volume}.tar.gz" -C /data .
        fi
    done

    log "Backup completed: $BACKUP_DIR"
}

case "$1" in
    status)
        docker_status
        ;;
    up)
        cd /opt/app
        log "Starting containers..."
        docker-compose -f config/docker-compose.yml up -d
        ;;
    down)
        cd /opt/app
        log "Stopping containers..."
        docker-compose -f config/docker-compose.yml down
        ;;
    restart)
        cd /opt/app
        log "Restarting containers..."
        docker-compose -f config/docker-compose.yml restart
        ;;
    logs)
        container_logs "$@"
        ;;
    ps)
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        ;;
    images)
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        ;;
    networks)
        docker network ls
        ;;
    volumes)
        docker volume ls
        ;;
    clean)
        docker_clean
        ;;
    build)
        build_images
        ;;
    deploy)
        deploy_from_registry
        ;;
    backup)
        backup_data
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
EOF

chmod +x /opt/app/scripts/docker-manager.sh

# Create Dockerfile for the application
log "🏗️ Creating application Dockerfile..."
cat > /opt/app/Dockerfile << 'EOF'
# Multi-stage Dockerfile for Node.js VPS Hosting Application

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci

# Copy source code
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache \
    dumb-init \
    curl \
    tini

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy static files
COPY public/ ./public/

# Create necessary directories
RUN mkdir -p logs data uploads && \
    chown -R appuser:nodejs /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose port
EXPOSE 3000

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
CMD ["node", "dist/app.js"]
EOF

# Create .dockerignore
cat > /opt/app/.dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
.vscode
*.log
dist
logs/*
data/*
uploads/*
.DS_Store
Thumbs.db
EOF

# Set proper ownership
chown -R vagrant:vagrant /opt/app

# Create Docker Compose override for development
log "🔧 Creating Docker Compose development override..."
cat > /opt/app/docker-compose.override.yml << 'EOF'
# Development overrides for docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      target: builder
    volumes:
      - ./src:/app/src
      - ./dist:/app/dist
      - app_logs:/app/logs
    environment:
      - NODE_ENV=development
    command: npm run dev
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port

  nginx:
    ports:
      - "8080:80"
      - "8443:443"
EOF

chown vagrant:vagrant /opt/app/docker-compose.override.yml

# Test Docker installation
log "🧪 Testing Docker installation..."
docker run --rm hello-world

if [ $? -eq 0 ]; then
    log "✅ Docker test completed successfully"
else
    error "❌ Docker test failed"
fi

# Configure firewall for Docker
log "🔥 Configuring firewall for Docker..."
ufw allow from 172.16.0.0/12 comment 'Docker containers'
ufw allow from 172.20.0.0/16 comment 'App network'

# Create monitoring script for Docker
cat > /opt/app/scripts/docker-monitor.sh << 'EOF'
#!/bin/bash

# Docker Monitoring Script
# Monitors Docker containers and sends alerts if needed

set -e

LOGFILE="/var/log/app/docker-monitor.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Check container health
check_containers() {
    log "Checking container health..."

    # Get list of containers that should be running
    expected_containers=("vps-hosting-app" "vps-redis" "vps-nginx")

    for container in "${expected_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            # Check container health
            health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            if [ "$health" = "healthy" ] || [ "$health" = "no-healthcheck" ]; then
                log "✅ $container is running and healthy"
            else
                log "⚠️ $container is running but unhealthy: $health"
            fi
        else
            log "❌ $container is not running"
        fi
    done
}

# Check Docker daemon
check_docker_daemon() {
    if systemctl is-active --quiet docker; then
        log "✅ Docker daemon is running"
    else
        log "❌ Docker daemon is not running"
        systemctl restart docker
    fi
}

# Check disk usage
check_disk_usage() {
    disk_usage=$(docker system df --format "table {{.Type}}\t{{.Size}}\t{{.Reclaimable}}" | tail -n +2)
    log "Docker disk usage:"
    echo "$disk_usage" | tee -a "$LOGFILE"
}

# Main monitoring function
main() {
    log "Starting Docker monitoring check..."
    check_docker_daemon
    check_containers
    check_disk_usage
    log "Docker monitoring check completed"
}

main
EOF

chmod +x /opt/app/scripts/docker-monitor.sh

# Add Docker monitoring to cron
log "⏰ Adding Docker monitoring to cron..."
(crontab -u vagrant -l 2>/dev/null; echo "*/5 * * * * /opt/app/scripts/docker-monitor.sh") | crontab -u vagrant -

# Display installation summary
log "📋 Docker Installation Summary:"
echo "======================================"
echo "Docker Version: $(docker --version)"
echo "Docker Compose Version: $(docker-compose --version)"
echo "Docker Status: $(systemctl is-active docker)"
echo "Containerd Status: $(systemctl is-active containerd)"
echo ""
echo "Docker Networks:"
docker network ls
echo ""
echo "Docker Volumes:"
docker volume ls
echo ""
echo "Management Scripts:"
echo "  Docker Manager: /opt/app/scripts/docker-manager.sh"
echo "  Docker Monitor: /opt/app/scripts/docker-monitor.sh"
echo ""
echo "Configuration Files:"
echo "  Daemon Config: /etc/docker/daemon.json"
echo "  Compose File: /opt/app/config/docker-compose.yml"
echo "  Dockerfile: /opt/app/Dockerfile"
echo "======================================"

log "✅ Docker installation and configuration completed successfully!"
log "🐳 Next steps:"
echo "  1. Build application: /opt/app/scripts/docker-manager.sh build"
echo "  2. Start containers: /opt/app/scripts/docker-manager.sh up"
echo "  3. Check status: /opt/app/scripts/docker-manager.sh status"
echo "  4. View logs: /opt/app/scripts/docker-manager.sh logs"
echo "  5. Configure GitLab registry access with proper tokens"

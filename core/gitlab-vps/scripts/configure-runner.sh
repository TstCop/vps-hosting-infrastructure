#!/bin/bash
# configure-runner.sh - GitLab Runner installation and configuration script
# File: /opt/xcloud/vps-hosting-infrastructure/core/gitlab-vps/scripts/configure-runner.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITLAB_URL="https://136.243.208.130"
RUNNER_NAME="gitlab-vps-runner"
RUNNER_TAGS="docker,ubuntu,vps,production"
CONCURRENT_JOBS=2

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

log "🏃 Starting GitLab Runner configuration..."

# Wait for GitLab to be ready
log "⏳ Waiting for GitLab to be ready..."
timeout 300 bash -c "until curl -s -o /dev/null -w '%{http_code}' $GITLAB_URL | grep -q '200\|302'; do sleep 10; echo 'Waiting for GitLab...'; done"

# Install GitLab Runner
log "📦 Installing GitLab Runner..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install -y gitlab-runner

# Create GitLab Runner user and add to docker group
log "👤 Configuring GitLab Runner user..."
usermod -aG docker gitlab-runner
usermod -aG sudo gitlab-runner

# Create runner directories
log "📁 Creating GitLab Runner directories..."
mkdir -p /home/gitlab-runner/.docker
mkdir -p /etc/gitlab-runner
mkdir -p /var/log/gitlab-runner

# Set proper permissions
chown -R gitlab-runner:gitlab-runner /home/gitlab-runner
chown -R gitlab-runner:gitlab-runner /var/log/gitlab-runner

# Get registration token from GitLab
log "🔑 Getting registration token..."
warning "⚠️ Manual step required: Get the registration token from GitLab Admin Area > CI/CD > Runners"
warning "💡 Or use the project-specific token from your project's Settings > CI/CD > Runners"

# Create registration script template
cat > /root/register-gitlab-runner.sh << 'EOF'
#!/bin/bash
# GitLab Runner registration script
# Usage: ./register-gitlab-runner.sh <REGISTRATION_TOKEN>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <REGISTRATION_TOKEN>"
    echo ""
    echo "Get the registration token from:"
    echo "1. GitLab Admin Area > CI/CD > Runners (instance runner)"
    echo "2. Project Settings > CI/CD > Runners (project runner)"
    exit 1
fi

REGISTRATION_TOKEN=$1

echo "🏃 Registering GitLab Runner..."

gitlab-runner register \
  --non-interactive \
  --url "https://136.243.208.130" \
  --registration-token "$REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "ubuntu:22.04" \
  --description "GitLab VPS Production Runner" \
  --tag-list "docker,ubuntu,vps,production" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-privileged="false" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-volumes "/cache" \
  --docker-network-mode="host" \
  --docker-pull-policy="if-not-present"

if [ $? -eq 0 ]; then
    echo "✅ GitLab Runner registered successfully!"
    gitlab-runner verify
    gitlab-runner list
else
    echo "❌ GitLab Runner registration failed!"
    exit 1
fi
EOF

chmod +x /root/register-gitlab-runner.sh

# Create GitLab Runner configuration template
log "⚙️ Creating GitLab Runner configuration template..."
cat > /etc/gitlab-runner/config.toml.template << 'EOF'
# GitLab Runner Configuration Template
concurrent = 2
check_interval = 3
log_level = "info"
log_format = "runner"

[session_server]
  session_timeout = 1800

[[runners]]
  name = "gitlab-vps-runner"
  url = "https://136.243.208.130"
  token = "REPLACE_WITH_ACTUAL_TOKEN"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "ubuntu:22.04"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
    shm_size = 0
    network_mode = "host"
    pull_policy = "if-not-present"
EOF

# Configure Docker daemon for GitLab Runner
log "🐳 Configuring Docker for GitLab Runner..."
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "hard": 65536,
      "soft": 65536
    }
  }
}
EOF

systemctl restart docker

# Create GitLab Runner service configuration
log "🔧 Configuring GitLab Runner service..."
cat > /etc/systemd/system/gitlab-runner.service.d/override.conf << 'EOF'
[Service]
LimitNOFILE=65536
LimitNPROC=65536
Environment="HOME=/home/gitlab-runner"
EOF

mkdir -p /etc/systemd/system/gitlab-runner.service.d/
systemctl daemon-reload

# Create runner monitoring script
log "📊 Creating runner monitoring script..."
cat > /usr/local/bin/gitlab-runner-monitor.sh << 'EOF'
#!/bin/bash
# GitLab Runner monitoring script

echo "🏃 GitLab Runner Status"
echo "======================"

# Runner service status
echo -e "\n🔧 Service Status:"
systemctl status gitlab-runner --no-pager -l

# Runner verification
echo -e "\n✅ Runner Verification:"
gitlab-runner verify

# Runner list
echo -e "\n📋 Registered Runners:"
gitlab-runner list

# Docker status
echo -e "\n🐳 Docker Status:"
docker info | grep -E "(Server Version|Storage Driver|Logging Driver)"

# Running containers
echo -e "\n🏗️ Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Recent runner logs
echo -e "\n📝 Recent Runner Logs:"
journalctl -u gitlab-runner --no-pager -n 10

# System resources
echo -e "\n💻 System Resources:"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') available"
EOF

chmod +x /usr/local/bin/gitlab-runner-monitor.sh

# Create runner cleanup script
log "🧹 Creating runner cleanup script..."
cat > /usr/local/bin/gitlab-runner-cleanup.sh << 'EOF'
#!/bin/bash
# GitLab Runner cleanup script

echo "🧹 GitLab Runner Cleanup"
echo "========================"

# Stop GitLab Runner
echo "Stopping GitLab Runner..."
gitlab-runner stop

# Clean up old Docker containers
echo "Cleaning up Docker containers..."
docker container prune -f

# Clean up Docker images
echo "Cleaning up Docker images..."
docker image prune -a -f

# Clean up Docker volumes
echo "Cleaning up Docker volumes..."
docker volume prune -f

# Clean up Docker networks
echo "Cleaning up Docker networks..."
docker network prune -f

# Clean up GitLab Runner builds
echo "Cleaning up build cache..."
rm -rf /tmp/gitlab-runner-builds/* 2>/dev/null || true
rm -rf /home/gitlab-runner/builds/* 2>/dev/null || true

# Start GitLab Runner
echo "Starting GitLab Runner..."
gitlab-runner start

echo "✅ Cleanup completed!"
EOF

chmod +x /usr/local/bin/gitlab-runner-cleanup.sh

# Create automated cleanup cron job
log "⏰ Setting up cleanup cron job..."
(crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/local/bin/gitlab-runner-cleanup.sh >> /var/log/runner-cleanup.log 2>&1") | crontab -

# Configure log rotation for runner
log "📄 Configuring log rotation..."
cat > /etc/logrotate.d/gitlab-runner << 'EOF'
/var/log/gitlab-runner/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    copytruncate
    notifempty
}

/var/log/runner-cleanup.log {
    weekly
    missingok
    rotate 12
    compress
    delaycompress
    copytruncate
    notifempty
}
EOF

# Enable and start GitLab Runner service
log "🚀 Enabling GitLab Runner service..."
systemctl enable gitlab-runner
systemctl start gitlab-runner

# Create CI/CD pipeline templates
log "📋 Creating CI/CD pipeline templates..."
mkdir -p /opt/gitlab-runner/templates

cat > /opt/gitlab-runner/templates/.gitlab-ci.yml << 'EOF'
# GitLab CI/CD Pipeline Template for VPS Projects
# File: .gitlab-ci.yml

# Define stages
stages:
  - test
  - build
  - deploy

# Global variables
variables:
  DOCKER_TLS_CERTDIR: "/certs"
  DOCKER_DRIVER: overlay2

# Cache configuration
cache:
  paths:
    - node_modules/
    - vendor/
    - .cache/

# Before script (runs on every job)
before_script:
  - echo "Starting CI/CD pipeline..."
  - docker info
  - echo "Runner tags: $CI_RUNNER_TAGS"

# Test stage
test:unit:
  stage: test
  image: ubuntu:22.04
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq git curl
  script:
    - echo "Running unit tests..."
    - # Add your test commands here
  tags:
    - docker
  only:
    - merge_requests
    - main
    - develop

test:lint:
  stage: test
  image: ubuntu:22.04
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq shellcheck
  script:
    - echo "Running linting..."
    - find . -name "*.sh" -exec shellcheck {} \;
  tags:
    - docker
  allow_failure: true

# Build stage
build:application:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - echo "Building application..."
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  tags:
    - docker
  only:
    - main
    - develop

# Deploy stage
deploy:staging:
  stage: deploy
  image: ubuntu:22.04
  script:
    - echo "Deploying to staging..."
    - # Add deployment commands here
  environment:
    name: staging
    url: https://staging.xcloud.local
  tags:
    - docker
  only:
    - develop
  when: manual

deploy:production:
  stage: deploy
  image: ubuntu:22.04
  script:
    - echo "Deploying to production..."
    - # Add deployment commands here
  environment:
    name: production
    url: https://136.243.208.131
  tags:
    - docker
  only:
    - main
  when: manual
  needs:
    - build:application

# Cleanup job
cleanup:
  stage: .post
  image: docker:latest
  script:
    - docker system prune -f
  tags:
    - docker
  when: always
EOF

cat > /opt/gitlab-runner/templates/docker-compose.yml << 'EOF'
# Docker Compose template for GitLab Runner CI/CD
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - .:/app
      - /app/node_modules
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - app
    restart: unless-stopped

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
EOF

# Create documentation
log "📚 Creating documentation..."
cat > /opt/gitlab-runner/README.md << 'EOF'
# GitLab Runner Configuration

## Overview
GitLab Runner configured for the VPS hosting infrastructure.

## Configuration
- **Executor**: Docker
- **Concurrent Jobs**: 2
- **Tags**: docker, ubuntu, vps, production
- **Image**: ubuntu:22.04

## Management Commands

### Register Runner
```bash
sudo /root/register-gitlab-runner.sh <REGISTRATION_TOKEN>
```

### Monitor Runner
```bash
sudo gitlab-runner-monitor.sh
```

### Cleanup
```bash
sudo gitlab-runner-cleanup.sh
```

### Manual Commands
```bash
# Check status
sudo gitlab-runner status

# Verify runner
sudo gitlab-runner verify

# List runners
sudo gitlab-runner list

# Restart runner
sudo systemctl restart gitlab-runner

# View logs
sudo journalctl -u gitlab-runner -f
```

## CI/CD Templates
- `.gitlab-ci.yml`: Basic pipeline template
- `docker-compose.yml`: Multi-service deployment

## Troubleshooting
1. Check runner logs: `journalctl -u gitlab-runner`
2. Verify Docker: `docker info`
3. Check registration: `gitlab-runner verify`
4. Monitor resources: `gitlab-runner-monitor.sh`
EOF

# Set permissions
chown -R gitlab-runner:gitlab-runner /opt/gitlab-runner

success "✅ GitLab Runner configuration completed!"

log "📋 Next Steps:"
echo "1. Get registration token from GitLab Admin Area or Project Settings"
echo "2. Run: sudo /root/register-gitlab-runner.sh <TOKEN>"
echo "3. Verify registration: sudo gitlab-runner verify"
echo "4. Test with a sample CI/CD pipeline"
echo ""
echo "🔧 Useful commands:"
echo "  gitlab-runner-monitor.sh     - Monitor runner status"
echo "  gitlab-runner-cleanup.sh     - Clean up Docker resources"
echo "  systemctl status gitlab-runner - Check service status"

warning "⚠️ Remember to register the runner with your GitLab instance!"
warning "⚠️ Registration token can be found in GitLab Admin Area > CI/CD > Runners"

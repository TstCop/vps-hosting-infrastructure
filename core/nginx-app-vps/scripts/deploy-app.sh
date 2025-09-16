#!/bin/bash

# Application Deployment Script
# Deploys the VPS hosting application with full configuration

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

log "🚀 Starting VPS Hosting Application deployment..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should NOT be run as root. Run as vagrant user."
fi

# Check prerequisites
log "🔍 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    error "Node.js is not installed. Run install-nodejs.sh first."
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Run install-docker.sh first."
fi

# Check Nginx
if ! systemctl is-active --quiet nginx; then
    error "Nginx is not running. Run install-nginx.sh first."
fi

# Check PM2
if ! command -v pm2 &> /dev/null; then
    error "PM2 is not installed. Install Node.js properly first."
fi

NODE_VERSION=$(node --version)
DOCKER_VERSION=$(docker --version)
NGINX_VERSION=$(nginx -v 2>&1)

log "✅ Prerequisites check passed"
info "Node.js: $NODE_VERSION"
info "Docker: $DOCKER_VERSION"
info "Nginx: $NGINX_VERSION"

# Set working directory
cd /opt/app

# Load environment variables
if [ -f ".env" ]; then
    source .env
    log "✅ Environment variables loaded"
else
    warn "No .env file found. Using defaults."
fi

# Install/update dependencies
log "📦 Installing/updating dependencies..."
npm install

# Build application
log "🔨 Building TypeScript application..."
npm run build

if [ ! -d "dist" ]; then
    error "Build failed - dist directory not found"
fi

log "✅ Application built successfully"

# Configure SSL certificates (if domain is configured)
setup_ssl() {
    log "🔐 Setting up SSL certificates..."

    if [ "$NODE_ENV" = "production" ] && [ -n "$DOMAIN" ]; then
        info "Setting up SSL for domain: $DOMAIN"

        # Install certbot if not present
        if ! command -v certbot &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y certbot python3-certbot-nginx
        fi

        # Create certificate directories
        sudo mkdir -p /etc/letsencrypt/live/$DOMAIN

        # Generate self-signed certificate for development/testing
        if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
            warn "Generating self-signed certificate for testing"
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
                -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

            # Create chain file
            sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/etc/letsencrypt/live/$DOMAIN/chain.pem"
        fi

        log "✅ SSL certificates configured"
    else
        warn "Skipping SSL setup - not in production or no domain configured"
    fi
}

# Setup application directories
log "📁 Setting up application directories..."
mkdir -p logs data uploads public/{css,js,img}

# Create public files
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS Hosting Infrastructure</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
            max-width: 600px;
            text-align: center;
        }
        h1 { font-size: 2.5em; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .status {
            background: rgba(255,255,255,0.2);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .card {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 15px;
            border: 1px solid rgba(255,255,255,0.2);
        }
        .card h3 { margin-bottom: 10px; color: #fff; }
        .card p { opacity: 0.9; }
        .footer { margin-top: 30px; opacity: 0.8; font-size: 0.9em; }
        .emoji { font-size: 1.5em; margin-right: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1><span class="emoji">🚀</span>VPS Hosting Infrastructure</h1>

        <div class="status">
            <h2><span class="emoji">✅</span>System Online</h2>
            <p>All services are running and ready to serve your applications</p>
        </div>

        <div class="grid">
            <div class="card">
                <h3><span class="emoji">🌐</span>Web Server</h3>
                <p>Nginx reverse proxy with SSL/TLS encryption and load balancing</p>
            </div>

            <div class="card">
                <h3><span class="emoji">⚡</span>Node.js Runtime</h3>
                <p>High-performance JavaScript runtime with PM2 process management</p>
            </div>

            <div class="card">
                <h3><span class="emoji">🐳</span>Docker Platform</h3>
                <p>Containerized applications with orchestration and scaling capabilities</p>
            </div>

            <div class="card">
                <h3><span class="emoji">🔒</span>Security</h3>
                <p>Firewall protection, fail2ban, and automated security updates</p>
            </div>
        </div>

        <div class="footer">
            <p>VPS Hosting Infrastructure v1.0 | Nginx/App Server</p>
            <p>IP: 136.243.208.131 | Environment: Production</p>
        </div>
    </div>

    <script>
        // Simple health check animation
        setInterval(() => {
            fetch('/health')
                .then(response => response.json())
                .then(data => console.log('Health check:', data.status))
                .catch(err => console.warn('Health check failed:', err));
        }, 30000);
    </script>
</body>
</html>
EOF

# Start PM2 applications
log "🔄 Starting PM2 applications..."

# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start applications
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save

# Check PM2 status
pm2 status

log "✅ PM2 applications started successfully"

# Setup SSL certificates
setup_ssl

# Test application endpoints
log "🧪 Testing application endpoints..."

# Wait for applications to start
sleep 5

# Test main application
if curl -sf http://localhost:3000/health > /dev/null; then
    log "✅ Main application is responding"
else
    warn "❌ Main application is not responding"
fi

# Test API
if curl -sf http://localhost:8080/health > /dev/null; then
    log "✅ API is responding"
else
    warn "❌ API is not responding"
fi

# Reload Nginx configuration
log "🔄 Reloading Nginx configuration..."
sudo nginx -t && sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    log "✅ Nginx configuration reloaded successfully"
else
    error "❌ Nginx configuration reload failed"
fi

# Setup monitoring
setup_monitoring() {
    log "📊 Setting up monitoring..."

    # Create monitoring dashboard
    cat > public/monitoring.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>VPS Monitoring Dashboard</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .widget { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .widget h3 { margin-top: 0; color: #333; }
        .status-ok { color: #28a745; }
        .status-warn { color: #ffc107; }
        .status-error { color: #dc3545; }
        iframe { width: 100%; height: 400px; border: none; border-radius: 4px; }
    </style>
</head>
<body>
    <h1>🖥️ VPS Monitoring Dashboard</h1>

    <div class="dashboard">
        <div class="widget">
            <h3>📊 System Metrics</h3>
            <iframe src="http://localhost:8090/netdata/" title="Netdata System Monitoring"></iframe>
        </div>

        <div class="widget">
            <h3>📈 Node Exporter</h3>
            <iframe src="http://localhost:8090/node-exporter/" title="Node Exporter Metrics"></iframe>
        </div>

        <div class="widget">
            <h3>🔍 Application Status</h3>
            <div id="app-status">Loading...</div>
        </div>

        <div class="widget">
            <h3>🐳 Docker Containers</h3>
            <div id="docker-status">Loading...</div>
        </div>
    </div>

    <script>
        // Fetch application status
        async function updateStatus() {
            try {
                const appResponse = await fetch('/health');
                const appData = await appResponse.json();

                const apiResponse = await fetch('/api/status');
                const apiData = await apiResponse.json();

                document.getElementById('app-status').innerHTML = `
                    <p class="status-ok">✅ Main App: ${appData.message}</p>
                    <p class="status-ok">✅ API: ${apiData.status}</p>
                    <p>Uptime: ${Math.floor(appData.uptime)}s</p>
                    <p>Memory: ${Math.round(appData.memory.heapUsed / 1024 / 1024)}MB</p>
                `;
            } catch (error) {
                document.getElementById('app-status').innerHTML =
                    '<p class="status-error">❌ Unable to fetch status</p>';
            }
        }

        // Update status every 30 seconds
        updateStatus();
        setInterval(updateStatus, 30000);
    </script>
</body>
</html>
EOF

    log "✅ Monitoring dashboard created"
}

setup_monitoring

# Create deployment info file
log "📄 Creating deployment info..."
cat > deployment-info.json << EOF
{
  "deployment": {
    "timestamp": "$(date -Iseconds)",
    "version": "1.0.0",
    "environment": "${NODE_ENV:-production}",
    "server": "nginx-app-vps",
    "ip": "136.243.208.131"
  },
  "services": {
    "nginx": {
      "status": "$(systemctl is-active nginx)",
      "version": "$(nginx -v 2>&1 | cut -d' ' -f3)"
    },
    "nodejs": {
      "version": "$NODE_VERSION",
      "pm2_processes": $(pm2 jlist | jq length)
    },
    "docker": {
      "version": "$(docker --version | cut -d' ' -f3 | tr -d ',')",
      "containers": $(docker ps --format "{{.Names}}" | wc -l)
    }
  },
  "endpoints": {
    "main_app": "http://localhost:3000",
    "api": "http://localhost:8080",
    "health_check": "http://localhost:3000/health",
    "monitoring": "http://localhost:8090/netdata/"
  }
}
EOF

# Final verification
log "🔍 Performing final verification..."

# Check all critical services
services_ok=true

# Check Nginx
if ! systemctl is-active --quiet nginx; then
    error "❌ Nginx is not running"
    services_ok=false
fi

# Check PM2 processes
pm2_count=$(pm2 jlist | jq length)
if [ "$pm2_count" -eq 0 ]; then
    error "❌ No PM2 processes running"
    services_ok=false
fi

# Check Docker
if ! systemctl is-active --quiet docker; then
    warn "⚠️ Docker is not running"
fi

# Check application endpoints
if ! curl -sf http://localhost:3000/health > /dev/null; then
    error "❌ Main application health check failed"
    services_ok=false
fi

if ! curl -sf http://localhost:8080/health > /dev/null; then
    error "❌ API health check failed"
    services_ok=false
fi

if [ "$services_ok" = true ]; then
    log "✅ All critical services verified successfully"
else
    error "❌ Service verification failed"
fi

# Display deployment summary
log "📋 Deployment Summary:"
echo "======================================"
echo "🚀 VPS Hosting Application Deployed Successfully!"
echo ""
echo "📊 Server Information:"
echo "  Hostname: $(hostname)"
echo "  IP Address: 136.243.208.131"
echo "  Environment: ${NODE_ENV:-production}"
echo "  Deployment Time: $(date)"
echo ""
echo "🌐 Application Endpoints:"
echo "  Main App: http://localhost:3000"
echo "  API: http://localhost:8080"
echo "  Health Check: http://localhost:3000/health"
echo "  Status API: http://localhost:8080/api/status"
echo ""
echo "📊 Monitoring:"
echo "  Netdata: http://localhost:8090/netdata/"
echo "  Dashboard: http://localhost:3000/monitoring.html"
echo ""
echo "🔧 Management Commands:"
echo "  PM2 Status: pm2 status"
echo "  PM2 Logs: pm2 logs"
echo "  App Manager: /opt/app/scripts/app-manager.sh"
echo "  Docker Manager: /opt/app/scripts/docker-manager.sh"
echo "  Nginx Manager: /opt/app/scripts/nginx-manager.sh"
echo ""
echo "📝 Log Files:"
echo "  Application: /opt/app/logs/"
echo "  Nginx: /var/log/nginx/"
echo "  PM2: ~/.pm2/logs/"
echo ""
echo "💾 Backup:"
echo "  Command: /opt/app/scripts/backup.sh"
echo "  Location: /backup/nginx-app/"
echo "======================================"

log "🎉 Deployment completed successfully!"
log "🔧 Next steps:"
echo "  1. Configure domain and SSL certificates for production"
echo "  2. Set up monitoring alerts and notifications"
echo "  3. Configure automated backups and log rotation"
echo "  4. Test load balancing and failover scenarios"
echo "  5. Review security settings and access controls"
echo ""
echo "📚 Documentation: /opt/xcloud/vps-hosting-infrastructure/core/nginx-app-vps/README.md"

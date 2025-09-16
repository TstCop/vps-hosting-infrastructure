#!/bin/bash

# Node.js Installation and Configuration Script
# Installs Node.js 18 LTS, npm, PM2, and development tools

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

log "🟢 Starting Node.js installation and configuration..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Install Node.js 18 LTS using NodeSource repository
log "📦 Adding NodeSource repository..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

log "📦 Installing Node.js 18 LTS..."
apt-get install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

log "✅ Node.js installed: $NODE_VERSION"
log "✅ npm installed: $NPM_VERSION"

# Install global packages
log "🌐 Installing global npm packages..."
npm install -g pm2@latest
npm install -g nodemon@latest
npm install -g typescript@latest
npm install -g @types/node@latest
npm install -g ts-node@latest
npm install -g eslint@latest
npm install -g prettier@latest

# Configure npm for vagrant user
log "👤 Configuring npm for vagrant user..."
su - vagrant -c "npm config set prefix '/home/vagrant/.npm-global'"
su - vagrant -c "echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile"

# Create application directory structure
log "📁 Creating Node.js application structure..."
mkdir -p /opt/app/{src,public,logs,data,uploads,scripts,config,tests}
mkdir -p /opt/app/src/{controllers,middleware,routes,models,services,utils}

# Set proper ownership
chown -R vagrant:vagrant /opt/app

# Create basic package.json
log "📄 Creating package.json..."
cat > /opt/app/package.json << 'EOF'
{
  "name": "vps-hosting-app",
  "version": "1.0.0",
  "description": "VPS Hosting Infrastructure Application",
  "main": "dist/app.js",
  "scripts": {
    "start": "node dist/app.js",
    "dev": "nodemon src/app.ts",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix",
    "format": "prettier --write src/**/*.ts",
    "pm2:start": "pm2 start ecosystem.config.js",
    "pm2:stop": "pm2 stop ecosystem.config.js",
    "pm2:restart": "pm2 restart ecosystem.config.js",
    "pm2:reload": "pm2 reload ecosystem.config.js",
    "pm2:delete": "pm2 delete ecosystem.config.js"
  },
  "keywords": [
    "nodejs",
    "express",
    "typescript",
    "vps",
    "hosting"
  ],
  "author": "VPS Infrastructure Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "compression": "^1.7.4",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "express-rate-limit": "^6.10.0",
    "express-validator": "^7.0.1",
    "multer": "^1.4.5-lts.1",
    "winston": "^3.10.0",
    "redis": "^4.6.7",
    "pg": "^8.11.3",
    "node-cron": "^3.0.2"
  },
  "devDependencies": {
    "@types/node": "^20.5.0",
    "@types/express": "^4.17.17",
    "@types/cors": "^2.8.13",
    "@types/morgan": "^1.9.4",
    "@types/compression": "^1.7.2",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/bcryptjs": "^2.4.2",
    "@types/multer": "^1.4.7",
    "@types/node-cron": "^3.0.8",
    "typescript": "^5.1.6",
    "ts-node": "^10.9.1",
    "nodemon": "^3.0.1",
    "jest": "^29.6.2",
    "@types/jest": "^29.5.4",
    "ts-jest": "^29.1.1",
    "eslint": "^8.47.0",
    "@typescript-eslint/eslint-plugin": "^6.4.0",
    "@typescript-eslint/parser": "^6.4.0",
    "prettier": "^3.0.1"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
EOF

# Create TypeScript configuration
log "⚙️ Creating TypeScript configuration..."
cat > /opt/app/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "sourceMap": true,
    "declaration": true,
    "declarationMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF

# Create PM2 ecosystem configuration
log "🔄 Creating PM2 ecosystem configuration..."
cat > /opt/app/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'vps-hosting-app',
      script: './dist/app.js',
      instances: 2,
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      error_file: '/opt/app/logs/pm2-error.log',
      out_file: '/opt/app/logs/pm2-out.log',
      log_file: '/opt/app/logs/pm2-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm Z',
      merge_logs: true,
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'vps-hosting-api',
      script: './dist/api.js',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production',
        PORT: 8080
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 8080
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 8080
      },
      error_file: '/opt/app/logs/api-error.log',
      out_file: '/opt/app/logs/api-out.log',
      log_file: '/opt/app/logs/api-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm Z',
      kill_timeout: 5000,
      max_restarts: 5,
      min_uptime: '10s'
    }
  ]
};
EOF

# Create basic Express application
log "🚀 Creating basic Express application..."
cat > /opt/app/src/app.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { config } from 'dotenv';
import path from 'path';
import fs from 'fs';

// Load environment variables
config({ path: '/opt/app/.env' });

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://app.vps.local', 'https://api.app.vps.local']
    : true,
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Compression
app.use(compression());

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV === 'production') {
  app.use(morgan('combined', {
    stream: fs.createWriteStream('/opt/app/logs/access.log', { flags: 'a' })
  }));
} else {
  app.use(morgan('dev'));
}

// Static files
app.use('/static', express.static(path.join(__dirname, '../public')));
app.use('/uploads', express.static('/opt/app/uploads'));

// Health check endpoint
app.get('/health', (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV,
    memory: process.memoryUsage(),
    version: process.version
  };

  res.status(200).json(healthCheck);
});

// API routes
app.get('/', (req, res) => {
  res.json({
    message: 'VPS Hosting Infrastructure API',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.get('/api/status', (req, res) => {
  res.json({
    status: 'online',
    server: 'nginx-app-vps',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`🚀 VPS Hosting App running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

export default app;
EOF

# Create API server
cat > /opt/app/src/api.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { config } from 'dotenv';
import fs from 'fs';

// Load environment variables
config({ path: '/opt/app/.env' });

const app = express();
const PORT = process.env.API_PORT || 8080;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://app.vps.local', 'https://api.app.vps.local']
    : true,
  credentials: true
}));

// API Rate limiting (more restrictive)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // limit each IP to 50 requests per windowMs
  message: 'API rate limit exceeded, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(apiLimiter);

// Body parsing
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

// Logging
if (process.env.NODE_ENV === 'production') {
  app.use(morgan('combined', {
    stream: fs.createWriteStream('/opt/app/logs/api-access.log', { flags: 'a' })
  }));
} else {
  app.use(morgan('dev'));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'vps-hosting-api',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// API routes
app.get('/', (req, res) => {
  res.json({
    message: 'VPS Hosting Infrastructure API',
    version: '1.0.0',
    documentation: '/api/docs',
    health: '/health'
  });
});

// VPS management endpoints
app.get('/api/vps', (req, res) => {
  res.json({
    message: 'VPS management endpoint',
    servers: [
      {
        name: 'gitlab-vps',
        ip: '136.243.208.130',
        status: 'online',
        services: ['gitlab', 'postgresql', 'redis']
      },
      {
        name: 'nginx-app-vps',
        ip: '136.243.208.131',
        status: 'online',
        services: ['nginx', 'nodejs', 'docker']
      }
    ]
  });
});

// System information endpoint
app.get('/api/system', (req, res) => {
  res.json({
    hostname: require('os').hostname(),
    platform: require('os').platform(),
    arch: require('os').arch(),
    uptime: require('os').uptime(),
    memory: {
      total: require('os').totalmem(),
      free: require('os').freemem(),
      used: require('os').totalmem() - require('os').freemem()
    },
    loadAverage: require('os').loadavg(),
    cpus: require('os').cpus().length
  });
});

// Error handling
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'API endpoint not found',
    path: req.originalUrl,
    method: req.method
  });
});

app.listen(PORT, () => {
  console.log(`🔌 VPS Hosting API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});

export default app;
EOF

# Create development scripts
log "🛠️ Creating development scripts..."

# Development startup script
cat > /opt/app/scripts/dev-start.sh << 'EOF'
#!/bin/bash

# Development startup script
cd /opt/app

echo "🚀 Starting development environment..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Build TypeScript
echo "🔨 Building TypeScript..."
npm run build

# Start applications with PM2
echo "🔄 Starting applications with PM2..."
npm run pm2:start

echo "✅ Development environment started!"
echo "📊 PM2 status:"
pm2 status

echo ""
echo "🌐 Services available at:"
echo "  App: http://localhost:3000"
echo "  API: http://localhost:8080"
echo "  Health: http://localhost:3000/health"
EOF

# Production startup script
cat > /opt/app/scripts/prod-start.sh << 'EOF'
#!/bin/bash

# Production startup script
cd /opt/app

echo "🚀 Starting production environment..."

# Install production dependencies
echo "📦 Installing production dependencies..."
npm ci --only=production

# Build application
echo "🔨 Building application..."
npm run build

# Start with PM2
echo "🔄 Starting with PM2..."
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save
pm2 startup

echo "✅ Production environment started!"
pm2 status
EOF

# Application management script
cat > /opt/app/scripts/app-manager.sh << 'EOF'
#!/bin/bash

# Application Management Script
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

show_help() {
    echo "Application Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start applications"
    echo "  stop        Stop applications"
    echo "  restart     Restart applications"
    echo "  status      Show application status"
    echo "  logs        Show application logs"
    echo "  build       Build TypeScript application"
    echo "  install     Install dependencies"
    echo "  deploy      Deploy new version"
    echo "  health      Check application health"
    echo "  help        Show this help message"
}

app_status() {
    cd /opt/app
    log "Application Status:"
    pm2 status || echo "PM2 not running"

    echo ""
    log "Process Information:"
    ps aux | grep -E "node|pm2" | grep -v grep || echo "No Node.js processes found"

    echo ""
    log "Port Usage:"
    netstat -tuln | grep -E ":3000|:8080" || echo "No application ports in use"
}

app_logs() {
    cd /opt/app
    log "Recent Application Logs:"

    if [ -f "logs/pm2-combined.log" ]; then
        tail -50 logs/pm2-combined.log
    else
        echo "No application logs found"
    fi
}

app_health() {
    log "Checking application health..."

    # Check main app
    if curl -sf http://localhost:3000/health > /dev/null; then
        log "✅ Main app is healthy"
    else
        error "❌ Main app is not responding"
    fi

    # Check API
    if curl -sf http://localhost:8080/health > /dev/null; then
        log "✅ API is healthy"
    else
        error "❌ API is not responding"
    fi
}

case "$1" in
    start)
        cd /opt/app
        log "Starting applications..."
        npm run pm2:start
        ;;
    stop)
        cd /opt/app
        log "Stopping applications..."
        npm run pm2:stop
        ;;
    restart)
        cd /opt/app
        log "Restarting applications..."
        npm run pm2:restart
        ;;
    status)
        app_status
        ;;
    logs)
        app_logs
        ;;
    build)
        cd /opt/app
        log "Building application..."
        npm run build
        ;;
    install)
        cd /opt/app
        log "Installing dependencies..."
        npm install
        ;;
    deploy)
        cd /opt/app
        log "Deploying application..."
        npm install
        npm run build
        npm run pm2:reload
        ;;
    health)
        app_health
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

# Make scripts executable
chmod +x /opt/app/scripts/*.sh

# Set proper ownership
chown -R vagrant:vagrant /opt/app

# Install application dependencies as vagrant user
log "📦 Installing application dependencies..."
cd /opt/app
su - vagrant -c "cd /opt/app && npm install"

# Build the application
log "🔨 Building TypeScript application..."
su - vagrant -c "cd /opt/app && npm run build"

# Configure PM2 for vagrant user
log "🔄 Configuring PM2..."
su - vagrant -c "pm2 install pm2-logrotate"
su - vagrant -c "pm2 set pm2-logrotate:max_size 10M"
su - vagrant -c "pm2 set pm2-logrotate:retain 30"
su - vagrant -c "pm2 set pm2-logrotate:compress true"

# Setup PM2 startup script
log "⚙️ Setting up PM2 startup..."
PM2_STARTUP=$(su - vagrant -c "pm2 startup | tail -1")
eval "$PM2_STARTUP" 2>/dev/null || warn "PM2 startup configuration may need manual setup"

# Create systemd service for PM2 (backup method)
log "🔧 Creating systemd service for PM2..."
cat > /etc/systemd/system/pm2-vagrant.service << 'EOF'
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=vagrant
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/home/vagrant/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=PM2_HOME=/home/vagrant/.pm2
PIDFile=/home/vagrant/.pm2/pm2.pid
Restart=on-failure

ExecStart=/home/vagrant/.npm-global/bin/pm2 resurrect
ExecReload=/home/vagrant/.npm-global/bin/pm2 reload all
ExecStop=/home/vagrant/.npm-global/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pm2-vagrant

# Display installation summary
log "📋 Node.js Installation Summary:"
echo "======================================"
echo "Node.js Version: $(node --version)"
echo "NPM Version: $(npm --version)"
echo "PM2 Status: $(which pm2 && echo 'Installed' || echo 'Not found')"
echo "Application Path: /opt/app"
echo "TypeScript Config: /opt/app/tsconfig.json"
echo "PM2 Config: /opt/app/ecosystem.config.js"
echo ""
echo "Global Packages:"
npm list -g --depth=0 2>/dev/null | grep -E "(pm2|nodemon|typescript)" || echo "  Check installation"
echo ""
echo "Management Scripts:"
echo "  Development: /opt/app/scripts/dev-start.sh"
echo "  Production: /opt/app/scripts/prod-start.sh"
echo "  App Manager: /opt/app/scripts/app-manager.sh"
echo "======================================"

log "✅ Node.js installation and configuration completed successfully!"
log "🌟 Next steps:"
echo "  1. Review application configuration: /opt/app/.env"
echo "  2. Start applications: /opt/app/scripts/app-manager.sh start"
echo "  3. Check status: /opt/app/scripts/app-manager.sh status"
echo "  4. View logs: /opt/app/scripts/app-manager.sh logs"
echo "  5. Test health: curl http://localhost:3000/health"

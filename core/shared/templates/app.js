const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('rate-limiter-flexible');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const cron = require('node-cron');
require('dotenv').config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Configure logging
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'vps-app' },
  transports: [
    new winston.transports.File({ filename: './logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: './logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// Rate limiting
const rateLimiter = new rateLimit.RateLimiterMemory({
  keyPrefix: 'middleware',
  points: 100, // Number of requests
  duration: 60, // Per 60 seconds
});

const rateLimiterMiddleware = async (req, res, next) => {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch (rejRes) {
    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Rate limit exceeded',
      retryAfter: Math.round(rejRes.msBeforeNext / 1000) || 1,
    });
  }
};

// Middleware
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

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
}));

app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use(morgan('combined', {
  stream: {
    write: (message) => logger.info(message.trim())
  }
}));

// Apply rate limiting
app.use(rateLimiterMiddleware);

// Health check endpoint
app.get('/health', (req, res) => {
  const healthData = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    memory: process.memoryUsage(),
    cpu: process.cpuUsage(),
  };

  res.status(200).json(healthData);
});

// Readiness check
app.get('/ready', (req, res) => {
  // Add any necessary checks here (database connections, etc.)
  res.status(200).json({
    status: 'Ready',
    timestamp: new Date().toISOString(),
  });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  const metrics = {
    timestamp: new Date().toISOString(),
    process: {
      pid: process.pid,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
    },
    system: {
      platform: process.platform,
      arch: process.arch,
      nodeVersion: process.version,
    },
  };

  res.status(200).json(metrics);
});

// API routes
app.get('/api/status', (req, res) => {
  res.json({
    message: 'VPS Infrastructure API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// Example API endpoint with validation
app.post('/api/data', [
  body('name').isLength({ min: 1 }).trim().escape(),
  body('email').isEmail().normalizeEmail(),
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }

  const { name, email } = req.body;

  logger.info('Data received', { name, email, ip: req.ip });

  res.json({
    message: 'Data received successfully',
    data: { name, email },
    timestamp: new Date().toISOString(),
  });
});

// GitLab integration endpoint
app.get('/api/gitlab/status', (req, res) => {
  // Example integration with GitLab VPS
  res.json({
    gitlab: {
      status: 'connected',
      endpoint: 'http://10.0.0.10',
      lastCheck: new Date().toISOString(),
    }
  });
});

// Infrastructure monitoring endpoint
app.get('/api/infrastructure', (req, res) => {
  const infrastructure = {
    vps: {
      gitlab: {
        ip: '10.0.0.10',
        publicIp: '136.243.208.130',
        status: 'running'
      },
      nginx: {
        ip: '10.0.0.20',
        publicIp: '136.243.208.131',
        status: 'running'
      }
    },
    monitoring: {
      netdata: 'http://10.0.0.20:19999',
      prometheus: 'http://localhost:9100',
    },
    timestamp: new Date().toISOString(),
  };

  res.json(infrastructure);
});

// Static files (if needed)
app.use(express.static('public'));

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Application error', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
  });

  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal Server Error'
      : err.message,
    timestamp: new Date().toISOString(),
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Scheduled tasks
cron.schedule('0 */6 * * *', () => {
  logger.info('Running scheduled health check');
  // Add periodic health checks or maintenance tasks
});

// PM2 ready signal
if (process.send) {
  process.send('ready');
}

// Start server
const server = app.listen(PORT, HOST, () => {
  logger.info(`VPS Infrastructure App listening on ${HOST}:${PORT}`, {
    environment: process.env.NODE_ENV || 'development',
    pid: process.pid,
  });
});

// Handle server errors
server.on('error', (err) => {
  logger.error('Server error', { error: err.message, stack: err.stack });
  process.exit(1);
});

module.exports = app;

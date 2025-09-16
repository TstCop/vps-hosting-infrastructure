module.exports = {
  apps: [
    {
      name: 'vps-app',
      script: './app.js',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      max_memory_restart: '1G',
      node_args: '--max_old_space_size=1024',
      watch: false,
      ignore_watch: [
        'node_modules',
        'logs',
        '.git'
      ],
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s',
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 8000
    }
  ],

  deploy: {
    production: {
      user: 'app',
      host: ['10.0.0.20'],
      ref: 'origin/main',
      repo: 'git@github.com:your-org/vps-infrastructure.git',
      path: '/opt/app',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      env: {
        NODE_ENV: 'production'
      }
    }
  }
};

# Laravel Deploy Tool

A comprehensive deployment tool for Laravel Sail applications on Ubuntu/DigitalOcean droplets.

## 🚀 Quick Start

### **Installation**
```bash
# Install via APT
sudo apt update
sudo apt install laravel-deploy
```

### **First Deployment**
```bash
# Navigate to your Laravel project
cd /path/to/your/laravel-project

# Initialize deployment
laravel-deploy init

# Edit configuration
nano laravel-deploy.yml

# Deploy
laravel-deploy deploy
```

## 📋 Commands

### **Initialize Project**
```bash
laravel-deploy init
```
- Creates deployment scripts in your project
- Generates configuration template
- Sets up project structure

### **Deploy Application**
```bash
laravel-deploy deploy
```
- Runs deployment based on configuration
- Supports interactive and automated modes
- Handles Docker, SSL, and database setup

### **Check Status**
```bash
laravel-deploy status
```
- Shows current deployment status
- Displays running containers
- Lists recent log entries

### **Create Backup**
```bash
laravel-deploy backup
```
- Creates restore point
- Backs up configuration and project files
- Stores metadata for rollback

### **Rollback Changes**
```bash
laravel-deploy rollback
```
- Rolls back to previous step
- Creates backup before rollback
- Provides resume instructions

## ⚙️ Configuration

### **Project Configuration**
Edit `laravel-deploy.yml` in your project:

```yaml
# Laravel Deploy Configuration
project:
  name: "your-laravel-app"
  repository: "git@github.com:your-username/your-project.git"

database:
  type: "local"  # local or external
  name: "laravel"
  user: "sail"
  password: "your-secure-password"

# For external database
# database:
#   type: "external"
#   host: "your-db-host.com"
#   port: "3306"
#   name: "your_database"
#   user: "your_user"
#   password: "your_password"

ssl:
  enabled: true
  domain: "yourdomain.com"
  email: "admin@yourdomain.com"

deployment:
  strategy: "interactive"  # interactive or automated
```

## 🛠️ Features

### **Deployment Strategies**
- **Interactive**: Step-by-step deployment with prompts
- **Automated**: Fully automated deployment with pre-configured settings

### **Database Support**
- **Local MySQL**: Laravel Sail's built-in MySQL container
- **External Database**: Connect to external MySQL/PostgreSQL clusters

### **SSL Management**
- **Let's Encrypt**: Automatic SSL certificate generation
- **Custom Certificates**: Support for custom SSL certificates
- **Auto-renewal**: Automatic certificate renewal

### **Backup & Rollback**
- **Restore Points**: Create backup points at any time
- **Rollback**: Return to previous deployment states
- **Metadata**: Track backup information and timestamps

### **Monitoring**
- **Status Checks**: Real-time deployment status
- **Health Checks**: Application and container health
- **Log Management**: Centralized log viewing

## 📁 File Structure

```
/usr/share/laravel-deploy/
├── scripts/
│   ├── deploy.sh                    # Interactive deployment
│   ├── deploy-non-interactive.sh    # Automated deployment
│   └── deployment-manager.sh        # Management tool
├── templates/
│   └── docker-compose.yml          # Sail template
└── config/
    └── config.yml                  # Default configuration

/etc/laravel-deploy/
└── config.yml                     # System configuration

/var/log/laravel-deploy/           # Log files
```

## 🔧 System Requirements

### **Minimum Requirements**
- Ubuntu 20.04 or later
- Docker and Docker Compose
- Git
- SSH client
- UFW firewall

### **Recommended**
- Nginx (for reverse proxy)
- Certbot (for SSL certificates)
- At least 2GB RAM
- 20GB free disk space

## 🆘 Troubleshooting

### **Common Issues**

#### **"Not in a Laravel project directory"**
```bash
# Make sure you're in the Laravel project root
cd /path/to/your/laravel-project
ls composer.json
```

#### **"Configuration file not found"**
```bash
# Initialize the project first
laravel-deploy init
```

#### **"Deployment manager not found"**
```bash
# Re-initialize the project
laravel-deploy init
```

#### **Permission denied errors**
```bash
# Make sure scripts are executable
chmod +x deploy.sh deploy-non-interactive.sh deployment-manager.sh
```

### **Getting Help**
```bash
# Show help
laravel-deploy help

# View manual
man laravel-deploy

# Check logs
tail -f /var/log/laravel-deploy/deployment.log
```

## 📊 Examples

### **First-Time Deployment**
```bash
# 1. Install the tool
sudo apt install laravel-deploy

# 2. Navigate to project
cd /var/www/my-laravel-app

# 3. Initialize
laravel-deploy init

# 4. Configure
nano laravel-deploy.yml

# 5. Deploy
laravel-deploy deploy
```

### **Production Deployment**
```bash
# 1. Configure for production
nano laravel-deploy.yml
# Set strategy: "automated"

# 2. Deploy
laravel-deploy deploy

# 3. Monitor
laravel-deploy status
```

### **Rollback After Issues**
```bash
# 1. Check status
laravel-deploy status

# 2. Create backup
laravel-deploy backup

# 3. Rollback if needed
laravel-deploy rollback
```

## 🔄 Integration

### **CI/CD Integration**
```bash
# In your CI/CD pipeline
laravel-deploy deploy --strategy=automated
```

### **Monitoring Integration**
```bash
# Health check
laravel-deploy status | grep "Application is running"
```

### **Backup Automation**
```bash
# Cron job for daily backups
0 2 * * * laravel-deploy backup
```

## 📞 Support

- **Documentation**: `man laravel-deploy`
- **Logs**: `/var/log/laravel-deploy/`
- **Configuration**: `/etc/laravel-deploy/config.yml`
- **Scripts**: `/usr/share/laravel-deploy/scripts/`

## 🎯 Best Practices

### **Before Deployment**
- ✅ Test in development environment
- ✅ Backup existing data
- ✅ Verify domain DNS settings
- ✅ Check server resources

### **During Deployment**
- ✅ Monitor deployment progress
- ✅ Create backup points
- ✅ Test application functionality
- ✅ Verify SSL certificate

### **After Deployment**
- ✅ Run health checks
- ✅ Monitor application logs
- ✅ Set up monitoring
- ✅ Configure backups

## 📝 License

This tool is provided as-is for Laravel application deployment.
For support, contact: support@laravel-deploy.com

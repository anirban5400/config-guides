# Laravel Deploy Tool - Installation Guide

## 🚀 Quick Installation

### **Step 1: Build the Package**
```bash
# Navigate to package directory
cd ubuntu-app-laravel-deploy

# Build the package
./build-package.sh
```

### **Step 2: Install the Package**
```bash
# Install the package
sudo dpkg -i laravel-deploy_1.0.0_all.deb

# Install dependencies if needed
sudo apt-get install -f
```

### **Step 3: Verify Installation**
```bash
# Check if installed
which laravel-deploy

# Show help
laravel-deploy help

# View manual
man laravel-deploy
```

## 📋 Usage Examples

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

### **Check Status**
```bash
# Check deployment status
laravel-deploy status

# Create backup
laravel-deploy backup

# Rollback if needed
laravel-deploy rollback
```

## 🔧 System Requirements

### **Required Packages**
- Ubuntu 20.04 or later
- Docker and Docker Compose
- Git
- SSH client
- UFW firewall

### **Recommended Packages**
- Nginx (for reverse proxy)
- Certbot (for SSL certificates)

## 🆘 Troubleshooting

### **Installation Issues**
```bash
# Check package info
dpkg -I laravel-deploy_1.0.0_all.deb

# Install missing dependencies
sudo apt-get install -f

# Check package contents
dpkg -c laravel-deploy_1.0.0_all.deb
```

### **Usage Issues**
```bash
# Check if executable exists
which laravel-deploy

# Check permissions
ls -la /usr/bin/laravel-deploy

# View logs
tail -f /var/log/laravel-deploy/deployment.log
```

## 📚 Documentation

- **Manual**: `man laravel-deploy`
- **Documentation**: `/usr/share/doc/laravel-deploy/README.md`
- **Scripts**: `/usr/share/laravel-deploy/scripts/`
- **Configuration**: `/etc/laravel-deploy/config.yml`

## 🎯 Next Steps

1. **Initialize project**: `laravel-deploy init`
2. **Configure deployment**: Edit `laravel-deploy.yml`
3. **Deploy application**: `laravel-deploy deploy`
4. **Monitor status**: `laravel-deploy status`

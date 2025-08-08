# Laravel Sail Deployment Scripts

Complete deployment solution for Laravel Sail applications on DigitalOcean droplets.

## 📁 Scripts Overview

### **🚀 Main Deployment Scripts**

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `deploy.sh` | Interactive deployment | Manual step-by-step deployment |
| `deploy-non-interactive.sh` | Automated deployment | Production deployments |

### **🛠️ Management Tools**

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `deployment-manager.sh` | Status & rollback management | Monitor and manage deployments |

## 🎯 Quick Start

### **For First-Time Users**
```bash
# 1. Interactive deployment (recommended for learning)
sudo ./deploy.sh

# 2. Non-interactive deployment (for production)
sudo ./deploy-non-interactive.sh
```

### **For Experienced Users**
```bash
# 1. Configure non-interactive script
nano deploy-non-interactive.sh

# 2. Run automated deployment
sudo ./deploy-non-interactive.sh

# 3. Monitor with manager
./deployment-manager.sh status
```

## 📋 Script Details

### **1. `deploy.sh` - Interactive Deployment**
- **Purpose**: Step-by-step deployment with user input
- **Best for**: Learning, testing, custom configurations
- **Features**:
  - Interactive prompts for configuration
  - Manual SSH key setup
  - Step-by-step verification
  - Resume functionality

```bash
sudo ./deploy.sh
```

### **2. `deploy-non-interactive.sh` - Automated Deployment**
- **Purpose**: Fully automated deployment
- **Best for**: Production, CI/CD, repeatable deployments
- **Features**:
  - All variables configured at top of script
  - No user interaction required
  - Comprehensive logging
  - Resume from any step

```bash
# Edit configuration first
nano deploy-non-interactive.sh

# Run deployment
sudo ./deploy-non-interactive.sh
```

### **3. `deployment-manager.sh` - Management Tool**
- **Purpose**: Monitor and manage deployments
- **Best for**: Ongoing maintenance and troubleshooting
- **Features**:
  - Check deployment status
  - Create restore points
  - Rollback to previous steps
  - Clean up old backups

```bash
# Check current status
./deployment-manager.sh status

# Create backup
./deployment-manager.sh backup

# List restore points
./deployment-manager.sh list
```

## 🔧 Configuration

### **Interactive Mode (`deploy.sh`)**
- No pre-configuration needed
- Script asks for all settings during deployment
- Good for one-time deployments

### **Non-Interactive Mode (`deploy-non-interactive.sh`)**
Edit these variables at the top of the script:

```bash
# Repository Configuration
REPO_URL="git@github.com:your-username/your-laravel-project.git"
PROJECT_NAME="app"

# Database Configuration
DB_NAME="laravel"
DB_USER="sail"
DB_PASS="your-secure-password"

# Application Configuration
APP_URL="https://yourdomain.com"
APP_ENV="production"

# SSL Configuration
SETUP_SSL=true
DOMAIN_NAME="yourdomain.com"
SSL_EMAIL="admin@yourdomain.com"
```

## 🚀 Deployment Workflow

### **Step 1: Choose Your Script**
```bash
# For learning/testing
sudo ./deploy.sh

# For production
sudo ./deploy-non-interactive.sh
```

### **Step 2: Monitor Progress**
```bash
# Check status
./deployment-manager.sh status

# Create backup points
./deployment-manager.sh backup
```

### **Step 3: Handle Issues**
```bash
# If deployment fails, resume
sudo ./deploy-non-interactive.sh --resume 6

# If you need to rollback
./deployment-manager.sh rollback
```

## 📊 What Gets Installed

- ✅ **Docker & Docker Compose**
- ✅ **Laravel Sail**
- ✅ **MySQL Database** (or external database)
- ✅ **Redis Cache**
- ✅ **Nginx** (reverse proxy)
- ✅ **SSL Certificate** (Let's Encrypt)
- ✅ **UFW Firewall**

## 🔑 Key Features

### **Interactive Script (`deploy.sh`)**
- 🎯 **User-friendly**: Step-by-step guidance
- 🔧 **Flexible**: Easy to customize during deployment
- 📝 **Educational**: Shows what each step does
- 🔄 **Resumable**: Can continue from any step

### **Non-Interactive Script (`deploy-non-interactive.sh`)**
- ⚡ **Fast**: Fully automated deployment
- 🔒 **Secure**: No manual intervention needed
- 📊 **Comprehensive**: Detailed logging and error handling
- 🎛️ **Configurable**: All settings in one place

### **Management Tool (`deployment-manager.sh`)**
- 📊 **Status Monitoring**: Real-time deployment status
- 💾 **Backup Management**: Create and manage restore points
- 🔄 **Rollback Capability**: Return to previous states
- 🧹 **Cleanup Tools**: Manage disk space

## 🆘 Common Scenarios

### **First Deployment**
```bash
# 1. Use interactive script to learn
sudo ./deploy.sh

# 2. Create backup after success
./deployment-manager.sh backup
```

### **Production Deployment**
```bash
# 1. Configure non-interactive script
nano deploy-non-interactive.sh

# 2. Run automated deployment
sudo ./deploy-non-interactive.sh

# 3. Monitor progress
./deployment-manager.sh status
```

### **Deployment Failure**
```bash
# 1. Check what failed
./deployment-manager.sh status

# 2. Resume from last step
sudo ./deploy-non-interactive.sh --resume 6

# 3. Or restore from backup
./deployment-manager.sh restore 1
```

### **External Database Setup**
```bash
# 1. Edit non-interactive script
nano deploy-non-interactive.sh

# 2. Set external database variables
USE_EXTERNAL_DB=true
DB_HOST="your-db-host.com"
DB_PORT="3306"
DB_NAME="your_database"
DB_USER="your_user"
DB_PASS="your_password"

# 3. Run deployment
sudo ./deploy-non-interactive.sh
```

## 📁 File Structure

```
Laravel-project-deploy-docker-ubuntu/
├── deploy.sh                      # Interactive deployment
├── deploy-non-interactive.sh      # Automated deployment
├── deployment-manager.sh          # Management tool
├── README.md                      # This file
├── README-non-interactive.md      # Non-interactive guide
├── README-deployment-manager.md   # Manager guide
├── EXTERNAL-DATABASE-SETUP.md    # External DB guide
└── backups/                       # Backup directory
```

## 🎯 Which Script to Use?

### **Use `deploy.sh` if:**
- ✅ First time deploying Laravel Sail
- ✅ Want to learn the deployment process
- ✅ Need custom configuration during deployment
- ✅ Deploying to test environment

### **Use `deploy-non-interactive.sh` if:**
- ✅ Deploying to production
- ✅ Want automated deployment
- ✅ Have all configuration ready
- ✅ Need repeatable deployments

### **Use `deployment-manager.sh` if:**
- ✅ Want to monitor deployment status
- ✅ Need to create backup points
- ✅ Want to rollback changes
- ✅ Need to manage deployment files

## 📞 Support

- **Interactive deployment**: `sudo ./deploy.sh`
- **Automated deployment**: `sudo ./deploy-non-interactive.sh`
- **Status check**: `./deployment-manager.sh status`
- **Create backup**: `./deployment-manager.sh backup`
- **View logs**: `tail -f deployment-non-interactive.log`

## 🔄 Quick Commands

```bash
# Start fresh deployment
sudo ./deploy.sh

# Resume from step 5
sudo ./deploy-non-interactive.sh --resume 5

# Check status
./deployment-manager.sh status

# Create backup
./deployment-manager.sh backup

# Rollback one step
./deployment-manager.sh rollback
```

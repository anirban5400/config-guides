# Laravel Sail Non-Interactive Deployment

Quick deployment script for Laravel Sail applications on DigitalOcean droplets.

## 🚀 Quick Start

```bash
# 1. Download the script
wget https://raw.githubusercontent.com/your-repo/deploy-non-interactive.sh

# 2. Make it executable
chmod +x deploy-non-interactive.sh

# 3. Edit configuration (IMPORTANT!)
nano deploy-non-interactive.sh

# 4. Run deployment
sudo ./deploy-non-interactive.sh
```

## ⚙️ Configuration (Required)

Edit these variables at the top of the script:

```bash
# Repository Configuration
REPO_URL="git@github.com:your-username/your-laravel-project.git"
PROJECT_NAME="app"

# Database Configuration
DB_NAME="laravel"
DB_USER="sail"
DB_PASS="your-secure-password-here"

# Application Configuration
APP_URL="https://yourdomain.com"
APP_ENV="production"

# SSL Configuration
SETUP_SSL=true
DOMAIN_NAME="yourdomain.com"
SSL_EMAIL="admin@yourdomain.com"
```

## 📋 Prerequisites

- ✅ DigitalOcean Ubuntu droplet (20.04+)
- ✅ Root or sudo access
- ✅ Git repository with Laravel project
- ✅ Domain name (for SSL)

## 🔧 Usage

### Fresh Deployment
```bash
sudo ./deploy-non-interactive.sh
```

### Resume from Specific Step
```bash
sudo ./deploy-non-interactive.sh --resume 5
```

### Check Logs
```bash
# View deployment log
tail -f deployment-non-interactive.log

# View failures
cat deployment-failures.log
```

## 🔑 SSH Key Setup

The script will automatically:
1. Generate SSH key
2. Display the key for you to copy
3. Guide you through adding it to your Git provider
4. Test the connection

**Required for SSH repositories** (`git@github.com:...`)

## 📦 What Gets Installed

- ✅ Docker & Docker Compose
- ✅ Laravel Sail
- ✅ MySQL Database
- ✅ Redis Cache
- ✅ Nginx (reverse proxy)
- ✅ SSL Certificate (Let's Encrypt)
- ✅ UFW Firewall

## 🛠️ Post-Deployment

```bash
# Start/Stop application
./vendor/bin/sail up -d
./vendor/bin/sail down

# View logs
./vendor/bin/sail logs -f

# Update deployment
./update.sh

# Check status
./status.sh
```

## 🔄 Resume Points

If deployment fails, resume from any step:

```bash
# Resume from step 3 (SSH key setup)
sudo ./deploy-non-interactive.sh --resume 3

# Resume from step 4 (repository cloning)
sudo ./deploy-non-interactive.sh --resume 4

# Resume from step 6 (environment setup)
sudo ./deploy-non-interactive.sh --resume 6
```

## 🆘 Troubleshooting

### SSH Key Issues
```bash
# If SSH key not added yet
sudo ./deploy-non-interactive.sh --resume 3
```

### Repository Cloning Fails
```bash
# Check if SSH key is added to Git provider
sudo ./deploy-non-interactive.sh --resume 4
```

### SSL Certificate Issues
```bash
# Resume from SSL setup
sudo ./deploy-non-interactive.sh --resume 9
```

## 📝 Important Notes

- **SSH Key Required**: For SSH repositories, you must add the SSH key to your Git provider
- **Domain Required**: For SSL certificates, your domain must point to the server IP
- **Resume Feature**: Script saves progress and can resume from any step
- **Dual Logging**: Separate logs for success and failures

## 🎯 Deployment Steps

1. **System Setup** - Update packages, install essentials
2. **Docker Installation** - Install Docker and Docker Compose
3. **SSH Key Setup** - Generate and configure SSH key
4. **Repository Clone** - Clone Laravel project
5. **Sail Setup** - Install Laravel Sail and dependencies
6. **Environment Config** - Configure .env file
7. **Container Build** - Build and start Docker containers
8. **Laravel Setup** - Run migrations and optimize
9. **SSL Setup** - Configure SSL certificate (optional)
10. **Firewall** - Configure UFW firewall
11. **Health Checks** - Verify deployment
12. **Summary** - Display deployment results

## 📞 Support

- Check logs: `tail -f deployment-non-interactive.log`
- View failures: `cat deployment-failures.log`
- Resume deployment: `sudo ./deploy-non-interactive.sh --resume [step]`

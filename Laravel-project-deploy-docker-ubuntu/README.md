# Laravel Sail Production Deployment

A comprehensive deployment script for Laravel Sail applications on DigitalOcean droplets.

## 🚀 Quick Start

```bash
# Download and run the script
wget https://raw.githubusercontent.com/your-repo/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

## 📋 Prerequisites

- DigitalOcean Ubuntu droplet (20.04+)
- Root or sudo access
- Git repository with Laravel project
- Domain name (optional, for SSL)

## 🔧 Usage

### Interactive Mode (Recommended)
```bash
sudo ./deploy.sh
```

### Non-Interactive Mode
```bash
sudo ./deploy.sh --yes
```

### Resume Deployment
```bash
sudo ./deploy.sh
# Then choose option 2
```

## 📦 What Gets Installed

- ✅ Docker & Docker Compose
- ✅ Laravel Sail
- ✅ MySQL Database
- ✅ Redis Cache
- ✅ Nginx (reverse proxy)
- ✅ SSL Certificate (Let's Encrypt)
- ✅ UFW Firewall

## 🛠️ Post-Deployment Commands

```bash
# Start/Stop application
./vendor/bin/sail up -d
./vendor/bin/sail down

# View logs
./vendor/bin/sail logs -f

# Run artisan commands
./vendor/bin/sail artisan migrate

# Update deployment
./update.sh

# Check status
./status.sh
```

## 🔒 Security Features

- Automatic firewall configuration
- SSL certificate setup
- Proper file permissions
- Database security

## 📝 Notes

- Script creates backups automatically
- Supports resume functionality
- Generates maintenance scripts
- Logs all operations to `deployment.log`

## 🆘 Troubleshooting

If deployment fails:
1. Check `deployment.log` for errors
2. Run `sudo ./deploy.sh` and choose option 2 to resume
3. Ensure your domain DNS points to server IP
4. Verify SSH key is added to your Git provider

## 📞 Support

For issues or questions, check the deployment log or restart the script.

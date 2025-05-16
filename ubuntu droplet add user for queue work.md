# 🖥️ Ubuntu 22.04 Server Management Guide

> *A professional guide for Laravel queue workers, Supervisor configuration, and user management in Plesk environments*

## 📋 Table of Contents

- [System User Management](#-system-user-management)
- [Website Directory Structure](#-website-directory-structure)
- [Supervisor Configuration](#-supervisor-configuration)
- [Laravel Queue Worker Setup](#-laravel-queue-worker-setup)
- [Service Management](#-service-management)

---

## 👤 System User Management

### Listing Users in Ubuntu 22.04

View all system users:
```bash
cut -d: -f1 /etc/passwd
```

View only real (non-system) users:
```bash
awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
```

### Creating a Dedicated Laravel User

Create a system user with no home directory:
```bash
sudo adduser --system --no-create-home --group laravel
```

---

## 📁 Website Directory Structure

### Plesk Website Locations

List all virtual hosts:
```bash
ls /var/www/vhosts/
```

Example output:
```
/var/www/vhosts/example.com/
/var/www/vhosts/yourdomain.com/
```

### Setting Proper Permissions

Grant Laravel user ownership to the project:
```bash
sudo chown -R laravel:laravel /var/www/vhosts/domain_name.com/subdomain.domain_name.com
```

Set permissions for specific Laravel directories:
```bash
sudo chown -R laravel:laravel /var/www/vhosts/domain_name.com/subdomain.domain_name.com/storage
sudo chown -R laravel:laravel /var/www/vhosts/domain_name.com/subdomain.domain_name.com/bootstrap/cache
```

---

## ⚙️ Supervisor Configuration

### Configuration File Locations

| File/Directory                     | Purpose                           |
| ---------------------------------- | --------------------------------- |
| `/etc/supervisor/supervisord.conf` | Main configuration file           |
| `/etc/supervisor/conf.d/`          | Program-specific config directory |

### Main Configuration

View the main Supervisor config:
```bash
cat /etc/supervisor/supervisord.conf
```

Example content:
```ini
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
```

---

## 🚀 Laravel Queue Worker Setup

### Viewing Existing Queue Configuration

Examine the current queue worker config:
```bash
cat /etc/supervisor/conf.d/product-redirection.conf
```

Root user configuration (not recommended):
```ini
[program:product-redirection]
process_name=%(program_name)s_%(process_num)02d
command=/opt/plesk/php/8.1/bin/php /var/www/vhosts/domain_name.com/subdomain.domain_name.com/artisan queue:work --queue=default --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/vhosts/domain_name.com/subdomain.domain_name.com/storage/logs/laravel.log
```

### Secure Laravel Queue Configuration

Updated configuration with dedicated user:
```ini
[program:product-redirection]
process_name=%(program_name)s_%(process_num)02d
command=/opt/plesk/php/8.1/bin/php /var/www/vhosts/domain_name.com/subdomain.domain_name.com/artisan queue:work --queue=default --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=laravel
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/vhosts/domain_name.com/subdomain.domain_name.com/storage/logs/laravel.log
```

---

## 🔄 Service Management

### Restarting Supervisor Services

Apply configuration changes and restart services:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart product-redirection
```

---

*Last updated: 2025* 

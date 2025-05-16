# Linux User Management & Security Configuration Guide

> *A comprehensive guide for creating service users, setting permissions, and implementing security best practices on Ubuntu, CentOS, and Debian systems*

## Table of Contents
- [Prerequisites](#prerequisites)
- [User Management Fundamentals](#user-management-fundamentals)
- [Creating Service Users](#creating-service-users)
- [Permission Management](#permission-management)
- [SSH Configuration](#ssh-configuration)
- [Security Hardening](#security-hardening)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Root or sudo access to the Linux server
- Basic knowledge of terminal commands
- Ubuntu 20.04+, CentOS 8+, or Debian 11+ (commands may vary slightly by distribution)

## User Management Fundamentals

### Viewing System Users

**Ubuntu/Debian:**
```bash
# List all users
cut -d: -f1 /etc/passwd

# List only real users (UID >= 1000)
awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
```

**CentOS/RHEL:**
```bash
# List all users
cut -d: -f1 /etc/passwd

# List only real users (UID >= 1000)
awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
```

### User Groups

```bash
# List all groups
getent group

# List groups for a specific user
groups username
```

## Creating Service Users

### System Service User

Best for background services that don't require login shell access:

```bash
# Create system user with no home directory and no login shell
sudo adduser --system --no-create-home --group servicename

# Check the created user
id servicename
```

### Application-Specific User

For web applications or services requiring a home directory:

```bash
# Create application user with home directory and restricted shell
sudo adduser --home /opt/appname --shell /usr/sbin/nologin appuser

# Grant ownership to application directory
sudo chown -R appuser:appuser /var/www/application
```

## Permission Management

### Setting Secure File Permissions

```bash
# Set ownership for web application files
sudo chown -R webuser:webgroup /var/www/application

# Set proper directory permissions
sudo find /var/www/application -type d -exec chmod 750 {} \;

# Set proper file permissions
sudo find /var/www/application -type f -exec chmod 640 {} \;

# Make specific scripts executable
sudo chmod +x /var/www/application/scripts/*.sh
```

### Using ACLs for Fine-Grained Control

```bash
# Install ACL package
sudo apt install acl   # Ubuntu/Debian
sudo yum install acl   # CentOS/RHEL

# Set default ACLs for new files in a directory
sudo setfacl -d -m u:webuser:rwx,g:webgroup:r-x,o::--- /var/www/application

# Set ACLs for existing files
sudo setfacl -R -m u:webuser:rwx,g:webgroup:r-x,o::--- /var/www/application
```

## SSH Configuration

### Secure SSH Configuration (/etc/ssh/sshd_config)

```bash
# Disable root login
PermitRootLogin no

# Use SSH key authentication only
PasswordAuthentication no
ChallengeResponseAuthentication no

# Restrict SSH access to specific users
AllowUsers admin maintainer

# Restrict SSH to specific groups
AllowGroups sshusers admins

# Set idle timeout (seconds)
ClientAliveInterval 300
ClientAliveCountMax 2
```

### Setting Up SSH Keys

```bash
# Generate SSH key pair (on local machine)
ssh-keygen -t ed25519 -C "username@example.com"

# Copy public key to server
ssh-copy-id username@server_ip
```

## Security Hardening

### File Permission Audit

```bash
# Find files with insecure permissions
find /home -type f -perm -o+w -ls

# Find SUID/SGID executables
find / -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null
```

### Limiting User Privileges

```bash
# Configure sudo access with limited privileges
echo "username ALL=(ALL) NOPASSWD:/usr/bin/systemctl restart apache2" | sudo tee /etc/sudoers.d/username

# Make sure the file has correct permissions
sudo chmod 440 /etc/sudoers.d/username
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Permission denied" errors | Check file ownership and permissions with `ls -la` |
| User can't execute sudo commands | Verify user is in sudo group with `groups username` |
| SSH key authentication failing | Check permissions on ~/.ssh directory (should be 700) and files (should be 600) |
| Service won't start under service user | Verify service user has access to required directories and configuration files |

### Diagnostic Commands

```bash
# Check user's sudo privileges
sudo -l -U username

# View authentication logs for issues
sudo tail -f /var/log/auth.log   # Ubuntu/Debian
sudo tail -f /var/log/secure     # CentOS/RHEL
```

---

*This guide is regularly updated with the latest security best practices. Last updated: 2025.* 
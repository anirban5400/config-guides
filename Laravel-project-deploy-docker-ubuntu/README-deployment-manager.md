# Laravel Sail Deployment Manager

A comprehensive management tool for Laravel Sail deployments that provides status checking, restore points, and rollback capabilities.

## 🚀 Quick Start

```bash
# Make executable
chmod +x deployment-manager.sh

# Check current status
./deployment-manager.sh status

# Create restore point
./deployment-manager.sh backup

# List restore points
./deployment-manager.sh list
```

## 📋 Commands

### **Status Check**
```bash
./deployment-manager.sh status
```
**Shows:**
- Current deployment step
- Application running status
- Recent log entries
- Failure count
- Available restore points

### **Create Restore Point**
```bash
./deployment-manager.sh backup
```
**Backs up:**
- `.env` file
- Project directory (`app/`)
- Step file (`.deploy_step`)
- Log files
- Creates metadata with timestamp and step info

### **List Restore Points**
```bash
./deployment-manager.sh list
```
**Shows:**
- Numbered list of restore points
- Timestamp and step for each point
- File size
- Creation date

### **Restore from Point**
```bash
./deployment-manager.sh restore 1
```
**Process:**
1. Creates backup of current state
2. Extracts restore point
3. Shows restored step
4. Provides resume command

### **Rollback Deployment**
```bash
./deployment-manager.sh rollback
```
**Actions:**
- Creates restore point before rollback
- Moves back one step
- Provides resume command

### **Cleanup Old Points**
```bash
./deployment-manager.sh cleanup 7
```
**Removes:**
- Restore points older than specified days
- Associated metadata files
- Default: 7 days if no number specified

## 🔍 Status Information

### **Deployment Steps**
- **0**: System Setup
- **1**: Docker Installation
- **2**: Docker Verification
- **3**: SSH Key Setup
- **4**: Repository Clone
- **5**: Sail Setup
- **6**: Environment Config
- **7**: Container Build
- **8**: Laravel Setup
- **9**: SSL Setup
- **10**: Firewall Config
- **11**: Health Checks
- **12**: Deployment Summary
- **completed**: Deployment Completed

### **Status Output Example**
```
================================
   Laravel Sail Deployment Manager
================================

ℹ️  Checking deployment status...

📊 Deployment Status:
• Current Step: 6 - Environment Config

📋 Recent Log Entries:
• [SUCCESS] Configuring environment variables [2024-01-15 10:30:45]
• [RUNNING] Building Docker containers [2024-01-15 10:31:00]

💾 Restore Points: 3
Available restore points:
restore_20240115_102500.tar.gz
restore_20240115_101500.tar.gz
restore_20240115_100000.tar.gz
```

## 🛠️ Use Cases

### **Before Making Changes**
```bash
# Create restore point
./deployment-manager.sh backup

# Check current status
./deployment-manager.sh status
```

### **After Deployment Failure**
```bash
# Check what failed
./deployment-manager.sh status

# Restore to working point
./deployment-manager.sh restore 1

# Resume deployment
sudo ./deploy-non-interactive.sh --resume 6
```

### **Rollback to Previous Step**
```bash
# Rollback one step
./deployment-manager.sh rollback

# Resume from rollback point
sudo ./deploy-non-interactive.sh --resume 5
```

### **Cleanup Old Backups**
```bash
# Clean up points older than 14 days
./deployment-manager.sh cleanup 14

# Clean up points older than 7 days (default)
./deployment-manager.sh cleanup
```

## 📁 File Structure

```
Laravel-project-deploy-docker-ubuntu/
├── deployment-manager.sh          # Main manager script
├── deploy-non-interactive.sh      # Deployment script
├── .deploy_step                   # Current step file
├── deployment-non-interactive.log  # Deployment log
├── deployment-failures.log        # Failure log
├── backups/                       # Backup directory
│   └── pre_restore_*.tar.gz      # Pre-restore backups
└── restore-points/                # Restore points directory
    ├── restore_*.tar.gz          # Restore point archives
    └── restore_*.meta            # Restore point metadata
```

## 🔒 Safety Features

### **Automatic Backups**
- Creates backup before any restore operation
- Stores current state in `backups/` directory
- Prevents data loss during restore

### **Confirmation Prompts**
- Asks for confirmation before destructive operations
- Shows what will be affected
- Allows cancellation

### **Validation**
- Checks if deployment script exists
- Validates restore point numbers
- Ensures required files are present

## 📊 Restore Point Metadata

Each restore point includes metadata with:
- **Timestamp**: When created
- **Step**: Deployment step at creation
- **Items**: What was backed up
- **Size**: Archive file size

Example metadata:
```
RESTORE_POINT: restore_20240115_102500
CREATED: Mon Jan 15 10:25:00 UTC 2024
STEP: 6
ITEMS: .env app .deploy_step deployment-non-interactive.log
SIZE: 45M
```

## 🆘 Troubleshooting

### **"Deployment script not found"**
```bash
# Make sure you're in the right directory
ls -la deploy-non-interactive.sh

# Check if script exists and is executable
chmod +x deploy-non-interactive.sh
```

### **"No restore points available"**
```bash
# Create a restore point first
./deployment-manager.sh backup

# Then try restore again
./deployment-manager.sh restore 1
```

### **"Invalid restore point number"**
```bash
# List available points
./deployment-manager.sh list

# Use the correct number from the list
./deployment-manager.sh restore 2
```

### **Restore failed**
```bash
# Check if you have enough disk space
df -h

# Check if tar is available
which tar

# Try manual extraction
tar -tzf restore-points/restore_*.tar.gz
```

## 🎯 Best Practices

### **Regular Backups**
```bash
# Create backup before major changes
./deployment-manager.sh backup

# Create backup after successful steps
./deployment-manager.sh backup
```

### **Cleanup Schedule**
```bash
# Set up cron job to clean old points weekly
0 2 * * 0 /path/to/deployment-manager.sh cleanup 7
```

### **Monitoring**
```bash
# Check status regularly
./deployment-manager.sh status

# Monitor log files
tail -f deployment-non-interactive.log
```

## 📞 Support

- **Check logs**: `tail -f deployment-non-interactive.log`
- **View failures**: `cat deployment-failures.log`
- **List backups**: `ls -la restore-points/`
- **Check disk usage**: `du -sh restore-points/ backups/`

## 🔄 Integration with Deployment Script

The manager works seamlessly with the deployment script:

```bash
# Start deployment
sudo ./deploy-non-interactive.sh

# Check status during deployment
./deployment-manager.sh status

# Create backup at any point
./deployment-manager.sh backup

# Resume from any step
sudo ./deploy-non-interactive.sh --resume 6
```

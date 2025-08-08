# External Database Setup Guide

This guide shows how to configure the deployment script to use external database clusters instead of the local Sail MySQL container.

## 🎯 **Supported External Databases**

- ✅ **DigitalOcean Managed Database**
- ✅ **AWS RDS (MySQL/Aurora)**
- ✅ **Google Cloud SQL**
- ✅ **Azure Database for MySQL**
- ✅ **Any MySQL-compatible database**

## ⚙️ **Configuration**

### **Step 1: Edit the Script Configuration**

```bash
# Open the deployment script
nano deploy-non-interactive.sh

# Find the database configuration section and update it:
```

### **Step 2: Configure External Database**

```bash
# Database Configuration
# For local Sail database (default)
DB_NAME="laravel"
DB_USER="sail"
DB_PASS="your-secure-password-here"

# For external database cluster (uncomment and configure)
DB_HOST="your-db-cluster-host.com"
DB_PORT="3306"
DB_NAME="your_database_name"
DB_USER="your_database_user"
DB_PASS="your-database-password"
USE_EXTERNAL_DB=true  # Set to true for external database
```

## 📋 **Examples for Different Providers**

### **DigitalOcean Managed Database**

```bash
# Get these from your DigitalOcean dashboard
DB_HOST="db-mysql-nyc1-12345.db.ondigitalocean.com"
DB_PORT="25060"  # DigitalOcean uses custom ports
DB_NAME="your_app_database"
DB_USER="doadmin"
DB_PASS="your-secure-password"
USE_EXTERNAL_DB=true
```

### **AWS RDS**

```bash
# Get these from your AWS RDS console
DB_HOST="your-db-instance.region.rds.amazonaws.com"
DB_PORT="3306"
DB_NAME="your_database_name"
DB_USER="admin"
DB_PASS="your-secure-password"
USE_EXTERNAL_DB=true
```

### **Google Cloud SQL**

```bash
# Get these from your Google Cloud Console
DB_HOST="your-project:region:instance-name"
DB_PORT="3306"
DB_NAME="your_database_name"
DB_USER="root"
DB_PASS="your-secure-password"
USE_EXTERNAL_DB=true
```

## 🔧 **Database Setup Requirements**

### **1. Create Database**
```sql
-- Connect to your database cluster and run:
CREATE DATABASE your_database_name;
```

### **2. Create User (if needed)**
```sql
-- Create a dedicated user for your application
CREATE USER 'your_database_user'@'%' IDENTIFIED BY 'your-secure-password';
GRANT ALL PRIVILEGES ON your_database_name.* TO 'your_database_user'@'%';
FLUSH PRIVILEGES;
```

### **3. Network Access**
Ensure your database cluster allows connections from your server's IP:

- **DigitalOcean**: Add your droplet's IP to the database firewall
- **AWS RDS**: Configure security groups to allow your server's IP
- **Google Cloud**: Configure authorized networks

## 🚀 **Deployment Process**

### **1. Configure the Script**
```bash
# Edit the configuration
nano deploy-non-interactive.sh

# Set USE_EXTERNAL_DB=true and configure your database details
```

### **2. Run Deployment**
```bash
# Fresh deployment
sudo ./deploy-non-interactive.sh

# Or resume from specific step
sudo ./deploy-non-interactive.sh --resume 6
```

### **3. What Happens**
- ✅ **Step 5**: Sail installs without MySQL container
- ✅ **Step 6**: Script configures external database in `.env`
- ✅ **Step 7**: Containers start (no MySQL container)
- ✅ **Step 8**: Migrations run against external database

## 🔍 **Verification**

### **Check Database Connection**
```bash
# Test connection from your server
mysql -h your-db-host -P your-port -u your-user -p your-database

# Or test via Laravel
./vendor/bin/sail artisan tinker
DB::connection()->getPdo();
```

### **Check .env Configuration**
```bash
# View the configured database settings
grep DB_ .env
```

## 🛠️ **Troubleshooting**

### **Connection Refused**
```bash
# Check if database host is reachable
telnet your-db-host your-port

# Check if your server's IP is whitelisted
# Add your server IP to database firewall rules
```

### **Authentication Failed**
```bash
# Verify credentials
mysql -h your-db-host -P your-port -u your-user -p

# Check if user has proper permissions
SHOW GRANTS FOR 'your-user'@'%';
```

### **Database Doesn't Exist**
```sql
-- Connect to your database cluster
CREATE DATABASE your_database_name;
```

## 📊 **Performance Considerations**

### **Advantages of External Database**
- ✅ **Scalability**: Easy to scale database independently
- ✅ **Backups**: Managed backups by provider
- ✅ **High Availability**: Built-in replication
- ✅ **Security**: Managed security patches
- ✅ **Monitoring**: Built-in monitoring tools

### **Network Latency**
- ⚠️ **Consider**: Network latency between server and database
- ⚠️ **Solution**: Choose database region close to your server
- ⚠️ **Optimization**: Use connection pooling if needed

## 🔒 **Security Best Practices**

### **1. Use Strong Passwords**
```bash
# Generate secure password
openssl rand -base64 32
```

### **2. Restrict Network Access**
- Only allow your server's IP
- Use VPC/private networks when possible
- Enable SSL connections

### **3. Use Dedicated Users**
```sql
-- Create application-specific user
CREATE USER 'app_user'@'%' IDENTIFIED BY 'secure-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON your_database.* TO 'app_user'@'%';
```

## 📝 **Example Complete Configuration**

```bash
# Repository Configuration
REPO_URL="git@github.com:your-username/your-laravel-project.git"
PROJECT_NAME="app"

# External Database Configuration
DB_HOST="db-mysql-nyc1-12345.db.ondigitalocean.com"
DB_PORT="25060"
DB_NAME="myapp_production"
DB_USER="doadmin"
DB_PASS="super-secure-password-here"
USE_EXTERNAL_DB=true

# Application Configuration
APP_URL="https://myapp.com"
APP_ENV="production"

# SSL Configuration
SETUP_SSL=true
DOMAIN_NAME="myapp.com"
SSL_EMAIL="admin@myapp.com"
```

## 🆘 **Common Issues**

### **"External database configuration incomplete"**
- Make sure all required variables are set
- Check that `USE_EXTERNAL_DB=true`
- Verify `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS` are set

### **"Connection refused"**
- Check database host and port
- Verify your server's IP is whitelisted
- Test connection manually: `telnet host port`

### **"Access denied"**
- Verify username and password
- Check user permissions in database
- Ensure user can connect from your server's IP

## 📞 **Support**

- Check deployment logs: `tail -f deployment-non-interactive.log`
- Test database connection manually
- Verify network connectivity
- Check database provider's documentation

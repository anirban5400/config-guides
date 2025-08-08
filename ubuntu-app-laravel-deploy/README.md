# Laravel Deploy Ubuntu APT Package

Complete Ubuntu/Debian package for Laravel Sail deployment tool.

## 📁 Package Structure

```
ubuntu-app-laravel-deploy/
├── DEBIAN/
│   ├── control              # Package metadata
│   ├── postinst             # Post-installation script
│   └── prerm                # Pre-removal script
├── usr/
│   ├── bin/
│   │   └── laravel-deploy   # Main executable
│   ├── share/
│   │   ├── laravel-deploy/
│   │   │   ├── scripts/     # Deployment scripts
│   │   │   ├── templates/   # Configuration templates
│   │   │   └── config/      # Default configurations
│   │   └── doc/
│   │       └── laravel-deploy/
│   │           └── README.md # Documentation
│   └── lib/
│       └── laravel-deploy/  # Library files
├── etc/
│   └── laravel-deploy/      # System configuration
├── var/
│   └── log/
│       └── laravel-deploy/  # Log files
├── build-package.sh         # Build script
└── README.md               # This file
```

## 🚀 Quick Build

### **Build the Package**
```bash
# Make build script executable
chmod +x build-package.sh

# Build the package
./build-package.sh
```

### **Install the Package**
```bash
# Install the built package
sudo dpkg -i laravel-deploy_1.0.0_all.deb

# Install dependencies if needed
sudo apt-get install -f
```

## 📋 Package Contents

### **Main Executable**
- **`/usr/bin/laravel-deploy`**: Main command-line tool

### **Deployment Scripts**
- **`/usr/share/laravel-deploy/scripts/deploy.sh`**: Interactive deployment
- **`/usr/share/laravel-deploy/scripts/deploy-non-interactive.sh`**: Automated deployment
- **`/usr/share/laravel-deploy/scripts/deployment-manager.sh`**: Management tool

### **Templates**
- **`/usr/share/laravel-deploy/templates/docker-compose.yml`**: Laravel Sail template

### **Documentation**
- **`/usr/share/doc/laravel-deploy/README.md`**: Comprehensive documentation
- **`/usr/share/man/man1/laravel-deploy.1.gz`**: Manual page

### **Configuration**
- **`/etc/laravel-deploy/config.yml`**: System configuration
- **`/var/log/laravel-deploy/`**: Log directory

## 🔧 Package Features

### **Dependencies**
- **bash**: Shell scripting
- **curl**: HTTP requests
- **git**: Version control
- **docker.io**: Container runtime
- **docker-compose**: Container orchestration
- **openssh-client**: SSH connections
- **ufw**: Firewall management

### **Recommended**
- **nginx**: Web server
- **certbot**: SSL certificates
- **python3-certbot-nginx**: Nginx SSL integration

### **Installation Process**
1. **Pre-installation**: Check system requirements
2. **Installation**: Copy files to system directories
3. **Post-installation**: Set permissions, create directories, generate man page

### **Removal Process**
1. **Pre-removal**: Clean up temporary files
2. **Removal**: Remove installed files
3. **Post-removal**: Clean up configuration files

## 🛠️ Build Process

### **Step 1: Prepare Structure**
```bash
# Create directory structure
mkdir -p DEBIAN usr/bin usr/share/laravel-deploy/scripts
```

### **Step 2: Add Files**
```bash
# Copy deployment scripts
cp ../Laravel-project-deploy-docker-ubuntu/*.sh usr/share/laravel-deploy/scripts/

# Create main executable
# (laravel-deploy script content)
```

### **Step 3: Set Permissions**
```bash
# Make scripts executable
chmod +x usr/bin/laravel-deploy
chmod +x usr/share/laravel-deploy/scripts/*.sh
chmod +x DEBIAN/postinst
chmod +x DEBIAN/prerm
```

### **Step 4: Build Package**
```bash
# Build Debian package
dpkg-deb --build . laravel-deploy_1.0.0_all.deb
```

## 📊 Package Information

### **Package Details**
- **Name**: laravel-deploy
- **Version**: 1.0.0
- **Architecture**: all (works on all architectures)
- **Section**: web
- **Priority**: optional

### **File Locations**
- **Executable**: `/usr/bin/laravel-deploy`
- **Scripts**: `/usr/share/laravel-deploy/scripts/`
- **Templates**: `/usr/share/laravel-deploy/templates/`
- **Documentation**: `/usr/share/doc/laravel-deploy/`
- **Configuration**: `/etc/laravel-deploy/`
- **Logs**: `/var/log/laravel-deploy/`

### **Man Page**
- **Location**: `/usr/share/man/man1/laravel-deploy.1.gz`
- **Access**: `man laravel-deploy`

## 🎯 Usage After Installation

### **Installation**
```bash
# Install package
sudo dpkg -i laravel-deploy_1.0.0_all.deb

# Install dependencies
sudo apt-get install -f
```

### **Usage**
```bash
# Show help
laravel-deploy help

# Initialize project
laravel-deploy init

# Deploy application
laravel-deploy deploy

# Check status
laravel-deploy status
```

### **Documentation**
```bash
# View manual
man laravel-deploy

# Read documentation
cat /usr/share/doc/laravel-deploy/README.md
```

## 🔄 Distribution

### **Local Installation**
```bash
# Build package
./build-package.sh

# Install locally
sudo dpkg -i laravel-deploy_1.0.0_all.deb
```

### **Repository Distribution**
```bash
# Create repository structure
mkdir -p repo/conf repo/db

# Add package to repository
reprepro -b repo includedeb focal laravel-deploy_1.0.0_all.deb

# Serve repository
python3 -m http.server 8000
```

### **PPA Distribution**
```bash
# Create PPA structure
mkdir -p ppa/ubuntu

# Add package to PPA
dput ppa:your-username/laravel-deploy laravel-deploy_1.0.0_source.changes
```

## 🆘 Troubleshooting

### **Build Issues**
```bash
# Check package structure
find . -type f -name "*.sh" -exec ls -la {} \;

# Verify permissions
ls -la usr/bin/laravel-deploy
ls -la usr/share/laravel-deploy/scripts/

# Check control file
cat DEBIAN/control
```

### **Installation Issues**
```bash
# Check dependencies
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

## 📝 Development

### **Modifying the Package**
1. Edit files in the package structure
2. Update version in `DEBIAN/control`
3. Rebuild with `./build-package.sh`

### **Adding Features**
1. Add new scripts to `usr/share/laravel-deploy/scripts/`
2. Update main executable in `usr/bin/laravel-deploy`
3. Update documentation in `usr/share/doc/laravel-deploy/`

### **Testing**
```bash
# Test package installation
sudo dpkg -i laravel-deploy_1.0.0_all.deb

# Test functionality
laravel-deploy help

# Test removal
sudo dpkg -r laravel-deploy
```

## 🎯 Next Steps

1. **Build the package**: `./build-package.sh`
2. **Test installation**: `sudo dpkg -i laravel-deploy_1.0.0_all.deb`
3. **Test functionality**: `laravel-deploy help`
4. **Distribute**: Upload to repository or PPA
5. **Document**: Update documentation and examples

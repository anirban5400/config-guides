# 🍎 Building Ubuntu APT Package on macOS

This guide shows you how to build the Laravel Deploy Ubuntu APT package on your Mac.

## 🚀 Quick Start

### **Method 1: Using Docker (Recommended)**
```bash
# Navigate to package directory
cd ubuntu-app-laravel-deploy

# Make build script executable
chmod +x build-on-mac.sh

# Build the package
./build-on-mac.sh
```

### **Method 2: Using Homebrew**
```bash
# Navigate to package directory
cd ubuntu-app-laravel-deploy

# Make build script executable
chmod +x build-on-mac-homebrew.sh

# Build the package
./build-on-mac-homebrew.sh
```

## 📋 Prerequisites

### **Method 1: Docker (Recommended)**
- **Docker Desktop**: Install from [docker.com](https://www.docker.com/products/docker-desktop)
- **Docker Running**: Start Docker Desktop

### **Method 2: Homebrew**
- **Homebrew**: Install from [brew.sh](https://brew.sh)
- **Required Tools**: The script will install `dpkg` and `gnu-tar`

## 🔧 Detailed Steps

### **Step 1: Choose Your Method**

#### **Docker Method (Recommended)**
- ✅ **Pros**: Uses proper Ubuntu environment, more reliable
- ✅ **Cons**: Requires Docker installation
- ✅ **Best for**: Production builds, ensuring compatibility

#### **Homebrew Method**
- ✅ **Pros**: No Docker required, faster builds
- ✅ **Cons**: Uses macOS tools, may have minor differences
- ✅ **Best for**: Quick testing, development

### **Step 2: Build the Package**

#### **Using Docker**
```bash
# Check Docker is running
docker info

# Build package
./build-on-mac.sh
```

#### **Using Homebrew**
```bash
# Check Homebrew is installed
brew --version

# Build package
./build-on-mac-homebrew.sh
```

### **Step 3: Test the Package**
```bash
# Test package contents
./test-on-mac.sh
```

### **Step 4: Distribute the Package**
```bash
# The package file is ready
ls -la laravel-deploy_1.0.0_all.deb
```

## 📦 What Gets Built

### **Package File**
- **Name**: `laravel-deploy_1.0.0_all.deb`
- **Size**: ~50-100KB
- **Architecture**: `all` (works on all Ubuntu architectures)

### **Package Contents**
```
laravel-deploy_1.0.0_all.deb
├── /usr/bin/laravel-deploy          # Main executable
├── /usr/share/laravel-deploy/       # Scripts and templates
├── /usr/share/doc/laravel-deploy/   # Documentation
├── /etc/laravel-deploy/             # Configuration
└── /var/log/laravel-deploy/         # Log directory
```

## 🧪 Testing on macOS

### **Test Package Structure**
```bash
# Extract package contents
mkdir test-extract
dpkg-deb -R laravel-deploy_1.0.0_all.deb test-extract

# View contents
find test-extract -type f

# Test main executable
head -10 test-extract/usr/bin/laravel-deploy

# Clean up
rm -rf test-extract
```

### **Test Package Information**
```bash
# Show package info
dpkg-deb -I laravel-deploy_1.0.0_all.deb

# Show package contents
dpkg-deb -c laravel-deploy_1.0.0_all.deb | head -10
```

## 🚀 Installation on Ubuntu

### **Transfer Package**
```bash
# Copy to Ubuntu system (example)
scp laravel-deploy_1.0.0_all.deb user@ubuntu-server:/tmp/
```

### **Install on Ubuntu**
```bash
# Install package
sudo dpkg -i laravel-deploy_1.0.0_all.deb

# Install dependencies if needed
sudo apt-get install -f

# Verify installation
which laravel-deploy
laravel-deploy help
```

## 🔄 Distribution Options

### **Local Installation**
```bash
# Copy to Ubuntu system and install
sudo dpkg -i laravel-deploy_1.0.0_all.deb
sudo apt-get install -f
```

### **APT Repository**
```bash
# On Ubuntu server, create repository
mkdir -p /var/www/repo/ubuntu
cp laravel-deploy_1.0.0_all.deb /var/www/repo/ubuntu/

# Add to repository
reprepro -b /var/www/repo includedeb focal laravel-deploy_1.0.0_all.deb

# Install from repository
echo "deb [trusted=yes] http://your-server.com/repo/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/laravel-deploy.list
sudo apt update
sudo apt install laravel-deploy
```

### **PPA (Personal Package Archive)**
```bash
# Upload to Ubuntu PPA
dput ppa:your-username/laravel-deploy laravel-deploy_1.0.0_source.changes

# Install from PPA
sudo add-apt-repository ppa:your-username/laravel-deploy
sudo apt update
sudo apt install laravel-deploy
```

## 🆘 Troubleshooting

### **Docker Issues**
```bash
# Check Docker is running
docker info

# Check Docker version
docker --version

# Restart Docker Desktop if needed
```

### **Homebrew Issues**
```bash
# Update Homebrew
brew update

# Install missing tools
brew install dpkg gnu-tar

# Check installations
brew list dpkg
```

### **Build Issues**
```bash
# Check package structure
find . -name "*.sh" -exec ls -la {} \;

# Verify permissions
ls -la usr/bin/laravel-deploy
ls -la usr/share/laravel-deploy/scripts/

# Check control file
cat DEBIAN/control
```

### **Package Issues**
```bash
# Test package structure
./test-on-mac.sh

# Check package info
dpkg-deb -I laravel-deploy_1.0.0_all.deb

# Extract and inspect
dpkg-deb -R laravel-deploy_1.0.0_all.deb test-extract
find test-extract -type f
```

## 📊 Build Comparison

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Docker** | ✅ Proper Ubuntu environment<br>✅ Reliable builds<br>✅ Production ready | ❌ Requires Docker<br>❌ Slower builds | Production, reliability |
| **Homebrew** | ✅ No Docker required<br>✅ Faster builds<br>✅ Simple setup | ❌ macOS tools<br>❌ Minor differences | Development, testing |

## 🎯 Next Steps

1. **Choose Method**: Docker (recommended) or Homebrew
2. **Build Package**: Run the appropriate build script
3. **Test Package**: Use the test script to verify
4. **Transfer**: Copy to Ubuntu system
5. **Install**: Install on Ubuntu system
6. **Use**: Start deploying Laravel applications!

## 📚 Additional Resources

- **Docker Desktop**: [docker.com](https://www.docker.com/products/docker-desktop)
- **Homebrew**: [brew.sh](https://brew.sh)
- **Ubuntu Package Management**: [help.ubuntu.com](https://help.ubuntu.com/community/PackageManagement)
- **Debian Packaging**: [debian.org](https://www.debian.org/doc/manuals/debian-faq/ch-pkg.en.html)

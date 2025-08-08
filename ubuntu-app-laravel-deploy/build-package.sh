#!/bin/bash

# Laravel Deploy Package Builder
# This script builds the Debian package

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "DEBIAN/control" ]]; then
    print_error "Not in package directory"
    print_info "Please run this script from the ubuntu-app-laravel-deploy directory"
    exit 1
fi

print_info "Building Laravel Deploy package..."

# Set permissions for scripts
print_info "Setting permissions..."
chmod +x usr/bin/laravel-deploy
chmod +x usr/share/laravel-deploy/scripts/*.sh
chmod +x DEBIAN/postinst
chmod +x DEBIAN/prerm

# Create package name
PACKAGE_NAME="laravel-deploy_1.0.0_all.deb"

# Build the package
print_info "Creating Debian package..."
if dpkg-deb --build . "$PACKAGE_NAME" 2>/dev/null; then
    print_success "Package built successfully: $PACKAGE_NAME"
    
    # Show package info
    print_info "Package information:"
    dpkg-deb -I "$PACKAGE_NAME"
    
    # Show package contents
    print_info "Package contents:"
    dpkg-deb -c "$PACKAGE_NAME" | head -20
    
    print_info "Package size:"
    ls -lh "$PACKAGE_NAME"
    
    print_success "Package is ready for installation!"
    print_info "To install:"
    echo "sudo dpkg -i $PACKAGE_NAME"
    echo "sudo apt-get install -f  # Install dependencies if needed"
    
else
    print_error "Failed to build package"
    exit 1
fi

print_info "Build completed successfully!"

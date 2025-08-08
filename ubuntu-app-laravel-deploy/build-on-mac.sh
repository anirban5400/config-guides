#!/bin/bash

# Laravel Deploy Package Builder for macOS
# This script builds the Debian package using Docker on macOS

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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        print_info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        print_info "Please start Docker Desktop"
        exit 1
    fi
    
    print_success "Docker is available"
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "DEBIAN/control" ]]; then
        print_error "Not in package directory"
        print_info "Please run this script from the ubuntu-app-laravel-deploy directory"
        exit 1
    fi
    
    print_success "Directory structure is correct"
}

# Build package using Docker
build_package() {
    print_info "Building Laravel Deploy package using Docker..."
    
    # Create a temporary Dockerfile for building
    cat > Dockerfile.build << 'EOF'
FROM ubuntu:20.04

# Install required packages
RUN apt-get update && apt-get install -y \
    dpkg-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy package files
COPY . .

# Set permissions
RUN chmod +x usr/bin/laravel-deploy
RUN chmod +x usr/share/laravel-deploy/scripts/*.sh
RUN chmod +x DEBIAN/postinst
RUN chmod +x DEBIAN/prerm

# Build package
CMD ["dpkg-deb", "--build", ".", "laravel-deploy_1.0.0_all.deb"]
EOF
    
    # Build Docker image
    print_info "Creating Docker build environment..."
    docker build -f Dockerfile.build -t laravel-deploy-builder .
    
    # Run the build
    print_info "Building package..."
    docker run --rm -v "$(pwd):/build" laravel-deploy-builder
    
    # Clean up
    rm -f Dockerfile.build
    
    print_success "Package built successfully!"
}

# Show package information
show_package_info() {
    if [[ -f "laravel-deploy_1.0.0_all.deb" ]]; then
        print_info "Package information:"
        echo "Package: laravel-deploy_1.0.0_all.deb"
        echo "Size: $(ls -lh laravel-deploy_1.0.0_all.deb | awk '{print $5}')"
        echo "Created: $(date)"
        
        print_info "Package contents (first 10 files):"
        dpkg-deb -c laravel-deploy_1.0.0_all.deb 2>/dev/null | head -10 || echo "Note: dpkg-deb not available on macOS"
        
        print_success "Package is ready for distribution!"
        print_info "You can now:"
        echo "1. Copy the .deb file to an Ubuntu system"
        echo "2. Install with: sudo dpkg -i laravel-deploy_1.0.0_all.deb"
        echo "3. Install dependencies: sudo apt-get install -f"
    else
        print_error "Package file not found"
        exit 1
    fi
}

# Test package structure
test_package_structure() {
    print_info "Testing package structure..."
    
    # Check required files
    local missing_files=()
    
    [[ -f "DEBIAN/control" ]] || missing_files+=("DEBIAN/control")
    [[ -f "DEBIAN/postinst" ]] || missing_files+=("DEBIAN/postinst")
    [[ -f "DEBIAN/prerm" ]] || missing_files+=("DEBIAN/prerm")
    [[ -f "usr/bin/laravel-deploy" ]] || missing_files+=("usr/bin/laravel-deploy")
    [[ -f "usr/share/laravel-deploy/scripts/deploy.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deploy.sh")
    [[ -f "usr/share/laravel-deploy/scripts/deploy-non-interactive.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deploy-non-interactive.sh")
    [[ -f "usr/share/laravel-deploy/scripts/deployment-manager.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deployment-manager.sh")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
    
    print_success "Package structure is valid"
}

# Main function
main() {
    print_info "Laravel Deploy Package Builder for macOS"
    echo ""
    
    # Run checks
    check_docker
    check_directory
    test_package_structure
    
    # Build package
    build_package
    
    # Show results
    show_package_info
    
    print_success "Build completed successfully!"
}

# Run main function
main "$@"

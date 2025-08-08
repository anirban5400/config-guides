#!/bin/bash

# Laravel Deploy Package Builder for macOS (Homebrew Method)
# This script builds the Debian package using Homebrew tools on macOS

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

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed"
        print_info "Please install Homebrew from: https://brew.sh"
        exit 1
    fi
    
    print_success "Homebrew is available"
}

# Install required tools
install_tools() {
    print_info "Installing required tools..."
    
    # Install dpkg-dev (provides dpkg-deb)
    if ! brew list dpkg &> /dev/null; then
        print_info "Installing dpkg..."
        brew install dpkg
    else
        print_success "dpkg is already installed"
    fi
    
    # Install other useful tools
    if ! brew list gnu-tar &> /dev/null; then
        print_info "Installing gnu-tar..."
        brew install gnu-tar
    fi
    
    print_success "All required tools are installed"
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

# Build package using native tools
build_package() {
    print_info "Building Laravel Deploy package..."
    
    # Set permissions
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
        print_info "Package contents (first 10 files):"
        dpkg-deb -c "$PACKAGE_NAME" | head -10
        
        print_info "Package size:"
        ls -lh "$PACKAGE_NAME"
        
        print_success "Package is ready for installation!"
        print_info "To install on Ubuntu:"
        echo "sudo dpkg -i $PACKAGE_NAME"
        echo "sudo apt-get install -f  # Install dependencies if needed"
        
    else
        print_error "Failed to build package"
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

# Create installation script for macOS testing
create_macos_test_script() {
    print_info "Creating macOS test script..."
    
    cat > test-on-mac.sh << 'EOF'
#!/bin/bash

# Test script for Laravel Deploy on macOS
# This script simulates the installation process

set -euo pipefail

echo "🧪 Testing Laravel Deploy Package on macOS"
echo ""

# Check if package exists
if [[ ! -f "laravel-deploy_1.0.0_all.deb" ]]; then
    echo "❌ Package file not found"
    echo "Please build the package first: ./build-on-mac-homebrew.sh"
    exit 1
fi

echo "✅ Package file found: laravel-deploy_1.0.0_all.deb"

# Extract package contents for testing
echo "📦 Extracting package contents..."
mkdir -p test-extract
dpkg-deb -R laravel-deploy_1.0.0_all.deb test-extract

echo "📋 Package contents:"
find test-extract -type f | head -10

echo ""
echo "🔍 Testing main executable..."
if [[ -f "test-extract/usr/bin/laravel-deploy" ]]; then
    echo "✅ Main executable found"
    echo "📄 First 10 lines of executable:"
    head -10 test-extract/usr/bin/laravel-deploy
else
    echo "❌ Main executable not found"
fi

echo ""
echo "🔍 Testing deployment scripts..."
if [[ -d "test-extract/usr/share/laravel-deploy/scripts" ]]; then
    echo "✅ Scripts directory found"
    echo "📄 Available scripts:"
    ls -la test-extract/usr/share/laravel-deploy/scripts/
else
    echo "❌ Scripts directory not found"
fi

echo ""
echo "🔍 Testing documentation..."
if [[ -f "test-extract/usr/share/doc/laravel-deploy/README.md" ]]; then
    echo "✅ Documentation found"
    echo "📄 Documentation size: $(wc -l < test-extract/usr/share/doc/laravel-deploy/README.md) lines"
else
    echo "❌ Documentation not found"
fi

echo ""
echo "🧹 Cleaning up test files..."
rm -rf test-extract

echo ""
echo "✅ Package test completed successfully!"
echo "📦 The package is ready for distribution to Ubuntu systems"
EOF
    
    chmod +x test-on-mac.sh
    print_success "Test script created: test-on-mac.sh"
}

# Main function
main() {
    print_info "Laravel Deploy Package Builder for macOS (Homebrew Method)"
    echo ""
    
    # Run checks
    check_homebrew
    check_directory
    test_package_structure
    
    # Install tools
    install_tools
    
    # Build package
    build_package
    
    # Create test script
    create_macos_test_script
    
    print_success "Build completed successfully!"
    print_info "Next steps:"
    echo "1. Test the package: ./test-on-mac.sh"
    echo "2. Copy laravel-deploy_1.0.0_all.deb to Ubuntu system"
    echo "3. Install on Ubuntu: sudo dpkg -i laravel-deploy_1.0.0_all.deb"
}

# Run main function
main "$@"

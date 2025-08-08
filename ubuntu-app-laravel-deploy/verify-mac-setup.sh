#!/bin/bash

# Laravel Deploy Package - macOS Setup Verification
# This script verifies that your Mac is ready to build the Ubuntu APT package

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

echo "🔍 Verifying macOS Build Environment for Laravel Deploy Package"
echo "================================================================"
echo ""

# Check if we're in the right directory
check_directory() {
    print_info "Checking directory structure..."
    
    if [[ ! -f "DEBIAN/control" ]]; then
        print_error "Not in package directory"
        print_info "Please run this script from the ubuntu-app-laravel-deploy directory"
        return 1
    fi
    
    print_success "Directory structure is correct"
    return 0
}

# Check Docker availability
check_docker() {
    print_info "Checking Docker availability..."
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed"
        print_info "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_warning "Docker is not running"
        print_info "Please start Docker Desktop"
        return 1
    fi
    
    print_success "Docker is available and running"
    return 0
}

# Check Homebrew availability
check_homebrew() {
    print_info "Checking Homebrew availability..."
    
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew is not installed"
        print_info "Install Homebrew from: https://brew.sh"
        return 1
    fi
    
    print_success "Homebrew is available"
    return 0
}

# Check required files
check_required_files() {
    print_info "Checking required files..."
    
    local missing_files=()
    
    # Check DEBIAN files
    [[ -f "DEBIAN/control" ]] || missing_files+=("DEBIAN/control")
    [[ -f "DEBIAN/postinst" ]] || missing_files+=("DEBIAN/postinst")
    [[ -f "DEBIAN/prerm" ]] || missing_files+=("DEBIAN/prerm")
    
    # Check main executable
    [[ -f "usr/bin/laravel-deploy" ]] || missing_files+=("usr/bin/laravel-deploy")
    
    # Check scripts
    [[ -f "usr/share/laravel-deploy/scripts/deploy.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deploy.sh")
    [[ -f "usr/share/laravel-deploy/scripts/deploy-non-interactive.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deploy-non-interactive.sh")
    [[ -f "usr/share/laravel-deploy/scripts/deployment-manager.sh" ]] || missing_files+=("usr/share/laravel-deploy/scripts/deployment-manager.sh")
    
    # Check documentation
    [[ -f "usr/share/doc/laravel-deploy/README.md" ]] || missing_files+=("usr/share/doc/laravel-deploy/README.md")
    
    # Check build scripts
    [[ -f "build-on-mac.sh" ]] || missing_files+=("build-on-mac.sh")
    [[ -f "build-on-mac-homebrew.sh" ]] || missing_files+=("build-on-mac-homebrew.sh")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
    
    print_success "All required files are present"
    return 0
}

# Check file permissions
check_permissions() {
    print_info "Checking file permissions..."
    
    local permission_issues=()
    
    # Check if build scripts are executable
    if [[ ! -x "build-on-mac.sh" ]]; then
        permission_issues+=("build-on-mac.sh (not executable)")
    fi
    
    if [[ ! -x "build-on-mac-homebrew.sh" ]]; then
        permission_issues+=("build-on-mac-homebrew.sh (not executable)")
    fi
    
    if [[ ${#permission_issues[@]} -gt 0 ]]; then
        print_warning "Permission issues found:"
        for issue in "${permission_issues[@]}"; do
            echo "  - $issue"
        done
        print_info "Run: chmod +x build-on-mac.sh build-on-mac-homebrew.sh"
        return 1
    fi
    
    print_success "File permissions are correct"
    return 0
}

# Check Homebrew tools
check_homebrew_tools() {
    print_info "Checking Homebrew tools..."
    
    local missing_tools=()
    
    if ! brew list dpkg &> /dev/null; then
        missing_tools+=("dpkg")
    fi
    
    if ! brew list gnu-tar &> /dev/null; then
        missing_tools+=("gnu-tar")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_warning "Missing Homebrew tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        print_info "Run: brew install ${missing_tools[*]}"
        return 1
    fi
    
    print_success "All required Homebrew tools are installed"
    return 0
}

# Main verification
main() {
    local all_good=true
    
    # Check directory
    if ! check_directory; then
        all_good=false
    fi
    
    echo ""
    
    # Check Docker
    if ! check_docker; then
        all_good=false
    fi
    
    echo ""
    
    # Check Homebrew
    if ! check_homebrew; then
        all_good=false
    fi
    
    echo ""
    
    # Check required files
    if ! check_required_files; then
        all_good=false
    fi
    
    echo ""
    
    # Check permissions
    if ! check_permissions; then
        all_good=false
    fi
    
    echo ""
    
    # Check Homebrew tools
    if ! check_homebrew_tools; then
        all_good=false
    fi
    
    echo ""
    echo "================================================================"
    
    if [[ "$all_good" == true ]]; then
        print_success "🎉 Your Mac is ready to build the Laravel Deploy package!"
        echo ""
        print_info "You can now build the package using:"
        echo "  • Docker method: ./build-on-mac.sh"
        echo "  • Homebrew method: ./build-on-mac-homebrew.sh"
        echo ""
        print_info "Recommended: Use the Docker method for production builds"
    else
        print_error "❌ Some issues need to be resolved before building"
        echo ""
        print_info "Please fix the issues above and run this script again"
    fi
    
    echo ""
}

# Run main verification
main "$@"

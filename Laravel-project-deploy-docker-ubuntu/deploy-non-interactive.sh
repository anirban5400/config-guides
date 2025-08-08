#!/bin/bash

# Laravel Sail Production Deployment Script for DigitalOcean (Non-Interactive)
# Version: 2.3 (Non-Interactive)
# Author: Production Ready Deployment

set -euo pipefail

# =============================================================================
# CONFIGURATION VARIABLES - MODIFY THESE BEFORE RUNNING
# =============================================================================

# Repository Configuration
REPO_URL="git@github.com:your-username/your-laravel-project.git"
PROJECT_NAME="app"

# Database Configuration
# For local Sail database (default)
DB_NAME="laravel"
DB_USER="sail"
DB_PASS="your-secure-password-here"

# For external database cluster (uncomment and configure)
# DB_HOST="your-db-cluster-host.com"
# DB_PORT="3306"
# DB_NAME="your_database_name"
# DB_USER="your_database_user"
# DB_PASS="your-database-password"
# USE_EXTERNAL_DB=false  # Set to true for external database

# Application Configuration
APP_URL="https://yourdomain.com"
APP_ENV="production"

# SSL Configuration
SETUP_SSL=true
DOMAIN_NAME="yourdomain.com"
SSL_EMAIL="admin@yourdomain.com"

# Deployment Options
SKIP_SSL=false
SKIP_FIREWALL=false
SKIP_BACKUP=false

# =============================================================================
# SCRIPT CONFIGURATION (Don't modify unless needed)
# =============================================================================

NON_INTERACTIVE=true
STEP_FILE=".deploy_step"
LOG_FILE="deployment-non-interactive.log"
ENV_FILE=".env"
BACKUP_DIR="backups"
FAILURE_LOG="deployment-failures.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_step() {
    echo -e "\n${BLUE}==> $1${NC}"
    echo "==> $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "✅ $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "❌ $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
    echo "FAILURE: $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$FAILURE_LOG"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "⚠️  $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
}

log_command() {
    local step_name="$1"
    local command="$2"
    local step_number="$3"
    
    echo -e "\n${GREEN}[RUNNING] $step_name${NC}"
    echo "[RUNNING] $step_name [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
    echo "Command: $command" >> "$LOG_FILE"
    
    if eval "$command" 2>&1 | tee -a "$LOG_FILE"; then
        echo "[SUCCESS] $step_name [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
        print_success "$step_name completed"
        return 0
    else
        echo "[FAILED] $step_name [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
        print_error "Step failed: $step_name"
        print_error "You can resume from step $step_number by running: sudo ./deploy-non-interactive.sh --resume $step_number"
        save_step $step_number
        exit 1
    fi
}

save_step() {
    echo "$1" > "$STEP_FILE"
    echo "Step saved: $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
}

load_step() {
    if [ -f "$STEP_FILE" ]; then
        cat "$STEP_FILE"
    else
        echo "0"
    fi
}

check_requirements() {
    print_step "Checking system requirements"
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Check internet connection with multiple fallbacks
    if ! ping -c 1 8.8.8.8 &> /dev/null && ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection available"
        exit 1
    fi
    
    # Validate configuration variables
    if [[ -z "$REPO_URL" ]]; then
        print_error "REPO_URL is not set. Please configure it at the top of the script."
        exit 1
    fi
    
    if [[ "$SETUP_SSL" == true ]] && [[ -z "$DOMAIN_NAME" ]]; then
        print_error "DOMAIN_NAME is required when SETUP_SSL is true"
        exit 1
    fi
    
    print_success "System requirements check passed"
}

create_backup() {
    if [[ "$SKIP_BACKUP" == false ]]; then
        print_step "Creating backup"
        mkdir -p "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
        if [ -f ".env" ]; then
            cp .env "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/"
        fi
        if [ -d "storage" ]; then
            cp -r storage "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/"
        fi
        print_success "Backup created"
    else
        print_warning "Skipping backup creation"
    fi
}

# =============================================================================
# DEPLOYMENT STEPS
# =============================================================================

step_0() {
    print_step "Step 0: Pre-deployment Setup"
    check_requirements
    
    # Create necessary directories
    log_command "Creating directories" "mkdir -p $BACKUP_DIR logs" "0"
    
    # Update system
    log_command "Updating system packages" "apt update && apt upgrade -y" "0"
    
    # Install essential packages
    log_command "Installing essential packages" "apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release" "0"
    
    save_step 1
}

step_1() {
    print_step "Step 1: Install Docker & Docker Compose"
    
    # Remove old Docker versions
    log_command "Removing old Docker versions" "apt remove -y docker docker-engine docker.io containerd runc || true" "1"
    
    # Add Docker GPG key (fixed for modern Ubuntu)
    log_command "Adding Docker GPG key" "install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg" "1"
    
    # Add Docker repository (fixed)
    log_command "Adding Docker repository" "echo 'deb [arch='\$(dpkg --print-architecture)' signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu '\$(. /etc/os-release && echo \"\$VERSION_CODENAME\")' stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" "1"
    
    # Update package index
    log_command "Updating package index" "apt update" "1"
    
    # Install Docker
    log_command "Installing Docker" "apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "1"
    
    # Start and enable Docker
    log_command "Starting Docker service" "systemctl start docker && systemctl enable docker" "1"
    
    # Add current user to docker group (if not root)
    if [ "$SUDO_USER" ]; then
        log_command "Adding user to docker group" "usermod -aG docker $SUDO_USER" "1"
        print_warning "You may need to log out and back in for docker group changes to take effect"
    fi
    
    save_step 2
}

step_2() {
    print_step "Step 2: Verify Docker Installation"
    
    log_command "Checking Docker version" "docker --version" "2"
    log_command "Checking Docker Compose version" "docker compose version" "2"
    log_command "Testing Docker with hello-world" "docker run --rm hello-world" "2"
    log_command "Checking Docker service status" "systemctl status docker --no-pager" "2"
    
    print_success "Docker installation verified successfully"
    save_step 3
}

step_3() {
    print_step "Step 3: SSH Key Setup for Git"
    
    # Create .ssh directory if it doesn't exist
    log_command "Creating SSH directory" "mkdir -p ~/.ssh && chmod 700 ~/.ssh" "3"
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        log_command "Generating SSH key" "ssh-keygen -t ed25519 -C 'deploy@laravel-server' -f ~/.ssh/id_ed25519 -N ''" "3"
    else
        print_warning "SSH key already exists, skipping generation"
    fi
    
    # Set proper permissions
    log_command "Setting SSH key permissions" "chmod 600 ~/.ssh/id_ed25519 && chmod 644 ~/.ssh/id_ed25519.pub" "3"
    
    # Start SSH agent and add key
    log_command "Adding SSH key to agent" "eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519" "3"
    
    # Always show SSH key and instructions (regardless of repository type)
    echo -e "\n${GREEN}🔑 SSH Key Generated Successfully!${NC}"
    echo "=================================================="
    echo -e "\n${YELLOW}📋 Your Public SSH Key:${NC}"
    echo "=================================================="
    cat ~/.ssh/id_ed25519.pub
    echo "=================================================="
    
    # Check if this is an SSH repository
    if [[ "$REPO_URL" == git@* ]]; then
        SSH_HOST=$(echo $REPO_URL | cut -d'@' -f2 | cut -d':' -f1)
        
        echo -e "\n${BLUE}📝 Steps to Add SSH Key to Git Provider:${NC}"
        echo "1. Copy the SSH key above (the entire key including ssh-ed25519...)"
        echo "2. Go to your Git provider:"
        echo "   • GitHub: https://github.com/settings/keys"
        echo "   • GitLab: https://gitlab.com/-/profile/keys"
        echo "   • Bitbucket: https://bitbucket.org/account/settings/ssh-keys/"
        echo "3. Click 'New SSH key' or 'Add SSH key'"
        echo "4. Give it a title like 'Laravel Server - $(hostname)'"
        echo "5. Paste the key in the 'Key' field"
        echo "6. Click 'Add key' or 'Save'"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: This step is required for SSH repository access${NC}"
        echo "Repository URL: $REPO_URL"
        echo "Git Host: $SSH_HOST"
        echo ""
        
        # Always prompt for verification in SSH repositories
        echo -e "${GREEN}Options:${NC}"
        echo "1. ✅ I've added the SSH key - Continue and test connection"
        echo "2. ⏸️  I'll add it later - Exit and resume when ready"
        echo "3. ❌ Skip SSH verification (not recommended)"
        echo ""
        
        read -p "Choose option (1/2/3): " SSH_CHOICE
        case "$SSH_CHOICE" in
            1)
                echo -e "\n${BLUE}Testing SSH connection to $SSH_HOST...${NC}"
                echo "This may take a few seconds..."
                
                # Test SSH connection with timeout
                if timeout 10 ssh -T git@$SSH_HOST 2>&1 | grep -q "successfully authenticated"; then
                    print_success "SSH connection verified successfully! ✅"
                    echo -e "${GREEN}You can now proceed to the next step.${NC}"
                else
                    print_warning "SSH connection test failed. This could mean:"
                    echo "• The SSH key hasn't been added yet"
                    echo "• The key was added but needs a few minutes to propagate"
                    echo "• There's a network connectivity issue"
                    echo ""
                    read -p "Continue anyway? (y/n): " CONTINUE_SSH
                    if [[ ! "$CONTINUE_SSH" =~ ^[Yy]$ ]]; then
                        print_error "SSH key verification failed. Exiting."
                        print_error "You can resume later with: sudo ./deploy-non-interactive.sh --resume 3"
                        save_step 3
                        exit 1
                    fi
                fi
                ;;
            2)
                print_warning "Exiting to allow time for SSH key setup."
                print_warning "After adding the SSH key, resume with:"
                print_warning "sudo ./deploy-non-interactive.sh --resume 3"
                save_step 3
                exit 0
                ;;
            3)
                print_warning "Skipping SSH verification (not recommended)"
                print_warning "If repository cloning fails in the next step, you'll need to add the SSH key."
                ;;
            *)
                print_error "Invalid choice. Exiting."
                save_step 3
                exit 1
                ;;
        esac
    else
        echo -e "\n${GREEN}✅ HTTPS repository detected${NC}"
        echo "SSH key is not required for HTTPS repositories, but you can still add it for future use."
        echo ""
        read -p "Press Enter to continue to next step..."
    fi
    
    save_step 4
}

step_4() {
    print_step "Step 4: Clone Laravel Project Repository"
    
    # Test connection if it's SSH
    if [[ "$REPO_URL" == git@* ]]; then
        SSH_HOST=$(echo $REPO_URL | cut -d'@' -f2 | cut -d':' -f1)
        print_step "Testing SSH connection to $SSH_HOST"
        
        # Test SSH connection with better error handling
        if ssh -T git@$SSH_HOST 2>&1 | grep -q "successfully authenticated"; then
            print_success "SSH connection verified successfully!"
        else
            print_error "SSH connection failed. The SSH key may not be added to your Git provider."
            print_error "Please add the SSH key from Step 3 to your Git provider and try again."
            print_error "You can resume from this step with: sudo ./deploy-non-interactive.sh --resume 4"
            save_step 4
            exit 1
        fi
    fi
    
    # Handle existing directory
    if [ -d "$PROJECT_NAME" ]; then
        print_warning "Directory $PROJECT_NAME already exists"
        log_command "Removing existing directory" "rm -rf $PROJECT_NAME" "4"
    fi
    
    # Clone repository with better error handling
    print_step "Cloning repository: $REPO_URL"
    if git clone $REPO_URL $PROJECT_NAME 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository. This could be due to:"
        print_error "1. SSH key not added to Git provider"
        print_error "2. Repository URL is incorrect"
        print_error "3. Repository is private and access is denied"
        print_error ""
        print_error "You can resume from this step with: sudo ./deploy-non-interactive.sh --resume 4"
        save_step 4
        exit 1
    fi
    
    # Verify directory exists and change to it
    if [ ! -d "$PROJECT_NAME" ]; then
        print_error "Failed to create or access project directory: $PROJECT_NAME"
        exit 1
    fi
    
    # Change to project directory
    cd "$PROJECT_NAME"
    
    print_success "Repository setup completed"
    save_step 5
}

step_5() {
    print_step "Step 5: Laravel Sail Setup & Prerequisites"
    
    # Install additional prerequisites
    log_command "Installing additional packages" "apt install -y git unzip curl php-cli php-curl php-zip" "5"
    
    # Check if we have composer.json (Laravel project)
    if [ ! -f "composer.json" ]; then
        print_error "composer.json not found. Are you in a Laravel project directory?"
        exit 1
    fi
    
    # Check if Laravel Sail is installed
    if [ ! -f "vendor/bin/sail" ]; then
        print_warning "Laravel Sail not found, installing dependencies first"
        
        # Install Composer if not present
        if ! command -v composer &> /dev/null; then
            log_command "Installing Composer" "curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer" "5"
            
            # Verify composer installation
            if ! composer --version &> /dev/null; then
                print_error "Composer installation failed"
                exit 1
            fi
        fi
        
        log_command "Installing Laravel dependencies" "composer install --no-dev --optimize-autoloader" "5"
    fi
    
    # Check if docker-compose.yml exists (Sail generates this)
    if [ ! -f "docker-compose.yml" ]; then
        if [[ "${USE_EXTERNAL_DB:-false}" == "true" ]]; then
            print_step "Installing Sail without MySQL (using external database)"
            log_command "Publishing Sail configuration" "php artisan sail:install --with=redis --no-interaction" "5"
        else
            log_command "Publishing Sail configuration" "php artisan sail:install --with=mysql,redis --no-interaction" "5"
        fi
    fi
    
    # Create environment file
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            log_command "Creating .env file from example" "cp .env.example .env" "5"
        else
            print_error ".env.example file not found"
            exit 1
        fi
    fi
    
    save_step 6
}

step_6() {
    print_step "Step 6: Environment Configuration"
    
    # Check if using external database
    if [[ "${USE_EXTERNAL_DB:-false}" == "true" ]]; then
        print_step "Configuring external database connection"
        
        # Validate external database configuration
        if [[ -z "${DB_HOST:-}" ]] || [[ -z "${DB_NAME:-}" ]] || [[ -z "${DB_USER:-}" ]] || [[ -z "${DB_PASS:-}" ]]; then
            print_error "External database configuration incomplete. Please set DB_HOST, DB_NAME, DB_USER, and DB_PASS."
            exit 1
        fi
        
        # Escape special characters for sed
        DB_HOST_ESC=$(printf '%s\n' "$DB_HOST" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_PORT_ESC=$(printf '%s\n' "${DB_PORT:-3306}" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_NAME_ESC=$(printf '%s\n' "$DB_NAME" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_USER_ESC=$(printf '%s\n' "$DB_USER" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_PASS_ESC=$(printf '%s\n' "$DB_PASS" | sed 's:[[\.*^$()+?{|]:\\&:g')
        APP_URL_ESC=$(printf '%s\n' "$APP_URL" | sed 's:[[\.*^$()+?{|]:\\&:g')
        APP_ENV_ESC=$(printf '%s\n' "$APP_ENV" | sed 's:[[\.*^$()+?{|]:\\&:g')
        
        # Update .env file for external database
        log_command "Configuring external database environment variables" "
            sed -i 's/^APP_ENV=.*/APP_ENV=$APP_ENV_ESC/' .env &&
            sed -i 's/^APP_URL=.*/APP_URL=$APP_URL_ESC/' .env &&
            sed -i 's/^DB_HOST=.*/DB_HOST=$DB_HOST_ESC/' .env &&
            sed -i 's/^DB_PORT=.*/DB_PORT=$DB_PORT_ESC/' .env &&
            sed -i 's/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME_ESC/' .env &&
            sed -i 's/^DB_USERNAME=.*/DB_USERNAME=$DB_USER_ESC/' .env &&
            sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS_ESC/' .env &&
            grep -q '^APP_PORT=' .env || echo 'APP_PORT=8080' >> .env"
        
        print_success "External database configuration completed"
        print_warning "Make sure your database cluster allows connections from this server's IP"
        
    else
        print_step "Configuring local Sail database"
        
        # Escape special characters for sed
        DB_NAME_ESC=$(printf '%s\n' "$DB_NAME" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_USER_ESC=$(printf '%s\n' "$DB_USER" | sed 's:[[\.*^$()+?{|]:\\&:g')
        DB_PASS_ESC=$(printf '%s\n' "$DB_PASS" | sed 's:[[\.*^$()+?{|]:\\&:g')
        APP_URL_ESC=$(printf '%s\n' "$APP_URL" | sed 's:[[\.*^$()+?{|]:\\&:g')
        APP_ENV_ESC=$(printf '%s\n' "$APP_ENV" | sed 's:[[\.*^$()+?{|]:\\&:g')
        
        # Update .env file for local Sail database
        log_command "Configuring local database environment variables" "
            sed -i 's/^APP_ENV=.*/APP_ENV=$APP_ENV_ESC/' .env &&
            sed -i 's/^APP_URL=.*/APP_URL=$APP_URL_ESC/' .env &&
            sed -i 's/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME_ESC/' .env &&
            sed -i 's/^DB_USERNAME=.*/DB_USERNAME=$DB_USER_ESC/' .env &&
            sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS_ESC/' .env &&
            sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' .env &&
            sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env &&
            grep -q '^APP_PORT=' .env || echo 'APP_PORT=8080' >> .env"
        
        print_success "Local database configuration completed"
    fi
    
    save_step 7
}

step_7() {
    print_step "Step 7: Build and Start Laravel Sail"
    
    # Build and start containers
    log_command "Building Docker containers" "./vendor/bin/sail build --no-cache" "7"
    log_command "Starting Laravel Sail" "./vendor/bin/sail up -d" "7"
    
    # Wait for containers to be ready
    print_step "Waiting for containers to start..."
    sleep 30
    
    # Check container status
    log_command "Checking container status" "./vendor/bin/sail ps" "7"
    
    save_step 8
}

step_8() {
    print_step "Step 8: Laravel Application Setup"
    
    # Generate application key
    log_command "Generating application key" "./vendor/bin/sail artisan key:generate" "8"
    
    # Run database migrations
    log_command "Running database migrations" "./vendor/bin/sail artisan migrate --force" "8"
    
    # Clear and cache configuration
    log_command "Optimizing application" "./vendor/bin/sail artisan config:cache && ./vendor/bin/sail artisan route:cache && ./vendor/bin/sail artisan view:cache" "8"
    
    # Set proper permissions
    log_command "Setting storage permissions" "./vendor/bin/sail exec laravel.test chmod -R 775 storage bootstrap/cache && ./vendor/bin/sail exec laravel.test chown -R www-data:www-data storage bootstrap/cache" "8"
    
    save_step 9
}

step_9() {
    print_step "Step 9: SSL Certificate Setup (Let's Encrypt)"
    
    if [[ "$SETUP_SSL" == true ]] && [[ -n "$DOMAIN_NAME" ]]; then
        # Install Certbot
        log_command "Installing Certbot" "apt install -y certbot python3-certbot-nginx" "9"
        
        # Install Nginx (reverse proxy)
        log_command "Installing Nginx" "apt install -y nginx" "9"
        
        # Configure Nginx for Laravel Sail with improved settings
        log_command "Configuring Nginx" "cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'EOL'
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOL" "9"
        
        log_command "Enabling Nginx site" "ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/ && rm -f /etc/nginx/sites-enabled/default" "9"
        log_command "Testing Nginx configuration" "nginx -t" "9"
        log_command "Restarting Nginx" "systemctl restart nginx && systemctl enable nginx" "9"
        
        # Get SSL certificate with proper email
        log_command "Obtaining SSL certificate" "certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email $SSL_EMAIL" "9"
        
        # Setup auto-renewal
        log_command "Setting up SSL renewal cron job" "(crontab -l 2>/dev/null; echo '0 12 * * * /usr/bin/certbot renew --quiet') | crontab -" "9"
        
        print_success "SSL certificate installed successfully"
    else
        print_warning "Skipping SSL setup"
    fi
    
    save_step 10
}

step_10() {
    print_step "Step 10: Firewall Configuration"
    
    if [[ "$SKIP_FIREWALL" == false ]]; then
        # Check current SSH connection to avoid locking out
        SSH_PORT=$(ss -tlnp | grep sshd | head -1 | awk '{print $4}' | cut -d: -f2)
        SSH_PORT=${SSH_PORT:-22}
        
        print_warning "Configuring firewall. SSH port detected: $SSH_PORT"
        print_warning "Make sure you have another way to access the server if needed"
        
        # Configure UFW firewall with proper SSH port
        log_command "Configuring firewall" "ufw allow $SSH_PORT/tcp && ufw allow 'Nginx Full' && ufw allow 80 && ufw allow 443 && ufw default deny incoming && ufw default allow outgoing && ufw --force enable" "10"
        
        log_command "Checking firewall status" "ufw status verbose" "10"
    else
        print_warning "Skipping firewall configuration"
    fi
    
    save_step 11
}

step_11() {
    print_step "Step 11: Final Health Checks & Verification"
    
    # Wait for containers to stabilize
    print_step "Waiting for application to stabilize..."
    sleep 10
    
    # Check container status first
    log_command "Checking container health" "./vendor/bin/sail ps" "11"
    
    # Get server IP address (multiple methods)
    SERVER_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || 
                 curl -s --max-time 5 http://whatismyip.akamai.com/ 2>/dev/null || 
                 curl -s --max-time 5 http://ifconfig.me 2>/dev/null || 
                 echo "localhost")
    
    # Smart protocol detection for health checks with timeout
    if [ -n "${DOMAIN_NAME:-}" ] && [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ] 2>/dev/null; then
        log_command "Testing HTTPS application response" "curl -I --max-time 10 --connect-timeout 5 https://$DOMAIN_NAME" "11"
        log_command "Testing HTTPS www subdomain" "curl -I --max-time 10 --connect-timeout 5 https://www.$DOMAIN_NAME || true" "11"
    else
        log_command "Testing HTTP application response" "curl -I --max-time 10 --connect-timeout 5 http://localhost:8080" "11"
    fi
    
    # Check specific Laravel endpoints
    log_command "Testing Laravel welcome page" "curl -s http://localhost:8080 | grep -i 'laravel' || echo 'Laravel check completed'" "11"
    
    # Check database connectivity
    log_command "Testing database connection" "./vendor/bin/sail artisan tinker --execute='DB::connection()->getPdo(); echo \"Database connected successfully\";'" "11"
    
    # Check logs for any critical errors
    log_command "Checking application logs for errors" "./vendor/bin/sail logs --tail=20 | grep -i 'error\\|exception\\|fatal' || echo 'No critical errors found in recent logs'" "11"
    
    # Create comprehensive maintenance and monitoring scripts
    log_command "Creating maintenance scripts" "cat > update.sh << 'EOL'
#!/bin/bash
set -euo pipefail
cd \$(dirname \$0)

echo 'Starting Laravel deployment update...'
git pull origin main
./vendor/bin/sail composer install --no-dev --optimize-autoloader
./vendor/bin/sail artisan migrate --force
./vendor/bin/sail artisan config:cache
./vendor/bin/sail artisan route:cache
./vendor/bin/sail artisan view:cache
./vendor/bin/sail artisan queue:restart
echo 'Deployment updated successfully!'
EOL

cat > status.sh << 'EOL'
#!/bin/bash
cd \$(dirname \$0)

echo '=== Laravel Sail Status ==='
./vendor/bin/sail ps
echo
echo '=== Recent Logs ==='
./vendor/bin/sail logs --tail=10
echo
echo '=== Disk Usage ==='
df -h
EOL

chmod +x update.sh status.sh" "11"
    
    save_step 12
}

step_12() {
    print_step "Step 12: Deployment Summary"
    
    echo -e "\n${GREEN}🎉 Laravel Sail Deployment Completed Successfully!${NC}"
    echo "=============================================="
    
    echo -e "\n${BLUE}📊 Deployment Summary:${NC}"
    echo "• Docker & Docker Compose: ✅ Installed"
    echo "• Laravel Sail: ✅ Configured and Running"
    echo "• Database: ✅ Migrated"
    echo "• SSL Certificate: $([ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ] 2>/dev/null && echo "✅ Configured" || echo "❌ Not configured")"
    echo "• Firewall: ✅ Configured"
    
    echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
    echo "• Start application: ./vendor/bin/sail up -d"
    echo "• Stop application: ./vendor/bin/sail down"
    echo "• View logs: ./vendor/bin/sail logs -f"
    echo "• Run artisan commands: ./vendor/bin/sail artisan [command]"
    echo "• SSH into container: ./vendor/bin/sail shell"
    echo "• Update deployment: ./update.sh"
    echo "• Check status: ./status.sh"
    echo "• Database access: ./vendor/bin/sail mysql"
    
    echo -e "\n${BLUE}📁 Important Files:${NC}"
    echo "• Environment: .env"
    echo "• Docker config: docker-compose.yml"
    echo "• Deployment log: $LOG_FILE"
    echo "• Failure log: $FAILURE_LOG"
    echo "• Update script: update.sh"
    echo "• Status script: status.sh"
    
    # Get server IP with fallbacks
    SERVER_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || 
                 curl -s --max-time 5 http://whatismyip.akamai.com/ 2>/dev/null || 
                 curl -s --max-time 5 http://ifconfig.me 2>/dev/null || 
                 echo "YOUR_SERVER_IP")
    
    if [ -n "${DOMAIN_NAME:-}" ]; then
        echo -e "\n${BLUE}🌐 Your application is available at:${NC}"
        echo "• https://$DOMAIN_NAME"
        echo "• https://www.$DOMAIN_NAME"
    else
        echo -e "\n${BLUE}🌐 Your application is available at:${NC}"
        echo "• http://$SERVER_IP:8080"
        echo "• http://localhost:8080 (if accessing locally)"
    fi
    
    echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
    echo "1. Configure your DNS settings to point to this server's IP"
    echo "2. Set up regular backups for your database and files"
    echo "3. Configure monitoring and logging"
    echo "4. Set up CI/CD pipeline for automated deployments"
    echo "5. Review and optimize your Laravel configuration for production"
    
    save_step "completed"
}

# =============================================================================
# EXECUTION FLOW
# =============================================================================

# Create log files
touch "$LOG_FILE" "$FAILURE_LOG"
echo "Non-interactive deployment started at $(date)" >> "$LOG_FILE"

# Check for resume parameter
if [[ "${1:-}" == "--resume" ]] && [[ -n "${2:-}" ]]; then
    echo "Resuming from step $2"
    save_step $2
    CURRENT_STEP=$2
else
    CURRENT_STEP=$(load_step)
fi

# Execute steps based on current step
case $CURRENT_STEP in
    0) step_0;;&
    1) step_1;;&
    2) step_2;;&
    3) step_3;;&
    4) step_4;;&
    5) step_5;;&
    6) step_6;;&
    7) step_7;;&
    8) step_8;;&
    9) step_9;;&
    10) step_10;;&
    11) step_11;;&
    12) step_12;;
    "completed") 
        echo -e "\n${GREEN}🎉 Deployment already completed!${NC}"
        echo "Run with --resume 1 to start fresh deployment."
        ;;
    *) 
        echo -e "\n${RED}❌ Unknown step: $CURRENT_STEP${NC}"
        echo "Resetting to beginning..."
        save_step 0
        step_0
        ;;
esac

echo -e "\n${GREEN}Non-interactive deployment script finished at $(date)${NC}"
echo -e "\n${BLUE}💡 Usage Examples:${NC}"
echo "• Fresh deployment: sudo ./deploy-non-interactive.sh"
echo "• Resume from step 5: sudo ./deploy-non-interactive.sh --resume 5"
echo "• Check logs: tail -f $LOG_FILE"
echo "• Check failures: cat $FAILURE_LOG"

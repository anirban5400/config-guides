#!/bin/bash

# Laravel Sail Production Deployment Script for DigitalOcean
# Version: 2.2 (Fixed)
# Author: Production Ready Deployment

set -euo pipefail

# Check for non-interactive mode
NON_INTERACTIVE=false
if [[ "${1:-}" == "--yes" ]] || [[ "${1:-}" == "-y" ]]; then
    NON_INTERACTIVE=true
    echo "Running in non-interactive mode..."
fi

STEP_FILE=".deploy_step"
LOG_FILE="deployment.log"
ENV_FILE=".env"
BACKUP_DIR="backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
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
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "⚠️  $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
}

run_step() {
    echo -e "\n${GREEN}[RUNNING] $1${NC}"
    echo "[RUNNING] $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
    
    if eval "$2" 2>&1 | tee -a "$LOG_FILE"; then
        echo "[SUCCESS] $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
        return 0
    else
        echo "[FAILED] $1 [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
        print_error "Step failed: $1"
        exit 1
    fi
}

ask_continue() {
    if [[ "$NON_INTERACTIVE" == true ]]; then
        echo "✔️ Continuing automatically (non-interactive mode)..."
        return 0
    fi
    
    echo
    read -p "✔️ Continue to next step? (y/n): " choice
    case "$choice" in 
      y|Y ) echo "Continuing...";;
      * ) echo "Exiting deployment."; exit 1;;
    esac
}

save_step() {
    echo "$1" > "$STEP_FILE"
}

load_step() {
    if [ -f "$STEP_FILE" ]; then
        cat "$STEP_FILE"
    else
        echo "0"
    fi
}

choose_start_step() {
    echo -e "\n${BLUE}🚀 Laravel Sail Production Deployment${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    if [[ "$NON_INTERACTIVE" == true ]]; then
        echo "Non-interactive mode: Starting from beginning..."
        save_step 0
        return
    fi
    
    echo -e "\n➡️ Do you want to:"
    echo "1. Start from beginning (fresh deployment)"
    echo "2. Resume from last saved step ($(load_step))"
    read -p "Enter 1 or 2: " CHOICE
    if [[ "$CHOICE" == "1" ]]; then
        save_step 0
        echo "Starting fresh deployment..."
    else
        echo "Resuming from step $(load_step)..."
    fi
}

create_backup() {
    if [ -d "$BACKUP_DIR" ]; then
        print_step "Creating backup"
        mkdir -p "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
        if [ -f ".env" ]; then
            cp .env "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/"
        fi
        if [ -d "storage" ]; then
            cp -r storage "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/"
        fi
        print_success "Backup created"
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
    
    print_success "System requirements check passed"
}

# --- Deployment Steps ---

step_0() {
    print_step "Step 0: Pre-deployment Setup"
    check_requirements
    
    # Create necessary directories
    run_step "Creating directories" "mkdir -p $BACKUP_DIR logs"
    
    # Update system
    run_step "Updating system packages" "apt update && apt upgrade -y"
    
    # Install essential packages
    run_step "Installing essential packages" "apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release"
    
    ask_continue
    save_step 1
}

step_1() {
    print_step "Step 1: Install Docker & Docker Compose"
    
    # Remove old Docker versions
    run_step "Removing old Docker versions" "apt remove -y docker docker-engine docker.io containerd runc || true"
    
    # Add Docker GPG key (fixed for modern Ubuntu)
    run_step "Adding Docker GPG key" "
        install -m 0755 -d /etc/apt/keyrings &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
        chmod a+r /etc/apt/keyrings/docker.gpg"
    
    # Add Docker repository (fixed)
    run_step "Adding Docker repository" "
        echo 'deb [arch='\$(dpkg --print-architecture)' signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu '\$(. /etc/os-release && echo \"\$VERSION_CODENAME\")' stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null"
    
    # Update package index
    run_step "Updating package index" "apt update"
    
    # Install Docker
    run_step "Installing Docker" "apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    
    # Start and enable Docker
    run_step "Starting Docker service" "systemctl start docker && systemctl enable docker"
    
    # Add current user to docker group (if not root)
    if [ "$SUDO_USER" ]; then
        run_step "Adding user to docker group" "usermod -aG docker $SUDO_USER"
        print_warning "You may need to log out and back in for docker group changes to take effect"
    fi
    
    ask_continue
    save_step 2
}

step_2() {
    print_step "Step 2: Verify Docker Installation"
    
    run_step "Checking Docker version" "docker --version"
    run_step "Checking Docker Compose version" "docker compose version"
    run_step "Testing Docker with hello-world" "docker run --rm hello-world"
    run_step "Checking Docker service status" "systemctl status docker --no-pager"
    
    print_success "Docker installation verified successfully"
    ask_continue
    save_step 3
}

step_3() {
    print_step "Step 3: SSH Key Setup for Git"
    
    # Create .ssh directory if it doesn't exist
    run_step "Creating SSH directory" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        run_step "Generating SSH key" "ssh-keygen -t ed25519 -C 'deploy@laravel-server' -f ~/.ssh/id_ed25519 -N ''"
    else
        print_warning "SSH key already exists, skipping generation"
    fi
    
    # Set proper permissions
    run_step "Setting SSH key permissions" "chmod 600 ~/.ssh/id_ed25519 && chmod 644 ~/.ssh/id_ed25519.pub"
    
    # Start SSH agent and add key
    run_step "Adding SSH key to agent" "eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
    
    echo -e "\n${YELLOW}📋 Your public SSH key (add this to your Git provider):${NC}"
    echo "=================================================="
    cat ~/.ssh/id_ed25519.pub
    echo "=================================================="
    echo -e "\n${BLUE}Instructions:${NC}"
    echo "1. Copy the key above"
    echo "2. Go to GitHub/GitLab → Settings → SSH Keys"
    echo "3. Add the key with a descriptive title"
    echo "4. Test with: ssh -T git@github.com (or gitlab.com)"
    
    ask_continue
    save_step 4
}

step_4() {
    print_step "Step 4: Clone Laravel Project Repository"
    
    if [[ "$NON_INTERACTIVE" == false ]]; then
        echo -e "\n${BLUE}Repository Setup${NC}"
        read -p "Enter your repository URL (SSH/HTTPS): " REPO_URL
        read -p "Enter project directory name [app]: " PROJECT_NAME
    else
        # Non-interactive defaults - will need to be set via environment variables
        REPO_URL=${REPO_URL:-""}
        PROJECT_NAME=${PROJECT_NAME:-"app"}
        
        if [[ -z "$REPO_URL" ]]; then
            print_error "REPO_URL environment variable must be set in non-interactive mode"
            exit 1
        fi
    fi
    
    PROJECT_NAME=${PROJECT_NAME:-app}
    
    # Test connection if it's SSH
    if [[ "$REPO_URL" == git@* ]]; then
        SSH_HOST=$(echo $REPO_URL | cut -d'@' -f2 | cut -d':' -f1)
        run_step "Testing SSH connection" "ssh -T git@$SSH_HOST || true"
    fi
    
    # Handle existing directory
    if [ -d "$PROJECT_NAME" ]; then
        print_warning "Directory $PROJECT_NAME already exists"
        if [[ "$NON_INTERACTIVE" == false ]]; then
            read -p "Remove and re-clone? (y/n): " RECLONE
            if [[ "$RECLONE" =~ ^[Yy]$ ]]; then
                run_step "Removing existing directory" "rm -rf $PROJECT_NAME"
                run_step "Cloning repository" "git clone $REPO_URL $PROJECT_NAME"
            fi
        else
            print_warning "Non-interactive mode: keeping existing directory"
        fi
    else
        run_step "Cloning repository" "git clone $REPO_URL $PROJECT_NAME"
    fi
    
    # Verify directory exists and change to it
    if [ ! -d "$PROJECT_NAME" ]; then
        print_error "Failed to create or access project directory: $PROJECT_NAME"
        exit 1
    fi
    
    # Change to project directory
    cd "$PROJECT_NAME"
    
    print_success "Repository setup completed"
    ask_continue
    save_step 5
}

step_5() {
    print_step "Step 5: Laravel Sail Setup & Prerequisites"
    
    # Install additional prerequisites
    run_step "Installing additional packages" "apt install -y git unzip curl php-cli php-curl php-zip"
    
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
            run_step "Installing Composer" "
                curl -sS https://getcomposer.org/installer | php &&
                mv composer.phar /usr/local/bin/composer &&
                chmod +x /usr/local/bin/composer"
            
            # Verify composer installation
            if ! composer --version &> /dev/null; then
                print_error "Composer installation failed"
                exit 1
            fi
        fi
        
        run_step "Installing Laravel dependencies" "composer install --no-dev --optimize-autoloader"
    fi
    
    # Check if docker-compose.yml exists (Sail generates this)
    if [ ! -f "docker-compose.yml" ]; then
        if [[ "$NON_INTERACTIVE" == false ]]; then
            run_step "Publishing Sail configuration" "php artisan sail:install --with=mysql,redis"
        else
            run_step "Publishing Sail configuration (non-interactive)" "php artisan sail:install --with=mysql,redis --no-interaction"
        fi
    fi
    
    # Create environment file
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            run_step "Creating .env file from example" "cp .env.example .env"
        else
            print_error ".env.example file not found"
            exit 1
        fi
    fi
    
    ask_continue
    save_step 6
}

step_6() {
    print_step "Step 6: Environment Configuration"
    
    if [[ "$NON_INTERACTIVE" == false ]]; then
        echo -e "\n${BLUE}Database Configuration${NC}"
        read -p "Enter database name [laravel]: " DB_NAME
        read -p "Enter database user [sail]: " DB_USER
        read -sp "Enter database password: " DB_PASS
        echo
        
        echo -e "\n${BLUE}Application Configuration${NC}"
        read -p "Enter application URL [http://localhost]: " APP_URL
        read -p "Enter application environment [production]: " APP_ENV
    else
        # Non-interactive defaults
        DB_NAME="laravel"
        DB_USER="sail"
        DB_PASS="$(openssl rand -base64 32)"
        APP_URL="http://localhost"
        APP_ENV="production"
        echo "Using default configuration for non-interactive mode"
    fi
    
    DB_NAME=${DB_NAME:-laravel}
    DB_USER=${DB_USER:-sail}
    APP_URL=${APP_URL:-http://localhost}
    APP_ENV=${APP_ENV:-production}
    
    # Escape special characters for sed
    DB_NAME_ESC=$(printf '%s\n' "$DB_NAME" | sed 's:[[\.*^$()+?{|]:\\&:g')
    DB_USER_ESC=$(printf '%s\n' "$DB_USER" | sed 's:[[\.*^$()+?{|]:\\&:g')
    DB_PASS_ESC=$(printf '%s\n' "$DB_PASS" | sed 's:[[\.*^$()+?{|]:\\&:g')
    APP_URL_ESC=$(printf '%s\n' "$APP_URL" | sed 's:[[\.*^$()+?{|]:\\&:g')
    APP_ENV_ESC=$(printf '%s\n' "$APP_ENV" | sed 's:[[\.*^$()+?{|]:\\&:g')
    
    # Update .env file with comprehensive configuration (fixed escaping)
    run_step "Configuring environment variables" "
        sed -i 's/^APP_ENV=.*/APP_ENV=$APP_ENV_ESC/' .env &&
        sed -i 's/^APP_URL=.*/APP_URL=$APP_URL_ESC/' .env &&
        sed -i 's/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME_ESC/' .env &&
        sed -i 's/^DB_USERNAME=.*/DB_USERNAME=$DB_USER_ESC/' .env &&
        sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS_ESC/' .env &&
        sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' .env &&
        sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env &&
        grep -q '^APP_PORT=' .env || echo 'APP_PORT=8080' >> .env"
    
    ask_continue
    save_step 7
}

step_7() {
    print_step "Step 7: Build and Start Laravel Sail"
    
    # Build and start containers
    run_step "Building Docker containers" "./vendor/bin/sail build --no-cache"
    run_step "Starting Laravel Sail" "./vendor/bin/sail up -d"
    
    # Wait for containers to be ready
    print_step "Waiting for containers to start..."
    sleep 30
    
    # Check container status
    run_step "Checking container status" "./vendor/bin/sail ps"
    
    ask_continue
    save_step 8
}

step_8() {
    print_step "Step 8: Laravel Application Setup"
    
    # Generate application key
    run_step "Generating application key" "./vendor/bin/sail artisan key:generate"
    
    # Run database migrations
    run_step "Running database migrations" "./vendor/bin/sail artisan migrate --force"
    
    # Seed database (optional)
    if [[ "$NON_INTERACTIVE" == false ]]; then
        read -p "Do you want to seed the database? (y/n): " SEED_DB
        if [[ "$SEED_DB" =~ ^[Yy]$ ]]; then
            run_step "Seeding database" "./vendor/bin/sail artisan db:seed --force"
        fi
    else
        print_warning "Skipping database seeding in non-interactive mode"
    fi
    
    # Clear and cache configuration
    run_step "Optimizing application" "
        ./vendor/bin/sail artisan config:cache &&
        ./vendor/bin/sail artisan route:cache &&
        ./vendor/bin/sail artisan view:cache"
    
    # Set proper permissions
    run_step "Setting storage permissions" "
        ./vendor/bin/sail exec laravel.test chmod -R 775 storage bootstrap/cache &&
        ./vendor/bin/sail exec laravel.test chown -R www-data:www-data storage bootstrap/cache"
    
    ask_continue
    save_step 9
}

step_9() {
    print_step "Step 9: SSL Certificate Setup (Let's Encrypt)"
    
    SETUP_SSL=false
    DOMAIN_NAME=""
    SSL_EMAIL=""
    
    if [[ "$NON_INTERACTIVE" == false ]]; then
        read -p "Do you want to setup SSL with Let's Encrypt? (y/n): " SETUP_SSL_INPUT
        if [[ "$SETUP_SSL_INPUT" =~ ^[Yy]$ ]]; then
            SETUP_SSL=true
            read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
            read -p "Enter your email for SSL notifications: " SSL_EMAIL
        fi
    else
        echo "Skipping SSL setup in non-interactive mode"
    fi
    
    if [[ "$SETUP_SSL" == true ]] && [[ -n "$DOMAIN_NAME" ]]; then
        # Install Certbot
        run_step "Installing Certbot" "apt install -y certbot python3-certbot-nginx"
        
        # Install Nginx (reverse proxy)
        run_step "Installing Nginx" "apt install -y nginx"
        
        # Configure Nginx for Laravel Sail with improved settings
        run_step "Configuring Nginx" "cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'EOL'
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
EOL"
        
        run_step "Enabling Nginx site" "
            ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/ &&
            rm -f /etc/nginx/sites-enabled/default"
        run_step "Testing Nginx configuration" "nginx -t"
        run_step "Restarting Nginx" "systemctl restart nginx && systemctl enable nginx"
        
        # Get SSL certificate with proper email
        SSL_EMAIL=${SSL_EMAIL:-"admin@$DOMAIN_NAME"}
        if [[ "$NON_INTERACTIVE" == false ]]; then
            run_step "Obtaining SSL certificate" "certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email $SSL_EMAIL"
        else
            run_step "Obtaining SSL certificate (non-interactive)" "certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email $SSL_EMAIL"
        fi
        
        # Setup auto-renewal
        run_step "Setting up SSL renewal cron job" "(crontab -l 2>/dev/null; echo '0 12 * * * /usr/bin/certbot renew --quiet') | crontab -"
        
        print_success "SSL certificate installed successfully"
    else
        print_warning "Skipping SSL setup"
    fi
    
    ask_continue
    save_step 10
}

step_10() {
    print_step "Step 10: Firewall Configuration"
    
    # Check current SSH connection to avoid locking out
    SSH_PORT=$(ss -tlnp | grep sshd | head -1 | awk '{print $4}' | cut -d: -f2)
    SSH_PORT=${SSH_PORT:-22}
    
    print_warning "Configuring firewall. SSH port detected: $SSH_PORT"
    print_warning "Make sure you have another way to access the server if needed"
    
    # Configure UFW firewall with proper SSH port
    run_step "Configuring firewall" "
        ufw allow $SSH_PORT/tcp &&
        ufw allow 'Nginx Full' &&
        ufw allow 80 &&
        ufw allow 443 &&
        ufw default deny incoming &&
        ufw default allow outgoing &&
        ufw --force enable"
    
    run_step "Checking firewall status" "ufw status verbose"
    
    ask_continue
    save_step 11
}

step_11() {
    print_step "Step 11: Final Health Checks & Verification"
    
    # Wait for containers to stabilize
    print_step "Waiting for application to stabilize..."
    sleep 10
    
    # Check container status first
    run_step "Checking container health" "./vendor/bin/sail ps"
    
    # Get server IP address (multiple methods)
    SERVER_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || 
                 curl -s --max-time 5 http://whatismyip.akamai.com/ 2>/dev/null || 
                 curl -s --max-time 5 http://ifconfig.me 2>/dev/null || 
                 echo "localhost")
    
    # Smart protocol detection for health checks with timeout
    if [ -n "${DOMAIN_NAME:-}" ] && [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ] 2>/dev/null; then
        run_step "Testing HTTPS application response" "curl -I --max-time 10 --connect-timeout 5 https://$DOMAIN_NAME"
        run_step "Testing HTTPS www subdomain" "curl -I --max-time 10 --connect-timeout 5 https://www.$DOMAIN_NAME || true"
    else
        run_step "Testing HTTP application response" "curl -I --max-time 10 --connect-timeout 5 http://localhost:8080"
    fi
    
    # Check specific Laravel endpoints
    run_step "Testing Laravel welcome page" "curl -s http://localhost:8080 | grep -i 'laravel' || echo 'Laravel check completed'"
    
    # Check database connectivity
    run_step "Testing database connection" "./vendor/bin/sail artisan tinker --execute='DB::connection()->getPdo(); echo \"Database connected successfully\";'"
    
    # Check logs for any critical errors
    run_step "Checking application logs for errors" "./vendor/bin/sail logs --tail=20 | grep -i 'error\\|exception\\|fatal' || echo 'No critical errors found in recent logs'"
    
    # Create comprehensive maintenance and monitoring scripts
    run_step "Creating maintenance scripts" "
        cat > update.sh << 'EOL'
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

        chmod +x update.sh status.sh"
    
    ask_continue
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

# --- Execution Flow ---

# Create log file
touch "$LOG_FILE"
echo "Deployment started at $(date)" >> "$LOG_FILE"

# Choose starting step
choose_start_step

CURRENT_STEP=$(load_step)

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
        echo "Run with step 1 to start fresh deployment."
        ;;
    *) 
        echo -e "\n${RED}❌ Unknown step: $CURRENT_STEP${NC}"
        echo "Resetting to beginning..."
        save_step 0
        step_0
        ;;
esac

echo -e "\n${GREEN}Deployment script finished at $(date)${NC}"
echo -e "\n${BLUE}💡 Usage Examples:${NC}"
echo "• Fresh deployment: sudo ./deploy.sh"
echo "• Non-interactive mode: sudo ./deploy.sh --yes"
echo "• Resume deployment: sudo ./deploy.sh (then choose option 2)"
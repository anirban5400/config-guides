#!/bin/bash

# Laravel Sail Deployment Manager
# Version: 1.0
# Author: Production Ready Deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOYMENT_SCRIPT="deploy-non-interactive.sh"
STEP_FILE=".deploy_step"
LOG_FILE="deployment-non-interactive.log"
FAILURE_LOG="deployment-failures.log"
BACKUP_DIR="backups"
RESTORE_POINTS_DIR="restore-points"
PROJECT_NAME="app"

# Create necessary directories
mkdir -p "$BACKUP_DIR" "$RESTORE_POINTS_DIR"

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}   Laravel Sail Deployment Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if deployment script exists
check_deployment_script() {
    if [[ ! -f "$DEPLOYMENT_SCRIPT" ]]; then
        print_error "Deployment script not found: $DEPLOYMENT_SCRIPT"
        exit 1
    fi
}

# Get current deployment step
get_current_step() {
    if [[ -f "$STEP_FILE" ]]; then
        cat "$STEP_FILE"
    else
        echo "0"
    fi
}

# Get step name by number
get_step_name() {
    local step=$1
    case $step in
        0) echo "System Setup";;
        1) echo "Docker Installation";;
        2) echo "Docker Verification";;
        3) echo "SSH Key Setup";;
        4) echo "Repository Clone";;
        5) echo "Sail Setup";;
        6) echo "Environment Config";;
        7) echo "Container Build";;
        8) echo "Laravel Setup";;
        9) echo "SSL Setup";;
        10) echo "Firewall Config";;
        11) echo "Health Checks";;
        12) echo "Deployment Summary";;
        "completed") echo "Deployment Completed";;
        *) echo "Unknown Step";;
    esac
}

# Check deployment status
check_status() {
    print_header
    print_info "Checking deployment status..."
    
    local current_step=$(get_current_step)
    local step_name=$(get_step_name "$current_step")
    
    echo -e "\n${BLUE}📊 Deployment Status:${NC}"
    echo "• Current Step: $current_step - $step_name"
    
    # Check if deployment is completed
    if [[ "$current_step" == "completed" ]]; then
        print_success "Deployment is completed!"
        
        # Check if application is running
        if [[ -d "$PROJECT_NAME" ]] && [[ -f "$PROJECT_NAME/vendor/bin/sail" ]]; then
            cd "$PROJECT_NAME"
            if ./vendor/bin/sail ps | grep -q "Up"; then
                print_success "Application is running"
                echo "• Containers: $(./vendor/bin/sail ps --format table | grep -c 'Up' || echo '0') running"
            else
                print_warning "Application containers are not running"
            fi
            cd ..
        else
            print_warning "Application directory not found"
        fi
    else
        print_info "Deployment is in progress at step $current_step"
    fi
    
    # Check logs
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "\n${BLUE}📋 Recent Log Entries:${NC}"
        tail -5 "$LOG_FILE" | while read -r line; do
            echo "• $line"
        done
    fi
    
    # Check failures
    if [[ -f "$FAILURE_LOG" ]]; then
        local failure_count=$(wc -l < "$FAILURE_LOG")
        if [[ $failure_count -gt 0 ]]; then
            echo -e "\n${RED}❌ Failures Found: $failure_count${NC}"
            tail -3 "$FAILURE_LOG" | while read -r line; do
                echo "• $line"
            done
        fi
    fi
    
    # Check restore points
    local restore_points=$(find "$RESTORE_POINTS_DIR" -name "*.tar.gz" 2>/dev/null | wc -l)
    echo -e "\n${BLUE}💾 Restore Points: $restore_points${NC}"
    
    if [[ $restore_points -gt 0 ]]; then
        echo "Available restore points:"
        find "$RESTORE_POINTS_DIR" -name "*.tar.gz" -exec basename {} \; | head -5
    fi
}

# Create restore point
create_restore_point() {
    print_header
    print_info "Creating restore point..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local restore_name="restore_${timestamp}"
    local restore_file="$RESTORE_POINTS_DIR/${restore_name}.tar.gz"
    
    # Create backup of current state
    local backup_items=()
    
    # Backup .env if exists
    if [[ -f ".env" ]]; then
        backup_items+=(".env")
    fi
    
    # Backup project directory if exists
    if [[ -d "$PROJECT_NAME" ]]; then
        backup_items+=("$PROJECT_NAME")
    fi
    
    # Backup step file
    if [[ -f "$STEP_FILE" ]]; then
        backup_items+=("$STEP_FILE")
    fi
    
    # Backup logs
    if [[ -f "$LOG_FILE" ]]; then
        backup_items+=("$LOG_FILE")
    fi
    
    if [[ ${#backup_items[@]} -eq 0 ]]; then
        print_warning "No items to backup"
        return
    fi
    
    # Create tar archive
    if tar -czf "$restore_file" "${backup_items[@]}" 2>/dev/null; then
        print_success "Restore point created: $restore_file"
        
        # Create metadata file
        cat > "$RESTORE_POINTS_DIR/${restore_name}.meta" << EOF
RESTORE_POINT: $restore_name
CREATED: $(date)
STEP: $(get_current_step)
ITEMS: ${backup_items[*]}
SIZE: $(du -h "$restore_file" | cut -f1)
EOF
        
        echo "• Timestamp: $timestamp"
        echo "• Items backed up: ${backup_items[*]}"
        echo "• File size: $(du -h "$restore_file" | cut -f1)"
    else
        print_error "Failed to create restore point"
    fi
}

# List restore points
list_restore_points() {
    print_header
    print_info "Available restore points:"
    
    local restore_files=$(find "$RESTORE_POINTS_DIR" -name "*.tar.gz" 2>/dev/null | sort -r)
    
    if [[ -z "$restore_files" ]]; then
        print_warning "No restore points found"
        return
    fi
    
    echo -e "\n${BLUE}📋 Restore Points:${NC}"
    echo "Format: [Number] Timestamp - Step - Size"
    echo "----------------------------------------"
    
    local count=1
    while IFS= read -r restore_file; do
        local basename=$(basename "$restore_file" .tar.gz)
        local meta_file="$RESTORE_POINTS_DIR/${basename}.meta"
        
        if [[ -f "$meta_file" ]]; then
            local timestamp=$(grep "CREATED:" "$meta_file" | cut -d' ' -f2-)
            local step=$(grep "STEP:" "$meta_file" | cut -d' ' -f2)
            local step_name=$(get_step_name "$step")
            local size=$(du -h "$restore_file" | cut -f1)
            
            echo "[$count] $timestamp - $step_name - $size"
        else
            local size=$(du -h "$restore_file" | cut -f1)
            echo "[$count] $basename - Unknown - $size"
        fi
        
        ((count++))
    done <<< "$restore_files"
}

# Restore from point
restore_from_point() {
    local restore_number=$1
    
    print_header
    print_warning "Restoring from point $restore_number..."
    
    # Get list of restore files
    local restore_files=($(find "$RESTORE_POINTS_DIR" -name "*.tar.gz" 2>/dev/null | sort -r))
    
    if [[ ${#restore_files[@]} -eq 0 ]]; then
        print_error "No restore points available"
        exit 1
    fi
    
    if [[ $restore_number -lt 1 ]] || [[ $restore_number -gt ${#restore_files[@]} ]]; then
        print_error "Invalid restore point number. Available: 1-${#restore_files[@]}"
        exit 1
    fi
    
    local restore_file="${restore_files[$((restore_number-1))]}"
    local basename=$(basename "$restore_file" .tar.gz)
    
    print_info "Restoring from: $basename"
    
    # Confirm restore
    echo -e "\n${YELLOW}⚠️  This will overwrite current deployment state${NC}"
    read -p "Are you sure you want to restore? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Create backup of current state before restore
    print_info "Creating backup of current state..."
    local current_backup="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    local current_items=()
    [[ -f ".env" ]] && current_items+=(".env")
    [[ -d "$PROJECT_NAME" ]] && current_items+=("$PROJECT_NAME")
    [[ -f "$STEP_FILE" ]] && current_items+=("$STEP_FILE")
    
    if [[ ${#current_items[@]} -gt 0 ]]; then
        tar -czf "$current_backup" "${current_items[@]}" 2>/dev/null
        print_success "Current state backed up to: $current_backup"
    fi
    
    # Extract restore point
    print_info "Extracting restore point..."
    if tar -xzf "$restore_file" -C .; then
        print_success "Restore completed successfully!"
        
        # Show restored state
        local restored_step=$(get_current_step)
        local step_name=$(get_step_name "$restored_step")
        echo "• Restored to step: $restored_step - $step_name"
        
        # Check if application is available
        if [[ -d "$PROJECT_NAME" ]]; then
            echo "• Project directory restored"
            if [[ -f "$PROJECT_NAME/vendor/bin/sail" ]]; then
                echo "• Laravel Sail available"
            fi
        fi
        
        print_info "You can now resume deployment with:"
        echo "sudo ./$DEPLOYMENT_SCRIPT --resume $restored_step"
        
    else
        print_error "Failed to extract restore point"
        exit 1
    fi
}

# Rollback deployment
rollback_deployment() {
    print_header
    print_warning "Rollback deployment..."
    
    local current_step=$(get_current_step)
    
    if [[ "$current_step" == "completed" ]]; then
        print_info "Deployment is completed. Rolling back to previous step..."
        local rollback_step=11
    else
        local rollback_step=$((current_step - 1))
        if [[ $rollback_step -lt 0 ]]; then
            rollback_step=0
        fi
    fi
    
    print_info "Rolling back to step $rollback_step"
    
    # Confirm rollback
    echo -e "\n${YELLOW}⚠️  This will rollback to step $rollback_step${NC}"
    read -p "Are you sure you want to rollback? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Rollback cancelled"
        exit 0
    fi
    
    # Create restore point before rollback
    create_restore_point
    
    # Save rollback step
    echo "$rollback_step" > "$STEP_FILE"
    
    print_success "Rollback completed!"
    print_info "You can now resume from step $rollback_step with:"
    echo "sudo ./$DEPLOYMENT_SCRIPT --resume $rollback_step"
}

# Clean up old restore points
cleanup_restore_points() {
    print_header
    print_info "Cleaning up old restore points..."
    
    local days=${1:-7}
    local cutoff_date=$(date -d "$days days ago" +%Y%m%d)
    
    local deleted_count=0
    while IFS= read -r restore_file; do
        local basename=$(basename "$restore_file" .tar.gz)
        local timestamp=$(echo "$basename" | grep -o '[0-9]\{8\}_[0-9]\{6\}' | head -1)
        
        if [[ -n "$timestamp" ]]; then
            local file_date=$(echo "$timestamp" | cut -d'_' -f1)
            if [[ "$file_date" < "$cutoff_date" ]]; then
                rm -f "$restore_file"
                rm -f "$RESTORE_POINTS_DIR/${basename}.meta"
                ((deleted_count++))
            fi
        fi
    done < <(find "$RESTORE_POINTS_DIR" -name "*.tar.gz" 2>/dev/null)
    
    print_success "Cleaned up $deleted_count old restore points (older than $days days)"
}

# Show help
show_help() {
    print_header
    echo -e "${BLUE}Usage: $0 [COMMAND] [OPTIONS]${NC}"
    echo ""
    echo "Commands:"
    echo "  status                    Check deployment status"
    echo "  backup                    Create restore point"
    echo "  list                      List available restore points"
    echo "  restore <number>          Restore from point number"
    echo "  rollback                  Rollback to previous step"
    echo "  cleanup [days]            Clean up old restore points (default: 7 days)"
    echo "  help                      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 status                 # Check current status"
    echo "  $0 backup                 # Create restore point"
    echo "  $0 list                   # List restore points"
    echo "  $0 restore 1              # Restore from first point"
    echo "  $0 rollback               # Rollback to previous step"
    echo "  $0 cleanup 14             # Clean up points older than 14 days"
    echo ""
    echo "Files:"
    echo "  • $STEP_FILE              # Current deployment step"
    echo "  • $LOG_FILE               # Deployment log"
    echo "  • $FAILURE_LOG            # Failure log"
    echo "  • $RESTORE_POINTS_DIR/    # Restore points directory"
}

# Main execution
main() {
    check_deployment_script
    
    case "${1:-help}" in
        "status")
            check_status
            ;;
        "backup")
            create_restore_point
            ;;
        "list")
            list_restore_points
            ;;
        "restore")
            if [[ -z "${2:-}" ]]; then
                print_error "Restore point number required"
                echo "Usage: $0 restore <number>"
                exit 1
            fi
            restore_from_point "$2"
            ;;
        "rollback")
            rollback_deployment
            ;;
        "cleanup")
            cleanup_restore_points "${2:-7}"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"

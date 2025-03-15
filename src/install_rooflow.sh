#!/bin/bash

# RooFlow Installation Script
# This script automates the installation of RooFlow into any project
# Usage:
#   Single project: ./install_rooflow.sh -p <target-directory>
#   All configured projects: ./install_rooflow.sh --all

# Load configuration
CONFIG_FILE="rooflow_config.json"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup directory
BACKUP_DIR=".rooflow_backups"

# Function to check dependencies
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_status "$RED" "Error: jq is required but not installed."
        print_status "$BLUE" "Please install jq first:"
        echo "  macOS: brew install jq"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        print_status "$RED" "Error: tar is required but not installed."
        exit 1
    fi
}

# Function to create backup
create_backup() {
    local target_dir=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="rooflow_backup_${timestamp}.tar.gz"
    local backup_path="${target_dir}/${BACKUP_DIR}/${backup_name}"
    
    print_status "$BLUE" "Creating backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "${target_dir}/${BACKUP_DIR}"
    
    # Create manifest file
    local manifest="${target_dir}/${BACKUP_DIR}/manifest_${timestamp}.txt"
    echo "RooFlow Backup Manifest" > "$manifest"
    echo "Created: $(date)" >> "$manifest"
    echo "Project: ${target_dir}" >> "$manifest"
    echo "Contents:" >> "$manifest"
    
    # List of files to backup
    local files_to_backup=()
    
    # Add root configuration files
    while IFS= read -r file; do
        if [ -f "${target_dir}/${file}" ]; then
            files_to_backup+=("${file}")
            echo "- ${file}" >> "$manifest"
        fi
    done < <(jq -r '.default_settings.required_files.root[]' "$CONFIG_FILE")
    
    # Add .roo directory files
    local config_path=$(jq -r '.default_settings.config_path' "$CONFIG_FILE")
    while IFS= read -r file; do
        if [ -f "${target_dir}/${config_path}/${file}" ]; then
            files_to_backup+=("${config_path}/${file}")
            echo "- ${config_path}/${file}" >> "$manifest"
        fi
    done < <(jq -r '.default_settings.required_files.roo_dir[]' "$CONFIG_FILE")
    
    # Add memory bank
    local memory_bank_path=$(jq -r '.default_settings.memory_bank_path' "$CONFIG_FILE")
    if [ -d "${target_dir}/${memory_bank_path}" ]; then
        files_to_backup+=("${memory_bank_path}")
        echo "- ${memory_bank_path}/" >> "$manifest"
    fi
    
    # Create backup archive
    if [ ${#files_to_backup[@]} -gt 0 ]; then
        tar -czf "$backup_path" -C "$target_dir" "${files_to_backup[@]}" "$BACKUP_DIR/manifest_${timestamp}.txt"
        if [ $? -eq 0 ]; then
            print_status "$GREEN" "✓ Backup created: ${backup_path}"
            # Keep only the 5 most recent backups
            ls -t "${target_dir}/${BACKUP_DIR}"/rooflow_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
            return 0
        else
            print_status "$RED" "Failed to create backup"
            rm -f "$manifest"
            return 1
        fi
    else
        print_status "$RED" "No files to backup"
        rm -f "$manifest"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    local target_dir=$1
    local backup_file=$2
    
    if [ ! -f "$backup_file" ]; then
        print_status "$RED" "Backup file not found: $backup_file"
        return 1
    fi
    
    print_status "$BLUE" "Restoring from backup: $backup_file"
    
    # Create temporary directory for restoration
    local temp_dir=$(mktemp -d)
    
    # Extract backup to temporary directory
    tar -xzf "$backup_file" -C "$temp_dir"
    
    if [ $? -eq 0 ]; then
        # Read manifest to verify contents
        local manifest=$(find "$temp_dir" -name "manifest_*.txt" | head -n 1)
        if [ -f "$manifest" ]; then
            print_status "$BLUE" "Restoring files..."
            
            # Get list of files from manifest
            local files=$(grep "^- " "$manifest" | cut -d' ' -f2-)
            
            # Create necessary directories
            for file in $files; do
                if [[ "$file" == */ ]]; then
                    mkdir -p "${target_dir}/${file%/}"
                else
                    mkdir -p "$(dirname "${target_dir}/${file}")"
                fi
            done
            
            # Copy files from temp directory to target
            cd "$temp_dir" && \
            for file in $files; do
                if [[ -e "$file" ]]; then
                    cp -R "$file" "${target_dir}/${file}"
                fi
            done
            
            if [ $? -eq 0 ]; then
                print_status "$GREEN" "✓ Restoration completed successfully"
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 0
            else
                print_status "$RED" "Failed to restore files"
            fi
        else
            print_status "$RED" "Invalid backup: manifest not found"
        fi
    else
        print_status "$RED" "Failed to extract backup"
    fi
    
    rm -rf "$temp_dir"
    return 1
}

# Function to read configuration file
read_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_status "$RED" "Error: Configuration file $CONFIG_FILE not found"
        exit 1
    fi
    
    # Validate JSON format
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_status "$RED" "Error: Invalid JSON in $CONFIG_FILE"
        exit 1
    fi
}

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to install to all configured projects
install_all_projects() {
    local projects
    projects=$(jq -r '.managed_projects[].path' "$CONFIG_FILE")
    
    local total_projects=$(echo "$projects" | wc -l)
    local current=0
    
    print_status "$BLUE" "Installing RooFlow to $total_projects projects..."
    
    while IFS= read -r project_path; do
        ((current++))
        print_status "$BLUE" "[$current/$total_projects] Installing to: $project_path"
        install_rooflow "$project_path"
    done <<< "$projects"
}

# Function to check if a directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        print_status "$RED" "Error: Directory $1 does not exist"
        exit 1
    fi
}

# Function to detect project type
detect_project_type() {
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python"
    elif [ -f "package.json" ]; then
        echo "nodejs"
    else
        echo "unknown"
    fi
}

# Function to get project type from config
get_project_type_from_config() {
    local target_dir=$1
    local project_type
    
    project_type=$(jq -r --arg path "$target_dir" '.managed_projects[] | select(.path == $path) | .type' "$CONFIG_FILE")
    
    if [ "$project_type" != "null" ] && [ -n "$project_type" ]; then
        echo "$project_type"
    else
        detect_project_type
    fi
}

# Function to create memory bank structure
create_memory_bank() {
    local target_dir=$1
    local memory_bank_path=$(jq -r '.default_settings.memory_bank_path' "$CONFIG_FILE")
    mkdir -p "${target_dir}/${memory_bank_path}"
    
    # Create activeContext.md with proper path
    cat > "${target_dir}/${memory_bank_path}/activeContext.md" << EOL
# Active Context

## Current Installation
- Location: ${target_dir}
- Status: Newly configured
- Timestamp: $(date "+%Y-%m-%d %H:%M %p") ($(date "+%Z"))

## Configured Modes
1. Architect (.clinerules-architect, system-prompt-architect)
2. Ask (.clinerules-ask, system-prompt-ask)
3. Code (.clinerules-code, system-prompt-code)
4. Debug (.clinerules-debug, system-prompt-debug)
5. Test (.clinerules-test, system-prompt-test)
6. Igor (.clinerules-igor, system-prompt-igor)
7. Communication Support (.clinerules-comm-support, system-prompt-comm-support)

## System Status
- Memory Bank: Initialized
- Configuration Files: Pending verification
- System Prompts: Pending verification
- Custom Modes: Pending initialization
EOL
}

# Function to update system information in prompts
update_system_information() {
    local target_dir=$1
    local config_path=$(jq -r '.default_settings.config_path' "$CONFIG_FILE")
    local system_prompts=($(jq -r '.default_settings.required_files.roo_dir[]' "$CONFIG_FILE"))
    
    # Get system information
    local os_name=$(uname -s)
    local shell=$(basename "$SHELL")
    local home_dir=$HOME
    
    print_status "$BLUE" "Updating system information in prompts..."
    
    for prompt in "${system_prompts[@]}"; do
        local prompt_path="${target_dir}/${config_path}/${prompt}"
        if [ -f "$prompt_path" ]; then
            # Create temp file
            local temp_file=$(mktemp)
            
            # Update system_information section
            awk -v target="$target_dir" \
                -v shell="$shell" \
                -v home="$home_dir" \
                -v config_path="$config_path" '
                /^system_information: \|$/ {
                    print $0
                    print "  Operating System: macOS Sonoma"
                    print "  Default Shell: " shell
                    print "  Home Directory: " home
                    print "  Current Working Directory: " target
                    print "  Global Custom Modes: " home "/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings"
                    p=1
                    next
                }
                p && /^[^ ]/ { p=0 }
                !p { print $0 }
            ' "$prompt_path" > "$temp_file"
            
            # Replace original file with updated content
            mv "$temp_file" "$prompt_path"
        fi
    done
}

# Main installation function
install_rooflow() {
    local target_dir=$1
    local source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    print_status "$BLUE" "Installing RooFlow to: ${target_dir}"
    
    # Verify target directory
    check_dir "$target_dir"
    
    # Get config settings
    local config_path=$(jq -r '.default_settings.config_path' "$CONFIG_FILE")
    mkdir -p "${target_dir}/${config_path}"
    
    # Get project type
    local project_type=$(get_project_type_from_config "$target_dir")
    print_status "$BLUE" "Project type: ${project_type}"
    
    # Copy configuration files
    print_status "$BLUE" "Copying configuration files..."
    local root_files=($(jq -r '.default_settings.required_files.root[]' "$CONFIG_FILE"))
    for file in "${root_files[@]}"; do
        cp "${source_dir}/${file}" "${target_dir}/"
        if [ $? -ne 0 ]; then
            print_status "$RED" "Failed to copy: ${file}"
            return 1
        fi
    done
    
    # Copy system prompt files
    print_status "$BLUE" "Copying system prompt files..."
    local roo_files=($(jq -r '.default_settings.required_files.roo_dir[]' "$CONFIG_FILE"))
    for file in "${roo_files[@]}"; do
        cp "${source_dir}/${config_path}/${file}" "${target_dir}/${config_path}/"
        if [ $? -ne 0 ]; then
            print_status "$RED" "Failed to copy: ${config_path}/${file}"
            return 1
        fi
    done
    
    # Create memory bank
    print_status "$BLUE" "Creating memory bank structure..."
    create_memory_bank "$target_dir"
    
    # Update system information in prompts
    update_system_information "$target_dir"
    
    # Verify installation
    local verification_failed=0
    
    # Verify root configuration files
    for file in "${root_files[@]}"; do
        if [ ! -f "${target_dir}/${file}" ]; then
            print_status "$RED" "Missing: ${file}"
            verification_failed=1
        fi
    done
    
    # Verify system prompt files
    for file in "${roo_files[@]}"; do
        if [ ! -f "${target_dir}/${config_path}/${file}" ]; then
            print_status "$RED" "Missing: ${config_path}/${file}"
            verification_failed=1
        fi
    done
    
    if [ $verification_failed -eq 0 ]; then
        print_status "$GREEN" "✓ RooFlow installation completed successfully!"
        print_status "$GREEN" "Next steps:"
        print_status "$GREEN" "1. Open project in VS Code"
        print_status "$GREEN" "2. Start new Roo conversation"
        print_status "$GREEN" "3. Switch to Architect mode to initialize Memory Bank"
    else
        print_status "$RED" "Installation completed with errors. Please check the messages above."
    fi
}

# Check dependencies first
check_dependencies

# Read and validate config file
read_config

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            if [ -n "$2" ]; then
                TARGET_PATH="$2"
                shift 2
            else
                print_status "$RED" "Error: -p|--path requires a directory path"
                exit 1
            fi
            ;;
        -a|--all)
            INSTALL_ALL=true
            shift
            ;;
        -b|--backup)
            if [ -n "$2" ]; then
                BACKUP_PATH="$2"
                ACTION="backup"
                shift 2
            else
                print_status "$RED" "Error: -b|--backup requires a directory path"
                exit 1
            fi
            ;;
        -r|--restore)
            if [ -n "$2" ] && [ -n "$3" ]; then
                RESTORE_PATH="$2"
                BACKUP_FILE="$3"
                ACTION="restore"
                shift 3
            else
                print_status "$RED" "Error: -r|--restore requires a directory path and backup file"
                exit 1
            fi
            ;;
        -l|--list-backups)
            if [ -n "$2" ]; then
                LIST_BACKUPS_PATH="$2"
                ACTION="list-backups"
                shift 2
            else
                print_status "$RED" "Error: -l|--list-backups requires a directory path"
                exit 1
            fi
            ;;
        -h|--help)
            echo "Usage:"
            echo "  $0 -p|--path <target-directory>    # Install to specific directory"
            echo "  $0 -a|--all                        # Install to all configured projects"
            echo "  $0 -b|--backup <directory>         # Create backup of installation"
            echo "  $0 -r|--restore <dir> <backup>     # Restore from backup file"
            echo "  $0 -l|--list-backups <directory>   # List available backups"
            echo "  $0 -h|--help                       # Show this help message"
            exit 0
            ;;
        *)
            print_status "$RED" "Error: Unknown option $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to list backups
list_backups() {
    local target_dir=$1
    local backup_dir="${target_dir}/${BACKUP_DIR}"
    
    if [ ! -d "$backup_dir" ]; then
        print_status "$RED" "No backups found in: $target_dir"
        return 1
    fi
    
    print_status "$BLUE" "Available backups in: $target_dir"
    echo "----------------------------------------"
    
    local count=0
    while IFS= read -r backup; do
        ((count++))
        local manifest="${backup_dir}/manifest_$(basename "${backup%.*.*}" | cut -d'_' -f3,4).txt"
        echo "[$count] $(basename "$backup")"
        if [ -f "$manifest" ]; then
            echo "    Created: $(grep "Created:" "$manifest" | cut -d' ' -f2-)"
        fi
    done < <(ls -t "${backup_dir}"/rooflow_backup_*.tar.gz 2>/dev/null)
    
    if [ $count -eq 0 ]; then
        print_status "$RED" "No backups found"
        return 1
    fi
    
    echo "----------------------------------------"
}

# Execute based on action and arguments
case "$ACTION" in
    "backup")
        if [ -d "$BACKUP_PATH" ]; then
            create_backup "$BACKUP_PATH"
        else
            print_status "$RED" "Error: Directory not found: $BACKUP_PATH"
            exit 1
        fi
        ;;
    "restore")
        if [ -d "$RESTORE_PATH" ]; then
            restore_from_backup "$RESTORE_PATH" "$BACKUP_FILE"
        else
            print_status "$RED" "Error: Directory not found: $RESTORE_PATH"
            exit 1
        fi
        ;;
    "list-backups")
        if [ -d "$LIST_BACKUPS_PATH" ]; then
            list_backups "$LIST_BACKUPS_PATH"
        else
            print_status "$RED" "Error: Directory not found: $LIST_BACKUPS_PATH"
            exit 1
        fi
        ;;
    *)
        if [ "$INSTALL_ALL" = true ]; then
            install_all_projects
        elif [ -n "$TARGET_PATH" ]; then
            install_rooflow "$TARGET_PATH"
        else
            print_status "$RED" "Error: No valid action or installation target specified"
            echo "Use -h or --help for usage information"
            exit 1
        fi
        ;;
esac
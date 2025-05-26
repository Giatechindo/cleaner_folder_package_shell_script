#!/bin/bash

# ==============================================
# PACKAGE CLEANER - MULTI-MODE DIRECTORY CLEANER
# ==============================================
# Version: 2.0
# Author: Your Name
# Description: A combined CLI/GUI tool to clean package directories (vendor/node_modules)
# Features:
#   - Both GUI (zenity) and CLI interfaces
#   - Progress reporting
#   - Undo functionality
#   - Logging system
#   - Configurable options
# ==============================================

# --------------------------
# CONFIGURATION
# --------------------------
LOG_FILE="${HOME}/.package_cleaner.log"
BACKUP_DIR="${HOME}/.package_cleaner_backups"
PROJECTS_ROOT="${HOME}/Projects"  # Default projects directory
MAX_BACKUPS=5                     # Max backups to keep
USE_GUI=false                     # Auto-detect GUI mode

# --------------------------
# INITIALIZATION
# --------------------------
# Create necessary directories
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# --------------------------
# LOGGING SYSTEM
# --------------------------
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# --------------------------
# COLOR OUTPUT (CLI)
# --------------------------
color_echo() {
    local color=$1
    local message=$2
    case $color in
        red)    echo -e "\033[31m$message\033[0m" ;;
        green)  echo -e "\033[32m$message\033[0m" ;;
        yellow) echo -e "\033[33m$message\033[0m" ;;
        blue)   echo -e "\033[34m$message\033[0m" ;;
        purple) echo -e "\033[35m$message\033[0m" ;;
        *)      echo -e "$message" ;;
    esac
}

# --------------------------
# BACKUP SYSTEM
# --------------------------
create_backup() {
    local folder=$1
    local backup_name=$(basename "$folder")_$(date +"%Y%m%d_%H%M%S")
    local backup_path="${BACKUP_DIR}/${backup_name}.tar.gz"
    
    log "Creating backup of $folder to $backup_path"
    tar -czf "$backup_path" -C "$(dirname "$folder")" "$(basename "$folder")" 2>> "$LOG_FILE"
    
    # Rotate backups
    local backups=("$BACKUP_DIR"/*.tar.gz)
    if [ ${#backups[@]} -gt $MAX_BACKUPS ]; then
        rm -f "${backups[0]}"
        log "Rotated backups, removed oldest backup"
    fi
    
    echo "$backup_path"
}

# --------------------------
# DIRECTORY OPERATIONS
# --------------------------
find_folders() {
    local root_dir=$1
    local folder_name=$2
    
    log "Searching for $folder_name in $root_dir"
    find "$root_dir" -type d -name "$folder_name" -not -path "*/.*" 2>/dev/null | sort
}

delete_folder() {
    local folder=$1
    local use_backup=$2
    
    if [ "$use_backup" = true ]; then
        local backup_path=$(create_backup "$folder")
        if [ -f "$backup_path" ]; then
            log "Backup created successfully: $backup_path"
            rm -rf "$folder"
            log "Deleted folder: $folder"
            echo "✅ Folder '$(basename "$folder")' deleted (backup: $(basename "$backup_path"))"
        else
            log "Backup failed for: $folder"
            echo "❌ Failed to create backup for '$folder' - skipping deletion"
        fi
    else
        rm -rf "$folder"
        log "Deleted folder (no backup): $folder"
        echo "✅ Folder '$(basename "$folder")' deleted"
    fi
}

# --------------------------
# GUI FUNCTIONS (Zenity)
# --------------------------
gui_main() {
    # Check if zenity is available
    if ! command -v zenity >/dev/null 2>&1; then
        color_echo "red" "Zenity not found. Falling back to CLI mode."
        USE_GUI=false
        cli_main
        return
    fi

    # Main GUI dialog
    while true; do
        local action=$(zenity --list --radiolist \
            --title="Package Cleaner" \
            --text="Select operation:" \
            --column="Select" --column="Action" \
            TRUE "Clean package directories" \
            FALSE "Restore from backup" \
            FALSE "View logs" \
            FALSE "Exit" \
            --width=500 --height=300)
        
        [ -z "$action" ] && action="Exit"
        
        case "$action" in
            "Clean package directories")
                gui_clean_directories
                ;;
            "Restore from backup")
                gui_restore_backup
                ;;
            "View logs")
                zenity --text-info --filename="$LOG_FILE" --width=800 --height=600
                ;;
            "Exit")
                break
                ;;
        esac
    done
}

gui_clean_directories() {
    # Select project root
    local project_dir=$(zenity --file-selection --directory \
        --title="Select Project Root Directory" \
        --filename="$PROJECTS_ROOT/")
    [ -z "$project_dir" ] && return
    
    # Select directory type
    local clean_type=$(zenity --list --radiolist \
        --title="Select Directory Type" \
        --text="Which directories do you want to clean?" \
        --column="Select" --column="Directory Type" \
        TRUE "vendor" \
        FALSE "node_modules" \
        FALSE "Both")
    [ -z "$clean_type" ] && return
    
    # Backup option
    zenity --question --title="Backup Option" \
        --text="Would you like to create backups before deletion?" \
        --ok-label="Yes" --cancel-label="No"
    local use_backup=$?
    
    # Find directories
    local folders=()
    case "$clean_type" in
        "vendor") folders=($(find_folders "$project_dir" "vendor")) ;;
        "node_modules") folders=($(find_folders "$project_dir" "node_modules")) ;;
        "Both") 
            folders=($(find_folders "$project_dir" "vendor"))
            folders+=($(find_folders "$project_dir" "node_modules"))
            ;;
    esac
    
    if [ ${#folders[@]} -eq 0 ]; then
        zenity --info --title="No Directories Found" \
            --text="No matching directories found in:\n$project_dir"
        return
    fi
    
    # Select directories to delete
    local folder_list=""
    for folder in "${folders[@]}"; do
        folder_list+="FALSE \"$folder\" "
    done
    
    local selected=$(eval zenity --list --checklist \
        --title="Select Directories to Delete" \
        --text="Found ${#folders[@]} directories. Select which to delete:" \
        --column="Delete" --column="Directory Path" \
        $folder_list \
        --width=800 --height=600)
    [ -z "$selected" ] && return
    
    # Confirm deletion
    zenity --question --title="Confirm Deletion" \
        --text="Are you sure you want to delete ${#selected[@]} directories?" \
        --ok-label="Delete" --cancel-label="Cancel"
    [ $? -ne 0 ] && return
    
    # Process deletion with progress bar
    (
        IFS="|" read -ra to_delete <<< "$selected"
        local count=${#to_delete[@]}
        local i=0
        
        for folder in "${to_delete[@]}"; do
            i=$((i+1))
            echo "$((i*100/count))"
            echo "# Deleting: $folder"
            
            result=$(delete_folder "$folder" $((use_backup == 0)))
            log "GUI: $result"
        done
    ) | zenity --progress --title="Deleting Directories" \
        --text="Starting deletion..." --percentage=0 \
        --auto-close --auto-kill
    
    zenity --info --title="Operation Complete" \
        --text="Selected directories have been processed."
}

gui_restore_backup() {
    # TODO: Implement backup restore functionality
    zenity --info --title="Coming Soon" \
        --text="Backup restore functionality will be implemented in a future version."
}

# --------------------------
# CLI FUNCTIONS
# --------------------------
cli_main() {
    while true; do
        clear
        color_echo "blue" "╔══════════════════════════════════════════╗"
        color_echo "blue" "║ 🧹 PACKAGE CLEANER - DIRECTORY MANAGER 🧹 ║"
        color_echo "blue" "╚══════════════════════════════════════════╝"
        color_echo "purple" "\nVersion: 2.0 | Last log: $(stat -c %y "$LOG_FILE" 2>/dev/null || echo "N/A")"
        
        echo ""
        echo "1) Clean vendor directories"
        echo "2) Clean node_modules directories"
        echo "3) Clean both vendor and node_modules"
        echo "4) Backup management"
        echo "5) View logs"
        echo "6) Switch to GUI mode"
        echo "7) Exit"
        echo ""
        
        read -rp "👉 Select option [1-7]: " choice
        
        case $choice in
            1) cli_clean_directories "vendor" ;;
            2) cli_clean_directories "node_modules" ;;
            3) 
                cli_clean_directories "vendor"
                cli_clean_directories "node_modules"
                ;;
            4) cli_backup_management ;;
            5) less "$LOG_FILE" ;;
            6) 
                USE_GUI=true
                gui_main
                ;;
            7) 
                color_echo "yellow" "🚪 Exiting program."
                exit 0
                ;;
            *)
                color_echo "red" "❗ Invalid option. Please try again."
                sleep 1
                ;;
        esac
        
        [ "$choice" != "5" ] && read -rp "Press Enter to continue..."
    done
}

cli_clean_directories() {
    local dir_type=$1
    local dir_name
    
    case "$dir_type" in
        "vendor") dir_name="vendor" ;;
        "node_modules") dir_name="node_modules" ;;
        *) return 1 ;;
    esac
    
    clear
    color_echo "blue" "╔══════════════════════════════════════╗"
    color_echo "blue" "║         CLEAN $dir_name DIRECTORIES       ║"
    color_echo "blue" "╚══════════════════════════════════════╝"
    echo ""
    
    read -rp "Enter root directory to search [$PROJECTS_ROOT]: " root_dir
    root_dir=${root_dir:-$PROJECTS_ROOT}
    
    if [ ! -d "$root_dir" ]; then
        color_echo "red" "❌ Directory does not exist: $root_dir"
        return
    fi
    
    color_echo "yellow" "🔍 Searching for $dir_name directories in $root_dir..."
    
    local folders=($(find_folders "$root_dir" "$dir_name"))
    
    if [ ${#folders[@]} -eq 0 ]; then
        color_echo "yellow" "✅ No $dir_name directories found in $root_dir."
        return
    fi
    
    color_echo "green" "\n📦 Found ${#folders[@]} $dir_name directories:\n"
    
    for i in "${!folders[@]}"; do
        printf "%3d) %s\n" $((i+1)) "${folders[$i]}"
    done
    
    while true; do
        color_echo "blue" "\n❓ Select action:"
        echo "   [1-${#folders[@]}] Select directory to delete"
        echo "   a) Delete ALL directories"
        echo "   b) Back to main menu"
        echo "   x) Exit program"
        
        read -rp "👉 Your choice: " input
        
        case "$input" in
            [0-9]*)
                if (( input >= 1 && input <= ${#folders[@]} )); then
                    local folder="${folders[$((input-1))]}"
                    cli_confirm_delete "$folder"
                    unset folders[$((input-1))]
                    folders=("${folders[@]}")
                    
                    if [ ${#folders[@]} -eq 0 ]; then
                        color_echo "green" "\n🎉 All directories processed."
                        break
                    fi
                    
                    # Show remaining directories
                    color_echo "blue" "\n📋 Remaining directories:"
                    for i in "${!folders[@]}"; do
                        printf "%3d) %s\n" $((i+1)) "${folders[$i]}"
                    done
                else
                    color_echo "red" "❗ Invalid selection."
                fi
                ;;
            a|A)
                color_echo "red" "\n⚠ WARNING: You are about to delete ALL ${#folders[@]} $dir_name directories!"
                read -rp "Are you sure? (y/n): " confirm
                if [[ "$confirm" =~ [yY] ]]; then
                    read -rp "Create backups first? (y/n): " backup_confirm
                    local backup=$([[ "$backup_confirm" =~ [yY] ]] && echo true || echo false)
                    
                    for folder in "${folders[@]}"; do
                        result=$(delete_folder "$folder" "$backup")
                        color_echo "green" "$result"
                    done
                else
                    color_echo "yellow" "❎ Operation cancelled."
                fi
                break
                ;;
            b|B)
                return
                ;;
            x|X)
                color_echo "yellow" "🚪 Exiting program."
                exit 0
                ;;
            *)
                color_echo "red" "❗ Invalid input."
                ;;
        esac
    done
}

cli_confirm_delete() {
    local folder=$1
    
    color_echo "yellow" "\n⚠ You selected: $folder"
    echo "Size: $(du -sh "$folder" | cut -f1)"
    
    read -rp "Delete this directory? (y/n): " confirm
    if [[ "$confirm" =~ [yY] ]]; then
        read -rp "Create backup first? (y/n): " backup_confirm
        local backup=$([[ "$backup_confirm" =~ [yY] ]] && echo true || echo false)
        
        result=$(delete_folder "$folder" "$backup")
        color_echo "green" "$result"
    else
        color_echo "yellow" "❎ Operation cancelled."
    fi
}

cli_backup_management() {
    # TODO: Implement CLI backup management
    color_echo "yellow" "\n🚧 Backup management feature is under construction."
    color_echo "yellow" "Check future versions for this functionality."
}

# --------------------------
# RUNTIME DETECTION
# --------------------------
# Detect if we're in a GUI environment
if [ -n "$DISPLAY" ] && command -v zenity >/dev/null 2>&1; then
    USE_GUI=true
fi

# Handle command line arguments
for arg in "$@"; do
    case "$arg" in
        --gui) USE_GUI=true ;;
        --cli) USE_GUI=false ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --gui   Force GUI mode"
            echo "  --cli   Force CLI mode"
            echo "  --help  Show this help"
            exit 0
            ;;
    esac
done

# --------------------------
# MAIN EXECUTION
# --------------------------
log "=== Starting Package Cleaner ==="
log "Mode: $([ "$USE_GUI" = true ] && echo "GUI" || echo "CLI")"
log "Project root: $PROJECTS_ROOT"

if [ "$USE_GUI" = true ]; then
    gui_main
else
    cli_main
fi

log "=== Program ended ==="

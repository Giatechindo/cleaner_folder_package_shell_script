#!/usr/bin/env bash

# Initialize application
init_cleanpack() {
    # Load configuration
    load_config
    
    # Load utilities
    source "$LIB_DIR/utils.sh"
    
    # Load modules
    source "$LIB_DIR/vendor_cleaner.sh"
    source "$LIB_DIR/node_modules_cleaner.sh"
    
    # Set default paths
    DEFAULT_SEARCH_PATH="$HOME/Projects"
    
    # Process command line arguments
    process_args "$@"
}

# Show main menu
show_main_menu() {
    clear
    color_echo "blue" "╔══════════════════════════════════════════╗"
    color_echo "blue" "║ 🧹 CLEANPACK - Package Directory Cleaner 🧹 ║"
    color_echo "blue" "╚══════════════════════════════════════════╝"
    echo ""
    echo "1) Clean vendor directories"
    echo "2) Clean node_modules directories"
    echo "3) Clean BOTH vendor and node_modules"
    echo "4) Settings"
    echo "5) Exit"
    echo ""
}

# Process command line arguments
process_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--path)
                SEARCH_PATH="$2"
                shift 2
                ;;
            -a|--all)
                CLEAN_ALL=true
                shift
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                show_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Exit handler
exit_cleanpack() {
    color_echo "green" "✨ Terima kasih telah menggunakan CleanPack!"
    exit 0
}
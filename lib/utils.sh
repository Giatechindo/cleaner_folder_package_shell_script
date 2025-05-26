#!/usr/bin/env bash

# Colors for output
color_echo() {
    local color=$1
    shift
    local message=$*
    
    case $color in
        red)    echo -e "\033[31m$message\033[0m" ;;
        green)  echo -e "\033[32m$message\033[0m" ;;
        yellow) echo -e "\033[33m$message\033[0m" ;;
        blue)   echo -e "\033[34m$message\033[0m" ;;
        *)      echo -e "$message" ;;
    esac
}

# Show error message
show_error() {
    color_echo "red" "❌ Error: $1"
}

# Show success message
show_success() {
    color_echo "green" "✅ $1"
}

# Show warning message
show_warning() {
    color_echo "yellow" "⚠️  $1"
}

# Show info message
show_info() {
    color_echo "blue" "ℹ️  $1"
}

# Pause execution
pause() {
    read -rp "Tekan Enter untuk melanjutkan..."
}

# Confirm action
confirm() {
    local message=${1:-"Apakah Anda yakin?"}
    if [[ $AUTO_CONFIRM == true ]]; then
        return 0
    fi
    read -rp "$message (y/n): " response
    [[ $response =~ ^[Yy]$ ]]
}

# Cross-platform directory size calculation
get_dir_size() {
    local dir=$1
    if [[ $OSTYPE == "darwin"* ]]; then
        du -sh "$dir" | awk '{print $1}'
    else
        du -sh --block-size=1M "$dir" | awk '{print $1 "M"}'
    fi
}
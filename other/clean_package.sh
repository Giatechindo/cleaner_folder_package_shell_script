#!/bin/bash

# Function to display colored messages
color_echo() {
    local color=$1
    local message=$2
    case $color in
        red)    echo -e "\033[31m$message\033[0m" ;;
        green)  echo -e "\033[32m$message\033[0m" ;;
        yellow) echo -e "\033[33m$message\033[0m" ;;
        blue)   echo -e "\033[34m$message\033[0m" ;;
        *)      echo -e "$message" ;;
    esac
}

# Function to display menu
show_menu() {
    clear
    color_echo "blue" "╔══════════════════════════════════════╗"
    color_echo "blue" "║ 🧹 CLEAN PACKAGE DIRECTORY MANAGER 🧹 ║"
    color_echo "blue" "╚══════════════════════════════════════╝"
    echo ""
    echo "1) Clean vendor directories"
    echo "2) Clean node_modules directories"
    echo "3) Clean BOTH vendor and node_modules"
    echo "4) Exit"
    echo ""
}

# Function to process directory cleaning
clean_directories() {
    local dir_type=$1
    local dir_name
    local find_command
    
    if [ "$dir_type" == "vendor" ]; then
        dir_name="vendor"
    elif [ "$dir_type" == "node_modules" ]; then
        dir_name="node_modules"
    else
        return 1
    fi
    
    cd ~/Projects || { color_echo "red" "Folder ~/Projects tidak ditemukan!"; exit 1; }

    mapfile -t folders < <(find . -type d -name "$dir_name" | sort)
    
    if [ ${#folders[@]} -eq 0 ]; then
        color_echo "yellow" "✅ Tidak ditemukan folder '$dir_name' di dalam Projects."
        return 0
    fi

    color_echo "blue" "\n📦 Ditemukan ${#folders[@]} folder '$dir_name':\n"

    for i in "${!folders[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${folders[$i]}"
    done

    while true; do
        color_echo "blue" "\n❓ Pilih nomor folder yang ingin DIHAPUS [1-${#folders[@]}], ketik:"
        echo "   - 'all' untuk menghapus semua"
        echo "   - 'skip' untuk lewati semua"
        echo "   - 'back' untuk kembali ke menu utama"
        echo "   - 'exit' untuk keluar program"
        read -rp "👉 Pilihan Anda: " input

        if [[ "$input" == "exit" ]]; then
            color_echo "yellow" "🚪 Keluar dari program."
            exit 0
        elif [[ "$input" == "back" ]]; then
            return
        elif [[ "$input" == "skip" ]]; then
            color_echo "yellow" "⏭ Melewati semua penghapusan folder $dir_name."
            break
        elif [[ "$input" == "all" ]]; then
            color_echo "yellow" "⚠ Anda memilih untuk menghapus SEMUA folder $dir_name."
            read -rp "Apakah Anda yakin? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                for folder in "${folders[@]}"; do
                    rm -rf "$folder"
                    color_echo "green" "✅ Folder '$folder' telah dihapus."
                done
                break
            else
                color_echo "yellow" "❎ Dibatalkan."
            fi
        elif [[ "$input" =~ ^[0-9]+$ ]] && (( input >= 1 && input <= ${#folders[@]} )); then
            folder_to_delete="${folders[$((input-1))]}"
            color_echo "yellow" "⚠ Anda memilih untuk menghapus: $folder_to_delete"
            read -rp "Apakah Anda yakin? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -rf "$folder_to_delete"
                color_echo "green" "✅ Folder '$folder_to_delete' telah dihapus."
                unset folders[$((input-1))]
                folders=("${folders[@]}") # Re-index array
            else
                color_echo "yellow" "❎ Dibatalkan."
            fi
        else
            color_echo "red" "❗ Masukkan tidak valid."
        fi

        if [ ${#folders[@]} -eq 0 ]; then
            color_echo "green" "\n🎉 Semua folder $dir_name telah diproses."
            break
        fi

        color_echo "blue" "\n📋 Daftar folder tersisa:"
        for i in "${!folders[@]}"; do
            printf "%2d) %s\n" $((i+1)) "${folders[$i]}"
        done
    done
}

# Main program loop
while true; do
    show_menu
    read -rp "👉 Pilih menu [1-4]: " choice
    
    case $choice in
        1)
            clean_directories "vendor"
            ;;
        2)
            clean_directories "node_modules"
            ;;
        3)
            clean_directories "vendor"
            clean_directories "node_modules"
            ;;
        4)
            color_echo "yellow" "🚪 Keluar dari program."
            exit 0
            ;;
        *)
            color_echo "red" "❗ Pilihan tidak valid. Silakan coba lagi."
            ;;
    esac
    
    read -rp "Tekan Enter untuk melanjutkan..."
done

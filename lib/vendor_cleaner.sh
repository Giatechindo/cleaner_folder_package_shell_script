#!/usr/bin/env bash

run_vendor_cleaner() {
    local dir_type="vendor"
    local dir_name="vendor"
    
    show_info "Memulai pembersihan folder $dir_name..."
    
    # Use configured path or default
    local search_path=${SEARCH_PATH:-$DEFAULT_SEARCH_PATH}
    
    cd "$search_path" || {
        show_error "Folder $search_path tidak ditemukan!"
        return 1
    }
    
    # Find directories
    show_info "Mencari folder $dir_name di $search_path..."
    mapfile -t folders < <(find . -type d -name "$dir_name" | sort)
    
    if [ ${#folders[@]} -eq 0 ]; then
        show_warning "Tidak ditemukan folder '$dir_name' di $search_path."
        return 0
    fi

    show_success "Ditemukan ${#folders[@]} folder '$dir_name':\n"
    
    # Display list with sizes
    for i in "${!folders[@]}"; do
        local size=$(get_dir_size "${folders[$i]}")
        printf "%2d) %-60s (%s)\n" $((i+1)) "${folders[$i]}" "$size"
    done

    process_cleaning "$dir_type" "${folders[@]}"
}
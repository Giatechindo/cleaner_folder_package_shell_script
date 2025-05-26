#!/bin/bash

# Pastikan Zenity tersedia
command -v zenity >/dev/null 2>&1 || { echo "Zenity tidak ditemukan. Install dengan: sudo apt install zenity"; exit 1; }

# Pilih folder root project
project_dir=$(zenity --file-selection --directory --title="Pilih folder project root" --filename="$HOME/Projects/")
[ $? -ne 0 ] && exit 0  # Batal

# Pilih jenis pembersihan
clean_type=$(zenity --list --radiolist \
  --title="Pilih Direktori yang Akan Dibersihkan" \
  --column="Pilih" --column="Tipe" TRUE "vendor" FALSE "node_modules" FALSE "Keduanya")

[ -z "$clean_type" ] && exit 0  # Batal

# Fungsi untuk mencari folder
function find_folders() {
    find "$project_dir" -type d -name "$1"
}

# Simpan daftar folder yang ditemukan
vendor_folders=()
node_modules_folders=()

[ "$clean_type" == "vendor" ] || [ "$clean_type" == "Keduanya" ] && vendor_folders=($(find_folders "vendor"))
[ "$clean_type" == "node_modules" ] || [ "$clean_type" == "Keduanya" ] && node_modules_folders=($(find_folders "node_modules"))

# Gabungkan semua folder
all_folders=("${vendor_folders[@]}" "${node_modules_folders[@]}")

if [ ${#all_folders[@]} -eq 0 ]; then
    zenity --info --title="Bersih Folder" --text="Tidak ditemukan folder $clean_type."
    exit 0
fi

# Tampilkan pilihan multi-select
selected_folders=$(zenity --list --checklist \
  --title="Pilih folder yang ingin dihapus" \
  --width=700 --height=400 \
  --column="Hapus" --column="Path Folder" \
  $(for folder in "${all_folders[@]}"; do echo FALSE "$folder"; done))

[ -z "$selected_folders" ] && exit 0  # Batal

# Konfirmasi
zenity --question --title="Konfirmasi Hapus" --text="Anda yakin ingin menghapus folder yang dipilih?"
[ $? -ne 0 ] && exit 0  # Batal

# Eksekusi penghapusan
IFS="|" read -ra to_delete <<< "$selected_folders"
for folder in "${to_delete[@]}"; do
    rm -rf "$folder"
done

zenity --info --title="Selesai" --text="✅ Folder yang dipilih telah dihapus."

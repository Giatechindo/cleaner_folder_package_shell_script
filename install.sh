#!/usr/bin/env bash

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Installing CleanPack system-wide..."
    INSTALL_DIR="/usr/local/bin"
    CONFIG_DIR="/etc/cleanpack"
else
    echo "Installing CleanPack for current user..."
    INSTALL_DIR="$HOME/.local/bin"
    CONFIG_DIR="$HOME/.config/cleanpack"
fi

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/lib"

# Copy files
cp bin/cleanpack "$INSTALL_DIR/"
cp -r lib/* "$CONFIG_DIR/lib/"
cp config/settings.conf "$CONFIG_DIR/"

# Set permissions
chmod +x "$INSTALL_DIR/cleanpack"

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to your PATH..."
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
    source "$HOME/.bashrc"
fi

echo "✅ CleanPack berhasil diinstall!"
echo "Jalankan dengan perintah: cleanpack"
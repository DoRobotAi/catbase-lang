#!/bin/bash

# CatBase Dependencies Installer
# This script downloads and installs dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/conf/config.conf"

# Default values
ZIG_INSTALL_PATH=""
DOWNLOAD_URL=""

# Read config file if exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading configuration from $CONFIG_FILE..."
    
    # Parse deps path from config - skip comment lines (starting with // or #)
    ZIG_INSTALL_PATH=$(grep -v "^//" "$CONFIG_FILE" | grep -v "^#" | grep "path" | head -1 | cut -d'=' -f2 | tr -d ' ')
    
    # Parse download URL from config (may have no spaces around = or spaces)
    DOWNLOAD_URL=$(grep -v "^//" "$CONFIG_FILE" | grep -v "^#" | grep "download_url" | head -1 | cut -d'=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# Validate installation path
if [ -z "$ZIG_INSTALL_PATH" ]; then
    echo "Error: Installation path not specified in config file"
    exit 1
fi

echo "Installation path: $ZIG_INSTALL_PATH"

# Check if dependencies are already installed
if [ -f "$ZIG_INSTALL_PATH/zig" ]; then
    echo "Dependencies are already installed at $ZIG_INSTALL_PATH"
    echo "Version: $($ZIG_INSTALL_PATH/zig version)"
    echo "No installation needed."
    exit 0
fi

echo "Dependencies not found at $ZIG_INSTALL_PATH, will install..."

# Validate download URL is provided
if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: download_url not specified in config file"
    exit 1
fi

TAR_FILE="/tmp/deps-$(basename "$DOWNLOAD_URL")"

# Use custom download URL from config
echo "Using custom download URL from config: $DOWNLOAD_URL"
FULL_DOWNLOAD_URL="$DOWNLOAD_URL"

echo "Downloading dependencies..."
echo "URL: $FULL_DOWNLOAD_URL"

# Download dependencies
if command -v curl &> /dev/null; then
    curl -L -f -o "$TAR_FILE" "$FULL_DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -O "$TAR_FILE" "$FULL_DOWNLOAD_URL"
else
    echo "Error: Neither curl nor wget is installed"
    exit 1
fi

echo "Download complete."

# Create install directory
echo "Installing dependencies to $ZIG_INSTALL_PATH..."

# Check if we need sudo (if installing to system directories)
if [[ "$ZIG_INSTALL_PATH" == /usr/* ]] && [ ! -w "$(dirname "$ZIG_INSTALL_PATH")" ]; then
    sudo mkdir -p "$ZIG_INSTALL_PATH"
    sudo tar --no-same-owner -xf "$TAR_FILE" -C "$ZIG_INSTALL_PATH" --strip-components=1
else
    mkdir -p "$ZIG_INSTALL_PATH"
    tar --no-same-owner -xf "$TAR_FILE" -C "$ZIG_INSTALL_PATH" --strip-components=1
fi

# Clean up
rm -f "$TAR_FILE"

echo "Dependencies installed successfully!"
echo ""

# Verify installation
if [ -f "$ZIG_INSTALL_PATH/zig" ]; then
    echo "Verification:"
    "$ZIG_INSTALL_PATH/zig" version
else
    echo "Warning: zig executable not found at $ZIG_INSTALL_PATH/zig"
fi

echo ""
echo "Installation complete!"
echo "You can now use CatBase compiler."

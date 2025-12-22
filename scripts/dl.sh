#!/bin/bash
# scripts/dl.sh

# Default to "openwrt" if no argument provided, or use the first argument as the OpenWrt root path
OPENWRT_PATH=${1:-"openwrt"}
DL_DIR="$OPENWRT_PATH/dl"

echo "Running dl.sh..."
echo "OpenWrt Path: $OPENWRT_PATH"
echo "Download Dir: $DL_DIR"

mkdir -p "$DL_DIR"

# Function to download
download_file() {
    local file_name="$1"
    local url1="$2"
    local url2="$3"

    echo "Checking $file_name..."
    if [ -f "$DL_DIR/$file_name" ]; then
        echo "  $file_name already exists."
    else
        echo "  Downloading $file_name..."
        wget -q -O "$DL_DIR/$file_name" "$url1" || \
        wget -q -O "$DL_DIR/$file_name" "$url2"
        
        if [ $? -eq 0 ]; then
             echo "  Success."
        else
             echo "  Failed to download $file_name"
        fi
    fi
}

# erofs-utils 1.8.10
download_file "erofs-utils-1.8.10.tar.gz" \
    "https://github.com/erofs/erofs-utils/archive/refs/tags/v1.8.10.tar.gz" \
    "http://deb.debian.org/debian/pool/main/e/erofs-utils/erofs-utils_1.8.10.orig.tar.gz"

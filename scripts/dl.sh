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

# ustream-ssl 2025-10-03-5a81c108
# Using manual git clone and repack since upstream 503s
USTREAM_FILE="ustream-ssl-2025-10-03-5a81c108.tar.xz"
if [ ! -f "$DL_DIR/$USTREAM_FILE" ]; then
    echo "Checking $USTREAM_FILE..."
    echo "  Manual repack from GitHub mirror..."
    
    # Create a temp dir inside DL_DIR to avoid permission or path issues
    TMP_WORK_DIR="$DL_DIR/tmp_repack"
    mkdir -p "$TMP_WORK_DIR"
    
    # Clone to a specifically named directory as expected by OpenWrt build
    REPO_DIR_NAME="ustream-ssl-2025-10-03-5a81c108"
    
    git clone https://github.com/openwrt/ustream-ssl.git "$TMP_WORK_DIR/$REPO_DIR_NAME"
    if [ $? -eq 0 ]; then
        cd "$TMP_WORK_DIR/$REPO_DIR_NAME"
        git checkout 5a81c108d20e24724ed847cc4be033f2a74e6635
        rm -rf .git
        cd ..
        
        # Tar and compress
        tar --numeric-owner --owner=0 --group=0 --sort=name -cJf "$DL_DIR/$USTREAM_FILE" "$REPO_DIR_NAME"
        
        if [ $? -eq 0 ]; then
             echo "  Success: $USTREAM_FILE created."
        else
             echo "  Failed to pack $USTREAM_FILE"
        fi
        
        # Cleanup
        cd "$DL_DIR" # Move out before deleting
        rm -rf "$TMP_WORK_DIR"
    else
        echo "  Failed to clone ustream-ssl from GitHub"
        rm -rf "$TMP_WORK_DIR"
    fi
else
    echo "  $USTREAM_FILE already exists."
fi

# firmware-utils 2024-10-20-4b763892
FIRMWARE_UTILS_FILE="firmware-utils-2024-10-20-4b763892.tar.xz"
if [ ! -f "$DL_DIR/$FIRMWARE_UTILS_FILE" ]; then
    echo "Checking $FIRMWARE_UTILS_FILE..."
    echo "  Manual repack from GitHub mirror..."

    TMP_WORK_DIR="$DL_DIR/tmp_repack_fw"
    mkdir -p "$TMP_WORK_DIR"
    
    # Clone to a specifically named directory
    REPO_DIR_NAME="firmware-utils-2024-10-20-4b763892"
    
    # Use the official GitHub mirror
    git clone https://github.com/openwrt/firmware-utils.git "$TMP_WORK_DIR/$REPO_DIR_NAME"
    if [ $? -eq 0 ]; then
        cd "$TMP_WORK_DIR/$REPO_DIR_NAME"
        # The full hash from the user's error log
        git checkout 4b7638925d3eac03e614e40bc30cb49f5877c46d
        rm -rf .git
        cd ..
        
        # Tar and compress
        tar --numeric-owner --owner=0 --group=0 --sort=name -cJf "$DL_DIR/$FIRMWARE_UTILS_FILE" "$REPO_DIR_NAME"
        
        if [ $? -eq 0 ]; then
             echo "  Success: $FIRMWARE_UTILS_FILE created."
        else
             echo "  Failed to pack $FIRMWARE_UTILS_FILE"
        fi
        
        # Cleanup
        cd "$DL_DIR"
        rm -rf "$TMP_WORK_DIR"
    else
        echo "  Failed to clone firmware-utils from GitHub"
        rm -rf "$TMP_WORK_DIR"
    fi
else
    echo "  $FIRMWARE_UTILS_FILE already exists."
fi

# ubus 2024-10-20-252a9b0c
UBUS_FILE="ubus-2024-10-20-252a9b0c.tar.xz"
if [ ! -f "$DL_DIR/$UBUS_FILE" ]; then
    echo "Checking $UBUS_FILE..."
    echo "  Manual repack from GitHub mirror..."

    TMP_WORK_DIR="$DL_DIR/tmp_repack_ubus"
    mkdir -p "$TMP_WORK_DIR"
    
    # Clone to a specifically named directory
    REPO_DIR_NAME="ubus-2024-10-20-252a9b0c"
    
    # Use the official GitHub mirror
    git clone https://github.com/openwrt/ubus.git "$TMP_WORK_DIR/$REPO_DIR_NAME"
    if [ $? -eq 0 ]; then
        cd "$TMP_WORK_DIR/$REPO_DIR_NAME"
        # The full hash from the user's error log
        git checkout 252a9b0c1774790fb9c25735d5a09c27dba895db
        rm -rf .git
        cd ..
        
        # Tar and compress
        tar --numeric-owner --owner=0 --group=0 --sort=name -cJf "$DL_DIR/$UBUS_FILE" "$REPO_DIR_NAME"
        
        if [ $? -eq 0 ]; then
             echo "  Success: $UBUS_FILE created."
        else
             echo "  Failed to pack $UBUS_FILE"
        fi
        
        # Cleanup
        cd "$DL_DIR"
        rm -rf "$TMP_WORK_DIR"
    else
        echo "  Failed to clone ubus from GitHub"
        rm -rf "$TMP_WORK_DIR"
    fi
else
    echo "  $UBUS_FILE already exists."
fi




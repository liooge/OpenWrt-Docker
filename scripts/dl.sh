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

# Generic function to download and repack OpenWrt git snapshots
download_openwrt_package() {
    local name="$1"
    local version="$2"
    local hash="$3"
    local full_hash="$4" # Optional, defaults to short hash if not provided (though full hash is safer)
    
    local filename="${name}-${version}-${hash}.tar.xz"
    
    if [ -f "$DL_DIR/$filename" ]; then
        echo "  $filename already exists."
        return 0
    fi
    
    echo "Checking $filename..."
    echo "  Generic repack from GitHub mirror..."
    
    local tmp_dir="$DL_DIR/tmp_repack_${name}"
    mkdir -p "$tmp_dir"
    
    local repo_dir="${name}-${version}-${hash}"
    
    # Try cloning from GitHub
    git clone "https://github.com/openwrt/${name}.git" "$tmp_dir/$repo_dir"
    
    if [ $? -eq 0 ]; then
        cd "$tmp_dir/$repo_dir"
        
        # Determine checkout target (full hash or short hash)
        local checkout_target="${full_hash:-$hash}"
        git checkout "$checkout_target"
        
        if [ $? -ne 0 ]; then
             echo "  Failed to checkout $checkout_target"
             cd "$DL_DIR"
             rm -rf "$tmp_dir"
             return 1
        fi
        
        rm -rf .git
        cd .. # Go back to tmp_dir
        
        # Tar and compress
        # Emulate OpenWrt's packing: numeric owner, sorted name, xz compressed
        tar --numeric-owner --owner=0 --group=0 --sort=name -cJf "$DL_DIR/$filename" "$repo_dir"
        
        if [ $? -eq 0 ]; then
             echo "  Success: $filename created."
        else
             echo "  Failed to pack $filename"
        fi
        
        cd "$DL_DIR"
        rm -rf "$tmp_dir"
    else
        echo "  Failed to clone $name from GitHub"
        rm -rf "$tmp_dir"
        return 1
    fi
}

echo "Starting Manual Downloads..."

# 1. erofs-utils (Static URL, not git snapshot)
download_file "erofs-utils-1.8.10.tar.gz" \
    "https://github.com/erofs/erofs-utils/archive/refs/tags/v1.8.10.tar.gz" \
    "http://deb.debian.org/debian/pool/main/e/erofs-utils/erofs-utils_1.8.10.orig.tar.gz"

# 2. ustream-ssl
download_openwrt_package "ustream-ssl" "2025-10-03" "5a81c108" "5a81c108d20e24724ed847cc4be033f2a74e6635"

# 3. firmware-utils
download_openwrt_package "firmware-utils" "2024-10-20" "4b763892" "4b7638925d3eac03e614e40bc30cb49f5877c46d"

# 4. ubus
download_openwrt_package "ubus" "2024-10-20" "252a9b0c" "252a9b0c1774790fb9c25735d5a09c27dba895db"



# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}
# Global replace of git.openwrt.org to github.com/openwrt matches
# 1. Replace the domain definition in include/download.mk, rules.mk and other includes
find . -name "download.mk" -o -name "rules.mk" -o -name "*.mk" | xargs -r sed -i 's/git.openwrt.org/github.com\/openwrt/g'

# 2. Fix the path mapping in Makefiles
#    Remove /project/ and /feed/ because GitHub repos are flattened (github.com/openwrt/repo)
#    Matches: $(PROJECT_GIT)/project/repo.git -> $(PROJECT_GIT)/repo.git
find . -name "Makefile" | xargs -r sed -i 's/$(PROJECT_GIT)\/project\//$(PROJECT_GIT)\//g'
find . -name "Makefile" | xargs -r sed -i 's/$(OPENWRT_GIT)\/project\//$(OPENWRT_GIT)\//g'
find . -name "Makefile" | xargs -r sed -i 's/$(LEDE_GIT)\/project\//$(LEDE_GIT)\//g'
find . -name "Makefile" | xargs -r sed -i 's/$(PROJECT_GIT)\/feed\//$(PROJECT_GIT)\//g'
find . -name "Makefile" | xargs -r sed -i 's/$(OPENWRT_GIT)\/feed\//$(OPENWRT_GIT)\//g'
find . -name "Makefile" | xargs -r sed -i 's/$(LEDE_GIT)\/feed\//$(LEDE_GIT)\//g'

# 3. Fallback for literal URLs (older packages or hardcoded strings)
find . -name "*.mk" -o -name "Makefile" -o -name "feeds.conf.default" | xargs -r sed -i 's/git:\/\/git.openwrt.org\/project\//https:\/\/github.com\/openwrt\//g'
find . -name "*.mk" -o -name "Makefile" -o -name "feeds.conf.default" | xargs -r sed -i 's/https:\/\/git.openwrt.org\/project\//https:\/\/github.com\/openwrt\//g'
find . -name "*.mk" -o -name "Makefile" -o -name "feeds.conf.default" | xargs -r sed -i 's/git:\/\/git.openwrt.org\/feed\//https:\/\/github.com\/openwrt\//g'
find . -name "*.mk" -o -name "Makefile" -o -name "feeds.conf.default" | xargs -r sed -i 's/https:\/\/git.openwrt.org\/feed\//https:\/\/github.com\/openwrt\//g'



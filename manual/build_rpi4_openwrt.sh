#!/bin/bash
set -e

# Environment Variables
export REPO_URL="https://github.com/coolsnowwolf/lede"
export REPO_BRANCH="master"
export CONFIG_FILE="configs/rpi4.config"
export EXTRA_CONFIG="configs/extra.config"
export DIY_SCRIPT="diy-script.sh"
export CLASH_KERNEL="arm64"
export TZ="Asia/Shanghai"

# Workspace Setup
export GITHUB_WORKSPACE="$PWD"
export OPENWRT_PATH="$PWD/openwrt"

echo "Starting Manual Build for RaspberryPi4 OpenWrt"
echo "Workdir: $GITHUB_WORKSPACE"

# Clone Source Code
if [ ! -d "openwrt" ]; then
    git clone $REPO_URL -b $REPO_BRANCH openwrt
else
    echo "openwrt directory already exists, skipping clone."
fi

cd openwrt

# Install Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Load Custom Configuration
[ -e ../files ] && cp -r ../files ./files
[ -e ../$CONFIG_FILE ] && cp ../$CONFIG_FILE .config
# Append Extra Config
[ -e ../$EXTRA_CONFIG ] && cat ../$EXTRA_CONFIG >> .config

chmod +x ../scripts/*.sh
chmod +x ../$DIY_SCRIPT

# Run DIY Scripts
../$DIY_SCRIPT
../scripts/preset-clash-core.sh $CLASH_KERNEL
../scripts/preset-terminal-tools.sh
../scripts/preset-adguard-core.sh $CLASH_KERNEL

# Download Packages
make defconfig
make download -j8
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

# Compile
echo "$(nproc) thread compile"
if make -j$(nproc); then
    echo "Parallel compile succeeded"
elif make -j1; then
    echo "Single thread compile succeeded"
elif make -j1 V=s; then
    echo "Verbose compile succeeded"
else
    echo "All compile attempts failed"
    exit 1
fi

echo "Build complete. Artifacts are in $OPENWRT_PATH/bin"

#!/bin/bash
set -e

# Environment Variables
export REPO_URL="https://github.com/coolsnowwolf/lede"
export REPO_BRANCH="master"
export CONFIG_FILE="configs/armv8-docker.config"
export DIY_SCRIPT="diy-script.sh"
export CLASH_KERNEL="arm64"
export DOCKER_BUILD="buildImageX.sh"
export DOCKER_IMAGE="summary/openwrt-aarch64"
export TZ="Asia/Shanghai"

# Workspace Setup
export GITHUB_WORKSPACE="$PWD"
export OPENWRT_PATH="$PWD/openwrt"

echo "Starting Manual Build for ARMv8 Docker OpenWrt"
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

# Special handling for this workflow
sed -i '/\/clash_/d; /.dat/d' ../scripts/preset-clash-core.sh

chmod +x ../scripts/*.sh
chmod +x ../$DIY_SCRIPT

# Run DIY Scripts
../$DIY_SCRIPT
../scripts/preset-clash-core.sh $CLASH_KERNEL

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

# Generate Firmware Actions
echo "Generating Docker Image..."
cd bin/targets/*/*
cp *rootfs.tar.gz $GITHUB_WORKSPACE/docker
cd $GITHUB_WORKSPACE/docker
chmod +x $DOCKER_BUILD 
./$DOCKER_BUILD

echo "Docker image built locally. To push to registry, ensure you are logged in and run 'docker push ...'"

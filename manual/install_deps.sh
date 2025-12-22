#!/bin/bash
set -e

echo "Installing OpenWrt Build Dependencies for Ubuntu 22.04 LTS..."

sudo apt-get update
sudo apt-get -y install \
    build-essential asciidoc binutils bzip2 gawk gettext git \
    libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev \
    lib32gcc-s1 libc6-dev-i386 subversion flex uglifyjs git-core \
    gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev \
    xmlto qemu-utils upx-ucl libelf-dev autoconf automake libtool \
    autopoint device-tree-compiler g++-multilib antlr3 gperf wget \
    curl swig rsync

echo "Dependencies installed successfully."

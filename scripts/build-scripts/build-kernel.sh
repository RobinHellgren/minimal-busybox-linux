#!/bin/bash

set -e

KERNEL_VERSION=${1:-6.6.58}
BUILD_DIR="/build/build/kernel"
CONFIG_DIR="/build/config/kernel"
OUTPUT_DIR="/build/output"

# Ensure output directory exists and has correct permissions
mkdir -p ${OUTPUT_DIR}

echo "Building Linux kernel ${KERNEL_VERSION}..."

# Create build directory
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Download kernel source if not present
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    echo "Downloading Linux kernel ${KERNEL_VERSION}..."
    wget -q https://cdn.kernel.org/pub/linux/kernel/v$(echo ${KERNEL_VERSION} | cut -d. -f1).x/linux-${KERNEL_VERSION}.tar.xz
    tar -xf linux-${KERNEL_VERSION}.tar.xz
    rm linux-${KERNEL_VERSION}.tar.xz
fi

cd linux-${KERNEL_VERSION}

# Create minimal kernel config
echo "Creating minimal kernel config..."
make defconfig

# Configure for minimal system - disable unnecessary features
scripts/config --disable CONFIG_SOUND
scripts/config --disable CONFIG_WIRELESS
scripts/config --disable CONFIG_WLAN
scripts/config --disable CONFIG_BT
scripts/config --disable CONFIG_DRM
scripts/config --disable CONFIG_FB
scripts/config --disable CONFIG_USB_HID
scripts/config --disable CONFIG_HID
scripts/config --disable CONFIG_STAGING
scripts/config --disable CONFIG_DEBUG_KERNEL
scripts/config --disable CONFIG_DEBUG_INFO

# Enable essential features
scripts/config --enable CONFIG_EMBEDDED
scripts/config --enable CONFIG_EXPERT
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_PROC_FS
scripts/config --enable CONFIG_SYSFS
scripts/config --enable CONFIG_TMPFS

# Container support for K8s
scripts/config --enable CONFIG_NAMESPACES
scripts/config --enable CONFIG_UTS_NS
scripts/config --enable CONFIG_IPC_NS
scripts/config --enable CONFIG_USER_NS
scripts/config --enable CONFIG_PID_NS
scripts/config --enable CONFIG_NET_NS
scripts/config --enable CONFIG_CGROUPS
scripts/config --enable CONFIG_CGROUP_FREEZER
scripts/config --enable CONFIG_CGROUP_DEVICE
scripts/config --enable CONFIG_CGROUP_CPUACCT
scripts/config --enable CONFIG_MEMCG

# Use olddefconfig to resolve any conflicts automatically
make olddefconfig

# Build kernel
echo "Compiling kernel..."
make -j$(nproc) bzImage

echo "Kernel build completed successfully!"
echo "Kernel image: ${BUILD_DIR}/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
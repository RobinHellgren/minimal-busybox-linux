#!/bin/bash

set -e

# Check for required environment variable
if [ -z "$KERNEL_VERSION" ]; then
    echo "Error: KERNEL_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export KERNEL_VERSION=6.6.58"
    echo "Or specify it when running make:"
    echo "  KERNEL_VERSION=6.6.58 make kernel"
    exit 1
fi

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

# Apply minimal kernel config
echo "Applying minimal kernel config..."
cp ${CONFIG_DIR}/minimal.config .config
make olddefconfig

# Build kernel
echo "Compiling kernel..."
make -j$(nproc) bzImage

echo "Kernel build completed successfully!"
echo "Kernel image: ${BUILD_DIR}/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
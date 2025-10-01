#!/bin/bash

set -e

BUSYBOX_VERSION=${1:-1.36.1}
BUILD_DIR="/build/build/rootfs"
OUTPUT_DIR="/build/output"

echo "Building minimal root filesystem with BusyBox ${BUSYBOX_VERSION}..."

# Create build directory
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Download BusyBox source if not present
if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
    echo "Downloading BusyBox ${BUSYBOX_VERSION}..."
    wget -q https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
    tar -xf busybox-${BUSYBOX_VERSION}.tar.bz2
    rm busybox-${BUSYBOX_VERSION}.tar.bz2
fi

cd busybox-${BUSYBOX_VERSION}

# Configure BusyBox for static build
echo "Configuring BusyBox..."
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

# Build BusyBox
echo "Compiling BusyBox..."
make -j$(nproc)
make install

# Create minimal rootfs structure
ROOTFS_DIR="${BUILD_DIR}/rootfs"
rm -rf ${ROOTFS_DIR}
mkdir -p ${ROOTFS_DIR}

# Copy BusyBox installation
cp -r _install/* ${ROOTFS_DIR}/

# Create essential directories
cd ${ROOTFS_DIR}
mkdir -p dev proc sys tmp var/log etc/init.d

# Copy init script from config
cp /build/config/system/init.sh init
chmod +x init

# Create basic /etc/passwd
cat > etc/passwd << 'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

# Create basic /etc/group
cat > etc/group << 'EOF'
root:x:0:
EOF

# Create initramfs
echo "Creating initramfs..."
cd ${ROOTFS_DIR}
find . | cpio -o -H newc | gzip > ${BUILD_DIR}/initramfs.gz

echo "Root filesystem build completed successfully!"
echo "Initramfs: ${BUILD_DIR}/initramfs.gz"
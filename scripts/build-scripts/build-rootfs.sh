#!/bin/bash

set -e

# Check for required environment variable
if [ -z "$BUSYBOX_VERSION" ]; then
    echo "Error: BUSYBOX_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export BUSYBOX_VERSION=1.36.1"
    echo "Or specify it when running make:"
    echo "  BUSYBOX_VERSION=1.36.1 make rootfs"
    exit 1
fi

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

# Option 1: Use custom init script (current default)
# This gives you full control over the boot process with a simple shell script
cp /build/config/system/init.sh init
chmod +x init

# Option 2: Use BusyBox's init system (commented out)
# Uncomment the lines below and comment out Option 1 to use BusyBox's init
# This requires creating an /etc/inittab configuration file
#
# Create /etc/inittab for BusyBox init
# cat > etc/inittab << 'EOF'
# ::sysinit:/etc/init.d/rcS
# ::respawn:/bin/sh
# ::ctrlaltdel:/sbin/reboot
# ::shutdown:/bin/umount -a -r
# EOF
#
# Create /etc/init.d/rcS startup script
# mkdir -p etc/init.d
# cat > etc/init.d/rcS << 'EOF'
# #!/bin/sh
# # Mount essential filesystems
# mount -t proc proc /proc
# mount -t sysfs sysfs /sys
# mount -t devtmpfs devtmpfs /dev
# # Set hostname
# hostname minimal-linux
# EOF
# chmod +x etc/init.d/rcS
#
# Note: BusyBox init requires kernel to pass init=/sbin/init
# You'll need to update build-iso.sh to change init=/init to init=/sbin/init

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
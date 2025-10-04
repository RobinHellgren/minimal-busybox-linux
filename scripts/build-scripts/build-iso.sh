#!/bin/bash

set -e

# Check for required environment variable
if [ -z "$KERNEL_VERSION" ]; then
    echo "Error: KERNEL_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export KERNEL_VERSION=6.6.58"
    echo "Or specify it when running make:"
    echo "  KERNEL_VERSION=6.6.58 make iso"
    exit 1
fi

BUILD_DIR="/build/build"
OUTPUT_DIR="/build/output"
ISO_DIR="/build/build/iso"

echo "Creating bootable ISO image..."

# Check if kernel and initramfs exist in build directories
KERNEL_FILE="/build/build/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
INITRAMFS_FILE="/build/build/rootfs/initramfs.gz"

if [ ! -f "${KERNEL_FILE}" ]; then
    echo "Error: Kernel not found at ${KERNEL_FILE}. Run 'make kernel' first."
    exit 1
fi

if [ ! -f "${INITRAMFS_FILE}" ]; then
    echo "Error: Initramfs not found at ${INITRAMFS_FILE}. Run 'make rootfs' first."
    exit 1
fi

# Create ISO directory structure
rm -rf ${ISO_DIR}
mkdir -p ${ISO_DIR}/boot/isolinux
mkdir -p ${BUILD_DIR}/iso

# Copy kernel and initramfs from build directories
cp ${KERNEL_FILE} ${ISO_DIR}/boot/vmlinuz
cp ${INITRAMFS_FILE} ${ISO_DIR}/boot/initramfs.gz

# Create isolinux configuration
cat > ${ISO_DIR}/boot/isolinux/isolinux.cfg << 'EOF'
DEFAULT minimal
PROMPT 0
TIMEOUT 30

LABEL minimal
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initramfs.gz console=tty0 console=ttyS0,115200 init=/init rdinit=/init debug loglevel=7
    TEXT HELP
        Boot minimal BusyBox Linux
    ENDTEXT
EOF

# Copy isolinux files
cp /usr/lib/ISOLINUX/isolinux.bin ${ISO_DIR}/boot/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 ${ISO_DIR}/boot/isolinux/

# Create ISO image
echo "Generating ISO image..."
genisoimage \
    -rational-rock \
    -volid "MINIMAL-LINUX" \
    -cache-inodes \
    -joliet \
    -hfs \
    -full-iso9660-filenames \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o ${BUILD_DIR}/iso/minimal-busybox-linux.iso \
    ${ISO_DIR}

# Make ISO hybrid (USB bootable)
isohybrid ${BUILD_DIR}/iso/minimal-busybox-linux.iso

echo "ISO build completed successfully!"
echo "Bootable ISO: ${BUILD_DIR}/iso/minimal-busybox-linux.iso"
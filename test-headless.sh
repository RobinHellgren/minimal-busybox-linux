#!/bin/bash

# Headless testing script for minimal-busybox-linux
# This runs the VM in text mode only - faster for debugging

set -e

ISO_FILE="output/minimal-busybox-linux.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    echo "Run 'make iso' first to build the ISO"
    exit 1
fi

echo "Starting QEMU in headless mode..."
echo "All output will appear in this terminal"
echo "Press Ctrl+C to exit"
echo ""

# Start QEMU in headless mode with serial console
exec qemu-system-x86_64 \
    -cdrom "$ISO_FILE" \
    -m 512M \
    -nographic \
    -serial mon:stdio \
    -boot d \
    -enable-kvm \
    -cpu host \
    -smp 2 \
    "$@"
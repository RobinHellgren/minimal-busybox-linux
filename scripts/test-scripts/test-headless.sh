#!/bin/bash

# Headless testing script for minimal-busybox-linux
# This runs the VM in text mode only - faster for debugging

set -e

ISO_FILE="./output/minimal-busybox-linux.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    echo "Run 'make iso' first to build the ISO"
    exit 1
fi

echo "Starting QEMU in headless mode..."
echo "All output will appear in this terminal"
echo ""
echo "How to exit:"
echo "  1. Type 'poweroff' in the VM shell (recommended)"
echo "  2. Open another terminal and run: killall qemu-system-x86_64"
echo ""
echo "Note: Ctrl+C won't work - use 'poweroff' or kill from another terminal"
echo ""

# Start QEMU in headless mode with serial console
# Using -serial stdio without mon: so Ctrl+A works properly
exec qemu-system-x86_64 \
    -cdrom "$ISO_FILE" \
    -m 512M \
    -nographic \
    -serial stdio \
    -boot d \
    -enable-kvm \
    -cpu host \
    -smp 2 \
    -monitor none \
    "$@"
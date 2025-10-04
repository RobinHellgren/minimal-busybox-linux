#!/bin/bash

# Local testing script for minimal-busybox-linux
# This script makes it easy to test the ISO locally with QEMU

set -e

ISO_FILE="./output/minimal-busybox-linux.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    echo "Run 'make iso' first to build the ISO"
    exit 1
fi

echo "Starting QEMU with minimal-busybox-linux ISO..."
echo ""
echo "QEMU GUI controls:"
echo "  Click in window  - Capture keyboard/mouse to VM"
echo "  Ctrl+Alt+G       - Release keyboard/mouse from VM"
echo "  Click X button   - Exit QEMU (easiest way to quit)"
echo ""
echo "Advanced:"
echo "  Ctrl+Alt+1       - Switch to VM console"
echo "  Ctrl+Alt+2       - Switch to QEMU monitor"
echo ""

# Start QEMU with useful options for debugging
exec qemu-system-x86_64 \
    -cdrom "$ISO_FILE" \
    -m 512M \
    -display gtk \
    -boot d \
    -enable-kvm \
    -cpu host \
    -smp 2 \
    "$@"
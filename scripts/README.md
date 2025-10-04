# Build Scripts

This directory contains all the build automation scripts for the minimal-busybox-linux project.

## Directory Structure

```
scripts/
├── README.md              # This file
├── build-scripts/         # Core build scripts
│   ├── build-kernel.sh    # Linux kernel compilation
│   ├── build-rootfs.sh    # Root filesystem creation
│   └── build-iso.sh       # ISO image assembly
└── test-scripts/          # QEMU test scripts
    ├── test-local.sh      # GUI mode testing
    └── test-headless.sh   # Headless mode testing
```

## Build Scripts Overview

### 1. build-kernel.sh

**Purpose**: Downloads, configures, and compiles the Linux kernel

**What it does:**
1. Downloads Linux kernel source from kernel.org
2. Applies minimal configuration from `config/kernel/minimal.config`
3. Compiles kernel with parallel build (`-j$(nproc)`)
4. Produces `bzImage` (compressed kernel image)

**Key features:**
- Uses `config/kernel/minimal.config` for kernel configuration
- Includes essential features and basic networking support
- Uses `olddefconfig` to resolve configuration conflicts automatically

**Inputs:**
- `KERNEL_VERSION` environment variable (default: 6.6.58)

**Outputs:**
- `build/kernel/linux-{VERSION}/arch/x86/boot/bzImage`
- Copied to `output/vmlinuz` by Makefile

### 2. build-rootfs.sh

**Purpose**: Creates a minimal root filesystem using BusyBox

**What it does:**
1. Downloads and compiles BusyBox as a static binary
2. Creates essential directory structure (`/dev`, `/proc`, `/sys`, etc.)
3. Copies init script from `config/system/init.sh` to `/init` in rootfs
4. Creates basic system files (`/etc/passwd`, `/etc/group`)
5. Packages everything into a compressed initramfs

**Key features:**
- Static BusyBox build (no shared library dependencies)
- Custom shell script at `/init` runs as PID 1 (not BusyBox's init applet)
- BusyBox provides all the commands the init script uses
- Compressed with gzip for minimal size

**Inputs:**
- `BUSYBOX_VERSION` environment variable (default: 1.36.1)

**Outputs:**
- `build/rootfs/initramfs.gz`
- Copied to `output/initramfs.gz` by Makefile

**Directory structure created:**
```
rootfs/
├── bin/        # BusyBox symlinks (ls, cp, mv, etc.)
├── sbin/       # System binaries (mount, init, etc.)
├── usr/bin/    # Additional utilities
├── usr/sbin/   # Additional system utilities
├── dev/        # Device files (created at boot)
├── proc/       # Process filesystem (mounted at boot)
├── sys/        # System filesystem (mounted at boot)
├── tmp/        # Temporary files
├── var/log/    # Log files
├── etc/        # Configuration files
│   ├── passwd  # User accounts
│   └── group   # Group definitions
└── init*       # Custom init script (executable)
```

### 3. build-iso.sh

**Purpose**: Assembles kernel and rootfs into a bootable ISO image

**What it does:**
1. Verifies kernel and initramfs are available
2. Creates ISO directory structure
3. Copies kernel (`vmlinuz`) and initramfs (`initramfs.gz`)
4. Installs ISOLINUX bootloader
5. Creates bootloader configuration
6. Generates hybrid ISO (bootable from CD/DVD or USB)

**Key features:**
- ISOLINUX bootloader for BIOS/UEFI compatibility
- Hybrid ISO format (works on CD/DVD and USB)
- Console output configuration for debugging
- Automatic timeout to boot without intervention

**Inputs:**
- Compiled kernel from build-kernel.sh
- Initramfs from build-rootfs.sh

**Outputs:**
- `build/iso/minimal-busybox-linux.iso`
- Copied to `output/minimal-busybox-linux.iso` by Makefile

## Test Scripts Overview

### 1. test-local.sh (GUI Mode)

**Purpose**: Test the built ISO in QEMU with a graphical interface

**What it does:**
1. Checks that `output/minimal-busybox-linux.iso` exists
2. Launches QEMU with GUI display
3. Configures KVM acceleration if available
4. Sets up serial console output to terminal

**Key features:**
- Graphical window with VM display
- Mouse and keyboard interaction
- 512MB RAM, 2 CPU cores

**Controls:**
- **Click in window** - Capture keyboard/mouse to VM (REQUIRED for input!)
- `Ctrl+Alt+G` - Release mouse/keyboard from VM
- **Click X on window** - Exit QEMU (easiest method)
- `Ctrl+Alt+1` - Switch to VM console
- `Ctrl+Alt+2` - Switch to QEMU monitor

**Important**: You must click inside the QEMU window before keyboard/mouse input will work.

**Usage:**
```bash
make test
# or
./scripts/test-scripts/test-local.sh

# With custom options
./scripts/test-scripts/test-local.sh -m 1024M -smp 4
```

### 2. test-headless.sh (Console Mode)

**Purpose**: Test the built ISO in QEMU without GUI (headless) - best for debugging

**What it does:**
1. Checks that `output/minimal-busybox-linux.iso` exists
2. Launches QEMU in headless mode
3. All output appears in the terminal via serial console
4. No graphical window

**Key features:**
- All kernel/system messages in terminal
- Easy to capture logs with `tee`
- Works in SSH sessions
- Perfect for CI/CD
- 512MB RAM, 2 CPU cores

**How to exit:**
- **Recommended**: Type `poweroff` in the VM shell
- **Alternative**: From another terminal, run `killall qemu-system-x86_64`

**Note**: Ctrl+C and Ctrl+A keyboard shortcuts don't work in headless mode - you must use `poweroff` command or kill from another terminal.

**Usage:**
```bash
make test-headless
# or
./scripts/test-scripts/test-headless.sh

# Capture boot log
make test-headless 2>&1 | tee boot.log
```

## Build Process Flow

```
Makefile
    ↓
1. build-kernel.sh
   - Download Linux source
   - Configure from config/kernel/minimal.config
   - Compile bzImage
   - Result: vmlinuz
    ↓
2. build-rootfs.sh
   - Download BusyBox source
   - Compile static binary
   - Create filesystem structure
   - Copy init script from config/system/init.sh
   - Package as initramfs.gz
    ↓
3. build-iso.sh
   - Combine vmlinuz + initramfs.gz
   - Add bootloader (ISOLINUX)
   - Create bootable ISO
   - Result: minimal-busybox-linux.iso
    ↓
4. test-local.sh / test-headless.sh
   - Boot ISO in QEMU
   - Verify system functionality
```

## Docker Integration

All scripts run inside a Docker container with:
- **Ubuntu 22.04 base**: Stable build environment
- **Build tools**: gcc, make, binutils, etc.
- **Kernel tools**: bc, flex, bison, libssl-dev, etc.
- **ISO tools**: isolinux, genisoimage, isohybrid

**Volume mounting:**
- Host project directory → `/build` in container
- Ensures build artifacts persist on host

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KERNEL_VERSION` | 6.6.58 | Linux kernel version to build |
| `BUSYBOX_VERSION` | 1.36.1 | BusyBox version to build |

## Customization Points

### Kernel Configuration
Modify `config/kernel/minimal.config` to change kernel features

### Init Script
Modify `config/system/init.sh` to customize the boot process and system initialization

### Root Filesystem
Modify `build-rootfs.sh` to customize the system:
- Change BusyBox configuration
- Add additional files to rootfs
- Change filesystem structure

### Boot Configuration
Modify `build-iso.sh` to change boot behavior:
- Kernel command line parameters
- Boot timeout settings
- Console configuration
- Boot menu options

## Debugging

### Build Logs
Capture build output for analysis:
```bash
make kernel 2>&1 | tee kernel-build.log
make rootfs 2>&1 | tee rootfs-build.log
make iso 2>&1 | tee iso-build.log
```

### Container Debugging
Access the build container directly:
```bash
docker run -it --rm -v $(pwd):/build minimal-busybox-linux-builder bash
```

## Error Handling

All scripts use `set -e` to exit on any error. Common failure points:

1. **Network issues**: Downloading source packages
2. **Compilation errors**: Missing dependencies or configuration issues
3. **Permission errors**: Docker volume mounting
4. **Disk space**: Large kernel builds require significant space

## Dependencies

Scripts automatically download required source packages:
- Linux kernel from kernel.org
- BusyBox from busybox.net
- Bootloader files from system packages

No manual downloads required - everything is automated.
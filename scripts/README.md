# Build Scripts

This directory contains all the build automation scripts for the minimal-busybox-linux project.

## Directory Structure

```
scripts/
├── README.md           # This file
├── build/              # Core build scripts
│   ├── build-kernel.sh # Linux kernel compilation
│   ├── build-rootfs.sh # Root filesystem creation
│   └── build-iso.sh    # ISO image assembly
└── utils/              # Utility scripts (future expansion)
```

## Build Scripts Overview

### 1. build-kernel.sh

**Purpose**: Downloads, configures, and compiles the Linux kernel

**What it does:**
1. Downloads Linux kernel source from kernel.org
2. Applies minimal configuration optimized for containers
3. Compiles kernel with parallel build (`-j$(nproc)`)
4. Produces `bzImage` (compressed kernel image)

**Key features:**
- Uses `defconfig` as base configuration
- Applies container-friendly settings (namespaces, cgroups)
- Disables unnecessary features (sound, wireless, etc.)
- Uses `olddefconfig` to resolve configuration conflicts automatically

**Inputs:**
- `KERNEL_VERSION` environment variable (default: 6.6.58)

**Outputs:**
- `build/kernel/linux-{VERSION}/arch/x86/boot/bzImage`
- Copied to `output/vmlinuz` by Makefile

**Configuration applied:**
```bash
# Essential container features
scripts/config --enable CONFIG_NAMESPACES
scripts/config --enable CONFIG_CGROUPS
scripts/config --enable CONFIG_MEMCG

# Disabled unnecessary features
scripts/config --disable CONFIG_SOUND
scripts/config --disable CONFIG_WIRELESS
```

### 2. build-rootfs.sh

**Purpose**: Creates a minimal root filesystem using BusyBox

**What it does:**
1. Downloads and compiles BusyBox as a static binary
2. Creates essential directory structure (`/dev`, `/proc`, `/sys`, etc.)
3. Installs custom init script
4. Creates basic system files (`/etc/passwd`, `/etc/group`)
5. Packages everything into a compressed initramfs

**Key features:**
- Static BusyBox build (no shared library dependencies)
- Custom init system (lightweight alternative to systemd)
- Essential device nodes created at boot
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

**Bootloader configuration:**
```
DEFAULT minimal
PROMPT 0
TIMEOUT 30

LABEL minimal
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initramfs.gz console=tty0 console=ttyS0,115200 init=/init rdinit=/init debug loglevel=7
```

## Build Process Flow

```
Makefile
    ↓
1. build-kernel.sh
   - Download Linux source
   - Configure for minimal/container use
   - Compile bzImage
   - Result: vmlinuz
    ↓
2. build-rootfs.sh
   - Download BusyBox source
   - Compile static binary
   - Create filesystem structure
   - Create init script
   - Package as initramfs.gz
    ↓
3. build-iso.sh
   - Combine vmlinuz + initramfs.gz
   - Add bootloader (ISOLINUX)
   - Create bootable ISO
   - Result: minimal-busybox-linux.iso
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
- Permission handling via Makefile for output files

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KERNEL_VERSION` | 6.6.58 | Linux kernel version to build |
| `BUSYBOX_VERSION` | 1.36.1 | BusyBox version to build |

## Customization Points

### Kernel Configuration
Modify `build-kernel.sh` to change kernel features:
```bash
# Add new kernel features
scripts/config --enable CONFIG_NEW_FEATURE

# Disable features
scripts/config --disable CONFIG_UNWANTED_FEATURE
```

### Root Filesystem
Modify `build-rootfs.sh` to customize the system:
- Change BusyBox configuration
- Modify init script behavior
- Add additional files to rootfs
- Change filesystem structure

### Boot Configuration
Modify `build-iso.sh` to change boot behavior:
- Kernel command line parameters
- Boot timeout settings
- Console configuration
- Boot menu options

## Debugging

### Verbose Output
Scripts include echo statements for key steps. For more detail:
```bash
# Run with bash -x for full tracing
bash -x scripts/build/build-kernel.sh
```

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
3. **Permission errors**: Docker volume mounting (handled by Makefile)
4. **Disk space**: Large kernel builds require significant space

## Dependencies

Scripts automatically download required source packages:
- Linux kernel from kernel.org
- BusyBox from busybox.net
- Bootloader files from system packages

No manual downloads required - everything is automated.
# minimal-busybox-linux

A minimal Linux distribution build system for creating lightweight Linux environments using BusyBox and a custom kernel configuration.

## Overview

This project builds a complete Linux system from scratch using:
- **Linux Kernel 6.6.58**: Minimal configuration with essential features
- **BusyBox 1.36.1**: Provides ~300 Unix utilities in a single binary
- **Custom Init System**: Lightweight shell-based init
- **Docker Build Environment**: Ensures reproducible builds across platforms

**Final Result**: ~15-25MB bootable ISO with full Linux functionality

## Features

- **Minimal footprint**: Built with only essential components
- **Educational**: Perfect for learning Linux internals and system building
- **Fast boot**: Optimized kernel configuration for quick startup (~3-5 seconds)
- **Reproducible builds**: Docker-based build environment ensures consistency
- **Modular design**: Separate kernel, rootfs, and toolchain builds
- **Local testing**: QEMU integration for rapid development cycles

## Quick Start

1. **Build the complete system:**
   ```bash
   make all
   ```

2. **Test locally with QEMU:**
   ```bash
   make test          # GUI mode
   make test-headless # Console mode
   ```

3. **Create bootable USB:**
   ```bash
   sudo dd if=output/minimal-busybox-linux.iso of=/dev/sdX bs=1M status=progress
   ```

## Build Targets

| Target | Description |
|--------|-------------|
| `make all` | Build complete minimal Linux distribution |
| `make kernel` | Build Linux kernel only |
| `make rootfs` | Build root filesystem only |
| `make iso` | Create bootable ISO image |
| `make test` | Test ISO with QEMU (GUI mode) |
| `make test-headless` | Test ISO with QEMU (console mode) |
| `make clean` | Clean all build artifacts |
| `make help` | Show all available targets |

## How It Works

### Build Process Flow

```
1. make all
   ↓
2. docker build (create build environment)
   ↓
3. make kernel
   - Download Linux kernel source
   - Apply minimal configuration from config/kernel/minimal.config
   - Compile kernel (bzImage)
   - Copy to output/vmlinuz
   ↓
4. make rootfs
   - Download BusyBox source
   - Compile static binary
   - Create filesystem structure
   - Copy init script from config/system/init.sh
   - Generate initramfs.gz
   ↓
5. make iso
   - Combine kernel + initramfs
   - Add ISOLINUX bootloader
   - Create hybrid ISO (CD/USB bootable)
   - Output: minimal-busybox-linux.iso
```

### Architecture Decisions

**Why Docker for builds?**
- Ensures consistent build environment across different host systems
- Isolates build dependencies from host system
- Reproducible builds regardless of host distro

**Why BusyBox?**
- Single static binary provides 300+ Unix commands
- No shared library dependencies
- Proven reliability in embedded systems
- ~1MB total size

**Why Custom Init?**
- systemd is too heavy for minimal systems
- Custom init provides exactly what's needed
- Fast boot time and minimal memory usage
- Educational value - understand what init actually does

## Directory Structure

```
minimal-busybox-linux/
├── README.md              # This file
├── Makefile              # Build orchestration
├── Dockerfile            # Build environment definition
├── test-local.sh         # Local QEMU testing (GUI)
├── test-headless.sh      # Local QEMU testing (console)
├── build/                # Build artifacts (generated)
│   ├── kernel/           # Kernel build workspace
│   ├── rootfs/           # Root filesystem build workspace
│   └── iso/              # ISO assembly workspace
├── config/               # Configuration files
│   ├── kernel/           # Kernel configurations
│   │   └── minimal.config # Minimal kernel config
│   └── system/           # System configurations
│       └── init.sh       # Custom init script
├── scripts/              # Build and utility scripts
│   └── build-scripts/    # Core build scripts
│       ├── build-kernel.sh   # Kernel compilation
│       ├── build-rootfs.sh   # Root filesystem creation
│       └── build-iso.sh      # ISO image creation
└── output/               # Final build outputs
    ├── vmlinuz           # Compiled kernel
    ├── initramfs.gz      # Root filesystem archive
    └── minimal-busybox-linux.iso # Bootable ISO image
```

## Requirements

- **Docker**: For containerized build environment
- **Make**: Build orchestration
- **QEMU** (optional): For local testing
- **2GB+ free disk space**: For build artifacts
- **Internet connection**: For downloading source packages

## Configuration & Customization

### Kernel Configuration
Edit `config/kernel/minimal.config` to modify kernel features:
- Enable/disable hardware support
- Add filesystem types
- Configure networking protocols
- Security features

### System Behavior
Edit `config/system/init.sh` to customize:
- Boot sequence
- Default services
- Environment setup

### Package Versions
Edit `Makefile` to change:
- `KERNEL_VERSION` (default: 6.6.58)
- `BUSYBOX_VERSION` (default: 1.36.1)

## Troubleshooting

### Common Issues

**Build fails with permission errors:**
- The build system handles Docker volume permissions automatically
- If issues persist, try `make clean` and rebuild

**Kernel panic on boot:**
- Check that init script is executable
- Verify kernel configuration includes essential features
- Use `make test-headless` for detailed boot logs

**System hangs after "crng init done":**
- This is normal - system is ready for input
- Try pressing Enter or typing commands

### Debugging

**View detailed build logs:**
```bash
make kernel 2>&1 | tee kernel-build.log
```

**Test with verbose kernel output:**
Edit `scripts/build-scripts/build-iso.sh` and change boot parameters to include `debug loglevel=7`

**Access QEMU monitor:**
In QEMU GUI: Ctrl+Alt+2 (Ctrl+Alt+1 to return to VM)

## Use Cases

**Perfect for:**
- Embedded systems and IoT devices
- Minimal VM images
- CI/CD build environments
- Testing and development environments
- Security research and testing
- Educational purposes (Linux internals)

**Size Comparison:**
- Ubuntu Server ISO: ~1.4GB
- CentOS Minimal: ~1.8GB
- Alpine Linux: ~130MB
- **minimal-busybox-linux**: ~15-25MB

## Contributing

This project demonstrates building a minimal Linux distribution from scratch. Key learning areas:
- Linux kernel configuration and compilation
- Root filesystem creation with BusyBox
- Bootloader setup (ISOLINUX)
- Docker-based build systems
- QEMU testing and debugging

## License

See LICENSE file for details.
# Configuration Files

This directory contains configuration files that control the behavior of the minimal-busybox-linux build system and resulting Linux distribution.

## Directory Structure

```
config/
├── README.md           # This file
├── kernel/            # Kernel configuration files
│   └── minimal.config # Minimal kernel configuration
└── system/            # System configuration files
    └── init.sh        # Custom init script template
```

## Kernel Configuration (`kernel/`)

### minimal.config

**Purpose**: Defines which Linux kernel features are enabled/disabled

**Current Configuration Philosophy**:
- **Minimal footprint**: Only essential features enabled
- **Security-focused**: Essential security features enabled
- **Hardware-minimal**: Most drivers disabled to reduce size

**Note**: Container/namespace support (CONFIG_NAMESPACES, CONFIG_CGROUPS, etc.) is included in the config but can be removed if not needed for your use case.

**Key Features Enabled**:

#### Core System
```
CONFIG_64BIT=y                    # 64-bit x86 architecture
CONFIG_EMBEDDED=y                 # Embedded system optimizations
CONFIG_EXPERT=y                   # Allow expert-level configuration
CONFIG_PRINTK=y                   # Kernel logging support
CONFIG_BUG=y                      # Bug detection and reporting
```

#### Process & Memory Management
```
CONFIG_SWAP=y                     # Virtual memory swap support
CONFIG_SYSVIPC=y                  # System V IPC (shared memory, etc.)
CONFIG_POSIX_MQUEUE=y            # POSIX message queues
CONFIG_CROSS_MEMORY_ATTACH=y     # Process memory access
```

#### Essential Filesystems
```
CONFIG_PROC_FS=y                 # /proc filesystem
CONFIG_SYSFS=y                   # /sys filesystem
CONFIG_TMPFS=y                   # Temporary filesystem
CONFIG_DEVTMPFS=y                # Device filesystem
CONFIG_DEVTMPFS_MOUNT=y          # Auto-mount /dev
```

#### Network Support (Minimal)
```
CONFIG_NET=y                     # Basic networking
CONFIG_UNIX=y                    # Unix domain sockets
CONFIG_INET=y                    # IPv4 support
CONFIG_IPV6=y                    # IPv6 support
CONFIG_IP_MULTICAST=y            # Multicast support
CONFIG_IP_ADVANCED_ROUTER=y      # Advanced routing
```

#### Console & TTY
```
CONFIG_TTY=y                     # TTY support
CONFIG_VT=y                      # Virtual terminals
CONFIG_VT_CONSOLE=y              # Virtual terminal console
CONFIG_SERIAL_8250=y             # Serial port support
CONFIG_SERIAL_8250_CONSOLE=y     # Serial console
```

**Key Features Disabled**:
```
# CONFIG_SOUND is not set            # Audio support
# CONFIG_WIRELESS is not set         # WiFi drivers
# CONFIG_WLAN is not set             # Wireless LAN
# CONFIG_BT is not set               # Bluetooth
# CONFIG_DRM is not set              # Graphics drivers
# CONFIG_FB is not set               # Framebuffer
# CONFIG_USB_HID is not set          # USB input devices
# CONFIG_HID is not set              # Human interface devices
# CONFIG_STAGING is not set          # Staging drivers
```

**Customization Guide**:

To add support for specific hardware:
1. Copy `minimal.config` to `custom.config`
2. Enable required drivers:
   ```
   CONFIG_USB=y                   # USB support
   CONFIG_USB_STORAGE=y           # USB storage devices
   CONFIG_E1000=y                 # Intel network card
   ```
3. Update `scripts/build-scripts/build-kernel.sh` to use your config

## System Configuration (`system/`)

### init.sh

**Purpose**: Custom init script that becomes `/init` in the root filesystem. This file is copied directly by the build process.

**Location**: `config/system/init.sh`

**How it's used**: During the rootfs build, this file is copied into the initramfs as `/init`

**Key Functions**:

1. **Filesystem Mounting**:
   - `/proc`: Process information
   - `/sys`: System information
   - `/dev`: Device files (auto-populated)

2. **Device Node Creation**:
   - `/dev/console`: Main console
   - `/dev/null`: Null device
   - `/dev/zero`: Zero device
   - `/dev/tty`: Current terminal

3. **Environment Setup**:
   - `PATH`: Standard binary locations
   - `HOME`: Root home directory
   - `TERM`: Terminal type

4. **Shell Management**:
   - Infinite loop to restart shell if it exits
   - Proper TTY redirection for interactive use

**Customization Examples**:

**Add network configuration**:
```bash
# Configure loopback interface
/sbin/ip link set lo up
/sbin/ip addr add 127.0.0.1/8 dev lo

# Configure DHCP (if network hardware enabled)
/sbin/udhcpc -i eth0
```

**Add service startup**:
```bash
# Start SSH daemon (if added to rootfs)
/usr/sbin/sshd

# Start custom service
/usr/bin/myservice &
```

**Add logging**:
```bash
# Start syslog daemon
/sbin/syslogd
/sbin/klogd
```

**Add user management**:
```bash
# Create additional users
/usr/sbin/adduser -D -s /bin/sh user1

# Set passwords (in real deployment, use proper secret management)
echo "root:password" | /usr/sbin/chpasswd
```

## Configuration Best Practices

### Kernel Configuration
1. **Start minimal**: Begin with current config and add features as needed
2. **Test changes**: Always test with `make test-headless` after changes
3. **Document changes**: Comment why features were added/removed
4. **Security first**: Only enable what's absolutely necessary

### Init Script
1. **Keep it simple**: Minimal init should do minimal work
2. **Error handling**: Check return codes for critical operations
3. **Logging**: Include echo statements for debugging
4. **Idempotent**: Script should work if run multiple times

## Advanced Customization

### Conditional Features
Use environment variables in build scripts:
```bash
if [ "$BUILD_TYPE" = "debug" ]; then
    scripts/config --enable CONFIG_DEBUG_KERNEL
    scripts/config --enable CONFIG_DEBUG_INFO
fi
```

### Multi-arch Support
Create architecture-specific configs:
```
config/kernel/
├── x86_64.config
├── arm64.config
└── riscv64.config
```

## Validation

After configuration changes, validate the build:

1. **Build test**: `make clean && make all`
2. **Boot test**: `make test-headless`
3. **Feature test**: Verify new features work as expected
4. **Size check**: Monitor ISO size growth

## Troubleshooting

**Kernel won't compile**:
- Check for missing dependencies in configuration
- Ensure conflicting options aren't enabled
- Use `make menuconfig` in kernel directory for interactive config

**Boot failures**:
- Verify essential features are enabled (DEVTMPFS, PROC_FS, etc.)
- Check init script syntax
- Add debug output to init script

**Missing functionality**:
- Check if required kernel features are enabled
- Verify BusyBox includes needed applets
- Ensure proper device nodes are created
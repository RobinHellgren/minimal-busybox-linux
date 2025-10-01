# Development Guide

This guide covers development workflows, testing procedures, and debugging techniques for the minimal-busybox-linux project.

## Development Workflow

### Quick Development Cycle

For rapid iteration while developing:

```bash
# 1. Make changes to configuration or scripts
vim config/kernel/minimal.config
vim scripts/build-scripts/build-rootfs.sh

# 2. Build only what changed
make kernel    # If kernel config changed
make rootfs    # If rootfs script changed
make iso       # If ISO script changed

# 3. Test immediately
make test-headless

# 4. Iterate
```

### Full Clean Build

For thorough testing or before commits:

```bash
make clean
make all
make test
```

## Testing

### Local Testing with QEMU

#### GUI Mode Testing
```bash
make test
./test-local.sh

# Features:
# - Full graphical interface
# - Mouse and keyboard input
# - Easy to use for interactive testing
# - Good for filesystem exploration
```

#### Headless Mode Testing (Recommended for development)
```bash
make test-headless
./test-headless.sh

# Features:
# - All output in terminal
# - Faster startup
# - Easy to capture logs
# - Better for debugging boot issues
```

#### Custom QEMU Options
```bash
# Test with more memory
./test-local.sh -m 1024M

# Test with multiple CPUs
./test-local.sh -smp 4

# Test with network
./test-local.sh -netdev user,id=net0 -device e1000,netdev=net0
```

### Testing Scenarios

#### Boot Testing
1. **Verify kernel loads**: Should see kernel boot messages
2. **Check init starts**: Look for "Run /init as init process"
3. **Filesystem mounts**: Should see "Mounting filesystems..."
4. **Shell availability**: Should get `/ #` prompt

#### Functionality Testing
```bash
# Test basic commands
ls
ps
mount
df
free

# Test filesystem
touch /tmp/test
echo "hello" > /tmp/test
cat /tmp/test

# Test process management
sleep 30 &
ps
kill %1

# Test networking (if enabled)
ip link
ping 127.0.0.1
```


### Performance Testing

#### Boot Time Measurement
```bash
# Time the boot process
time make test-headless | grep "Minimal Linux system started"
```

#### Memory Usage Analysis
```bash
# In the running system
free
cat /proc/meminfo
ps aux  # Check process memory usage
```

#### Size Analysis
```bash
# Check component sizes
ls -lh output/
du -h build/kernel/
du -h build/rootfs/
```

## Debugging

### Build Debugging

#### Kernel Build Issues
```bash
# Verbose kernel build
make kernel V=1

# Check kernel config
docker run --rm -v $(pwd):/build minimal-busybox-linux-builder bash -c "
cd /build/build/kernel/linux-*/
make menuconfig  # Interactive config check
"

# Save kernel build log
make kernel 2>&1 | tee kernel.log
```

#### Rootfs Build Issues
```bash
# Debug BusyBox build
make rootfs 2>&1 | tee rootfs.log

# Check BusyBox config
docker run --rm -v $(pwd):/build minimal-busybox-linux-builder bash -c "
cd /build/build/rootfs/busybox-*/
make menuconfig
"

# Inspect generated rootfs
mkdir -p /tmp/rootfs
cd /tmp/rootfs
gunzip -c ~/projects/minimal-busybox-linux/output/initramfs.gz | cpio -i
ls -la
```

#### ISO Build Issues
```bash
# Test ISO structure
mkdir -p /tmp/iso
sudo mount -o loop output/minimal-busybox-linux.iso /tmp/iso
ls -la /tmp/iso/
sudo umount /tmp/iso
```

### Runtime Debugging

#### Boot Debugging
Enable verbose kernel output by editing `scripts/build-scripts/build-iso.sh`:

```bash
# Change from:
APPEND initrd=/boot/initramfs.gz console=tty0 console=ttyS0,115200 init=/init rdinit=/init debug loglevel=7

# To:
APPEND initrd=/boot/initramfs.gz console=tty0 console=ttyS0,115200 init=/init rdinit=/init debug loglevel=7 ignore_loglevel
```

#### Init Script Debugging
Add debug output to init script in `config/system/init.sh`:

```bash
# Add to init script
set -x  # Enable command tracing
echo "DEBUG: Starting init script"
echo "DEBUG: Mounting proc..."
/bin/mount -t proc proc /proc
echo "DEBUG: Proc mounted, checking:"
ls /proc/
```

#### Interactive Debugging
```bash
# Access container environment
docker run -it --rm -v $(pwd):/build minimal-busybox-linux-builder bash

# Test components individually
cd /build/build/kernel/linux-*/
make menuconfig

cd /build/build/rootfs/busybox-*/
./busybox --list
```

### Common Debugging Scenarios

#### "Kernel panic - not syncing: No working init found"
1. Check that init script is executable
2. Verify init script path in bootloader config
3. Ensure essential filesystems are mounted
4. Check that /init exists in initramfs

#### "System hangs after kernel messages"
1. Enable verbose kernel output
2. Check init script for infinite loops
3. Verify console configuration
4. Test with simpler init script

#### "Shell commands not found"
1. Check BusyBox compilation
2. Verify PATH environment variable
3. Ensure BusyBox applets are linked correctly
4. Check filesystem permissions

#### "Permission denied" errors
1. Verify file permissions in rootfs
2. Check device node creation
3. Ensure proper filesystem mounting
4. Test with different user/group settings

## Development Tools

### Makefile Targets
```bash
make help           # Show all available targets
make clean          # Clean build artifacts
make docker-build   # Build container environment only
make kernel         # Build kernel only
make rootfs         # Build rootfs only
make iso           # Build ISO only
make test          # Test with QEMU GUI
make test-headless # Test with QEMU console
```

### Environment Variables
```bash
# Customize build versions
KERNEL_VERSION=6.1.55 make kernel
BUSYBOX_VERSION=1.35.0 make rootfs

# Enable debug builds
DEBUG=1 make all
```

### Container Development
```bash
# Enter build environment
docker run -it --rm -v $(pwd):/build minimal-busybox-linux-builder bash

# Test build steps manually
cd /build
bash scripts/build-scripts/build-kernel.sh
bash scripts/build-scripts/build-rootfs.sh
bash scripts/build-scripts/build-iso.sh
```

## Code Quality

### Shell Script Standards
- Use `set -e` for error handling
- Quote variables: `"$VAR"` not `$VAR`
- Use meaningful function names
- Include comments for complex operations
- Use `shellcheck` for static analysis

### Documentation Standards
- Update README files when changing functionality
- Include examples in documentation
- Document environment variables and their defaults
- Explain design decisions in comments

### Testing Standards
- Test on clean build environment
- Verify both success and failure cases
- Test with different configuration options
- Validate on different host systems

## Performance Optimization

### Build Speed
```bash
# Parallel builds (adjust based on CPU cores)
export MAKEFLAGS="-j$(nproc)"

# Docker build caching
docker build --cache-from minimal-busybox-linux-builder .

# Incremental builds
make kernel  # Only rebuild kernel if needed
```

### Runtime Performance
- Monitor memory usage with minimal configs
- Profile boot time with different init scripts
- Test with various kernel optimizations
- Benchmark I/O performance

### Size Optimization
```bash
# Check what's taking space
du -h build/
ls -lh output/

# Analyze kernel size
scripts/bloat-o-meter vmlinux.old vmlinux.new

# Optimize initramfs
find build/rootfs/rootfs -type f -exec file {} \; | grep "not stripped"
```

## Release Process

### Pre-release Checklist
- [ ] Clean build succeeds
- [ ] All tests pass
- [ ] Documentation is up to date
- [ ] Configuration is validated
- [ ] Size targets are met
- [ ] Boot time is acceptable

### Release Build
```bash
# Clean release build
make clean
KERNEL_VERSION=6.6.58 BUSYBOX_VERSION=1.36.1 make all

# Validate release
make test-headless
ls -lh output/minimal-busybox-linux.iso

# Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
```

### Deployment Testing
- Test on different hardware platforms
- Verify container functionality
- Test with real Kubernetes workloads
- Validate security configurations

## Troubleshooting Quick Reference

| Issue | Command | Solution |
|-------|---------|----------|
| Build fails | `make clean && make all` | Clean rebuild |
| Permission errors | `docker run --rm -v $(pwd):/build minimal-busybox-linux-builder ls -la /build/output/` | Check volume permissions |
| Boot hangs | `make test-headless` | Check console output |
| Missing commands | `docker run --rm -v $(pwd):/build minimal-busybox-linux-builder /build/build/rootfs/busybox-*/busybox --list` | Verify BusyBox applets |
| Large ISO | `du -h build/` | Identify size contributors |
| Slow boot | Add timing to init script | Profile boot process |

## Contributing

When contributing to the project:

1. **Test your changes**: Always test with `make test-headless`
2. **Update documentation**: Keep README files current
3. **Follow conventions**: Use existing code style
4. **Explain changes**: Include clear commit messages
5. **Test edge cases**: Verify error handling works

## Getting Help

Common resources for development:
- Linux kernel documentation: https://kernel.org/doc/
- BusyBox documentation: https://busybox.net/
- QEMU documentation: https://qemu.org/docs/
- ISOLINUX documentation: https://wiki.syslinux.org/
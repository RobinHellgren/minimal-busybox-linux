# Minimal Linux Distribution Build System
# For minimal-busybox-linux

KERNEL_VERSION ?= 6.6.58
BUSYBOX_VERSION ?= 1.36.1

BUILD_DIR := $(CURDIR)/build
CONFIG_DIR := $(CURDIR)/config
SCRIPTS_DIR := $(CURDIR)/scripts
SRC_DIR := $(CURDIR)/src
OUTPUT_DIR := $(CURDIR)/output

DOCKER_IMAGE := minimal-busybox-linux-builder
DOCKER_RUN := docker run --rm -v $(CURDIR):/build --user $(shell id -u):$(shell id -g) $(DOCKER_IMAGE)

.PHONY: all clean docker-build kernel rootfs iso test test-headless

all: docker-build kernel rootfs iso

docker-build:
	@echo "Building Docker build environment..."
	docker build -t $(DOCKER_IMAGE) .

kernel: docker-build
	@echo "Building Linux kernel $(KERNEL_VERSION)..."
	$(DOCKER_RUN) bash /build/scripts/build/build-kernel.sh $(KERNEL_VERSION)
	@echo "Copying kernel to output directory..."
	@mkdir -p $(OUTPUT_DIR)
	@if [ -f $(BUILD_DIR)/kernel/linux-$(KERNEL_VERSION)/arch/x86/boot/bzImage ]; then \
		cp $(BUILD_DIR)/kernel/linux-$(KERNEL_VERSION)/arch/x86/boot/bzImage $(OUTPUT_DIR)/vmlinuz; \
		echo "Kernel copied to $(OUTPUT_DIR)/vmlinuz"; \
	else \
		echo "Error: Kernel not found"; \
		exit 1; \
	fi

rootfs: docker-build
	@echo "Building minimal root filesystem..."
	$(DOCKER_RUN) bash /build/scripts/build/build-rootfs.sh $(BUSYBOX_VERSION)
	@echo "Copying initramfs to output directory..."
	@mkdir -p $(OUTPUT_DIR)
	@if [ -f $(BUILD_DIR)/rootfs/initramfs.gz ]; then \
		cp $(BUILD_DIR)/rootfs/initramfs.gz $(OUTPUT_DIR)/initramfs.gz; \
		echo "Initramfs copied to $(OUTPUT_DIR)/initramfs.gz"; \
	else \
		echo "Error: Initramfs not found"; \
		exit 1; \
	fi

iso: kernel rootfs
	@echo "Creating bootable ISO image..."
	$(DOCKER_RUN) bash /build/scripts/build/build-iso.sh
	@echo "Copying ISO to output directory..."
	@if [ -f $(BUILD_DIR)/iso/minimal-busybox-linux.iso ]; then \
		cp $(BUILD_DIR)/iso/minimal-busybox-linux.iso $(OUTPUT_DIR)/minimal-busybox-linux.iso; \
		echo "ISO copied to $(OUTPUT_DIR)/minimal-busybox-linux.iso"; \
	else \
		echo "Error: ISO not found"; \
		exit 1; \
	fi

test: iso
	@echo "Testing ISO with QEMU (GUI mode)..."
	./test-local.sh

test-headless: iso
	@echo "Testing ISO with QEMU (headless mode)..."
	./test-headless.sh

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)/* $(OUTPUT_DIR)/*
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

help:
	@echo "Available targets:"
	@echo "  all           - Build complete minimal Linux distribution"
	@echo "  kernel        - Build Linux kernel only"
	@echo "  rootfs        - Build root filesystem only"
	@echo "  iso           - Create bootable ISO image"
	@echo "  test          - Test ISO with QEMU (GUI mode)"
	@echo "  test-headless - Test ISO with QEMU (headless mode)"
	@echo "  clean         - Clean all build artifacts"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  KERNEL_VERSION  - Linux kernel version (default: $(KERNEL_VERSION))"
	@echo "  BUSYBOX_VERSION - BusyBox version (default: $(BUSYBOX_VERSION))"
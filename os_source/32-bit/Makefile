# ==============================================================================
# Makefile for DurhamOS
# Stage 1: Simple BIOS Bootloader
# ==============================================================================

# Assembler
NASM = nasm

# Emulator
QEMU = qemu-system-x86_64

# --- Build Configuration ---

# Source files
BOOT_SRC = boot.asm

# Output files
BOOT_BIN = boot.bin
OS_IMAGE = durhamos.img

# --- Build Rules ---

# Default target: build the OS image and run it
all: run

# Build the final OS image. For now, it's just the bootloader.
# We use 'dd' to create a 1.44MB floppy disk image and write our
# bootloader to the very beginning of it.
$(OS_IMAGE): $(BOOT_BIN)
	@echo "Creating floppy image: $@"
	@dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	@dd if=$(BOOT_BIN) of=$(OS_IMAGE) conv=notrunc

# Assemble the bootloader
$(BOOT_BIN): $(BOOT_SRC)
	@echo "Assembling bootloader: $<"
	@$(NASM) -f bin -o $(BOOT_BIN) $(BOOT_SRC)

# Run the OS image in QEMU
run: $(OS_IMAGE)
	@echo "Booting DurhamOS in QEMU..."
	@$(QEMU) -drive format=raw,file=$(OS_IMAGE)

# Clean up all generated files
clean:
	@echo "Cleaning up build files..."
	@rm -f $(BOOT_BIN) $(OS_IMAGE)

# Phony targets are not files
.PHONY: all run clean
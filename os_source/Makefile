# ==============================================================================
# Makefile for DurhamOS
# Definitive Version: Builds a single-stage bootloader and C kernel.
# ==============================================================================

# --- Toolchain ---
CC = x86_64-elf-gcc
AS = nasm
LD = x8-64-elf-ld

# --- C Compiler Flags ---
CFLAGS = -Wall -Wextra -ffreestanding -nostdlib -fno-exceptions -fno-rtti -mno-red-zone

# --- Source Files ---
BOOT_SRC = boot.asm
KERNEL_C_SRC = kernel.c
LINKER_SCRIPT = linker.ld

# --- Object/Binary Files ---
BOOT_BIN = boot.bin
KERNEL_OBJ = kernel.o
KERNEL_BIN = kernel.bin

# --- Output File ---
OS_IMAGE = durhamos.img

# --- Build Rules ---

all: run

# Build the final OS image by combining the bootloader and kernel
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	@echo "Creating final disk image: $@"
	@dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	@dd if=$(BOOT_BIN) of=$(OS_IMAGE) conv=notrunc
	@dd if=$(KERNEL_BIN) of=$(OS_IMAGE) seek=1 conv=notrunc

# Link the C kernel
$(KERNEL_BIN): $(KERNEL_OBJ) $(LINKER_SCRIPT)
	@echo "Linking kernel..."
	@$(LD) -n -T $(LINKER_SCRIPT) -o $(KERNEL_BIN) $(KERNEL_OBJ)

# Compile the C kernel
$(KERNEL_OBJ): $(KERNEL_C_SRC)
	@echo "Compiling C kernel..."
	@$(CC) $(CFLAGS) -c $< -o $@

# Assemble the bootloader
$(BOOT_BIN): $(BOOT_SRC)
	@echo "Assembling bootloader..."
	@$(AS) -f bin -o $(BOOT_BIN) $(BOOT_SRC)

run: $(OS_IMAGE)
	@echo "Booting DurhamOS in QEMU..."
	@qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE)

clean:
	@echo "Cleaning up build files..."
	@rm -f *.bin *.o $(OS_IMAGE)

.PHONY: all run clean

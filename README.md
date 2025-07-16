DurhamOS: A Developmental Roadmap
This document outlines the phased development plan for creating a new operating system, DurhamOS, from the ground up. The plan is structured to build upon foundational concepts, ensuring a working and testable system at each major milestone.

Stage 0: Foundation and Environment Setup
This preliminary stage is critical. A correct and consistent development environment prevents countless issues with compilation, linking, and testing.

Objective: To prepare a robust toolchain and testing environment for OS development.

Key Tasks:

Host Environment: Set up a Linux environment. A native installation of Debian/Ubuntu or using Windows Subsystem for Linux (WSL) 2 is recommended.

Essential Tools: Install the necessary software packages:

build-essential (provides make, gcc, g++)

nasm (The Netwide Assembler for our assembly code)

qemu-system-x86 (The emulator to run and test our OS)

xorriso (For creating bootable ISO images)

Cross-Compiler: Build an x86_64-elf cross-compiler (GCC and Binutils). This is crucial because we cannot use our host system's compiler (e.g., Linux GCC), as it targets a different environment with different libraries and conventions. A cross-compiler ensures our code is built for a "freestanding" environment—our OS—without any host dependencies.

Build Automation: Create a basic Makefile to automate the process of compiling our code and running it in QEMU.

Stage 1: The Bootloader - From Power-On to Kernel
The bootloader is the first piece of our own software that the machine will run. Its primary goal is to prepare the system and hand control over to our kernel. We will start with the simpler BIOS boot process.

Objective: To create a bootloader that transitions the CPU into a modern 64-bit state and loads our kernel from disk.

Key Tasks:

16-bit "Hello, World" (Real Mode):

Write a 512-byte boot sector in x86 assembly.

Use BIOS interrupt calls (int 0x10) to print a message to the screen.

This serves as the "smoke test" to confirm our build system and emulator are working correctly.

Transition to 32-bit (Protected Mode):

The original BIOS environment is 16-bit and has a 1MB memory limit. To access more memory, we must enter Protected Mode.

This requires setting up a Global Descriptor Table (GDT). The GDT defines memory segments for code and data, which is a legacy requirement for entering a 64-bit state.

Transition to 64-bit (Long Mode):

This is the standard operating mode for modern x86-64 CPUs.

This transition requires setting up Paging. We will create a basic set of page tables (PML4, PDPT, etc.) to identity-map the first few megabytes of physical memory, allowing our code to continue executing after paging is enabled.

Kernel Loading:

The final job of the bootloader. It will read the kernel from a known location on the disk (we'll embed it directly in our image initially) into a specific memory address.

Once loaded, the bootloader will perform a final jump to the kernel's entry point, officially handing off control.

Stage 2: The Kernel - The Core of the System
The kernel is the heart of DurhamOS. It manages all system resources and provides the fundamental services upon which everything else is built. We will write the kernel primarily in C.

Objective: To build a foundational kernel that can manage interrupts, memory, and basic hardware.

Key Tasks:

Kernel Entry & Screen Output:

Create the C entry point for the kernel (kmain).

Write a simple VGA text-mode driver to print to the screen. Since BIOS interrupts are unavailable in 64-bit Long Mode, we must interact directly with video memory (0xB8000).

Interrupt and Exception Handling:

Set up an Interrupt Descriptor Table (IDT). The IDT tells the CPU where to find the handler code when an interrupt or exception occurs (e.g., keyboard press, timer tick, or a "division by zero" error).

Implement basic exception handlers that print an error message. This is invaluable for debugging.

Memory Management:

Physical Memory Manager (PMM): Write a "frame allocator" to keep track of all usable physical RAM in the system, page by page. A bitmap-based allocator is a common and effective approach.

Virtual Memory Manager (VMM): Implement functions to manage the page tables created by the bootloader. This will allow the kernel to map and unmap pages of memory, which is the foundation for creating separate address spaces for user processes.

Kernel Heap: Create kmalloc() and kfree() functions. This allows the kernel to dynamically allocate memory for its own internal structures, just like malloc in a regular C program.

Initial Device Drivers:

Programmable Interval Timer (PIT): Configure the system timer to fire interrupts at a regular frequency. This is the heartbeat of the OS and will be essential for process scheduling.

PS/2 Keyboard Driver: Write a driver to handle keyboard interrupts and read scancodes, allowing for user input.

Serial Port Driver: A simple driver to send text to the serial port. This is a powerful debugging tool, as QEMU can redirect the serial output to your host terminal.

Stage 3: Userspace and Concurrency
With a stable kernel, the next step is to run programs outside of the kernel in a restricted "user mode."

Objective: To enable the loading and execution of independent user programs and to schedule multiple tasks concurrently.

Key Tasks:

System Calls:

Design and implement a system call interface. This is the only way a user program can request services (like writing to the screen) from the kernel. We can use the syscall instruction for this.

Process Management:

Define a simple executable file format (e.g., a subset of ELF, or a custom format).

Write the kernel logic to load a program from a disk/ramdisk, set up its own virtual address space, and prepare it for execution.

Create the first user-mode process and jump to it.

Scheduling:

Implement a simple, preemptive round-robin scheduler. The PIT interrupt handler will be used to trigger a "context switch," saving the state of the current task and restoring the state of the next, creating the illusion of parallel execution.

Minimal C Standard Library (libc):

Begin creating a custom libc for DurhamOS. This library will contain functions like printf(), malloc(), and exit(), which will translate these high-level requests into system calls for the kernel.

Stage 4: Advanced Features and Custom Tooling
Once the core OS is functional, we can expand its capabilities and begin work on the custom programming language and its ecosystem.

Objective: To add a filesystem, a shell, and begin development of the DurhamOS Programming Language (DPL) and its compiler.

Key Tasks:

Filesystems:

Implement an Initial RAM Disk (initramfs). This allows us to bundle user programs and data with the kernel in a single image.

Later, write a driver for a simple on-disk filesystem like FAT32.

The DurhamOS Shell:

Create a simple command-line interpreter that runs as a user program. It will use system calls to display a prompt, read keyboard input, and request that the kernel launch other programs.

The DurhamOS Programming Language (DPL) & Compiler:

Phase 1: Language Design. Define the syntax, features, and type system of DPL.

Phase 2: Lexer & Parser. Use tools like flex and bison (or write them by hand) to convert source code into an Abstract Syntax Tree (AST).

Phase 3: Code Generation. Traverse the AST and generate x86-64 assembly code.

Phase 4: Integration. The compiler will eventually produce executables in the format our kernel understands, making DPL a native language for DurhamOS.

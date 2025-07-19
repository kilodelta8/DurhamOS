; =============================================================================
; DurhamOS Stage 2 Bootloader
;
; This code is loaded by Stage 1 and is responsible for all the heavy lifting:
; - Switching to Protected Mode
; - Switching to Long Mode
; - Loading the C kernel
; =============================================================================

bits 16

; =============================================================================
; Constants
; =============================================================================
PAGE_TABLES_START equ 0x9000    ; Physical address to build our page tables
KERNEL_TEMP_ADDR  equ 0x10000   ; Safe, temporary address to load kernel to
KERNEL_LOAD_ADDR  equ 0x100000  ; Final physical address for the kernel

stage2_start:
    ; We are loaded at 0x8000 by Stage 1.
    ; The boot drive number is at 0x7DFE (set by Stage 1)
    mov [boot_drive], dl

    ; --- Enable A20 Gate ---
    in al, 0x92
    or al, 2
    out 0x92, al

    ; --- Switch to Protected Mode ---
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG_32:protected_mode_start

; =============================================================================
; 32-bit Protected Mode Code
; =============================================================================
bits 32
protected_mode_start:
    mov ax, DATA_SEG_32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- Load the kernel using a simple CHS read ---
    ; We are now in Protected Mode, but we can temporarily switch back
    ; to call the 16-bit BIOS. This is complex, so for now we will
    ; assume Stage 1 has already loaded the kernel for us.
    ; In a real scenario, we would load the kernel here.
    ; For now, we proceed as if it's already at KERNEL_TEMP_ADDR.
    
    ; --- Copy kernel from temporary location to its final destination ---
    call copy_kernel

    ; --- Now proceed with setting up for Long Mode ---
    call setup_paging

    lgdt [gdt_descriptor]
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    mov eax, PAGE_TABLES_START
    mov cr3, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 0
    mov cr0, eax

    ; --- Set up a hardcoded stack for our 64-bit C Kernel ---
    mov esp, 0x200000

    ; --- JUMP TO THE KERNEL ---
    jmp CODE_SEG_64:KERNEL_LOAD_ADDR

; =============================================================================
; Subroutines
; =============================================================================

; --- Copy kernel from temporary to final address ---
copy_kernel:
    mov esi, KERNEL_TEMP_ADDR
    mov edi, KERNEL_LOAD_ADDR
    mov ecx, (50 * 512) / 4
    rep movsd
    ret

; --- Setup Page Tables ---
setup_paging:
    mov edi, PAGE_TABLES_START
    mov ecx, 4096 * 4
    xor eax, eax
    rep stosb
    mov edi, PAGE_TABLES_START
    lea eax, [edi + 4096]
    or eax, 0b11
    mov [edi], eax
    add edi, 4096
    lea eax, [edi + 4096]
    or eax, 0b11
    mov [edi], eax
    add edi, 4096
    mov eax, 0x00000000
    or eax, 0b10000011
    mov [edi], eax
    ret

; =============================================================================
; Global Descriptor Table (GDT)
; =============================================================================
gdt_start:
    dd 0, 0
.code_32: dw 0xFFFF, 0x0000, 0x009A00, 0x00CF
.data_32: dw 0xFFFF, 0x0000, 0x009200, 0x00CF
.code_64: dw 0x0000, 0x0000, 0x009A00, 0x00AF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG_32 equ gdt_start.code_32 - gdt_start
DATA_SEG_32 equ gdt_start.data_32 - gdt_start
CODE_SEG_64 equ gdt_start.code_64 - gdt_start

boot_drive: db 0

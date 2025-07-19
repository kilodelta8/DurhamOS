; =============================================================================
; DurhamOS Bootloader (Definitive Single-Stage Version)
;
; This bootloader correctly initializes the hardware, loads the kernel to a
; safe low-memory area using a reliable CHS read, then switches to
; 64-bit long mode and hands off control.
; =============================================================================

org 0x7C00
bits 16

; =============================================================================
; Constants
; =============================================================================
KERNEL_TEMP_ADDR  equ 0x10000   ; Safe, temporary address to load kernel to
KERNEL_LOAD_ADDR  equ 0x100000  ; Final physical address for the kernel
PAGE_TABLES_START equ 0x9000    ; Physical address to build our page tables

start:
    ; --- Set up all segment registers and a safe stack immediately ---
    cli
    mov ax, cs      ; The BIOS loads us at 0000:7C00, so CS is 0.
    mov ds, ax      ; Set Data Segment to match
    mov es, ax      ; Set Extra Segment to match
    mov ss, ax      ; Set Stack Segment to match
    mov sp, 0x7C00  ; Stack grows downwards from our load address.
    sti

    mov [boot_drive], dl ; Save the boot drive number

    ; --- Print loading message ---
    mov si, msg_loading
    call print_string

    ; --- Load the Kernel from disk (INLINE) ---
    mov ax, KERNEL_TEMP_ADDR / 16
    mov es, ax
    mov bx, 0

    mov ah, 0x02
    mov al, 50
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; --- Print success message ---
    mov si, msg_read_ok
    call print_string

    ; --- Enable the A20 Line ---
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
    ; --- DIAGNOSTIC TEST ---
    ; This code replaces the entire long mode transition. Its only job is to
    ; prove that we have successfully entered 32-bit Protected Mode.
    ; If the screen turns blue, the GDT and the jump were successful.
    mov ax, DATA_SEG_32
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov edi, 0xb8000 ; VGA memory address
    mov ecx, 80 * 25 ; Total number of screen characters
    mov eax, 0x1F201F20 ; Blue background, white space, write two at a time
.clear_loop:
    mov [edi], eax
    add edi, 4
    sub ecx, 2
    jnz .clear_loop

    ; If we see a blue screen, we have succeeded. Hang the system.
    jmp $

; =============================================================================
; Subroutines
; =============================================================================
bits 32
copy_kernel:
    mov esi, KERNEL_TEMP_ADDR
    mov edi, KERNEL_LOAD_ADDR
    mov ecx, (50 * 512) / 4
    rep movsd
    ret

bits 16
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

disk_error:
    mov si, msg_error
    call print_string
    jmp $

bits 32
setup_paging:
    mov edi, PAGE_TABLES_START
    mov ecx, 4096 * 3
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
; GDT and Data
; =============================================================================
bits 16
gdt_start:
    ; Null descriptor (required)
    dq 0

    ; 32-bit Code Segment (Ring 0)
.code_32:
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0b10011010   ; Access byte
    db 0b11001111   ; Granularity + Limit (high)
    db 0x00         ; Base (high)

    ; 32-bit Data Segment (Ring 0)
.data_32:
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0b10010010   ; Access byte
    db 0b11001111   ; Granularity
    db 0x00         ; Base (high)

    ; 64-bit Code Segment (Ring 0)
.code_64:
    dw 0x0000       ; Limit (low) - Ignored in 64-bit
    dw 0x0000       ; Base (low) - Ignored in 64-bit
    db 0x00         ; Base (mid) - Ignored in 64-bit
    db 0b10011010   ; Access byte
    db 0b10101111   ; Granularity (L-bit for 64-bit)
    db 0x00         ; Base (high) - Ignored in 64-bit
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG_32 equ gdt_start.code_32 - gdt_start
DATA_SEG_32 equ gdt_start.data_32 - gdt_start
CODE_SEG_64 equ gdt_start.code_64 - gdt_start

boot_drive: db 0
msg_loading: db 'Loading DurhamOS Kernel...', 0x0D, 0x0A, 0
msg_read_ok: db 'Disk read successful!', 0x0D, 0x0A, 0
msg_error:   db 'Disk read error!', 0

times 510 - ($ - $$) db 0
dw 0xAA55

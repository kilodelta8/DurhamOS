; =============================================================================
; DurhamOS Stage 1 Bootloader
;
; This code now transitions the CPU from 16-bit Real Mode, through 32-bit
; Protected Mode, and finally into 64-bit Long Mode.
; =============================================================================

org 0x7C00
bits 16

; =============================================================================
; Constants
; =============================================================================
PAGE_TABLES_START equ 0x9000 ; Physical address to build our page tables

start:
    ; --- Setup Data Segments ---
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; --- Print our initial "Hello" message in Real Mode ---
    mov si, msg_hello_16
    call print_string_16

    ; --- Check for Long Mode support ---
    call check_long_mode
    
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
    ; --- Setup Data Segments for Protected Mode ---
    mov ax, DATA_SEG_32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- Print confirmation message ---
    mov esi, msg_hello_32
    mov edi, 0xb8000 + (80 * 2 * 1) ; Print on the second line
    call print_string_32

    ; --- Setup Page Tables for Long Mode ---
    call setup_paging

    ; --- Switch to Long Mode ---
    ; 1. Load the new GDT with a 64-bit code segment
    lgdt [gdt_descriptor]
    
    ; 2. Enable Physical Address Extension (PAE)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; 3. Load the top-level page table (PML4) address
    mov eax, PAGE_TABLES_START ; Use our constant
    mov cr3, eax

    ; 4. Enable Long Mode in the Extended Feature Enable Register (EFER)
    mov ecx, 0xC0000080  ; EFER MSR address
    rdmsr               ; Read EFER into EDX:EAX
    or eax, 1 << 8      ; Set the Long Mode Enable (LME) bit
    wrmsr               ; Write it back

    ; 5. Enable Paging (this also activates Long Mode)
    mov eax, cr0
    or eax, 1 << 31     ; Set the Paging (PG) bit
    or eax, 1 << 0      ; Ensure Protection Enable (PE) is still set
    mov cr0, eax

    ; 6. Far jump to our 64-bit code segment
    jmp CODE_SEG_64:long_mode_start

; =============================================================================
; 64-bit Long Mode Code
; =============================================================================
bits 64
long_mode_start:
    ; --- Print confirmation message ---
    mov rsi, msg_hello_64
    mov rdi, 0xb8000 + (80 * 2 * 2) ; Print on the third line
    call print_string_64

    ; --- Hang the system ---
    hlt ; Use hlt (halt) in 64-bit mode, it's more power efficient

; =============================================================================
; Subroutines
; =============================================================================

; --- 16-bit print function ---
bits 16
print_string_16:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; --- 32-bit print function ---
bits 32
print_string_32:
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0F
    mov [edi], ax
    add edi, 2
    jmp .loop
.done:
    ret

; --- 64-bit print function ---
bits 64
print_string_64:
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0A ; Light green on black
    mov [rdi], ax
    add rdi, 2
    jmp .loop
.done:
    ret

; --- Check for Long Mode support using cpuid ---
bits 16
check_long_mode:
    pusha
    mov eax, 0x80000000 ; Check for extended function support
    cpuid
    cmp eax, 0x80000001 ; Must support at least this level
    jb .no_long_mode    ; If not, long mode is not available

    mov eax, 0x80000001 ; Get extended feature bits
    cpuid
    test edx, 1 << 29   ; Test bit 29 (LM bit)
    jz .no_long_mode    ; If not set, no long mode

    popa
    ret

.no_long_mode:
    mov si, msg_no_long_mode
    call print_string_16
    jmp $

; --- Setup Page Tables ---
bits 32
setup_paging:
    ; We will identity map the first 2MB of memory.
    ; This requires one PML4 entry, one PDPT entry, and one PD entry.
    ; The PD entry will point to a 2MB large page.
    
    ; Location of our tables
    mov edi, PAGE_TABLES_START ; Use our constant

    ; Clear the page table memory
    mov ecx, 4096 * 3 ; 3 tables, 4KB each
    xor eax, eax
    rep stosb

    ; PML4[0] -> PDPT
    mov edi, PAGE_TABLES_START
    lea eax, [edi + 4096] ; Address of PDPT
    or eax, 0b11 ; Present, Read/Write
    mov [edi], eax

    ; PDPT[0] -> PD
    add edi, 4096
    lea eax, [edi + 4096] ; Address of PD
    or eax, 0b11 ; Present, Read/Write
    mov [edi], eax

    ; PD[0] -> 2MB Page
    add edi, 4096
    mov eax, 0x00000000 ; Physical address of the page
    or eax, 0b10000011 ; Present, Read/Write, Large Page (2MB)
    mov [edi], eax

    ret

; =============================================================================
; Global Descriptor Table (GDT)
; =============================================================================
gdt_start:
    ; Null Descriptor
    dd 0, 0

    ; 32-bit Code Segment
.code_32:
    dw 0xFFFF, 0x0000, 0x009A00, 0x00CF

    ; 32-bit Data Segment
.data_32:
    dw 0xFFFF, 0x0000, 0x009200, 0x00CF

    ; 64-bit Code Segment (L-bit set)
.code_64:
    dw 0x0000, 0x0000, 0x009A00, 0x00AF

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start ; dq = define quad word (8 bytes) for 64-bit address

CODE_SEG_32 equ gdt_start.code_32 - gdt_start
DATA_SEG_32 equ gdt_start.data_32 - gdt_start
CODE_SEG_64 equ gdt_start.code_64 - gdt_start

; =============================================================================
; Data and Boot Signature
; =============================================================================
msg_hello_16: db 'Hello from 16-bit Real Mode!', 0x0D, 0x0A, 0
msg_hello_32: db 'Hello from 32-bit Protected Mode!', 0
msg_hello_64: db 'SUCCESS! Now in 64-bit Long Mode!', 0
msg_no_long_mode: db 'Error: CPU does not support 64-bit Long Mode.', 0

times 510 - ($ - $$) db 0
dw 0xAA55
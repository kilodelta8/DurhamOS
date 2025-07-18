; =============================================================================
; DurhamOS Stage 1 Bootloader
;
; This code now transitions the CPU from 16-bit Real Mode to 32-bit
; Protected Mode.
; =============================================================================

org 0x7C00      ; The BIOS loads us at this address.
bits 16         ; We start in 16-bit Real Mode.

start:
    ; --- Setup Data Segments ---
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; --- Print our initial "Hello" message in Real Mode ---
    mov si, msg_hello
    call print_string_16

    ; --- Enable A20 Gate ---
    ; The A20 line must be enabled to access memory above the first megabyte.
    ; Failing to do this before entering Protected Mode is a common cause of
    ; system hangs on some hardware and emulators. We use the "fast gate"
    ; method via port 0x92, which is supported by most modern systems.
    in al, 0x92     ; Read the current value of port 0x92.
    or al, 2        ; Set bit 1 (the A20 enable bit).
    out 0x92, al    ; Write the new value back to the port.

    ; --- Switch to Protected Mode ---
    cli             ; 1. Clear interrupts. We must not be interrupted.
    lgdt [gdt_descriptor] ; 2. Load the GDT descriptor.
    
    mov eax, cr0    ; 3. Get the control register 0.
    or eax, 1       ; 4. Set the Protection Enable (PE) bit.
    mov cr0, eax    ; 5. Write it back. We are now in Protected Mode!

    ; 6. Far jump to flush the CPU pipeline and load our new code segment.
    jmp CODE_SEG:protected_mode_start

; =============================================================================
; 16-bit Subroutines (Real Mode)
; =============================================================================
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

; =============================================================================
; Global Descriptor Table (GDT)
; =============================================================================
gdt_start:
    ; Null Descriptor (required)
    dd 0    ; dd = define double word (4 bytes)
    dd 0

    ; Code Segment Descriptor (Base=0, Limit=0xFFFFF, Ring 0, 32-bit)
    ; Limit (bits 0-15)
    dw 0xFFFF
    ; Base (bits 0-15)
    dw 0x0000
    ; Base (bits 16-23)
    db 0x00
    ; Access Byte: Present(1), Ring 0(00), Type(1), Executable(1), Dir(0), RW(1), Accessed(0)
    db 0b10011010 
    ; Flags (Granularity(1), 32-bit(1)) + Limit (bits 16-19)
    db 0b11001111 
    ; Base (bits 24-31)
    db 0x00

    ; Data Segment Descriptor (Base=0, Limit=0xFFFFF, Ring 0, 32-bit)
    ; Same as code segment, but with a different access byte.
    dw 0xFFFF
    dw 0x0000
    db 0x00
    ; Access Byte: Present(1), Ring 0(00), Type(1), Executable(0), Dir(0), RW(1), Accessed(0)
    db 0b10010010
    db 0b11001111
    db 0x00

gdt_end:

; GDT Descriptor (a pointer to the GDT itself)
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of the GDT
    dd gdt_start                ; Start address of the GDT

; GDT segment selectors (offsets into the GDT)
CODE_SEG equ 0x08 ; Offset of the code segment (8 bytes from the start)
DATA_SEG equ 0x10 ; Offset of the data segment (16 bytes from the start)

; =============================================================================
; 32-bit Protected Mode Code
; =============================================================================
bits 32
protected_mode_start:
    ; --- Setup Data Segments for Protected Mode ---
    ; We must load our data segment selectors into the segment registers.
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- Print a confirmation message in Protected Mode ---
    ; We can no longer use BIOS interrupts. We must write to video memory directly.
    mov esi, msg_protected
    mov edi, 0xb8000 ; Video memory starts here.
    call print_string_32

    ; --- Hang the system ---
    jmp $ ; The '$' symbol means "this current address". Infinite loop.

; =============================================================================
; 32-bit Subroutine: print_string_32
; Prints a null-terminated string by writing to VGA memory.
; Input: ESI must point to the string, EDI must point to video memory location.
; =============================================================================
print_string_32:
.loop:
    lodsb           ; Load byte from [ESI] into AL, and increment ESI.
    cmp al, 0
    je .done
    
    mov ah, 0x0A    ; Attribute byte: White text on Black background.
    mov [edi], ax   ; Write the character and attribute to video memory.
    
    add edi, 2      ; Move to the next character cell (2 bytes).
    jmp .loop
.done:
    ret

; =============================================================================
; Data Section
; =============================================================================
msg_hello:
    db 'Hello from 16-bit Real Mode!', 0x0D, 0x0A, 0

msg_protected:
    db 'Successfully switched to 32-bit Protected Mode!', 0

; =============================================================================
; Bootloader Signature
; =============================================================================
times 510 - ($ - $$) db 0
dw 0xAA55
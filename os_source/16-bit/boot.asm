; =============================================================================
; DurhamOS Stage 1 Bootloader
;
; This code runs in 16-bit Real Mode and is the first code executed by the
; CPU after the BIOS hands off control. Its only job is to print a message
; to the screen to verify that our toolchain and boot process work.
; =============================================================================

org 0x7C00      ; The BIOS loads the bootloader at this memory address.
bits 16         ; We are in 16-bit Real Mode.

start:
    ; --- Setup Data Segments ---
    ; We can't assume the segment registers are set up for us, so we
    ; set DS (Data Segment) to the same address as CS (Code Segment).
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; --- Print the "Hello" message using a BIOS interrupt ---
    ; BIOS video teletype interrupt: int 0x10
    ;  - AH = 0x0E (function: write character in teletype mode)
    ;  - AL = The character to print
    ;  - BH = Page number (usually 0)
    ;  - BL = Color (not needed in teletype mode)
    mov si, msg_hello   ; SI (Source Index) points to our message string.
    call print_string   ; Call our printing subroutine.

    ; --- Hang the system ---
    ; The bootloader's job is done. We put the CPU in an infinite loop
    ; to prevent it from executing random memory.
hang:
    jmp hang

; =============================================================================
; Subroutine: print_string
; Prints a null-terminated string to the screen via BIOS interrupt 0x10.
; Input: SI must point to the start of the string.
; =============================================================================
print_string:
    mov ah, 0x0E        ; Set BIOS function to "teletype output".
.loop:
    lodsb               ; Load byte from [SI] into AL, and increment SI.
    cmp al, 0           ; Is the character a null terminator (0)?
    je .done            ; If so, we are finished.
    int 0x10            ; Otherwise, call the BIOS video interrupt to print it.
    jmp .loop           ; Repeat for the next character.
.done:
    ret                 ; Return from the subroutine.

; =============================================================================
; Data Section
; =============================================================================
msg_hello:
    db 'Hello, DurhamOS!', 0x0D, 0x0A, 0   ; The string to print.
                                          ; 0x0D = Carriage Return
                                          ; 0x0A = Line Feed
                                          ; 0    = Null terminator

; =============================================================================
; Bootloader Signature
; The BIOS requires the boot sector to be exactly 512 bytes long and to
; end with the magic number 0xAA55.
; =============================================================================
times 510 - ($ - $$) db 0   ; Pad the rest of the file with zeros.
dw 0xAA55                   ; The magic boot signature.
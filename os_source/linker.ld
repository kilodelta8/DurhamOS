/*
 * DurhamOS Linker Script
 *
 * Defines the memory layout for our kernel executable.
 */

ENTRY(kmain) /* The name of the entry point function */

SECTIONS {
    /* The kernel will be loaded at 1MB (0x100000) */
    . = 0x100000;

    /* The executable code */
    .text : {
        *(.text)
    }

    /* Read-only data */
    .rodata : {
        *(.rodata)
    }

    /* Initialized data */
    .data : {
        *(.data)
    }

    /* Uninitialized data (BSS) */
    .bss : {
        *(.bss)
    }
}
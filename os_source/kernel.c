// =============================================================================
// DurhamOS Kernel - Stage 2
//
// A simple C-based kernel that runs in 64-bit Long Mode.
// =============================================================================

// A pointer to the video memory buffer.
// The buffer is 80 columns by 25 rows, with 2 bytes per character.
// The volatile keyword prevents the compiler from optimizing away our writes.
volatile unsigned char* const VIDEO_MEMORY = (unsigned char*)0xb8000;

// The entry point for our kernel.
// The bootloader will jump to this function.
void kmain() {
    const char* message = "Welcome to DurhamOS! We are now running C code in a 64-bit Kernel.";
    unsigned int message_pos = 0;
    unsigned int video_pos = 0;

    // Clear the screen by writing a space character with a black background
    // and white foreground to each cell.
    for (int i = 0; i < 80 * 25; ++i) {
        VIDEO_MEMORY[video_pos++] = ' ';      // Character
        VIDEO_MEMORY[video_pos++] = 0x0F;     // Attribute: White on Black
    }

    // Reset video position to the top left.
    video_pos = 0;

    // Print our welcome message.
    while (message[message_pos] != 0) {
        VIDEO_MEMORY[video_pos++] = message[message_pos++]; // Character
        VIDEO_MEMORY[video_pos++] = 0x0A; // Attribute: Light Green on Black
    }

    // Hang the system.
    while (1) {}
}
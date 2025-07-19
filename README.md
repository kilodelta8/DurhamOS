Stage 0 (Revised): Setting Up a Clean Development Environment
This guide will help you set up a well-structured environment on Ubuntu/Debian for OS development.

Step 1: Install Core Dependencies
First, update your system and install the essential packages.

Bash  
`sudo apt update && sudo apt upgrade`  
`sudo apt install build-essential nasm qemu-system-x86 xorriso libgmp-dev libmpfr-dev libmpc-dev texinfo bison flex`

Step 2: Create an Organized Directory Structure
We will create a main project folder, and inside it, we'll have separate directories for our toolchain and our OS source code.

Bash  
`mkdir ~/durhamos_project`  
`cd ~/durhamos_project`  
`mkdir toolchain       # For downloading and building the compiler`  
`mkdir os_source       # Where your actual OS code will live`  
`mkdir toolchain/src   # To store the downloaded source code for binutils/gcc`  

Step 3: Set Up Environment Variables
These variables will point to our new directories.

Bash  
`export TARGET=x86_64-elf`  
`export PREFIX="$HOME/durhamos_project/cross_compiler"`  
`export PATH="$PREFIX/bin:$PATH"`

Pro-Tip: To make these variables permanent, add the three export lines above to the end of your ~/.bashrc file. Then, run source ~/.bashrc or open a new terminal for the changes to take effect.

Step 4: Build and Install the Cross-Compiler
We'll perform the downloads and builds inside the toolchain directory.

4a. Build Binutils
Bash  
`# Navigate to the toolchain source directory`  
`cd ~/durhamos_project/toolchain/src`  

`# Download Binutils`  
`wget https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz`  
`tar -xf binutils-2.38.tar.xz`  

`# Now, create a separate build directory`  
`cd .. # Go up to ~/durhamos_project/toolchain`  
`mkdir build-binutils`  
`cd build-binutils`  

`# Configure the build`  
`../src/binutils-2.38/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror`  

`# Compile and install`  
`make`  
`make install`  

4b. Build GCC
Bash  
`# Navigate back to the toolchain source directory`  
`cd ~/durhamos_project/toolchain/src`  

`# Download GCC`  
`wget https://ftp.gnu.org/gnu/gcc/gcc-11.3.0/gcc-11.3.0.tar.xz`  
`tar -xf gcc-11.3.0.tar.xz`  

`# Create a separate build directory for GCC`  
`cd .. # Go up to ~/durhamos_project/toolchain`  
`mkdir build-gcc`  
`cd build-gcc`  

`# Configure the build (note the --without-headers flag)`  
`../src/gcc-11.3.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers`  

`# Compile and install GCC and its support library (libgcc)`  
`make all-gcc`  
`make all-target-libgcc`  
`make install-gcc`  
`make install-target-libgcc`  

Step 5: Verification
After the build completes, verify that the new cross-compiler is installed and accessible.

Bash  
`x86_64-elf-gcc --version`  

You should see the output:  
`x86_64-elf-gcc (GCC) 11.3.0`  

...  

Your environment is now fully configured with a clean, organized structure. All your OS development will happen inside ~/durhamos_project/os_source, and your purpose-built compiler is ready to use.


================================================================================================
================================================================================================



Stage 1, Task 1: "Hello, World" in 16-bit Real Mode
Here's the plan:

Navigate to our OS source directory: `~/durhamos_project/os_source`.  

Create a new file named `boot.asm`. This will contain our assembly code.  

Create a Makefile to automate assembling boot.asm and running it in QEMU.  



Instructions
Save the Files: In your `~/durhamos_project/os_source` directory, create `boot.asm` and `Makefile`.

Run the Makefile: Open your terminal in the os_source directory and simply type:

Bash    
`make`  

You can also use `make run`, which does the same thing.


If everything is set up correctly, you will see a QEMU window appear. 
Inside that window, at the very top left, you should see the text:

`Hello, DurhamOS!`  

This simple message is a huge milestone. It proves that you have successfully:
Written valid 16-bit assembly code.
Assembled it into a binary file.
Created a valid boot sector that the BIOS recognizes.
Packaged it into a disk image.
Booted your machine (the QEMU emulator) from that disk.



================================================================================================
================================================================================================
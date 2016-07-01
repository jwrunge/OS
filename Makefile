#Auto generate lists of sources using wildcards
C_SOURCES = $(wildcard kernel/*.c drivers/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h)

#Convert the *.c filenames to *.o to give a list of object files to build
OBJ = ${C_SOURCES:.c=.o}

#Default make target
all: os-image

#Make and run
run: all
	qemu-system-i386 os-image | remmina --connect="/home/jake/.remmina/1467131326034.remmina"
	
#Make os-image
os-image: boot/boot.bin kernel/kernel.bin boot/filler.bin
	cat $^ > os-image
	
#Build the kernel binary ($^ means "all dependencies listed above"
kernel/kernel.bin: kernel/kernel_entry.o ${OBJ}
	ld -o kernel/kernel.bin -Ttext 0x1000 $^ --oformat binary
	
#Generic rule for compiling C code to an object file
#All C files depend on all header files
%.o: %.c ${HEADERS}
	gcc -ffreestanding -c $< -o $@
	
#Assemble the kernel entry
%.o: %.asm
	nasm $< -f elf -o $@
	
%.bin: %.asm
	nasm $< -f bin -I './functions/' -o $@
	
#Clean
clean:
	rm boot/*.bin kernel/*.bin boot/*.o kernel/*.o os-image

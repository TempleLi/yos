Asm = nasm
AsmBootFlags = -I boot/include/ # the / is very important
AsmKernelFlags = -I include/ -f elf
Boot    = boot/boot.bin boot/loader.bin
Kernel  = kernel.bin
EntryPoint=0x30400
KObjs = kernel/kernel.o kernel/start.o lib/kliba.o lib/string.o

.PHONY : boot kernel clean install

boot: boot/boot.bin boot/loader.bin
kernel: kernel/kernel.bin
clean:
	rm -f lib/*.o
	rm -f kernel/*.o
	rm -f kernel/*.bin
	rm -f boot/*.o
	rm -f boot/*.bin

install: boot/boot.bin boot/loader.bin kernel/kernel.bin
	cp backup.img a.img
	python3 disk_writer.py -image a.img -bin boot/boot.bin  -offset 0
	python3 disk_writer.py -image a.img -bin boot/loader.bin  -offset 10
	python3 disk_writer.py -image a.img -bin kernel/kernel.bin  -offset  20

everything : $(Boot)

all : clean everything

boot/boot.bin : boot/boot.asm boot/include/pm.inc boot/include/util.asm
	$(Asm) $(AsmBootFlags) -o $@ $<
boot/loader.bin : boot/loader.asm boot/include/pm.inc boot/include/util.asm
	$(Asm) $(AsmBootFlags) -o $@ $<

kernel/kernel.bin: $(KObjs)
	ld -m elf_i386 -s -Ttext $(EntryPoint) -o kernel/kernel.bin $(KObjs)

kernel/kernel.o : kernel/kernel.asm
	$(Asm) $(AsmKernelFlags) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/const.h include/protect.h
	gcc -m32 -I include/ -c -o $@ $< 

lib/kliba.o : lib/kliba.asm
	$(Asm) $(AsmKernelFlags) -o $@ $<

lib/string.o : lib/string.asm
	$(Asm) $(AsmKernelFlags) -o $@ $<

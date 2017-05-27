all: obj example1

obj:
	mkdir obj

example1:
	sdasz80 -plosgff obj/example1.rel src/example1.asm
	sdldz80 -mjwxi -b _CODE=0x1000 obj/example1.ihx  obj/example1.rel
	sdobjcopy -Iihex -Obinary  obj/example1.ihx  obj/example1.bin
	hexdump -C obj/example1.bin

z9001:
	sdasz80 -plosgff obj/z9001.rel src/z9001.asm
	sdldz80 -mjwxi -b _CODE=0x300 obj/z9001.ihx  obj/z9001.rel
	sdobjcopy -Iihex -Obinary  obj/z9001.ihx  obj/z9001.bin
	hexdump -C obj/z9001.bin

	

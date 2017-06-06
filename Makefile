all: obj example1

.PHONY: isr clean

obj:
	mkdir obj

#assemble und berechne taktzyklen
isr: obj/isr_test.bin

obj/isr_test.bin: src/isr_test.asm
	sdasz80 -plosgff $(@:bin=rel) $<
	sdldz80 -mjwxi -b _CODE=0x0300 $(@:bin=ihx) $(@:bin=rel)
	sdobjcopy -Iihex -Obinary  $(@:bin=ihx)  $@
	cat $(@:bin=lst)

example1:
	sdasz80 -plosgff obj/example1.rel src/example1.asm
	sdldz80 -mjwxi -b _CODE=0x1000 obj/example1.ihx  obj/example1.rel
	sdobjcopy -Iihex -Obinary  obj/example1.ihx  obj/example1.bin
	hexdump -C obj/example1.bin

isr_example:
	

z9001:
	sdasz80 -plosgff obj/z9001.rel src/z9001.asm
	sdldz80 -mjwxi -b _CODE=0x300 obj/z9001.ihx  obj/z9001.rel
	sdobjcopy -Iihex -Obinary  obj/z9001.ihx  obj/z9001.bin
	hexdump -C obj/z9001.bin

clean:
	rm -rf obj

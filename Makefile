all: obj example1

.PHONY: isr clean tools

obj:
	mkdir obj

#assemble und berechne taktzyklen
isr: obj/isr_test.bin

z9001: tools obj/z9001.kcc obj/z9001.wav 

tools: obj obj/kcc2wav

obj/kcc2wav: src/kcc2wav.c
	gcc -Wall $< -o $@

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

obj/z9001.kcc: src/z9001.asm src/header_z9001.asm
	sdasz80 -plosgff obj/header_z9001.rel src/header_z9001.asm
	sdasz80 -plosgff $(@:kcc=rel) $<
	sdldz80 -mjwxi -b _KCC_HEADER=0x280 -b _CODE=0x0300 $(@:kcc=ihx) obj/header_z9001.rel $(@:kcc=rel)
	sdobjcopy -Iihex -Obinary  $(@:kcc=ihx)  $@
	printf "%.8s" "HSAVE2" >obj/filename.txt
	dd bs=1 if=obj/filename.txt of="$@" count=8 seek=0 conv=notrunc,ucase

obj/%.wav: obj/%.kcc
	obj/kcc2wav $< $@

clean:
	rm -rf obj

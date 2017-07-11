all: example1 z9001 kc85 kc85mot

.PHONY: example1 z9001 isr clean tools kc85 kc85mot

obj:
	mkdir -p out
	mkdir -p obj/kc85
	mkdir -p obj/z9001

SDAS_OPT=-plowff

# SDASZ80 Optionen
# -p   Disable automatic listing pagination
# -l   Create list   file/outfile[.lst]
# -o   Create object file/outfile[.rel]
#      wichtig, ähnlich -c beim GCC
# -w   Wide listing format for symbol table
#      auch im .lst File  
#
# inaktiv:
# -g   Undefined symbols made global 
#      alle externen symbole müssen mittels .globl deklariert werden
#      hilft so Flüchtigkeitsfehler zu vermeiden
# -s   Create symbol file/outfile[.sym]

SDLD_OPT=-mwxiu
# SDLDZ80 Optionen
#Map format:
# -m   Map output generated as (out)file[.map]
# -w   Wide listing format for map file
# -x   Hexadecimal (default)
#Output:
# -i   Intel Hex as (out)file[.ihx]
#List:
# -u   Update listing file(s) with link data as file(s)[.rst]
#      sehr hilfreich!

kc85mot:  obj obj/kc85/SchaltTest.kcc

kc85:  obj obj/kc85/HeaderKC.kcc

z9001: obj obj/z9001/HeaderKC.kcc

tools: obj obj/kcc2wav

obj/kcc2wav: src/kcc2wav.c
	gcc -Wall $< -o $@

obj/isr_test.bin: src/isr_test.asm
	sdasz80 $(SDAS_OPT) $(@:bin=rel) $<
	sdldz80 -mjwxi -b _CODE=0x0300 $(@:bin=ihx) $(@:bin=rel)
	sdobjcopy -Iihex -Obinary  $(@:bin=ihx)  $@
	cat $(@:bin=lst)

obj/kc85/SchaltTest.kcc: obj/kc85/header.rel obj/kc85/schalttest.rel
	sdldz80 $(SDLD_OPT) -b _KCC_HEADER=0x180 -b _CODE=0x0200 $(@:kcc=ihx) $^
	sdobjcopy -Iihex -Obinary  $(@:kcc=ihx)  $@
	printf "%.8s" "MOT" >obj/kc85/filename2.txt
	dd bs=1 if=obj/kc85/filename2.txt of="$@" count=8 seek=0 conv=notrunc,ucase

offset:
	tools/calc_offset.pl
	
obj/kc85/HeaderKC.kcc: obj/kc85/header.rel obj/kc85/hsave_cmd.rel  obj/kc85/hsave.rel obj/kc85/hload.rel
	sdldz80 $(SDLD_OPT) -b _KCC_HEADER=0x7906 -b _CODE=0x7986 $(@:kcc=ihx) $^
	sdobjcopy -Iihex -Obinary  $(@:kcc=ihx)  $@
	printf "%.8s" "HSAVE4" >obj/kc85/filename.txt
	dd bs=1 if=obj/kc85/filename.txt of="$@" count=8 seek=0 conv=notrunc,ucase

obj/z9001/HeaderKC.kcc: obj/z9001/header.rel obj/z9001/hsave_cmd.rel obj/z9001/hload.rel obj/z9001/hsave.rel
	sdldz80 $(SDLD_OPT) -b _KCC_HEADER=0x280 -b _CODE=0x0300 $(@:kcc=ihx) $^
	sdobjcopy -Iihex -Obinary  $(@:kcc=ihx)  $@
	printf "%.8s" "HSAVE4" >obj/z9001/filename.txt
	dd bs=1 if=obj/z9001/filename.txt of="$@" count=8 seek=0 conv=notrunc,ucase

obj/z9001.kcc: src/z9001.asm src/header_z9001.asm
	sdasz80 -plosgff obj/header_z9001.rel src/header_z9001.asm
	sdasz80 -plosgff $(@:kcc=rel) $<
	sdldz80 -mjwxi -b _KCC_HEADER=0x280 -b _CODE=0x0300 $(@:kcc=ihx) obj/header_z9001.rel $(@:kcc=rel)
	sdobjcopy -Iihex -Obinary  $(@:kcc=ihx)  $@
	printf "%.8s" "HSAVE2" >obj/filename.txt
	dd bs=1 if=obj/filename.txt of="$@" count=8 seek=0 conv=notrunc,ucase

obj/%.rel: src/%.asm
	sdasz80 $(SDAS_OPT) $@ $<

obj/z9001/%.rel: src/common/%.asm src/z9001/config.inc
	sdasz80 -Isrc/z9001 $(SDAS_OPT) $@ $<

obj/kc85/%.rel: src/common/%.asm src/z9001/config.inc
	sdasz80 -Isrc/kc85 $(SDAS_OPT) $@ $<

out/%.wav: obj/%.kcc
	obj/kcc2wav $< $@

clean:
	rm -rf obj out

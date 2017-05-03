md obj
sdasz80 -plosgff obj/example1.rel src/example1.asm
sdldz80 -mjwxi -b _CODE=0x1000 obj/example1.ihx  obj/example1.rel
sdobjcopy -Iihex -Obinary  obj/example1.ihx  obj/example1.bin


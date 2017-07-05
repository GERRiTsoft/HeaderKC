;
; Einfügen in Kommandotabelle
;
    .area _CODE
    jp  run_hload
    .ascii 'HLOAD   '
    .db 0x00

    .area _CODE2
run_hload::
    ret

    .module hsave
    .include 'caos.inc'
    .include 'config.inc'

    .area _CODE
    .dw 0x7f7f
    .ascii 'HSAVE'
    .db 0x01
run_hsave::
   ; cp #0 ; keine Argumente
   ; jp nz, has_arguments
    ld de,#str_usage
    call cputs
has_arguments:
    ret

cputs:
    ld a,#1 ;setze Vordergrundfarbe
    ld (ARGN),a
cputs_next:
    ld a,(de)
    inc de
    or a
    ret z
    cp #0x14; Farbcode
    jr z,set_foreground_color
    call PV1
    .db FNCRT
    jr cputs_next
set_foreground_color:
    ld a,(de)
    push de
    ld l,a
    ld e,#3
    call PV1
    .db FNCOLORUP
    pop de
    inc de
    jr cputs_next

    .area _RODATA
timer_lookup:
    .db 28,57,117                            ;2.5 MHz    Z1013:2   MHz
    .db 14,(14*20357)/10000,(14*41786)/10000 ;2.5 MHz    Z1013:4   MHz
    .db 11,(11*20357)/10000,(11*41786)/10000 ;2.5 MHz    Z1013:5.1 MHz
    ;ab hier wird etwas geschummelt. Der kritische Pfad für das 0-Bit
    ;kann etwas verlängert werden z.B. von 10 auf 11
    .db 10,(10*20357)/10000,(10*41786)/10000 ;2.5 MHz    Z1013:5.6 MHz
LEN_TIMER_LOOKUP .equ (.-timer_lookup)/3

str_usage:
    .ascii 'HeaderKC Turbo V.'
    .include '../version.inc'
    .ascii '\n\r'
    .ascii '  Abspeichern im Z1013-Format\n\r\n\r'
    .ascii 'HSAVE \024\003AADR EADR \024\002[\024\003SADR\024\002] [\024\003Geschw.\024\002]\n\r'
    .ascii '\024\003AADR   - \024\006Anfangadresse oder \n\r'
    .ascii '         : letzten Vorgang wiederholen\n\r'
    .ascii '\024\003EADR   - \024\006Endadresse (letztes Byte!)\n\r'
    .ascii '\024\003SADR   - \024\006(optional) Startadresse\n\r'
    .ascii '\024\003Geschw.- \024\006(optional) 0-'
    .db LEN_TIMER_LOOKUP-1+0x30
    .ascii '\n\r'
    .ascii '         0 .. normal    Z1013 2.0MHz\n\r'
    .ascii '         1 .. turbo     Z1013 4.0MHz\n\r'
    .ascii '         2 .. usw.      Z1013 5.1MHz\n\r'
    .ascii '         3 ..           Z1013 5.6MHz\n\r'
    .ascii '\024\007Beispiele:\n\r'
    .ascii 'HSAVE :\n\r'
    .ascii 'HSAVE F000 F7FF\n\r'
    .asciz 'HSAVE F000 F7FF 0000 03\n\r\024\002'

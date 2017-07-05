        .module hsave
        .include 'config.inc'

        .globl prepare_arguments

        .area   _CODE2
run_hsave::
        call    prepare_arguments
        jr      c,header_prepared
        jp      z,show_usage_and_exit
        ld      (header_aadr),hl
        ld      (header_eadr),de
        ld      (header_sadr),bc
        ld      hl,#str_hsave4
        ld      de,#header_note
        ld      bc,#sizeof_str_hsave4
        ldir
        CPUTS_NEWLINE   str_typ
1$:
        GETCH
        cp      #' ' ; steuerzeichen
        jr      c,1$
        ld      (header_typ),a
        PUTCH
        CPUTS_APPEND    str_filename
        ld      de,#input_buffer
        ld      a,#sizeof_header_filename
        ld      (de),a
        INLINE
        ; TODO
        ; rest mit leerzeichen ausfuellen
        ; check CF Ende
        ld      hl,#header_3dots
        ld      a,#0xd3
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
header_prepared::
        xor     a
        ret

show_usage_and_exit:
        CPUTS_NEWLINE   str_usage
        xor     a
        ret

        .area   _RODATA
timer_lookup:
        .db 28,57,117                            ;2.5 MHz    Z1013:2   MHz
        .db 14,(14*20357)/10000,(14*41786)/10000 ;2.5 MHz    Z1013:4   MHz
        .db 11,(11*20357)/10000,(11*41786)/10000 ;2.5 MHz    Z1013:5.1 MHz
        ;ab hier wird etwas geschummelt. Der kritische Pfad für das 0-Bit
        ;kann etwas verlängert werden z.B. von 10 auf 11
        .db 10,(10*20357)/10000,(10*41786)/10000 ;2.5 MHz    Z1013:5.6 MHz
LEN_TIMER_LOOKUP .equ (.-timer_lookup)/3
str_hsave4:
        .ascii 'HSAVE4'
sizeof_str_hsave4 .equ .-str_hsave4

str_usage:
        .dw CHR_GREEN
        .ascii 'HeaderKC Turbo V.'
        .include '../version.inc'
        .ascii '\n\r'
        .ascii '  Abspeichern im Z1013-Format\n\r\n\r'
        .ascii 'HSAVE '
        .dw CHR_YELLOW
        .ascii 'AADR EADR '
        .dw CHR_GREEN
        .ascii '('
        .dw CHR_YELLOW
        .ascii 'SADR'
        .dw CHR_GREEN
        .ascii ') ('
        .dw CHR_YELLOW
        .ascii 'Geschw.'
        .dw CHR_GREEN
        .ascii ')\n\r'
        .dw CHR_YELLOW
        .ascii 'AADR   - '
        .dw CHR_CYAN
        .ascii 'Anfangadresse oder '
        .ascii "'"
        .db CHR_REPEAT
        .ascii "'"
        .ascii '\n\r'
        .ascii '          letzten Vorgang wiederholen\n\r'
        .dw CHR_YELLOW
        .ascii 'EADR   - '
        .dw CHR_CYAN
        .ascii 'Endadresse (letztes Byte!)\n\r'
        .dw CHR_YELLOW
        .ascii 'SADR   - '
        .dw CHR_CYAN
        .ascii '(optional) Startadresse\n\r'
        .dw CHR_YELLOW
        .ascii 'Geschw.- '
        .dw CHR_CYAN
        .ascii '(optional) 0-'
        .db LEN_TIMER_LOOKUP-1+0x30
        .ascii '\n\r'
        .ascii '         0 .. normal    Z1013 2.0MHz\n\r'
        .ascii '         1 .. turbo     Z1013 4.0MHz\n\r'
        .ascii '         2 .. usw.      Z1013 5.1MHz\n\r'
        .ascii '         3 ..           Z1013 5.6MHz\n\r'
        .dw CHR_WHITE
        .ascii 'Beispiele:\n\r'
        .ascii 'HSAVE '
        .db CHR_REPEAT
        .ascii '\n\r'
        .ascii 'HSAVE F000 F7FF\n\r'
        .asciz 'HSAVE F000 F7FF 0000 03\n\r'
        .dw CHR_DEFAULT
str_typ:
        .asciz 'typ:'
str_filename:
        .asciz ' filename:'
;
; uninitialisierte Daten
;
        .area _BSS
timer_bit0:
        .ds 1
timer_bit1:
        .ds 1
timer_bit_sync:
        .ds 1
save_ctc_tape:
        .ds 2
header_aadr:
    .ds 2
header_eadr:
    .ds 2
header_sadr:
    .ds 2
header_note:
    .ds 6
sizeof_header_note .equ .-header_note
header_typ:
    .ds 1
header_3dots:
    .ds 1
input_buffer:
    .ds 2
header_filename:
    .ds 16
sizeof_header_filename .equ .-header_filename

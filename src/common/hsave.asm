        .module hsave
        .include 'config.inc'

        .globl prepare_arguments

.macro WRITE_BIT ?write_full_period,?next_bit
        rrca
        out     (c),b
        jr      c,write_full_period
        out     (c),e
        halt
        jr      next_bit
write_full_period:
        out     (c),d
next_bit:
        halt
.endm

.macro WRITE_DE
        ld  a,d
        ex  af,af
        ld  a,e
        exx
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        ex  af,af
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        exx
.endm

.macro WRITE16_MEM_READ ?write_full_period,?next_bit
        ld      d,(hl)
        ld      a,d
        ex      af,af
        ld      a,e
        exx
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        ex  af,af
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        rrca
        out     (c),b
        jr      c,write_full_period
        out     (c),e
        halt
        jr      next_bit
write_full_period:
        out     (c),d
next_bit:
        exx
        inc     hl
        add     iy,de
        ld      e,(hl)
        inc     hl
        dec     c
        halt
.endm

.macro WRITE_DE2 ?write_full_period ?write_done ?write_next_bit
    ld b,#16
write_next_bit:
    rrc d
    rr e
write_next_bit_b:
    exx
    out (c),b
    jr nc,write_full_period
    out (c),d
    halt
    exx
    djnz write_next_bit
    jr write_done
write_full_period:
    out (c),e
    halt
    ; wir verlieren hier viel Zeit,
    ; eigentlich warten wir nur auf den zweiten Nulldurchgang
    ; ggf. kann man hierhin noch mehr Befehle verschieben
    exx
    rrc d
    rr e
    halt
    djnz write_next_bit_b
write_done:
.endm
        .area   _CODE2
run_hsave::
        call    prepare_arguments
        jr      c,header_prepared
        jp      z,show_usage_and_exit
        ld      a,(ARG4)
        cp      #LEN_TIMER_LOOKUP
        jp      nc,show_usage_and_exit
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
        push    de
        pop     iy
        INLINE
        jp       c,exit
inline_str::
        ld      a,#sizeof_header_filename+1
        sub     1(iy)
        ld      b,a
        ld      hl,#header_filename+#sizeof_header_filename-1
        ld      a,#' '
        dec     b
        jr      z,2$
4$:
        ld      (hl),a
        dec     hl
        djnz    4$
2$:
        ld      hl,#header_3dots
        ld      a,#0xd3
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
header_prepared::
        call    stop_all_timers
        call    save_old_iv

        ld      hl,(header_eadr)
        ld      bc,(header_aadr)
        xor     a
        sbc     hl,bc
        ; bitshift >>5, bc block länge
        add     hl,hl
        rla
        add     hl,hl
        rla
        add     hl,hl
        rla
        ld      c,h
        ld      b,a
        inc     bc

get_timers::
        ld      a,(ARG4)
        ld      d,a
        add     a
        add     d
        push    bc
        ld      c,a
        ld      b,#0
        ld      hl,#timer_lookup
        add     hl,bc
        ld      de,#timer_bit0
        ld      bc,#TIMER_LOOKUP_SIZE
        ldir

        ld      hl,#header_aadr
        ld      iy,#0x00e0
        ld      de,(sync_count)
        call    BSMK
        ld      hl,(header_aadr)
        push    hl
        pop     iy
        ld      de,(sync_count)
        call    BSMK

write_next_block::
        push    hl
        pop     iy
        ld      de,#14
        call    BSMK
        pop     bc
        dec     bc
        push    bc
        ld      a,b
        or      c
        jr      nz,write_next_block
        pop     bc

        call    restore_iv
        jr      exit

show_usage_and_exit:
        CPUTS_NEWLINE   str_usage
exit:
        xor     a
        ret
;
;-------------------------------------------------------------------------------
;startet CTC + Ausgabe SYNC bits
;-------------------------------------------------------------------------------
;
sync:
        ld      a,#CTC_CMD|CTC_INT_ENABLE|CTC_RESET|CTC_SET_COUNTER
        out     (PORT_CTC_TAPE),a
        ld      a,(timer_bit_sync)
        out     (PORT_CTC_TAPE),a
next_sync_bit:
        halt
        dec     de
        ld      a,e
        or      d
        jr      nz, next_sync_bit
        ret

stop_all_timers:
        ld      a,#CTC_CMD|CTC_INT_DISABLE
        out     (PORT_CTC+1),a
        out     (PORT_CTC+2),a
        out     (PORT_CTC+3),a
        ret
restore_iv:
        di
        ld hl,(save_ctc_tape)
        ld (IV_CTC_TAPE),hl

.if eq(MODEL-Z9001)
        ld a,#CTC_CMD|CTC_INT_ENABLE
        out (PORT_CTC+3),a
        ld a,#(PIO_CONTROL_WORD|PIO_INT_ENABLE)
        out (PIO_TASTATUR_B_CMD),a
.endif
        ei
        ret

save_old_iv:
        di
        ld      a,#CTC_CMD|CTC_INT_DISABLE|CTC_RESET
        out     (PORT_CTC_TAPE),a
        ld      hl,(IV_CTC_TAPE)
        ld      (save_ctc_tape),hl
        ld      hl,#isr_halt
        ld      (IV_CTC_TAPE),hl
        ei
        ret
;
;-------------------------------------------------------------------------------
;Schreiben eines Blocks
;-------------------------------------------------------------------------------
;
BSMK::
        exx
        ld      a,(#timer_bit0)
        ld      e,a
        ld      a,(#timer_bit1)
        ld      d,a
        ld      c,#PORT_CTC_TAPE
        ld      b,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
        exx

        call    sync
        ; setze möglichst schnell den nächsten Timer
        ld      a,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
        out     (PORT_CTC_TAPE),a
        ld      a,(timer_bit1)
        out     (PORT_CTC_TAPE),a
        halt
        halt

        push    iy  ; Ausgabe blocknummer
        pop     de
        ;de blocknummer
write_block_nr::
        WRITE_DE

        ld      c,#16
write_next_word::
        ld      e,(hl)
        inc     hl
write_next_word_highbyte:
        ld      d,(hl)
        ld      a,d
        ex      af,af
        ld      a,e
        exx
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        ex  af,af
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        WRITE_BIT

        WRITE_BIT
        WRITE_BIT
        WRITE_BIT
        rrca
        out     (c),b
        jr      c,write_full_period
        out     (c),e
        halt
        jr      next_bit
write_full_period:
        out     (c),d
next_bit:
        exx
        inc     hl
        add     iy,de
        ld      e,(hl)
        inc     hl
        dec     c
        halt
        jp      nz,write_next_word_highbyte
        dec     hl
        push    iy
        pop     de
        ; Prüfsumme
        WRITE_DE
        ld      a,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
        out     (PORT_CTC_TAPE),a
        ld      a,#0xe8
        out     (PORT_CTC_TAPE),a
        halt ; das letzte bit braucht noch mind. einen Nulldurchgang
        halt ; erstmal zu Ende zählen lassen
        ld      a,#CTC_CMD|CTC_INT_DISABLE|CTC_RESET
        out     (PORT_CTC_TAPE),a
        ret

isr_halt::
        ei
        reti
;
; Datensegment
;
        .area   _RODATA
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
.if gt(LEN_TIMER_LOOKUP-0)
        .ascii '         0 .. normal    Z1013 2.0MHz\n\r'
.endif
.if gt(LEN_TIMER_LOOKUP-1)
        .ascii '         1 .. turbo     Z1013 4.0MHz\n\r'
.endif
.if gt(LEN_TIMER_LOOKUP-2)
        .ascii '         2 .. usw.      Z1013 5.0MHz\n\r'
.endif
.if gt(LEN_TIMER_LOOKUP-3)
        .ascii '         3 ..           Z1013 5.4MHz\n\r'
.endif
.if gt(LEN_TIMER_LOOKUP-4)
        .ascii '         4 ..           Z1013 6.0MHz\n\r'
.endif
.if gt(LEN_TIMER_LOOKUP-5)
        .ascii '         5 ..           Z1013 6.8MHz\n\r'
.endif
        .dw CHR_WHITE
        .ascii 'Beispiele:\n\r'
        .db CHR_MENU
        .ascii 'HSAVE '
        .db CHR_REPEAT
        .ascii '\n\r'
        .db CHR_MENU
        .ascii 'HSAVE F000 F7FF\n\r'
        .db CHR_MENU
        .ascii 'HSAVE F000 F7FF 0000 '
.if gt(LEN_TIMER_LOOKUP-1)
        .ascii '1'
.else
        .ascii '0'
.endif
        .dw CHR_DEFAULT
        .asciz '\n\r'
str_typ:
        .asciz 'typ:'
str_filename:
        .asciz ' filename:'
; Werte der Original-Z1013-Savefunktion.
HZ_SYNC .equ 658
HZ_BIT1 .equ 1316
HZ_BIT0 .equ 2630
timer_lookup:
        ; db   28,  57, 117                            ;2.45 MHz   Z1013:2 MHz
        ; db 0x14,0x29,0x54                            ;1.75 MHz - Z1013:2 MHz
        ; db   20,  41,  84                            ;1.75 MHz - Z1013:2 MHz
        .db ((CLK16/HZ_BIT0)+1)/2,((CLK16/HZ_BIT1)+1)/2,((CLK16/HZ_SYNC)+1)/2 ;1.75 MHz - Z1013:2 MHz
        .dw 4096
TIMER_LOOKUP_SIZE .equ (.-timer_lookup)

        .db ((CLK16/HZ_BIT0)+1)/4,((CLK16/HZ_BIT1)+1)/4,((CLK16/HZ_SYNC)+1)/4 ;1.75 MHz - Z1013:4 MHz
        .dw 8192
        ; das +1 ist ein wenig geschummelt, es gibt dem KC noch 32 Takzyklen Zeit
        ; bis zum nächsten Interrupt, andernfalls kommt womöglich noch eine extra
        ; Halbwelle zu viel auf das Band
        ;.db ((CLK16/HZ_BIT0)+1)/5+1,((CLK16/HZ_BIT1)+1)/5,((CLK16/HZ_SYNC)+1)/5;1.75 MHz - Z1013:5 MHz
.if ne(CLK-1750000)
        .db 11,(11*20357)/10000,(11*41786)/10000 ;2.45 MHz    Z1013:5.0 MHz
        .dw 10000

        .db 10,(10*20357)/10000,(10*41786)/10000 ;2.45 MHz    Z1013:5.4 MHz
        .dw 11060

        .db 9,(9*20357)/10000,(9*41786)/10000    ;2.45 MHz    Z1013:6.0 MHz
        .dw 12200

        .db 8,(8*20357)/10000,(8*41786)/10000    ;2.45 MHz    Z1013:6.8 MHz
        .dw 13800
.endif

LEN_TIMER_LOOKUP .equ (.-timer_lookup)/TIMER_LOOKUP_SIZE
;
; uninitialisierte Daten
;
        .area _BSS
timer_bit0::
        .ds 1
timer_bit1:
        .ds 1
timer_bit_sync:
        .ds 1
sync_count:
        .ds 2
save_ctc_tape:
        .ds 2
header_aadr::
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
end_of_ram::

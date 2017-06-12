    .module Z9001
;
;------------------------------------------------------------------------------
; Arbeitsspeicher
;------------------------------------------------------------------------------
;
        .include 'z9001.inc'

BIOS_CALL   .equ 0x0005
currbank    .equ 0x0042       ; aktuelle Bank
firstent    .equ currbank+1  ; temp. Zelle f. Menu
DATA        .equ firstent+1  ; Konvertierungsbuffer
ARG1        .equ DATA+2      ; 1. Argument
ARG2        .equ ARG1+2      ; 2. Argument
ARG3        .equ ARG2+2      ; 3. Argument
ARG4        .equ ARG3+2      ; 4. Argument
CONBU       .equ 0x0080
IV_CTC_TAPE .equ 0x0200  ; Kassette Schreiben
IV_CTC1     .equ 0x0202  ; frei
IV_CTC2     .equ 0x0204  ; entprellen Tastatur
IV_CTC3     .equ 0x0206  ; Systemuhr

;IO Ports
PORT_CTC            .equ 0x80
PORT_CTC_TAPE       .equ 0x80
PIO_TASTATUR_B_CMD  .equ 0x93

PIO_MODE            .equ 0x0f
PIO_M0_ALL_OUTPUT   .equ 0x00
PIO_M1_ALL_INPUT    .equ 0x40
PIO_M2_BIDIRECT     .equ 0x80
PIO_M3_BITWISE      .equ 0xc0

PIO_CONTROL_WORD    .equ 0x07
PIO_INT_ENABLE      .equ 0x80
PIO_INT_DISABLE     .equ 0x00
PIO_M3_AND          .equ 0x40
PIO_M3_OR           .equ 0x00
PIO_M3_HIGH         .equ 0x20
PIO_M3_LOW          .equ 0x00
PIO_M3_MASK         .equ 0x10

CTC_INT_ENABLE      .equ 0x80
CTC_INT_DISABLE     .equ 0x00

CTC_MODE_COUNTER    .equ 0x40
CTC_MODE_TIMER      .equ 0x00

CTC_PRESCALE_256    .equ 0x20 ; timer mode only
CTC_PRESCALE_16     .equ 0x00 ; timer mode only

CTC_TRIGGER_EXT     .equ 0x08
CTC_TRIGGER_NOW     .equ 0x00

CTC_SET_COUNTER     .equ 0x04
CTC_RESET           .equ 0x02
CTC_CMD             .equ 0x01

;BIT_0     .equ 28
;BIT_1     .equ 57
;BIT_SYNC  .equ 117
SYNC_BITS .equ 4087 ; ich nehme mal an es sollten beim Z1013 4096 werden
                    ; da aber die Zeit eingehalten werden sollte, werden hier
                    ; ein paar Zyklen entfernt

.macro WRITE_DE ?write_full_period ?write_done ?write_next_bit
    ld b,#16
write_next_bit:
    rrc d
    rr e
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
    halt
    exx
    djnz write_next_bit
write_done:
.endm

    .area _CODE
init::
    jp  run_hsave
    .ascii 'HSAVE   '
    .dw 0
run_hsave:
    call KDOPAR
    cp #':'
    jp z,header_prepared
    ld (header_aadr),hl
    ld (header_eadr),de
    ld (header_sadr),bc
    cp #LEN_TIMER_LOOKUP
    jp nc,quit_error
    ld hl,#header_note
    ld b,#32-6
    ld a,#' '

fill_buffer:
    ld (hl),a
    inc hl
    djnz fill_buffer

    ld c,#UP_PRNST
    ld de,#str_typ
    call BIOS_CALL
    ld c,#UP_CONSI
    call BIOS_CALL
    ld e,a
    ld (header_typ),a
    ld c,#UP_CONSO
    call BIOS_CALL
    ld c,#UP_PRNST
    ld de,#str_filename
    call BIOS_CALL
    ld c,#UP_RCONB
    ld de,#input_buffer
    ld a,#sizeof_header_filename
    ld (de),a
    call BIOS_CALL
    jp   c,end ; stop gedrückt
    ld hl,#header_3dots
    ld a,#0xd3
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a

header_prepared:
    ld a,#CTC_CMD|CTC_INT_DISABLE
    out (PORT_CTC+1),a
    out (PORT_CTC+2),a
    out (PORT_CTC+3),a

    di
    ; stop counting
    ld a,#CTC_CMD|CTC_INT_DISABLE|CTC_RESET
    out (PORT_CTC_TAPE),a
    ld hl,(IV_CTC_TAPE)
    ld (save_ctc_tape),hl
    ld hl,#isr_halt
    ld (IV_CTC_TAPE),hl
    ei

    ld hl,(header_eadr)
    ld bc,(header_aadr)
    xor a
    sbc hl,bc
    ; bitshift >>5, bc block länge
    add hl,hl
    rla
    add hl,hl
    rla
    add hl,hl
    rla
    ld c,h
    ld b,a
    inc bc

    ld a,(ARG4)
    ld d,a
    add a
    add d
    push bc
    ld c,a
    ld b,#0
    ld hl,#timer_lookup
    add hl,bc
    ld de,#timer_bit0
    ld bc,#3
    ldir

    ld hl,#header_aadr
    ld ix,#0x00e0
    ld de,#SYNC_BITS
    call BSMK

    ld hl,(header_aadr)
    push hl
    pop ix
    ld de,#SYNC_BITS
    call BSMK

write_next_block:
    push hl
    pop ix
    ld de,#14
    call BSMK
    pop bc
    dec bc
    push bc
    ld a,b
    or c
    jr nz,write_next_block
    pop bc
end:
    call restore_isr
    xor a
    ret
quit_error:
    call restore_isr
    ld a,#1
    scf
    ret
restore_isr:
    ld a,#CTC_CMD|CTC_INT_ENABLE
    out (PORT_CTC+3),a
    ld hl,(save_ctc_tape)
    ld (IV_CTC_TAPE),hl
    ld a,#(PIO_CONTROL_WORD|PIO_INT_ENABLE)
    out (PIO_TASTATUR_B_CMD),a
    ret
;
;-------------------------------------------------------------------------------
;startet CTC + Ausgabe SYNC bits
;-------------------------------------------------------------------------------
;
sync:
    ld a,#CTC_CMD|CTC_INT_ENABLE|CTC_RESET|CTC_SET_COUNTER
    out (PORT_CTC_TAPE),a
    ld a,(timer_bit_sync)
    out (PORT_CTC_TAPE),a

next_sync_bit:
    halt
    dec de
    ld a,e
    or d
    jr nz, next_sync_bit
    ret
;
;-------------------------------------------------------------------------------
;Schreiben eines Blocks
;-------------------------------------------------------------------------------
;
BSMK::
    exx
    ld a,(#timer_bit0)
    ld e,a
    ld a,(#timer_bit1)
    ld d,a
    ld c,#PORT_CTC_TAPE
    ld b,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
    exx

    call sync
    ; setze möglichst schnell den nächsten Timer
    ld a,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
    out (PORT_CTC_TAPE),a
    ld a,(timer_bit1)
    out (PORT_CTC_TAPE),a
    halt
    halt

    push ix  ; Ausgabe blocknummer
    pop de
    ;de blocknummer
    WRITE_DE

    ld c,#16
write_next_word:
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    add ix,de
    WRITE_DE
    dec c
    jr nz,write_next_word
    push ix
    pop de
    ; Prüfsumme
    WRITE_DE
    ld a,#CTC_CMD|CTC_INT_ENABLE|CTC_SET_COUNTER
    out (PORT_CTC_TAPE),a
    ld a,#0xe8
    out (PORT_CTC_TAPE),a
    halt ; das letzte bit braucht noch mind. einen Nulldurchgang
    halt ; erstmal zu Ende zählen lassen
    ld a,#CTC_CMD|CTC_INT_DISABLE|CTC_RESET
    out (PORT_CTC_TAPE),a
    ret

isr_halt:
    ei
    reti
;
;-------------------------------------------------------------------------------
;Kommandoparameter aufbereiten
;-------------------------------------------------------------------------------
;
KDOPAR:
    ld de,#(CONBU+2)
    call SPACE
    ld a,(de)
    cp #':'          ;die alten Werte nehmen ?
    ret z
    call INHEX
    ld (ARG1),hl       ;neue Argumente holen
    call INHEX
    ld (ARG2),hl
    call INHEX
    ld (ARG3),hl
    call INHEX
    ld (ARG4),hl
    call INHEX
PARA:
    ld hl,(ARG1)
    ld de,(ARG2)
    ld bc,(ARG3)
    ld a,(ARG4)
    ret
;
;-------------------------------------------------------------------------------
;fuehrende Leerzeichen ueberlesen
;-------------------------------------------------------------------------------
;
SPACE:
    ld a,(de)
    cp #' '
    ret nz
    inc de
    jr SPACE
;
;-------------------------------------------------------------------------------
;letzen vier Zeichen als Hexzahl konvertieren
;und in DATA ablegen
;-------------------------------------------------------------------------------
;
KONVX:
    call SPACE
    xor a
    ld hl,#DATA
    ld (hl),a               ;DATA=0
    inc hl
    ld (hl),a
KON1:
    ld a,(de)
    dec hl
    sub #0x30              ;Zeichen<"0"?
    ret m
    cp #0x0a               ;Zeichen<="9"?
    jr c,KON2
    sub #7
    cp #0x0a               ;Zeichen<"A"?
    ret m
    cp #0x10               ;Zeichen>"F"?
    ret p
KON2:
    inc de                 ;Hexziffer eintragen
    rld
    inc hl
    rld
    jr KON1                 ;naechste Ziffer
;
;-------------------------------------------------------------------------------
;Konvertierung ASCII-Hex ab (DE) --> (HL)
;-------------------------------------------------------------------------------
;
INHEX:
    push bc
    call KONVX
    ld b,h
    ld c,l
    ld l,(hl)
    inc bc
    ld a,(bc)
    ld h,a
    or l          ;Z-Flag setzen
    pop bc
    ret

timer_lookup:
    .db 28,57,117                            ;2.5 MHz    Z1013:2   MHz
    .db 14,(14*20357)/10000,(14*41786)/10000 ;2.5 MHz    Z1013:4   MHz
    .db 11,(11*20357)/10000,(11*41786)/10000 ;2.5 MHz    Z1013:5.1 MHz
    ;ab hier wird etwas geschummelt. Der kritische Pfad für das 0-Bit
    ;kann etwas verlängert werden z.B. von 10 auf 11
    .db 10,(10*20357)/10000,(10*41786)/10000 ;2.5 MHz    Z1013:5.6 MHz
LEN_TIMER_LOOKUP .equ (.-timer_lookup)/3

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
header_typ:
    .ds 1
header_3dots:
    .ds 1
input_buffer:
    .ds 2
header_filename:
    .ds 16
sizeof_header_filename .equ .-header_filename

; Kritischer Pfad besteht wenn 16 Bit Wort zu Ende ist und dann
; ein neues vom Speicher gelesesen werden muss inklusive CRC
;          CTC/Vorteiler
;ei        28.15
;reti      28.11   4
;exx       27.13   18
;DJNZ      27.09   22
;ld c,0x10 27.01   30
;ld e,(hl) 26.10   37
;inc hl    26.03   44
;ld d,(hl) 25.13   50
;inc hl    25.06   57
;add ix,de         64
;ld b,0x10 24.01   78
;rrc d     23.10   85
;rr e      23.02   85
;exx       22.10  101
;out(),CMD 22.06  105
;jr nc     21.10  117
;out(),B0  20.14  129
;halt      20.02  141
;auf interrupt warten
;          19.14  145




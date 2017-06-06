    .module HeaderKC

;
;------------------------------------------------------------------------------
; Arbeitsspeicher
;------------------------------------------------------------------------------
;
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

UP_CONSI    .equ 0x01
UP_CONSO    .equ 0x02
UP_PRNST    .equ 0x09
UP_RCONB    .equ 0x0a ; input string

;IO Ports
;PORT_CTC            .equ 0x80
PORT_CTC_TAPE       .equ 0x80

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

BIT_0    .equ 23
BIT_1    .equ 56
BIT_SYNC .equ 116
SYNC_BITS .equ 4121

.macro WRITE_DE ?wait
    ld      c,#0x16 ; 16 bits per word
    or      c
wait:
    jr      nz,wait
.endm

    .area _CODE
    jp  run_hsave
    .ascii 'HSAVE   '
    .dw 0
run_hsave:
    call KDOPAR
    ld (header_aadr),hl
    ld (header_eadr),de
    ld (header_sadr),bc
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

    di
    ; stop counting
    ld a,#CTC_CMD|CTC_INT_DISABLE|CTC_RESET
    out (PORT_CTC_TAPE),a
    ld hl,(IV_CTC_TAPE)
    ld (save_ctc_tape),hl
    ld hl,#isr_sync
    ld (IV_CTC_TAPE),hl

    ld a,#CTC_CMD|CTC_INT_DISABLE
    out (0x83),a

    ei
isr_inst::
    ld hl,#header_aadr
    ld ix,#0x00e0
    ld de,#SYNC_BITS
    call BSMK
end:
    xor a
    ret
;
;-------------------------------------------------------------------------------
;startet CTC + Ausgabe SYNC bits
;-------------------------------------------------------------------------------
;
sync:
        ld      a,#0x87
        out     (PORT_CTC_TAPE),a
        ld      a,#BIT_SYNC
        out     (PORT_CTC_TAPE),a
        or      a ; reset ZF
wait_sync:
        jr      nz,wait_sync
        ret
;
;-------------------------------------------------------------------------------
;Schreiben eines Blocks
;-------------------------------------------------------------------------------
;
BSMK::
    call sync
    ld  hl,#isr_ctc     ; wir kommen gerade von der ISR
    ld (IV_CTC_TAPE),hl ; so hier soll und wird kein interrupt dazwischen funken
    ld c,#2             ; jetzt kommen 2 EINS bits
    ld e,#0xff
    or c
wait_eins_bits:
    jr nz,wait_eins_bits
    push ix  ; ausgabe blocknummner
    pop de
    WRITE_DE
;    ld e,(hl)
;    inc hl
;    ld d,(hl)
;    inc hl
;isr_inst2::
    ld c,#2             ; die letzte halbwelle fehlt
    ld e,#0xff
    or c
wait_last_bit:
    jr nz,wait_last_bit
    ld a,#0x03
    out (PORT_CTC_TAPE),a
    ret


isr_sync::
    dec     de
    ld      a,e
    or      d
    ei
    reti

isr_ctc::
    ld      a,#0x87
    out     (PORT_CTC_TAPE),a
    rrc     d
    rr      e
    ld      a,#BIT_0
    jr      nc,isr_bit
    ld      a,#BIT_1
isr_bit:
    out     (PORT_CTC_TAPE),a
    dec     c
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
    ;ld (ARG4),hl
    ;call INHEX
PARA:
    ld hl,(ARG1)
    ld de,(ARG2)
    ld bc,(ARG3)
    ;ld a,(ARG4)
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

str_typ:
    .asciz 'typ:'
str_filename:
    .asciz ' filename:'
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

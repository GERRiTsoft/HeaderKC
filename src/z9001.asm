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
UP_CONSI    .equ 0x01
UP_CONSO    .equ 0x02
UP_PRNST    .equ 0x09
UP_RCONB    .equ 0x0a ; input string

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

    ld hl,#header_aadr
    ld ix,#0x00e0
    ld de,#14
    call BSMK
end:
    ret
;
;-------------------------------------------------------------------------------
;Schreiben eines Blocks
;-------------------------------------------------------------------------------
;
BSMK:

    ret
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
        .module  hsave_cmd
        .include 'config.inc'

        .globl run_hsave
;
; Einfügen in Kommandotabelle
;
        .area _CODE
        jp  run_hsave
        .ascii 'HSAVE   '
        .db 0x00


        .area _CODE2
;-------------------------------------------------------------------------------
;Kommandoparameter aufbereiten
;-------------------------------------------------------------------------------
;
; CF gesetzt - wiederhole Vorgang mit den letzten Parametern
; ZF Parameterliste leer
prepare_arguments::
        ld de,#(CONBU+2)
        call SPACE
        ld a,(de)
        cp #':'          ;die alten Werte nehmen ?
        scf
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
        ld hl,(ARG1)
        ld de,(ARG2)
        ld bc,(ARG3)
        ld a,(ARG4)
        or c
        or b
        or e
        or d
        or l
        or h
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

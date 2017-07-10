        .module hsave_cmd
        .include 'caos.inc'
        .include 'config.inc'

        .globl run_hsave

        .area _CODE
        .dw 0x7f7f
        .ascii 'HSAVE'
        .db 0x01
        jp run_hsave

        .area _CODE2
prepare_arguments::
        ld      a,(ARGN)
        or      a
        ret     z  ; ZF=1 keine Argumente (CF:=0!)
        dec     a
        ret     nz ; mehr als ein Argument
        or      h
        or      l
        scf
        ret     z  ; CF=1 wiederhole letzten Aufruf
        ccf
        ret
;Bemerkung:
; die Routine löscht bei jeder neuen Zeile den gesamten Inhalt ebendieser.
; Das mag nicht ganz kompatibel mit der Steuerzeichenbehandlung sein,
; wie es z.B. bei MSDOS der Fall wäre, aber für dieses spezielle Programm
; ist dieses abweichende Verhalten akzeptabel, sprich das Verhalten ist
; ähnlich der Kommandozeilenprogrammer unter DOS, aber die Ausgabe ist sehr
; langsam
cputs::
        ld a,#2 ;lösche Zeileninhalt
        call PV1
        .db FNCRT
        ld a,#1 ;setze Vordergrundfarbe
        ld (ARGN),a
cputs_next::
        ld a,(de)
        inc de
        or a
        ret z
        cp #0x14; Farbcode
        jr z,set_foreground_color
        cp #0x0a
        jr nz,cputs_print
        ld a,#0x0a ;lösche Zeileninhalt
        call PV1
        .db FNCRT
        ld a,#0x02
        call PV1
        .db FNCRT
cputs_print:
        call    PV1
        .db     FNCRT
        jr      cputs_next
set_foreground_color:
        ld      a,(de)
        push    de
        ld      l,a
        ld      e,#3
        call    PV1
        .db     FNCOLORUP
        pop     de
        inc     de
        jr      cputs_next

inline::
        push    de
        inc     de
        inc     de
        pop     iy
        xor     a
        ld      1(iy),a
next_character:
        GETCH
        cp      #(' '-1)
        call    c,steuerzeichen
        ; return if CF=1
        jr      nc,2$
        cp      #VK_BREAK
        scf
        ret     z
        ccf
        ret
2$:
        jr      z,next_character
        ld      b,a
        ld      a,1(iy)
        cp      0(iy)
        jr      z,next_character
        inc     1(iy)
        ld      a,b
        ld      (de),a
        inc     de
        PUTCH
        jr      next_character
steuerzeichen::
        cp      #VK_ENTER
        scf
        ret     z
        cp      #VK_BREAK
        scf
        ret     z
        cp      #VK_LEFT
        jr      nz,$1
        ld      a,1(iy)
        or      a
        jr      z,$1
        ld      a,#0x1; clear+cursor left
        PUTCH
        ld      a,#0x1f; clear+cursor left
        PUTCH
        dec     1(iy)
        dec     de
$1:
        ld      a,#0
        or      a
        ret

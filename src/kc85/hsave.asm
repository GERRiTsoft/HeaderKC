    .module hsave
    .include 'caos.inc'
    .include 'config.inc'

    .area _CODE
    .dw 0x7f7f
    .ascii 'HSAVE'
    .db 0x01
run_hsave::
    ld a,(ARGN)
    cp #0 ; keine Argumente
    jp nz, has_arguments
    ld de,#str_usage
    call cputs
has_arguments:
    ret
;Bemerkung:
; die Routine löscht bei jeder neuen Zeile den gesamten Inhalt.
; Das mag nicht ganz kompatibel mit der Steuerzeichenbehandlung sein,
; wie es z.B. bei MSDOS der Fall wäre, aber für dieses spezielle Programm
; ist dieses abweichende Verhalten akzeptabel.
cputs:
    ld a,#2 ;lösche Zeileninhalt
    call PV1
    .db FNCRT
    ld a,#1 ;setze Vordergrundfarbe
    ld (ARGN),a
cputs_next:
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

BLUE        .equ 0x01
RED         .equ 0x02
MAGENTA     .equ 0x03
GREEN       .equ 0x04
CYAN        .equ 0x05
YELLOW      .equ 0x06
WHITE       .equ 0x07

CHR_GREEN   .equ GREEN*0x100+0x14
CHR_YELLOW  .equ YELLOW*0x100+0x14
CHR_CYAN    .equ CYAN*0x100+0x14
CHR_WHITE   .equ WHITE*0x100+0x14
CHR_DEFAULT .equ CHR_WHITE

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
    .ascii 'Anfangadresse oder \n\r'
    .ascii '         : letzten Vorgang wiederholen\n\r'
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
    .ascii 'HSAVE :\n\r'
    .ascii 'HSAVE F000 F7FF\n\r'
    .asciz 'HSAVE F000 F7FF 0000 03\n\r'
    .dw CHR_DEFAULT

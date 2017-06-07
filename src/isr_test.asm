;****************************************************************
;*
;* Vereinfachte Darstellung einer generischen LOAD Routine
;*
;* Grundstruktur zum Testen verschiedender ISR Routinen Zwecks
;*  Taktzyklenzählung und Ideensammlung zur Beschleunigung.
;*
;* Variante A) isr_standard
;*             ähnlich KC85/3 Entkopplung via Speicherzelle (IX+0)
;* 
;* Variante B) Anstatt "Flag (IX+0)" AF Register verwenden
;*             Wenn die ISR AF verändert, darf man im Hauptprogramm
;*             weder A noch F verwenden
;*
;* Variante C) kein (oder nur minimal) ISR und dafür die HALT Instruktion verwenden
;*             Wenn man die Zeit zwischen 2 HALT Befehlen misst, sollten dann keine
;*             anderen Interrupts auftreten.
;*
;****************************************************************
UP_CONSI            .equ 0x01
UP_CONSO            .equ 0x02

BOS                 .equ 0x0005
CONBU               .equ 0x0080
IV_CTC_TAPE         .equ 0x0200  ; Kassette Schreiben
IV_CTC1             .equ 0x0202  ; frei
IV_CTC2             .equ 0x0204  ; entprellen Tastatur
IV_CTC3             .equ 0x0206  ; Systemuhr
IV_PIO_KEYBOARD     .equ 0x0208  ; Tastaturinterrupt
IV_PIO_TAP          .equ 0x020a  ; Kassette lesen

PORT_CTC_TAPE       .equ 0x80
PORT_CTC            .equ 0x80

PIO_SYSTEM_A_CMD    .equ 0x8a
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

BIT0                .equ 0x80
BUFFER_LEN          .equ 0x100
    .module isr_test
ENTRY::
    jp  run_hload
    .ascii 'HLOAD   '
    .dw 0
run_hload:
    di
    ld hl,(IV_PIO_TAP)
    ld (save_iv),hl
    ld hl,#isr_standard
    ld hl,#isr_empty ; Variante C
    ld (IV_PIO_TAP),hl

    ld a,#(CTC_CMD|CTC_INT_DISABLE)
    out (PORT_CTC+0),a
    out (PORT_CTC+1),a
    out (PORT_CTC+2),a
    out (PORT_CTC+3),a

    ld a,#(PIO_CONTROL_WORD|PIO_INT_DISABLE)
    out (PIO_TASTATUR_B_CMD),a
    ld a,#(PIO_MODE|PIO_M0_ALL_OUTPUT)
    out (PIO_SYSTEM_A_CMD),a
    ld a,#(PIO_CONTROL_WORD|PIO_INT_ENABLE)
    out (PIO_SYSTEM_A_CMD),a
    ld a,#<(IV_PIO_TAP)
    out (PIO_SYSTEM_A_CMD),a

    ld b,#8
    ld ix,#CONBU
    xor a
    ld 0(ix),a
    ld a,#(CTC_CMD|CTC_INT_DISABLE|CTC_RESET|CTC_SET_COUNTER)
    out (PORT_CTC_TAPE),a
    ld hl,#(end_of_program-1+0x100)
    ld a,#0x00
    ld l,a
    out (PORT_CTC_TAPE),a
    ;call wait_for_isrA ; Variante A
    ei
    call wait_for_isrC ; Variante C
    ret
;
; Variante C) HALT
;
isr_C::
wait_for_isrC:
    in a,(0x88)                                                 
    out (0x88),a                                                
    in a,(PORT_CTC_TAPE)                                       
    ld e,a
    halt                                                        
    in a,(PORT_CTC_TAPE)                                        ; 22
    sub e
    call record_time  ; optional - fliesst nicht mit in die Zyklenzählung ein
    jr wait_for_isrC
;
; Variante A) Originalroutine
;
wait_for_isrA:
    in a,(0x88)                                                 ; 91
    out (0x88),a                                                ; 102
next_bit:                                                       ; 0 
                                                                ; hier kann der interrupt
                                                                ; erstmalig auftreten
    ld a,0(ix)                                                  ; 19
    or a                                                        ; 23  
    jr z,wait_for_isrA                                          ; 30
    cp #BIT0    ; setze CF                                      ; 37
    rr d                                                        ; 45 
    call record_time  ; optional - fliesst nicht mit in die Zyklenzählung ein
    xor a                                                       ; 49 
    ld 0(ix),a                                                  ; 68
    jr wait_for_isrA                                            ; 80
quit:
    di
    ld hl,(save_iv)
    ld (IV_PIO_TAP),hl
    ld a,#(PIO_CONTROL_WORD|PIO_INT_DISABLE)
    out (PIO_SYSTEM_A_CMD),a
    ei

isr_display_values::
    ld hl,#(end_of_program-1+0x100)
    ld a,#0x00
    ld l,a

    ld bc,#BUFFER_LEN
print_next_byte:
    ld a,(hl)
    inc hl
    push bc
    call up_outhx
    pop bc
    dec bc
    ld a,b
    or c
    jr nz,print_next_byte


    xor a
    ret
up_outhx:
    push af
    rra
    rra
    rra
    rra
    call outa
    pop af
outa:
    push af
    and #0x0f
    add #0x30
    cp #0x3a
    jr c,hex_korrektur
    add #0x07
hex_korrektur:
    call up_outch
    pop af
    ret
up_outch:
    ld c,#UP_CONSO
    ld e,a
    call BOS
    ret
record_time:
    ld (hl),a
    inc l
    ret nz
    pop af
    jp quit

isr_empty::                                                     ;   0
    ei                                                          ;   4
    reti                                                        ;  18

isr_standard::                                                  ;   0
    push af                                                     ;  11
    in a,(PORT_CTC_TAPE)                                        ;  22
    ld 0(ix),a                                                  ;  41
    ld a,#(CTC_CMD|CTC_INT_DISABLE|CTC_RESET|CTC_SET_COUNTER)   ;  48
    out (PORT_CTC_TAPE),a                                       ;  59
    ld a,#0x00                                                  ;  66
    out (PORT_CTC_TAPE),a                                       ;  77
    pop af                                                      ;  87
    ei                                                          ;  91
    reti                                                        ; 105

save_iv:
    .ds 2
end_of_program:

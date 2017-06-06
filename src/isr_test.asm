;****************************************************************
;*
;* Vereinfachte Darstellung einer generischen LOAD routine
;*
;****************************************************************
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
    ei

    ld b,#8
    ld ix,#CONBU
    xor a
    ld 0(ix),a
    ld a,#(CTC_CMD|CTC_INT_DISABLE|CTC_RESET|CTC_SET_COUNTER)
    out (PORT_CTC_TAPE),a
    ld a,#0x00
    out (PORT_CTC_TAPE),a

wait_for_isr:
    in a,(0x88)                                                 ; 91
    out (0x88),a                                                ; 102
next_bit:                                                       ; 0 
                                                                ; hier kann der interrupt
                                                                ; erstmalig auftreten
    ld a,0(ix)                                                  ; 19
    or a                                                        ; 23  
    jr z,wait_for_isr                                           ; 30
    cp #BIT0    ; setze CF                                      ; 37
    rr d                                                        ; 45 
    xor a                                                       ; 49 
    ld 0(ix),a                                                  ; 68
    jr wait_for_isr                                             ; 80

    di
    ld hl,(save_iv)
    ld (IV_PIO_TAP),hl
    ei
    ret

isr_standard:                                                   ; 0
    push af                                                     ; 11
    in a,(PORT_CTC_TAPE)                                        ; 22
    ld 0(ix),a                                                  ; 41
    ld a,#(CTC_CMD|CTC_INT_DISABLE|CTC_RESET|CTC_SET_COUNTER)   ; 48
    out (PORT_CTC_TAPE),a                                       ; 59
    ld a,#0x00                                                  ; 66
    out (PORT_CTC_TAPE),a                                       ; 77
    pop af                                                      ; 87
    ei                                                          ; 91
    reti                                                        ; 105

save_iv:
    .ds 2

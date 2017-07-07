        .module schalt_test
        .include 'caos.inc'

PIOA_DATA .equ 0x88

BIT_MOTOR .equ (1<<6)

.macro WAIT_ZYKLEN ?m
        ld  b,#1
m:
        djnz m
.endm

.macro OFF
        out (c),d
.endm

.macro ON
        out (c),e
.endm


        .area _CODE
        .dw 0x7f7f
        .ascii 'MOT'
        .db 0x01

        in      a,(PIOA_DATA)
        and     #~BIT_MOTOR
        ld      d,a
        or      #BIT_MOTOR
        ld      e,a
        ld      c, #PIOA_DATA
        ld      hl,#data
        xor     a
        ex      af,af
        OFF
        ON
        OFF
        nop
        nop
        nop
        jp      again ; gleiches timing wie nach dem loop
again:
        ld      a,(hl)
        ld      b,a
        ex      af,af
        add     b
        ex      af,af
        inc     hl
        OFF
        rra
        jr  c,1$
11$:
        ON
        rra
        jr  c,2$
21$:
        OFF
        rra
        jr  c,3$
31$:
        ON
        rra
        jr  c,4$
41$:
        OFF
        rra
        jr  c,5$
51$:
        ON
        rra
        jr  c,6$
61$:
        OFF
        rra
        jr  c,7$
71$:
        ON
        rra
        jr  c,8$
81$:
        OFF
        ld  b,d ; on/off umkehren
        ld  d,e
        ld  e,b
        jp  again
1$:     jr 11$
2$:     jr 21$
3$:     jr 31$
4$:     jr 41$
5$:     jr 51$
6$:     jr 61$
7$:     jr 71$
8$:     jr 81$

        ret

data:
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f
       .db 0x80,0xff,0xf0,0x0f,0x00,0xff,0xf0,0x0f


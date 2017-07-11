PV1                 .equ 0xf003 ; Parameter in Registern, .db FNnr nach call PV1

FNCRT               .equ 0x00
FNKBD               .equ 0x04
FNCOLORUP           .equ 0x0f
FNINLIN             .equ 0x17
FNOSTR              .equ 0x23
FNCRLF              .equ 0x2c

Z9001               .equ 0
KC85                .equ 1
MODEL               .equ KC85

BLUE                .equ 0x01
RED                 .equ 0x02
MAGENTA             .equ 0x03
GREEN               .equ 0x04
CYAN                .equ 0x05
YELLOW              .equ 0x06
WHITE               .equ 0x07

CHR_GREEN           .equ GREEN*0x100+0x14
CHR_YELLOW          .equ YELLOW*0x100+0x14
CHR_CYAN            .equ CYAN*0x100+0x14
CHR_WHITE           .equ WHITE*0x100+0x14
CHR_DEFAULT         .equ CHR_WHITE
CHR_REPEAT          .equ '0'
CHR_MENU            .equ '%'

VK_BREAK            .equ 0x03
VK_LEFT             .equ 0x08
VK_ENTER            .equ 0x0d

PORT_CTC            .equ 0x8c
PORT_CTC_TAPE       .equ 0x8d
;IV_CTC_TAPE         .equ 0x01e8  ; Kanal 0
IV_CTC_TAPE         .equ 0x01ea  ; Kanal 1 Kassette Schreiben L

CTC_INT_ENABLE      .equ 0x80
CTC_INT_DISABLE     .equ 0x00

CTC_MODE_COUNTER    .equ 0x40
CTC_MODE_TIMER      .equ 0x00

CTC_PRESCALE_256    .equ 0x20 ; timer mode only
CTC_PRESCALE_16     .equ 0x00 ; timer mode only

CTC_TRIGGER_EXT     .equ 0x08
CTC_TRIGGER_NOW     .equ 0x00

ARG4                .equ 0xb788

CTC_SET_COUNTER     .equ 0x04
CTC_RESET           .equ 0x02
CTC_CMD             .equ 0x01
;KC85/3 Wenn wir diese Konstanten verwenden wird es zu schnell auf dem KC85/4
;CLK                 .equ 1750000
;CLK16               .equ  109375
; dann lieber 1,5% langsamer auf dem KC85/3
;CLK                 .equ 1773447.6
CLK16               .equ  110840

        .globl  cputs
        .globl  cputs_next
        .globl  inline

.macro CPUTS_NEWLINE str
        ld      de,#str
        call    cputs
.endm

.macro CPUTS_APPEND str
        ld      de,#str
        call    cputs_next
.endm

.macro GETCH
        call    PV1
        .db     FNKBD
.endm

.macro PUTCH
        call    PV1
        .db     FNCRT
.endm

.macro CRLF
        call    PV1
        .db     FNCRLF
.endm

.macro INLINE
        call    inline
        CRLF
.endm


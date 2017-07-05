PV1             .equ 0xf003 ; Parameter in Registern, .db FNnr nach call PV1

FNCRT           .equ 0x00
FNKBD           .equ 0x04
FNCOLORUP       .equ 0x0f
FNINLIN         .equ 0x17
FNOSTR          .equ 0x23


BLUE            .equ 0x01
RED             .equ 0x02
MAGENTA         .equ 0x03
GREEN           .equ 0x04
CYAN            .equ 0x05
YELLOW          .equ 0x06
WHITE           .equ 0x07

CHR_GREEN       .equ GREEN*0x100+0x14
CHR_YELLOW      .equ YELLOW*0x100+0x14
CHR_CYAN        .equ CYAN*0x100+0x14
CHR_WHITE       .equ WHITE*0x100+0x14
CHR_DEFAULT     .equ CHR_WHITE
CHR_REPEAT      .equ '0'

VK_LEFT         .equ 0x08
CURSOR_RIGHT    .equ 0x09
VK_ENTER        .equ 0x0d

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


.macro INLINE
        call    inline
.endm


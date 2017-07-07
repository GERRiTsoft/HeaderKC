;Unterprogramme des Betriebssystems
UP_INIT     .equ  0  ; Systeminitialisierung
UP_CONSI    .equ  1  ; Eingabe eines Zeichens von der Tastatur
UP_CONSO    .equ  2  ; Ausgabe eines Zeichens zum Bildschirm
UP_READI    .equ  3  ; Eingabe eines Zeichens vom READER
UP_PUNO     .equ  4  ; Ausgabe eines Zeichens an PUNCH
UP_LISTO    .equ  5  ; Ausgabe eines Zeichens an den Drucker LIST
UP_GETST    .equ  6  ; Spielhebelabfrage
UP_GETIO    .equ  7  ; Eingabe des E/A Bytes
UP_SETIO    .equ  8  ; Ausgabe des E/A Bytes
UP_PRNST    .equ  9  ; Ausgabe String; String muss mit NUL-Byte abgeschlossen sein
UP_RCONB    .equ 10  ; Eingabe eines Strings 1. Byte Länge Puffer, 2. Byte enthält wirkliche Länge ohne CR, 3. Byte String
UP_CSTS     .equ 11  ; Abfrage Konsolenstatus
UP_RETVN    .equ 12  ; aktuelle Nummer der MONITOR-Version
UP_OPENR    .equ 13  ; OPEN für READ
UP_CLOSER   .equ 14  ; CLOSE für READ
UP_OPENW    .equ 15  ; OPEN für WRITE
UP_CLOSEW   .equ 16  ; CLOSE für WRITE
UP_GETCU    .equ 17  ; aktuelle Kursorposition Zeile/Spalte/Adresse
UP_SETCU    .equ 18  ; Neubelegung der Kursorposition
;                19 unbelegt
UP_READS    .equ 20  ; einmaliges Lesen eines Blockes zur DMA Adresse
UP_WRITS    .equ 21  ; einmaliges Schreiben eines Blockes ab DMA Adresse
UP_SETTI    .equ 22  ; Stellen der Systemuhr
UP_GETTI    .equ 23  ; Abfragen der Systemuhr
UP_PRITI    .equ 24  ; Ausgabe der Systemuhrzeit
UP_INITA    .equ 25  ; Initialisierung der Tastatur
UP_SETDM    .equ 26  ; Einrichten des Puffers für READS und WRITS
UP_GETM     .equ 27  ; Testet Speicher in 1kByte Schritten auf ROM/RAM
UP_SETM     .equ 28  ; Willkürliche Zuweisung von ROM/RAM, RAM Schreibschutz
UP_DCU      .equ 29  ; Kursor löschen
UP_SCU      .equ 30  ; Kursor wieder setzen
UP_COEXT    .equ 31  ; Komprimieren eines Strings, Entfernung aller Steuerzeichen
;                32 unbelegt
UP_RRAND    .equ 33  ; Lesen eines Blockes, setze vorher FCB Byte 32 mit Blocknummer

BLACK               .equ 0x00
RED                 .equ 0x01
GREEN               .equ 0x02
YELLOW              .equ 0x03
BLUE                .equ 0x04
MAGENTA             .equ 0x05
CYAN                .equ 0x06
WHITE               .equ 0x07

CHR_GREEN           .equ GREEN*0x100+0x14
CHR_YELLOW          .equ YELLOW*0x100+0x14
CHR_CYAN            .equ CYAN*0x100+0x14
CHR_WHITE           .equ WHITE*0x100+0x14
CHR_DEFAULT         .equ CHR_WHITE
CHR_REPEAT          .equ ':'

BIOS_CALL           .equ 0x0005
currbank            .equ 0x0042       ; aktuelle Bank
firstent            .equ currbank+1  ; temp. Zelle f. Menu
DATA                .equ firstent+1  ; Konvertierungsbuffer
ARGN                .equ DATA+2
ARG1                .equ ARGN+2  ; 1. Argument
ARG2                .equ ARG1+2  ; 2. Argument
ARG3                .equ ARG2+2  ; 3. Argument
ARG4                .equ ARG3+2  ; 4. Argument
CONBU               .equ 0x0080
IV_CTC_TAPE         .equ 0x0200  ; Kassette Schreiben
IV_CTC1             .equ 0x0202  ; frei
IV_CTC2             .equ 0x0204  ; entprellen Tastatur
IV_CTC3             .equ 0x0206  ; Systemuhr

;IO Ports
PORT_CTC            .equ 0x80
PORT_CTC_TAPE       .equ 0x80
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
CLK                 .equ 2457500
CLK16               .equ  153594

SYNC_BITS           .equ 4096

VK_BREAK            .equ 0x03
VK_LEFT             .equ 0x08
VK_ENTER            .equ 0x0d

.macro CPUTS_NEWLINE str
        ld c,#UP_PRNST
        ld de,#str
        call BIOS_CALL
.endm

.macro CPUTS_APPEND str
        ld c,#UP_PRNST
        ld de,#str
        call BIOS_CALL
.endm

.macro GETCH
        ld      c,#UP_CONSI
        call    BIOS_CALL
.endm

.macro PUTCH
        ld      e,a
        ld      c,#UP_CONSO
        call BIOS_CALL
.endm

.macro INLINE
        ld      c,#UP_RCONB
        call    BIOS_CALL
.endm

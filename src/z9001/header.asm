;--------------------------------------------------------------------------
;  header.asm
;
;  Copyright (C) 2017, Andreas Ziermann
;
;  This library is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by the
;  Free Software Foundation; either version 2, or (at your option) any
;  later version.
;
;  This library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this library; see the file COPYING. If not, write to the
;  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;
;  As a special exception, if you link this library with other files,
;  some of which are compiled with SDCC, to produce an executable,
;  this library does not by itself cause the resulting executable to
;  be covered by the GNU General Public License. This exception does
;  not however invalidate any other reasons why the executable file
;   might be covered by the GNU General Public License.
;--------------------------------------------------------------------------

; Header für das .KCC Dateiformat 
; zur Verwendung für Emulator, Disk, Tape, USB, usw.
        .module header

        .globl s__CODE
        .globl s__BSS

        .area   _KCC_HEADER (abs)
start_of_header:
        .rept 8
                .db 0x00 ; platzhalter für Kommandoname
        .endm
        .ascii 'COM'                 ; Dateityp
        .db 0x00,0x00,0x00,0x00,0x00 ; reserviert
        .db 0x02                     ; Anzahl der Argumente
        .dw s__CODE                  ; Anfangsadresse
        .dw s__BSS-1                 ; Endadresse+1 beim KC85/2
                                     ; letzte Adresse beim Z9001
        .dw 0x0000                   ; Startadresse
LEN_HEADER .equ .-start_of_header
        .rept 128-LEN_HEADER
                .db 0x00 ; reserviert
        .endm

        ; setze Linkerreihenfolge
        ; CCP oder Menueinträge
        .area _CODE
        ; hier kommt der Code
        .area _CODE2
        ; Read only Daten
        .area _RODATA
        ;uninitialisierte Daten
        .area _BSS

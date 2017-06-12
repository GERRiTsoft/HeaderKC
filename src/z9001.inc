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

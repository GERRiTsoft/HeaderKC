;------------------------------------------------------------------------------
;                 HEADERKC
;   HeaderSave fuer den KC85/2-5
;
;       von Gerrit Schulz u. Frank Ludwig
;               letzte Aenderung 14.03.2015
;
;
; (erstellt mit EDAS 1.6 am KC85/4 und OCE am Z1013)
;------------------------------------------------------------------------------
;
	ORG	0BA00H
FEND:	EQU	0BF80H	;Fileende fuer OCE
;
PV1:	EQU	0F003H
;
CRT:	EQU	000H
KBD:	EQU	004H
KBDZ:	EQU	00EH
WAIT:	EQU	014H
INLIN:	EQU	017H
HLHX:	EQU	01AH
HLDE:	EQU	01BH
OSTR:	EQU	023H
BRKT:	EQU	02AH
CRLF:	EQU	02CH
PADR:	EQU	034H
;
ARN:	EQU	0B781H	;ARGN
AR1:	EQU	0B782H	;ARG1
AR2:	EQU	0B784H	;ARG2
ARG3:	EQU	0B786H	;originale Anfangsadresse
KC4:	EQU	0B788H	;ARG4  KC-TYP
EBL:	EQU	0B794H	;ARG10 erwarteter Block
WIN:	EQU	0B79CH	;WINON
CUR:	EQU	0B7A0H	;CURSO
COL:	EQU	0B7A3H	;COLOR
TL0:	EQU	0B7A6H	;CCTL0
SUT:	EQU	0B7B0H	;SUTAB
;
;Konstanten fuer HLOAD
G01:	EQU	08AH+1	;Grenzwert High/Low
GVT:	EQU	106+1	;Grenzwert Vorton
;
;Aufbau Kopfblock Headersave
TAADR:	EQU	0	;Anfangsadresse
TEADR:	EQU	2	;Endadresse
TSADR:	EQU	4	;Startadresse
TFREI:	EQU	6	;6 Byte frei fuer Zusatzinformation (z.B. Signatur)
TTYP:	EQU	12	;Typkennzeichen (1 Zeichen)
TMAGL:	EQU	13	;Kopfkennzeichen 3x 0D3H (MagicBytes)
TNAME:	EQU	16	;Dateiname (16 Zeichen)
;
;HeaderKC-Arbeitszellen
;befinden sich in einem praktisch ungenutzten Bereich im 
;CAOS-Modulsteuerwortspeicher Adresse 0B85CH..0B8AFH
;
PUF:	EQU	0B85CH	;Lesepuffer (Adresse+Daten+CRC=36Byte)
PUD:	EQU	PUF+2	;Datenbereich des Lesepuffers
ZSP:	EQU	PUF+36	;Zwischenspeicher fuer SP (Adr. 0B880H)
FAR:	EQU	0B888H	;Farbe fuer Hexausgabe, bei 0 Farbe wie im CAOS
			;Vorschlag: 70H eintragen (z.B. mit %SWITCH 88 70)
PUK:	EQU	0B890H	;Kopfpuffer (nur Datenbereich=32Byte)
;
;------------------------------------------------------------------------------
; HeaderKC-Sprungverteiler
;------------------------------------------------------------------------------
EEE:	JP	EIN	;0BA00H
			; Abfrage des Dateinamens und Saven des Files (HSAVE)
			;  PE: ARG1=AADR, ARG2=EADR, bei Typ B und C: ARG3=SARG 
			;      A=Typ, HL=Offset fuer Dateinamen 
;
SBL:	JP	NVT	;0BA03H
			; Block mit Vorton ausgeben
			;  PE: HL=AADR, B=1:langer Vorton
			;  PA: HL=AADR naechster Block
;
INS:	RET		;0BA06H
	RET		; (reserviert)
	RET
;
EVE:	JP	VRI	;0BA09H
			; Aufruf HVERI
;
VBL:	JP	BLV	;0BA0CH
			; Lesen eines Datenblocks fuer Verify
			;  PA: HL=Blockadresse, DE=Adr. im RAM, Z=1:Block Ok.
;
IVL:	JP	INL	;0BA0FH
			; Initialisierung fuer HLOAD und HVERI
			; (Init.Handshake, CTC2 und PIO A, Motor und LED an)
;
ELO:	JP	LOA	;0BA12H
			; Aufruf HLOAD
			;  PE: ARGN=Anzahl Argumente, ARG1=Anfangsadresse
;
LBL:	JP	BLA	;0BA15H
			; Lesen eines Datenblocks fuer Load
			;  PE: HL=erwartete Blockadresse, ARG2=EADR.
			;  PA: HL=Blockadresse, DE=Adr. im RAM, Z=1:Block Ok.
;
;------------------------------------------------------------------------------
; HSAVE
; Aufruf: %HSAVE AADR EADR+1 (SADR)
;------------------------------------------------------------------------------
; eigene ISR:
;------------
ISR:	LD	(IX+00H),0FFH
	EI
	RETI
;----------------------------
;
HSA:	DW	07F7FH
	DB	'HSAVE',1
ARG:	LD	A,(ARN)		;notw. wg. KC85/2-3
	CP	2		;A=Anz. ARG <2
	JR	C,VOR		;HSAVE ohne Param.?
	DEC	DE		;EADR+1 => EADR
	LD	(AR2),DE
	LD	B,'C'		;3 Par. = COM-File
	JR	NZ,TYC
	LD	B,'M'		;genau 2 Parameter
	SBC	HL,HL
	LD	(ARG3),HL	;dann SADR auf 0
TYC:	CALL	PV1
	DB	OSTR		;2xSpace falls
TYP:	DB	'TYP:  ',0	;Neuaufruf
	LD	HL,CUR		;Cursor hinter TYP:
	DEC	(HL)
	DEC	(HL)
;
;Typvorgabe:
;
	LD	A,B
	CALL	PV1
	DB	CRT		;Zeichen (A) auf BS
	DEC	(HL)		;1 Sp. zurueck, fuer
CA4:	CALL	PV1		;Typkorrektur
	DB	KBD		;Zeichen ->A
	CP	3		;BRK?
	RET	Z		;ja, tschuess
	CP	20H		;keine Sonderzeichen
	JR	NC,CA0		;gueltiges Zeichen?
	CP	0DH		;Neueingabe wenn z.B.
	JR	NZ,CA4		;STOP, DEL, CLR
	LD	A,B		;fuer d. Fall Enter
CA0:	CALL	PV1
	DB	CRT		;Zeichen (A) auf BS
	LD	HL,11		;Offset: 11 Zeichen fuer Name und Typ
;
;Hier Einsprungadresse von HKC-CSAVE
;PE: A =Typ (='B'), HL=Offset fuer Dateinamen auf dem Bildschirm (=6)
;
EIN:	EX	AF		;Typ sichern
	CALL	PV1
	DB	OSTR
NAM:	DB	' NAME:',0
;
;Namenseingabe mit Kontrolle:
;
	CALL	PV1		;Zeichenkette eing.
	DB	INLIN		;DE=Zeile im VRAM
	ADD	HL,DE		;Adresse berechnen
	XOR	A		;keine Namenseingabe=
	CP	(HL)		;Programmabbruch
REZ:	RET	Z		;Kopfpuffer unveraendert
;
;NAME+Leerz. uebertragen:
;
	LD	DE,PUK+TNAME
	LD	BC,1016H	;B=Zaehler,C fuer spaeteres LDIR
LD2:	LDI			;1 Zeichen uebertr.
	CP	(HL)		;A war 0, Nullen?
	JR	NZ,LD1
	LD	(HL),20H	;Video-RAM=Leerz.
LD1:	DJNZ	LD2
;
;Argumente uebertragen:
;
	LD	E,PUK+TAADR	;D ist 0B8H
	LD	HL,AR1		;BC ist jetzt =6
	LDIR			;ARG1-3 uebertragen
	LD	E,PUK+TTYP	;DE auf TYP-Byte
	EX	AF
	LD	(DE),A		;Typ -> Kopfpuffer
	LD	A,0D3H		;schreibe MagicBytes
	INC	DE
	LD	(DE),A
	INC	DE
	LD	(DE),A
	INC	DE
	LD	(DE),A
VOR:	LD	HL,PUK+TTYP	;Einspr.v.Anfang
	CALL	MAG		;Kopfpuffer gueltig?
	JR	Z,INI		;ja, File ausgeben
	LD	HL,CUR		;Nein, Fehler anz.
	LD	(HL),7		;ab Spalte 7
	CALL	PV1
	DB	OSTR
	DB	0BH,'VON BIS?',0
	RET			;Zurueck ins CAOS
;
;----------------------------------
;Block mit VT ausgeben
; PE: HL=AADR, B=1:langer Vorton
; PA: HL=AADR naechster Block
; VR: A,B,DE,HL,IY
;----------------------------------
;Regs:	A= fuer Out
;	B,C=Zaehler
;	DE=Daten
;	HL=Adr
;	IY=Checksum
;
NVT:	LD	A,85H		;kein Reset, sonst fehlt eine Halbwelle
	OUT	8DH		;Vorton mit 600Hz
	LD	A,85		;quasi keine Austastluecke
	OUT	8DH		;da OUT schon hier vorn steht
	CALL	HLZ
	LD	DE,13		;DE=Vortonlaenge
	DJNZ	BLS		;wenn B=1:Langer Vorton 
VTO:	LD	DE,4096
BLS:	CALL	HLB		;Vorton ausgeben
	DEC	DE		;bis DE=0
	LD	A,E
	OR	D
	JR	NZ,BLS		;Vorton fertig
	LD	A,85H		;Trennzeichen mit 1200Hz
	OUT	8DH
	LD	D,H		;DE erhaelt BlAdr fuer Adr+Pruefsumme
	LD	E,L
	PUSH	HL		;1 Byte weniger als LD IYH*
	POP	IY		;IY fuer Pruefsummenberechnung
	LD	A,42
	CALL	O8D		;eine Vollschwingung (CY ist 0)
	LD	B,17		;wiederhole 17 mal
	JR	CAD		;BlAdr und dann die Daten ausgeben
;
;Datenblock ausgeben:
;
LDE:	LD	E,(HL)		;naechstes Word
	INC	HL
	LD	D,(HL)
	INC	HL
	ADD	IY,DE		;ChkSum berechnen
CAD:	CALL	ADE		;Word ausgeben
	DJNZ	LDE
	PUSH	IY		;zum Schluss IY ausgeben
	POP	DE		;PushPop spart 1 Byte
;
;Word ausgeben:
;
ADE:	LD	C,16		;16 Bits
RR2:	RR	D		;DE => CY
	RR	E		
	DI			;Ints aus, alles sehr zeitkritisch
	LD	A,85H		;Init CTC mit 1200Hz bzw 2400Hz
	OUT	8DH
	LD	A,42		;lade Zeitkonst. 1
	JR	C,RR1		;sonst rotiere Zeitkonst. 0
	RRCA			;Bit 0 ist 0, CY bleibt also 0
RR1:	CALL	O8D		;CY ausgeben
	DEC	C
	JR	NZ,RR2
	RET
;
;--------------------------------------
;Warte auf Ende der Halb-/Vollschwingung
;----------------
;PE:
; - SWG: CY=0 Vollschw.,CY=1 Halbschw.
; - O8D: wie SWG, A=Zeitkonstante
;
O8D:	OUT	8DH		;ZK an CTC
SWG:	CALL	NC,HLB		;Vollschwingung ?
HLB:	XOR	A
	LD	(IX+0),A	
	EI			;jetzt darf die ISR
HL0:	OR	(IX+0)		;warte bis (IX+0)<>0
	RET	NZ		;raus wenn Bit7 ges.
	JR	HL0
;
;--------------------------------------
;Ausgabe des Files
;------------------
;
INI:	DI
	RES	1,(IX+8)
;
;Interruptservice aendern:
;
	LD	A,I		;aktuelles Segment
	LD	H,A
	LD	L,0EAH		;INT CTC1
	PUSH	HL		;merken
	LD	E,(HL)		;alte ISR nach DE
	LD	(HL),ISR	;schreibe neue ISR
	INC	L
	LD	D,(HL)
	LD	(HL),ISR/256
	PUSH	DE		;alte ISR merken
	LD	A,47H
	OUT	8EH		;Blink-Kanal ein
	LD	A,0CH
	OUT	8EH
	CALL	PIO		;Motor + LED ein
	IN	A,89H
	OR	1		;Flipflop trueck ein
	OUT	89H
	LD	A,3		;Toene aus
	OUT	8CH		;Kanal Reset
	EI
STA:	CALL	HLI		;Hardwaretest+Farbbytes
	LD	HL,PUK		;Adresse Kopfpuffer
	INC	B		;B=1: langer Vorton
	CALL	NVT		;Kopf ausgeben
	LD	HL,(PUK+TAADR)	;AAdr laden
	INC	B		;B=1: langer Vorton
;
;Ausgabe Speicherbereich
;
SAV:	CALL	NVT		;Neuer BlockVT,HL=BlAdr
	LD	A,(IX+13)	;A=Tastencode
	SUB	3		;Test auf BRK
	JR	Z,FER
;
;Endepruefung
;
	EX	DE,HL		;HL sichern
	LD	HL,(PUK+TEADR)	;EAdr holen
	AND	A		;CY:=0
	SBC	HL,DE		;EAdr ueberschritten?
	EX	DE,HL		;HL zurueck
	JR	NC,SAV		;naechster Block
FER:	AND	A
	CALL	SWG		;warte auf letzte HW
	DI
;
;Rueckstellen INT-Service:
;
	POP	DE		;alte Routine holen
	POP	HL		;Adresse holen
	LD	(HL),E
	INC	L
	LD	(HL),D
	CALL	DI1		;Motor + LED aus, CRLF
	CALL	PV1		;bei BRK kein Verify
	DB	BRKT
	RET	C		;bei CY=1 ist A=3
	CALL	PV1
	DB	OSTR		;Zeichenkette ausgeben
VER:	DB	'VERIFY? (Y):',0
	CALL	PV1
	DB	KBD		;Zeichen eingeben ->A
	CP	'Y'		;YES?
	JR	NZ,NLR
	CALL	NLR
	JR	VRI
;
;------------------------------------------------------------------------------
; HVERI
; Aufruf ohne Parameter
;------------------------------------------------------------------------------
;
HVE:	DW	07F7FH
	DB	'HVERI',1
VRI:	CALL	INL		;Initialisierung
SUV:	CALL	BLV
	JR	NZ,SUV		;warte bis Block gueltig
	CALL	MAL		;Magicbytes?
	JR	NZ,SUV		;dann Kopfblock gefunden
	LD	DE,(PUD+TAADR)	;lade AADR
	LD	HL,(PUD+TEADR)	;lade EADR
	SBC	HL,DE	 	;(CY ist 0)
	LD	A,L
	AND	0E0H
	LD	L,A
	ADD	HL,DE		;HL=AADR vom letzten Block
	LD	(EBL),HL 
	CALL	KAZ		;Kopfblock ausgeben
	CALL	HLI		;Init Hexausgabe
	LD	HL,(PUF)
	CALL	HLS		;Adr.Kopfblock anzeigen
VGL:	CALL	BLV		;naechster Block
	JR	Z,VGLA		;Lesefehler?
	CALL	HLS		;dann Adr anzeigen
	LD	A,(IX+0DH)	;BRK ?
	CP	3
	JR	Z,DI1
	CALL	NLR		;neue Zeile
	CALL	SEK		;Zeichenfarbe einstellen
	JR	VG1
VGLA:	CALL	HLZ		;Adr anzeigen mit Zaehlwerkeffekt
VG1:	LD	DE,(EBL)	;letzter Block ?
	AND	A
	SBC	HL,DE
	JR	NZ,VGL
	EX	DE,HL		;"ordentliche" Anzeige der letzten BlockAdr
DI0:	CALL	HLS
DI1:	DI			;PIO Int. aus
	LD	A,3		;PIO=DI, Ton aus
	OUT	08AH
	OUT	8DH		;Kanal Reset
	IN	A,88H
	AND	9FH		;Motor + LED aus
	OUT	88H
	EI
NLR:	CALL	PV1		;Neue Zeile und raus
	DB	CRLF
	RET
;
;Kopfblock aus dem Puffer heraus anzeigen
;
KAZ:	LD	HL,(PUD+TAADR)	;AADR
	LD	DE,(PUD+TEADR)	;EADR
	INC	DE		;fuer KC85 +1
	CALL	PV1
	DB	HLDE
	LD	HL,(PUD+TSADR)	;SADR
	CALL	PV1
	DB	HLHX
	CALL	NLR		;neue Zeile
	LD	HL,PUD+TNAME-1	;1Byte vor Dateinamen
	LD	(HL),020H	;Leerzeichen einfuegen 
	LD	A,(PUD+TTYP)	;fuer Anzeige Typbyte holen
	LD	B,18		;insgesamt 18Zeichen ausgeben:
KA1:	CALL	PV1		; Typbyte,Leerzeichen,Dateiname
	DB	CRT
	LD	A,(HL)
	INC	L
	DJNZ	KA1
	JR	NLR		;neue Zeile
;
;------------------------------------------------------------------------------
; HLOAD
; Aufruf: %HLOAD (AADR)
;------------------------------------------------------------------------------
;
HLO:	DW	07F7FH
	DB	'HLOAD',1
LOA:	CALL	INL		;Initialisierung
SUK:	CALL	PV1
	DB	BRKT		;BRK gedrueckt ?
	JR	C,DI1
	LD	HL,PUK+31	;EADR fuer Kopfpuffer
	LD	(AR2),HL
	LD	L,PUK+TAADR	;HL=AADR Kopfpuffer)
	CALL	BLA		;Block laden
	JR	NZ,SUK
	LD	A,H		;Blockadr=0000H ?
	OR	L
	EX	AF
	CALL	MAL		;Magicbytes vorhanden ?
	JR	NZ,SUK
	CALL	KAZ		;Kopfblock anzeigen
	EX	AF		;War Blockadr=0 ?
DI2:	JR	Z,DI1		;dann raus
	LD	BC,(PUK+TEADR)	;ARG2:=EADR
	LD	(AR2),BC
	LD	HL,(PUK+TAADR)	;erwarteter Block:=AADR
	LD	(ARG3),HL
	LD	(EBL),HL
	LD	A,(ARN)		;HLOAD mit Parameter gestartet ?
	CP	1		;Test ob <1, damit ZF beim Sprung =0 ist
	JR	C,EAF
	EX	DE,HL
	LD	HL,(AR1)
	LD	A,H
	INC	A		;Selbststart unterdruecken ?
	JR	Z,EAF
	LD	(PUK+TAADR),HL	;AADR gem. ARG1
	PUSH	HL
	SBC	HL,DE		;HL:=Offset
	ADD	HL,BC		;EADR:=EADR+Offset
	LD	(PUK+TEADR),HL
	LD	(AR2),HL	;ARG2:=(neue)EADR
	EX	DE,HL
	POP	HL		;HL:=AADR
	CALL	PV1		;die neuen Adressen anzeigen
	DB	HLDE
	CALL	NLR
	XOR	A		;Aufruf mit Param => kein Selbststart
EAF:	EX	AF		;ZF'=1: kein Selbststart
	CALL	HLI		;Init Hexausgabe
	LD	HL,(PUK+TAADR)	;HL:=Blockadr
BLK:	CALL	HLZ
	CALL	BLA		;lese Datenblock
	JR	Z,DL1
	CALL	PV1		;Bei Lesefehler:
	DB	OSTR		;Anzeige BAD! und TAKE 
	DB	' BAD! <T>AKE',19H,0
INP:	CALL	SEK		;Hintergrundfarbe einstellen
	EX	DE,HL		;Speicheradr ordentlich ausgeben
	CALL	HLS
	EX	DE,HL
	CALL	PV1
	DB	KBD		;warte auf Taste 
	CP	3		;BRK ?
DI3:	JR	Z,DI2      
	CP	'T'		;bei T Block uebernehmen,
	PUSH	AF
	CALL	Z,NLR		;und Cursor auf neue Zeile
	CALL	PV1
	DB	OSTR	
	DB	2,0		;Zeile loeschen
	CALL	SEK		;Cursor zurueck und SEEK anzeigen
IN1:	LD	(IX+0DH),0	;bewirkt FastRepeat
	LD	A,120/6		;120ms warten
	CALL	PV1
	DB	WAIT
	CALL	PV1
	DB	KBDZ		;Taste noch gedrueckt ?
	JR	C,IN1		;warte bis Taste losgelassen
	LD	HL,(EBL)
	POP	AF
	JR	Z,DL1
SUB:	EX	DE,HL
	CALL	BLA
	JR	NZ,SUB		;Schleife bis Block Ok.
DL1:	LD	A,H		;Blockadr=FFFFh ?
	AND	L
	INC	A
	JR	Z,DI3		;dann sofort raus
	LD	BC,(EBL)	;Blockadr=Erwarteter Block ?
	SBC	HL,BC
	JR	NZ,DL2
	LD	HL,00020H  
	EX	DE,HL
	ADD	HL,DE		;naechste Speicheradr
	EX	DE,HL		;naechste erwartete Blockadr.
	ADD	HL,BC		;(hier kein Ueberlauf)
	LD	(EBL),HL
	LD	HL,(PUK+TEADR)
	SBC	HL,DE		;letzter Block ?
	EX	DE,HL		;HL:=BLA.AADR naechster Block
	JR	NC,BLK
	LD	HL,(PUK+TEADR)	;wenn fertig
	CALL	DI0		;EADR anzeigen, CTC anhalten und NewLine
	EX	AF		;HLOAD mit Offset gestartet ?
	RET	Z		;ja, raus
	LD	A,(PUK+TTYP)	;Typ=C
	CP	'C'
	RET	NZ		;nein, raus
	LD	HL,(PUK+TSADR)	;sonst zu SADR springen
	JP	(HL)
DL2:	JR	C,SUB
OVR:	CALL	PV1		;Anzeige OVER
	DB	OSTR	
	DB	' OVER',19H,0
	JR	INP		;auf Taste warten.
;----------------------------------
; Lesen eines Datenblocks
;  - BLV fuer HVERI  PE: -
;  - BLA fuer HLOAD  PE: HL=erwartete Blockadresse, ARG2=EADR.
; PA: HL=Blockadresse, DE=Adr. im RAM, Z=1:Block Ok.
;----------------------------------
;
BLV:	LD	A,0FFH		;EADR fuer HVERI>=0FF00H
	LD	(AR2+1),A
	LD	HL,0A7E0H
BLA:	LD	BC,0700H+G01	;B=7, C=Grenzwert 0/1
VTE:	CALL	WAI
	CP	GVT		;VT erkannt: CY=1
	CALL	LED		;System-LED an
	JR	NC,BLA		;HW zu kurz
	DJNZ	VTE
;
;7 VT Halbwellen erkannt
BL0:	CALL	WAI
	CP	GVT		;weitere VT abwarten
	JR	C,BL0
	CP	C		;zwei Trenn-1 abwarten
	JR	NC,BLA		;0 wuerde Neustart fordern
	CALL	WAI		;naechste HW
	CP	C		;0? dann Neustart
	JR	NC,BLA		;B-Reg hat nun 0
	PUSH	HL
;
;Einlesen Datenblock
;
	LD	HL,PUF		;ans Ende vom
BL1:	LD	D,7FH		;Kassettenpuffer
BL2:	CALL	WAI		;(B85C=Adr)
	CP	C		;(B85E=Daten)
	CALL	NC,WAI		;(B87E=CRC)
	RR	D
	JR	C,BL2
	LD	(HL),D
	INC	L		;fertig wenn Adr.B880h
	JP	P,BL1		;erreicht
	CALL	LED		;System-LED aus
;
;Daten in den Speicher kopieren, auch bei Lesefehler
;
	POP	DE		;hole Speicheradr.
	PUSH	DE
	LD	HL,(AR2)	;Endadresse
	XOR	A
	SBC	HL,DE		;Restliche Dateilaenge
	OR	L		;(L->A u. CY->0)
	LD	C,31		;(B ist 0)
	SBC	HL,BC		;<31 Bytes? (EADR zeigt auf das letzte Byte)
	JR	NC,COP
	LD	C,A		;dann nur die Restlaenge
COP:	INC	C		;Anzahl zu kopierender Bytes
	LD	HL,PUD
	LDIR
;
;CRC pruefen
;
	DI
	LD	(ZSP),SP 
	LD	SP,PUF		;SP als Zeiger
	LD	B,16
	POP	HL		;Adr holen
CHK:	POP	DE		;16 Datenwords addieren
	ADD	HL,DE
	DJNZ	CHK
	POP	DE		;vergleiche mit CRC
	AND	A
	SBC	HL,DE
	POP	HL		;SP zeigt jetzt auf ZSP
	LD	SP,HL		;SP wieder zurueck
	EI
	LD	HL,(PUF)	;PA: HL=Blockadresse
	POP	DE		;    DE=ADR im RAM
	RET			;    Z=1:Block Ok.
;--------------------------------------
;Warte auf naechste Halbwelle am TAPE-Eingang
; PA: A=Dauer
;------------------
WAI:	IN	A,88H
	OUT	88H		;KC85/4 Quittung
	LD	E,(IX+0)	
	INC	E
	JR	Z,WAI		;wdh. falls E=0FFh
	LD	(IX+0),0FFH	;fuer naechstes Handshake
	OUT	88H		;KC85/4 Quittung
	LD	A,E
	RET
;--------------------------------------
;System-LED schalten
; PE: CY=1:LED an 
;------------------
LED:	IN	A,88H
	SET	5,A
	JR	C,LED1
	RES	5,A
LED1:	OUT	88H
	RET
;
;--------------------------------------
;Initialisierung fuer HLOAD und HVERI
;
INL:	LD	A,5		;Init CTC2
	OUT	8EH
	LD	A,83H		;EI
	OUT	8AH		;an PIO A
	LD	A,0A3H		;ZK CTC2
;(ab hier mit Ints der PIO rechnen!)
	OUT	8EH
	LD	(IX+0),0FFH	;fuer 1.Handshake
PIO:	IN	A,88H		;Motor + LED ein
	OR	60H
	OUT	88H		;+KC85/4 Quittung
	RET
;
;Pruefe ob Magicbytes vorhanden
;MAL: Aufruf durch HVERI/HLOAD
;MAG: Aufruf durch HSAVE
;
MAL:	LD	HL,PUD+TMAGL-1
MAG:	LD	A,0D3H
	LD	B,3
CMP1:	INC	HL
	CP	(HL)		;Magicbyte ?
	RET	NZ
	DJNZ	CMP1
	RET			;3x Ja - Hurra
;
;------------------------------------------------------------------------------
;Schnelles HLHX
;Anzeige erfolgt links neben dem Cursor !
;KC4:Unterscheidung KC85/3, /4
;------------------------------------------------------------------------------
;KC-Typ ermitteln und Hintergrundfarbe einstellen
;HLI: VR: IY,HL,AF,DE,C
;SEK: VR: HL,AF,C
;---------------------
HLI:	LD	IY,1		;Adresse fuer Byte an Postion X=0,Y=1
	CALL	JPA		;CAOS-UP PADR
	LD	(KC4),HL	;beim KC85/3 ist jetzt L=1
SEK:	LD	HL,COL
	LD	C,(HL)		;alte Farbe sichern
	LD	A,(FAR)		;neue Farbe
	AND	A		;wenn 0
	JR	Z,SE1		;keine Aenderung
	LD	(HL),A
SE1:	CALL	PV1
	DB	OSTR		;fuer die 4 Zeichen einstellen
	DB	'SEEK',0
	LD	(HL),C		;alte Farbe zurueck
	RET
;---------------------
;Ausgabe
;HLS: ohne Zaehlwerkeffekt
;HLZ: mit Zaehlwerkeffekt
;PE:  HL=Hexword
;VR: AF,DE,IY
;---------------------
HLZ:	LD	A,L		;Verschiebung im Zaehlwerk ermitteln
	ADD	A		;Test A>80h + links schieben
	JR	C,HL1
HLS:	XOR	A		;kein Zaehlwerkeffekt
HL1:	RLCA			;Bits 6 u.7 nach 0 u.1 rotieren
	RLCA			;ergibt spaeter die Verschiebung
	AND	3		;A,B=2 Zeilen; C,D=4 Zeilen; E,F=6 Zeilen
	PUSH	BC
	PUSH	HL
	PUSH	AF
	LD	A,L
	LD	HL,(CUR)	;Berechne Zeichenadresse
	LD	DE,(WIN) 
	ADD	HL,DE
	SLA	H
	SLA	H
	SLA	H
	PUSH	HL
	POP	IY		;Zeichenadresse nach IY
	LD	B,0		;beim ersten Byte keine Verschiebung	
	CALL	AHX
	POP	BC		;beim zweiten Byte B=Verschiebung
	POP	AF	 
	PUSH	AF
	CALL	AHX
	POP	HL
	POP	BC
	RET
;
;Hexausgabe eines Bytes
;Anzeige erfolgt links von der Zeichenadr.
;PE:A=Byte, B=Verschiebung fuer Zaehlwerk
;   IY=Zeichenadresse
;PA:IY=neue Zeichenadr
;
AHX:	PUSH	AF
	RLCA			;untere Tetrade nach Bit 2..5
	RLCA
	CALL	HEX		;Anzeigen
	POP	AF
	RRCA			;obere Tetrade nach Bit 2..5
	RRCA
	BIT	6,B		;war untere Tetrade=F 
	JR	NZ,HEX		;ist jetzt Bit 6 gesetzt.
	LD	B,0		;Nur dann Verscheibung behalten
HEX:	AND	3CH	
	OR	B		;A=Zeichen*4+Verschiebung	
	LD	B,A
	DEC	IY
	CALL	JPA		;Pixeladr.holen
	RET	C		;CY=1:ausserhalb
	EX	DE,HL
	CALL	ZAD		;Zeichenadr.holen
	LD	A,(KC4)		;KC85/4 ?
	OR	A
	JR	Z,DR4
;
;Zeichenausgabe beim KC85/3
;(aehnlich Klemm,Haftmann u.Pischel)
;
	CALL	D31	
	DEC	D
	SET	5,E
D31:	CALL	D32
	INC	D
D32:	LD	A,(HL)
	INC	HL
	LD	(DE),A
	SET	7,E
	LD	A,(HL)
	INC	HL
	LD	(DE),A
	RES	7,E
	JR	D43
;
;Zeichenausgabe beim KC85/4
;
DR4:	LD	C,8		;Ueberlauf nach B verhindern
	CALL	D41		;UP 4x aufrufen
D41:	CALL	D42
D42:	LDI
	LDI
D43:	INC	B		;Test ob naechstes Zeichen
	LD	A,B
	AND	3		;naechstes Zeichen ?
	RET	NZ
	LD	A,B
;
;berechne Zeichenadr in der Zeichenbildtab.
;PE: A=Zeichen*4+Verschiebung
;PA: HL=Adresse
;
ZAD:	ADD	A
	OR	80h
	LD	HL,(TL0)	;CCTL0
	CP	0D0H
	JR	C,ZA1
	INC	H
	ADD	7*8
ZA1:	ADD	L
	LD	L,A
	RET	NC
	INC	H
	RET
;
;Aufruf von CAOS-UP PADR ohne den Sprungverteiler zu benutzen
;PE: IY=Zeichenposition
;
JPA:	LD	HL,(SUT)	;SUTAB
	LD	DE,PADR*2	;CAOS-UP 34H
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		;DE=UP-Adresse
	PUSH	IY
	POP	HL		;HL=Zeichenpostion
	PUSH	DE
	RET
;
;------------------------------------------------------------------------------
;HeaderKC-BASIC-Files und Sprungverteiler
;------------------------------------------------------------------------------
; CSAVE
;---------------------
CSA:	LD	HL,(035FH)	;Anfangsadresse
	LD	(AR1),HL
	LD	HL,(03D7H)	;Endadresse
	LD	(AR2),HL
	LD	HL,0300H
	LD	(ARG3),HL
	LD	A,'B'		;Typ=Basic
	LD	HL,6		;6 Byte Offset fuer Dateiname
	PUSH	IY
	CALL	EIN		;File saven
	POP	IY
	RET
;
;---------------------
; CLOAD
;---------------------
CLO:	LD	HL,(03D7H)	;Aktuelles Programmende in Basic
	DEC	HL
	DEC	HL
	LD	(AR1),HL	;als Parameter an HLOAD uebergeben
	LD	A,1		;Das File wird angehaengt.
	LD	(ARN),A
	PUSH	HL
	PUSH	IY
	CALL	LOA		;File loaden
	POP	IY
	LD	HL,(ARG3)	;Anfangsadresse des Files ohne Offset
	LD	DE,02BC0H	;Z1013-Basic-File ?
	XOR	A
	SBC	HL,DE
	POP	DE		;echte Anfangsadresse
	LD	HL,(PUK+TEADR)	;echte Endadresse
	JR	NZ,LD7
	SBC	HL,DE		;(CY ist 0)
	LD	BC,65		;Z1013-Basic-Files enthalten zusaetzlich die
	SBC	HL,BC		;letzten 65 Bytes des Basic-Arbeitsbereiches.
	PUSH	BC		;Diese muessen entfernt werden.
	EX	(SP),HL		;HL und BC tauschen
	POP	BC		;BC=Nettolaenge des Files 
	ADD	HL,DE
	LDIR			;File um 65 Byte nach vorne verschieben
	EX	DE,HL
LD7:	LD	(03D7H),HL	;Neues Programmende im Arbeitsbereich eintragen
	LD	(03D9H),HL
	LD	(03DBH),HL
	LD	DE,0401H	
	LD	HL,(PUK+TAADR)	;AADR > 401H ?
	XOR	A		;dann wurde das Programm angehaengt
	SBC	HL,DE		; => Selbststart unterdruecken
	JR	NZ,LD8
	LD	L,89H		;Token für RUN in den Eingabepuffer
	LD	(0362H),HL	;Das Byte dahinter loeschen (H ist 0)
	LD	DE,0C41FH	;Basic-Selbststartadresse
	LD	HL,(PUK+TSADR)	;Startadresse des Files
	SBC	HL,DE		;Startadresse = 0C41F?
	RET	Z		;ausfuehren
LD8:	LD	DE,0C48AH	;kein Selbststart, dann nach LIN10 springen
	RET			;Die Zeilenpointer werden angepasst und in die
				;Basic-Eingabeaufforderung gesprungen
;------------------------------------
; Sprungverteiler
; Aufruf %SPV AADR
;------------------------------------
SPI:	DW	07F7FH
	DB	'SPV',1
SPL:	LD	A,(ARN)		;notw. wg. KC85/2-3
	AND	A		;Zieladresse als Parameter erforderlich
	JR	Z,SPE		;ansonsten Fehlermeldung
	EX	DE,HL		;DE=Zieladresse
	LD	HL,SPV
	LD	BC,SPEND-SPV
	LDIR			;Spungverteiler kopieren
	RET
SPE:	CALL	PV1
	DB	OSTR
	DB	0BH,'%SPV AADR?',0
	RET			;Zurueck ins CAOS
;
;------------------------------------
; BASIC-Sprungverteiler
; wird durch %SPV in den Arbeitsspeicher kopiert
;----------------------
;
SPV:	JR	CL1		;SPV+0: CLOAD
	JR	CS1		;SPV+2: CSAVE
				;SPV+4: BLOAD
BLO:	CALL	0F018H		;CAOS-Ebene
	PUSH	IY
	CALL	LOA		;Aufruf HLOAD
	POP	IY
	JR	CS2
;
CS1:	CALL	0F018H		;CAOS-Ebene
	CALL	CSA		;Aufruf HKC-CSAVE
CS2:	CALL	0F01BH		;Basic-Ebene
	RET
;
CL1:	CALL	0F018H		;CAOS-Ebene
	CALL	CLO		;Aufruf HKC-CLOAD
	CALL	0F01BH		;Basic-Ebene
	PUSH	DE		;DE=Sprungziel im Basic-ROM
	RET
SPEND:
;------------------------------------------------------------------------------
	DS	FEND-$,0FFH	;fuer OCE ;-)
;------------------------------------------------------------------------------

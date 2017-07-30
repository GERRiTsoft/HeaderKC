program K85_TurboKC_Konverter;
{$M 16384,0,655360}
{$A+,B-,D-,L-,Y-,O-,F-,I-,G-,N-,E-,P-,Q-,R-,S+,T-,V-,X-}
uses Crt;
const Posi:Boolean=True;Vers='1.00';
      Cpyr='(c) 2017 Gerrit Schulz ˙ GERRiTsoft@gmx.de';
      Kopf:array[1..44]of Byte=($52,$49,$46,$46,$44,0,0,0,
      $57,$41,$56,$45,$66,$6D,$74,$20,$10,0,0,0,1,0,1,0,
      $44,$AC,0,0,$44,$AC,0,0,1,0,8,0,$64,$61,$74,$61,0,0,0,0);
      {'RIFFD   WAVEfmt      D¨  D¨    data    '}

var R:array[1..128]of Byte;
    RW:array[1..64]of Word absolute R;
    B:array[0..129]of Byte;
    ZName,S:string;j:LongInt;
    Pr,i,aadr,eadr,Blnr,Result,PC:Word;
    Quelle,ZielB:file;Ziel:Text;
    Magic:Boolean;

procedure Hilfe;
begin
  TextAttr:=7;ClrScr;
  Writeln('Eingabe:');
  Writeln('========');
  Writeln;Writeln('HEADER5 [Quellpfad]Quelldatei.K85 [ [Zielpfad]Zieldatei]');
  TextColor(LightGreen);
  Writeln('wandelt .K85-Bin-Dateien bzw. Programme in eine TurboKC-Wave-Datei um.');
  TextColor(7);Writeln;
  Writeln('Es werden .K85-Dateien mit 128 Byte Header+Daten unterstÅtzt.');
  Writeln('Auch jede beliebige andere Datei bis 64KB Grî·e ist konvertierbar.');
  TextColor(LightRed);
  Writeln('Bitte immer vollstÑndige Dateinamen ohne Platzhalter angeben!');
  TextColor(7);Writeln;
  Writeln('Das Programm kann mit Strg+C unterbrochen werden.');
  Writeln;TextColor(LightMagenta);
  Writeln('Header5-Konverter Version '+vers:54);
  TextColor(11);
  Writeln('(c) Gerrit':43);
  Writeln('   $chulz':43);
  Writeln('Aschersleben':46);
  TextColor(9);
  Writeln('GERRiTsoft@gmx.de':49);
end;{Hilfe Format 44.1 kHz,8Bit,Mono}

Procedure PosVor;
begin
  Write(Ziel,'¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿@@@@@@@@@@@@@@@@@@@@');
end;

Procedure NegVor;
begin
  Write(Ziel,'@@@@@@@@@@@@@@@@@@@@¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿');
end;

Procedure Trenn;
begin
  if Posi then Write(Ziel,'¿¿¿¿¿¿¿¿¿¿@@@@@@@@@@')
	  else Write(Ziel,'@@@@@@@@@@¿¿¿¿¿¿¿¿¿¿');
end;

Procedure Null;
begin
  if Posi then begin
Write(Ziel,'¿¿¿¿¿');Posi:=False;end
	  else begin
Write(Ziel,'@@@@@');Posi:=True;end;
end;

Procedure Eins;
begin
  if Posi then begin Write(Ziel,'¿¿¿¿¿¿¿¿¿¿');Posi:=False;end
	  else begin Write(Ziel,'@@@@@@@@@@');Posi:=True;end;
end;

Procedure Silence;
begin
  for i:=1to 44100do
    Write(Ziel,'Ä');
end;

Procedure Vorton;
begin
  if Posi
    then for i:=1to 4000do
      PosVor
    else for i:=1to 4000do
      NegVor;
end;

Procedure Aus;
{erzeugt Block B mit Blnr & Pr¸fsumme}
begin
  Pr:=0;
  B[0]:=Blnr;
  for i:=1to 128do begin
    B[i]:=R[i];
    Inc(Pr,R[i]);{PrÅfsumme bilden}
  end;{for}
  Inc(i);B[i]:=Pr;
  if Posi then for i:=1to 25do PosVor
	  else for i:=1to 25do NegVor;
  Trenn;
  for i:=0to 129do begin{Bytes}
    j:=1;
    while j<$81 do begin
      if B[i]And j=j then Eins else Null;
      Inc(j,j);
    end;
  end;{Bytes}
end;{Aus}

Procedure Header;
begin
  BlockRead(Quelle,R,128,Result);
  if R[14]<>$D3then Magic:=True;
  if R[15]<>$D3then Magic:=True;
  if R[16]<>$D3then Magic:=True;
  if(Result<128)or Magic then begin
    Writeln;
    Writeln('Ihrer K85-Datei fehlt leider noch ein gÅltiger Header');
    {$I-}Reset(Quelle,1);{$I+}
    Write('Anfangsadresse:');Readln(S);
    Val('$'+S,RW[1],Result);
    RW[2]:=RW[1]+FileSize(Quelle);{eadr}
    Write('[Startadresse]:');Readln(S);
    Val('$'+S,RW[3],Result);
    Write('Typ (1 Zeichen kl/GR):');S:=ReadKey;Writeln(S);
    R[13]:=Ord(S[1]);
    R[14]:=$D3;RW[8]:=$D3D3;
    S:='                ';
    Write('Dateiname max. 16):');Readln(S);
    for i:=1to 16do
    R[16+i]:=Ord(S[i]);
  end;
  aadr:=RW[1];
  eadr:=RW[2];
  Blnr:=$1;
  Aus;
end;

Procedure Data;
begin
  repeat
    BlockRead(Quelle,R,128,Result);
    Inc(Blnr);
    Aus;
  until Eof(Quelle);
    Aus;
  if Result<128then begin
    Writeln('Ihrer K85-Datei fehlen mîglicherweise Daten am Ende');
    Write('das File kînnte dennoch einlesbar sein');
  end;
end;

begin{Hauptprogramm}
  FileMode:=0;PC:=ParamCount;
  if(PC<1)or(PC>2)then begin HILFE;Exit;end;
  if(PC=2)and(ParamStr(PC)=ParamStr(PC+1))then begin
    Write('Die Dateinamen/Pfade sind gleich.');Exit;
  end;
  if PC=2then ZName:=ParamStr(2)else begin
    i:=Pos('.',ParamStr(1));
    if i=0then ZName:=ParamStr(1)+'.WAV'else
      ZName:=Copy(ParamStr(1),1,i)+'WAV';
  end;
  Assign(Quelle,ParamStr(1));
  {$I-}
  Reset(Quelle,1);
  {$I+}
  if IOResult<>0then begin
    Writeln('die Datei ',ParamStr(PC),' konnte nicht geîffnet werden.');
    Exit;
  end;
  Assign(ZielB,ZName);
  {$I-}
  Reset(ZielB);
  {$I+}
  if IOResult=0then begin
    Write('die Datei ',ZName,' existiert bereits. öberschreiben? J/N');
    if ReadKey<>'j'then Exit;
  end;
  Rewrite(ZielB,1);
  BlockWrite(ZielB,Kopf,44,Result);
  Close(ZielB);Assign(Ziel,ZName);Append(Ziel);

  Vorton;Header;
  Data;Silence;

  Close(Quelle);Close(Ziel);FileMode:=2;
  Assign(ZielB,ZName);Reset(ZielB,1);
  j:=FileSize(ZielB);Seek(ZielB,4);
  BlockWrite(ZielB,j,4,Result);j:=j-44;
  Seek(ZielB,$28);BlockWrite(ZielB,j,4,Result);
  Close(ZielB);
  Writeln;
  TextColor(11);
  Write(cpyr);
  TextColor(7);Writeln(' ');
end.{Hauptprogramm}
Start Sa, 23.1.10
Mi,24.3.10: Kommentar zu {Words} korrigiert, lÑngere Pause am Ende
Mo,4.12.11: VT jetzt exakt wie Brosig = 2048 Waves
Do,25.7.13: HeaderprÅfung eingebaut, Bugfix zusÑtzliches Aus

Was mir aber noch mehr behagt: Z13CONV:
In einer g‰ngigen .K85-Datei ist zun‰chst der Kopf mit
aadr,eadr,sadr,crc+creator,type,D3D3D3,16Byte=Name
Dann die entsprechende Menge Daten mit Auff¸llung auf volle 128 Byte.

Ein Block besteht nun aus 1 Byte f¸r die BlockNr,
dann 128 Byte Daten und 1 Byte PrÅfsumme Åber alles.
Der Kopfblock sollte eine Zieladresse >0200 beinhalten.
Samplingfrequenz: 44100 Hz 8 Bit Mono
Nun reiht das Prog einfach die Muster aus 40h, 80h und C0h aneinander:

Vorton hat 40 Byte ~ 1100Hz:
¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿@@@@@@@@@@@@@@@@@@@@
neg.@@@@@@@@@@@@@@@@@@@@¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
vor jedem Block davon je 7 St¸ck
beide Vortˆne d¸rfen gleich lang sein, daher je 2048 Schwingungen f¸r je 3,1s
(Brosig verwendet auch 2048 Schwingungen)
Trennzeichen 20 Byte ~ 2200Hz:
¿¿¿¿¿¿¿¿¿¿@@@@@@@@@@ neg.@@@@@@@@@@¿¿¿¿¿¿¿¿¿¿
Null = 4400Hz:
¿¿¿¿¿ oder negativ @@@@@
Eins = 2200Hz:
¿¿¿¿¿¿¿¿¿¿ oder @@@@@@@@@@
(daﬂ dabei etwas Gleichstrom entsteht
war nur f¸r die Rundfunk¸bertragung problematisch)
und eine Austastl¸cke nach jedem Block
34 x ¿ oder @ (die Phasenlage wechselt mit jeder 1)
Fehlen am Ende der K85-Datei Bytes, mit Nullen auff¸llen und Hinweis melden!
Zum Schluﬂ noch 12000 Nullen, um etwas Silence zu haben,
da manche Player gerne das Ende abschneiden.

----------------------------------
KC85:
Die L‰nge der Schwingungen so, daﬂ es einigermaﬂen mit der korrekten Frequenz
arbeitet, aber ein wenig 22050kHz-like?!
(Hab es noch mal mit Haftmanns Angaben im Sourcecode von KCLOAD abgeglichen)
Einsen und Vorton: (ich setze einfach mal eine negative Welle voraus wie
bei KCCONV)
@@@@@@@@@@Ä¿¿¿¿¿¿¿¿¿¿
(10 von jeder Sorte+80h=1050Hz)
Der Vorton gute 3.8 Sek lang, also exakt 4000 Schwingungen
Blockvorton = 160 (A0) Schwingungen
Stopbit bzw. Trennzeichen:
@@@@@@@@@@@@@@@@@@@@¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
(also 20 von jeder Sorte ohne Nulldurchgang ~ 550Hz von 566)
dahinter am Blockende ' = 60h
Null:
¿¿¿¿¿Ä@@@@@
(insgesamt 11 ~ 2004Hz den originalen 1950Hz auch sehr nahe.)

die Blockl¸cken vielleicht 1024 mal 80h
(ich weiﬂ die entstehen durch das Umladen in den IRM)
und um es ganz 'rogh' zu machen, die letzte Blockl¸cke etwas k¸rzer,
384 mal 80h; dann hˆrt man es schon: der letzte Block!

Also wenn mich mal die Programmierwut packt?

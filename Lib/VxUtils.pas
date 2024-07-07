unit VxUtils;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Graphics, ueLed;


Const
  _rsUnknown   = 0;
  _rsOK        = 1;
  _rsDataError = 2;
  _rsNetError  = 3;

  _rkRead      = 0; // For get Register status
  _rkWrite     = 1; // For get Register status

Type

  TRegisterModule = record
    Index   : integer;
    Status  : integer;
    Enabled : boolean;
  end;

Const
  Mask : array[0..15] of word =
    ($0001, $0002, $0004, $0008, $0010, $0020, $0040, $0080,
     $0100, $0200, $0400, $0800, $1000, $2000, $4000, $8000);

  LedComColor  : array[0..3] of TColor = ($003B3B3B, clLime, clYellow, clRed);

type
  TWordBits = array[0..15] of boolean;

function FloatStr(V : double; Precision : integer) : string;
function CalcLine(X1,Y1,X2,Y2 : double; var Slope, Inter : double): boolean;
function WordToBits(W : word) : TWordBits;
function BitsToWord(Bits : TWordBits) : word;
function RegisterConflictMsg(Index, Register : integer) : string;
procedure SetLedStatus(Led : TuELED; Status : integer);
function RightJustify(s : string; L : integer) : string;

implementation

function FloatStr(V : double; Precision : integer) : string;
begin
  Str(V:0:Precision, Result);
end;

function CalcLine(X1,Y1,X2,Y2 : double; var Slope, Inter : double): boolean;
begin
  if Round(X2-X1)<>0 then
  begin
    Result:=true;
    try
      Slope:=(Y2-Y1)/(X2-X1);
      Inter:=((X2*Y1)-(X1*Y2))/(X2-X1);
    except
      Result:=false;
    end;
  end
  else
    Result:=false;
end;

function WordToBits(W : word) : TWordBits;
Var
  c : integer;
begin
  for c:=0 to 15 do
    Result[c]:=(W and Mask[c])<>0;
end;

function BitsToWord(Bits : TWordBits) : word;
Var
  c : integer;
begin
  Result:=0;
  for c:=0 to 15 do
    if Bits[c] then
      Result:=Result or Mask[c]
end;

function RegisterConflictMsg(Index, Register : integer) : string;
begin
  Result:=format('Write register conflict in Module %d. The Register N° %d was already used.',[Index, Register]);
end;

procedure SetLedStatus(Led : TuELED; Status : integer);
begin
  if Status in [0..3] then
    Led.Color:=LedComColor[Status]
  else
    Led.Color:=LedComColor[0];
end;

function RightJustify(s: string; L: integer): string;
begin
  Result:=S;
  while Length(Result)<L do
    Result:=' '+Result;
end;

end.


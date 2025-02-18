unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCButton, BGRACustomDrawn, JvSimScope,
  BGRAFlashProgressBar, ECSwitch, LedNumber, VxUtils, ueled;

type

  TAnalogInChannelParams = record
    Register   : word;
    Umis       : string;
    Precision  : integer;
    X1         : double;
    Y1         : double;
    X2         : double;
    Y2         : double;
    ScopeMax   : double;
    Slope      : double; // runtime calc
    Inter      : double; // runtime calc
  end;

  TAnalogInputParams = record
    CH  : array[1..2] of TAnalogInChannelParams;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    UMis_CH_1: TLabel;
    UMis_CH_2: TLabel;
    pts_CH_1: TLabel;
    pts_CH_2: TLabel;
    lblName: TLabel;
    Display_1: TLEDNumber;
    Display_2: TLEDNumber;
    Panel1: TPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    // Common
    FIndex                : integer;
    FName                 : string;
    FRunning              : boolean;
    CommRegisterRead      : TCommRegisterRead;
    CommRegisterWrite     : TCommRegisterWrite;
    CommRegisterFastWrite : TCommRegisterFastWrite;
    CommReadRegisterAdd   : TCommReadRegisterAdd;
    CommWriteRegisterAdd  : TCommWriteRegisterAdd;
    CommRegisterStatus    : TCommRegisterStatus;
    LedCom                : array[1..2] of TuELED;
    // Specific
    Scope                 : TJvSimScope;
    Params                : TAnalogInputParams;
    Display               : array[1..2] of TLedNumber;
    UMis_CH               : array[1..2] of TLabel;
    pts_CH                : array[1..2] of TLabel;
    WValues               : array[1..2] of word;
    AValues               : array[1..2] of double;
    Regs                  : array[1..2] of TRegisterModule;
    procedure CreateScope;
    function GetWordValue(index : integer): word;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure OnScopeUpdate(Sender : TObject);
    procedure SetWordValue(index : integer; AValue: word);
  public
    procedure Start;
    procedure Stop;
    procedure PrepareStart;
    function Edit : boolean;
    procedure LoadFromFile(Filename : string);
    procedure SaveToFile(Filename : string);
    procedure SetHooks(Hooks : PHooksRecord);
    property Index : integer read FIndex write SetFIndex;
    property Name : string read FName write FName;
    property WordValue[index : integer] : word read GetWordValue write SetWordValue;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Const
  ChannelColor : array[1..2] of TColor = (clAqua, $000080FF);

var
  VxForm: TVxForm;

function StrAnalogValue(V : double; Precision : integer; Const width : integer = 11) : string;
Var
  isNeg : boolean;
  S : string;
begin
  isNeg:=V<0.0;
  if IsNeg then
    V:=Abs(V);
  Str(V:0:Precision,S);

  while Length(S)<width do
    S:=' '+S;
  if isNeg then
    Result:='-'+S
  else
    Result:='+'+S;
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  Display[1]:=Display_1;
  Display[2]:=Display_2;
  UMis_CH[1]:=UMis_CH_1;
  UMis_CH[2]:=UMis_CH_2;
  pts_CH[1] :=pts_CH_1;
  pts_CH[2] :=pts_CH_2;
  SetDefaultParams;
  CreateScope;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value  : word;
  c : integer;
begin
  for c:=1 to 2 do
  begin
    Regs[c].Status:=CommRegisterRead(Regs[c].Index, {%H-}Value);
    if Regs[c].Status = _rsOK then
      WordValue[c]:=Value;
    SetLedStatus(LedCom[c], Regs[c].Status);
  end;
end;

procedure TVxForm.CreateScope;
begin
  Scope := TJvSimScope.Create(Self);
  Scope.SetBounds(4,150,385,162);
  Scope.Minimum:=0;
  Scope.Maximum:=100;
  Scope.GridSize:=-1;
  Scope.VerticalGridSize:=16;
  Scope.HorizontalGridSize:=10;
  Scope.DisplayUnits:=jduLogical;
  Scope.UpdateTimeSteps:=1;
  with Scope.Lines.Add do
  begin
    Color:=ChannelColor[1];
    PositionUnit:=jluPercent;
    Position:=0;
  end;
  with Scope.Lines.Add do
  begin
    Color:=ChannelColor[2];
    PositionUnit:=jluPercent;
    Position:=0;
  end;
  Scope.Parent:=Self;
  Scope.OnUpdate:=OnScopeUpdate;
end;

function TVxForm.GetWordValue(index : integer): word;
begin
  Result:=WValues[index];
end;

procedure TVxForm.SetDefaultParams;
Var
  c : integer;
begin
  With Params do
  begin
    for c:=1 to 2 do
    begin
      CH[c].Umis:='V';
      CH[c].Precision:=2;
      CH[c].X1:=0;
      CH[c].Y1:=0;
      CH[c].X2:=65535;
      CH[c].Y2:=10.0;
      CH[c].ScopeMax:=65535;
      CalcLine(CH[c].X1, CH[c].Y1, CH[c].X2, CH[c].Y2, CH[c].Slope, CH[c].Inter);
    end;
    CH[1].Register:=3;
    CH[2].Register:=4;
  end;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  for c:=1 to 2 do
  begin
    UMis_CH[c].Caption:=Params.CH[c].Umis;
    AValues[c]:=WValues[c]*Params.CH[c].Slope+Params.CH[c].Inter;
    Display[c].Caption:=StrAnalogValue(AValues[c], Params.CH[c].Precision);
    with Params do
    begin
      CalcLine(CH[c].X1, CH[c].Y1, CH[c].X2, CH[c].Y2, CH[c].Slope, CH[c].Inter);
    end;
  end;
  lblName.Hint:='CH1 Reg : '+IntToStr(Params.CH[1].Register)+#13+
                'CH2 Reg : '+IntToStr(Params.CH[2].Register);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.OnScopeUpdate(Sender: TObject);
begin
  Scope.Lines[0].Position:=Round(Integer(WValues[1])*100/Params.CH[1].ScopeMax);
  Scope.Lines[1].Position:=Round(Integer(WValues[2])*100/Params.CH[2].ScopeMax);
end;

procedure TVxForm.SetWordValue(index : integer; AValue: word);
begin
  if WValues[index]<>AValue then
  begin
    WValues[index]:=AValue;
    pts_CH[index].Caption:=IntToStr(Avalue);
    AValues[index]:=AValue*Params.CH[index].Slope+Params.CH[index].Inter;
    Display[index].Caption:=StrAnalogValue(AValues[index], Params.CH[index].Precision);
  end;
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  FRunning:=true;
  Scope.Active:=true;
end;

procedure TVxForm.Stop;
begin
  Scope.Active:=false;
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.PrepareStart;
Var
  c : integer;
begin
  for c:=1 to 2 do
    Regs[c].Index:=CommReadRegisterAdd(Params.CH[c].Register);
end;

function TVxForm.Edit: boolean;
begin
 Result:=EditParams(FIndex, Params);
 if Result then
   ApplyParams;
end;

procedure TVxForm.LoadFromFile(Filename: string);
Var
  ini : TMemIniFile;
  Section : string;
begin
  Section:='SLOT_'+IntToStr(FIndex);

  if Filename<>'' then
  begin
    ini:=TMemIniFile.Create(FileName);
    try
      Params.CH[1].Register:=ini.ReadInteger(Section,'CH1.Register',Params.CH[1].Register);
      Params.CH[1].Umis:=ini.ReadString(Section,'CH1.Umis',Params.CH[1].Umis);
      Params.CH[1].Precision:=ini.ReadInteger(Section,'CH1.Precision',Params.CH[1].Precision);
      Params.CH[1].X1:=ini.ReadFloat(Section,'CH1.X1',Params.CH[1].X1);
      Params.CH[1].Y1:=ini.ReadFloat(Section,'CH1.Y1',Params.CH[1].Y1);
      Params.CH[1].X2:=ini.ReadFloat(Section,'CH1.X2',Params.CH[1].X2);
      Params.CH[1].Y2:=ini.ReadFloat(Section,'CH1.Y2',Params.CH[1].Y2);
      Params.CH[1].ScopeMax:=ini.ReadFloat(Section,'CH1.ScopeMax',Params.CH[1].ScopeMax);

      Params.CH[2].Register:=ini.ReadInteger(Section,'CH2.Register',Params.CH[2].Register);
      Params.CH[2].Umis:=ini.ReadString(Section,'CH2.Umis',Params.CH[2].Umis);
      Params.CH[2].Precision:=ini.ReadInteger(Section,'CH2.Precision',Params.CH[2].Precision);
      Params.CH[2].X1:=ini.ReadFloat(Section,'CH2.X1',Params.CH[2].X1);
      Params.CH[2].Y1:=ini.ReadFloat(Section,'CH2.Y1',Params.CH[2].Y1);
      Params.CH[2].X2:=ini.ReadFloat(Section,'CH2.X2',Params.CH[2].X2);
      Params.CH[2].Y2:=ini.ReadFloat(Section,'CH2.Y2',Params.CH[2].Y2);
      Params.CH[2].ScopeMax:=ini.ReadFloat(Section,'CH2.ScopeMax',Params.CH[2].ScopeMax);
    finally
      ini.Free;
    end;
  end;
  ApplyParams;
end;

procedure TVxForm.SaveToFile(Filename: string);
Var
  ini : TMemIniFile;
  Section : string;
begin
  Section:='SLOT_'+IntToStr(FIndex);
  ini:=TMemIniFile.Create(FileName);
  try
    ini.WriteString(Section, 'ModuleName', FName);
    ini.WriteInteger(Section,'CH1.Register',Params.CH[1].Register);
    ini.WriteString(Section,'CH1.Umis',Params.CH[1].Umis);
    ini.WriteInteger(Section,'CH1.Precision',Params.CH[1].Precision);
    ini.WriteFloat(Section,'CH1.X1',Params.CH[1].X1);
    ini.WriteFloat(Section,'CH1.Y1',Params.CH[1].Y1);
    ini.WriteFloat(Section,'CH1.X2',Params.CH[1].X2);
    ini.WriteFloat(Section,'CH1.Y2',Params.CH[1].Y2);
    ini.WriteFloat(Section,'CH1.ScopeMax',Params.CH[1].ScopeMax);

    ini.WriteInteger(Section,'CH2.Register',Params.CH[2].Register);
    ini.WriteString(Section,'CH2.Umis',Params.CH[2].Umis);
    ini.WriteInteger(Section,'CH2.Precision',Params.CH[2].Precision);
    ini.WriteFloat(Section,'CH2.X1',Params.CH[2].X1);
    ini.WriteFloat(Section,'CH2.Y1',Params.CH[2].Y1);
    ini.WriteFloat(Section,'CH2.X2',Params.CH[2].X2);
    ini.WriteFloat(Section,'CH2.Y2',Params.CH[2].Y2);
    ini.WriteFloat(Section,'CH2.ScopeMax',Params.CH[2].ScopeMax);
    ini.UpdateFile;
  finally
    ini.Free;;
  end;
end;

procedure TVxForm.SetHooks(Hooks: PHooksRecord);
begin
  CommRegisterRead      :=Hooks^.CommRegisterRead;
  CommRegisterWrite     :=Hooks^.CommRegisterWrite;
  CommRegisterFastWrite :=Hooks^.CommRegisterFastWrite;
  CommReadRegisterAdd   :=Hooks^.CommReadRegisterAdd;
  CommWriteRegisterAdd  :=Hooks^.CommWriteRegisterAdd;
  CommRegisterStatus    :=Hooks^.CommRegisterStatus;
end;

begin
  VxForm:=nil;
end.


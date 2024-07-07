unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCButton, BGRACustomDrawn,
   BCFluentSlider, atshapelinebgra, ECSwitch, LedNumber,
  VxUtils, ueled;

type

  TAnalogOutChannelParams = record
    Register   : word;
    FastWrite  : boolean;
    Umis       : string;
    Precision  : integer;
    X1         : double;
    Y1         : double;
    X2         : double;
    Y2         : double;
    SafeValue  : double;
    Slope      : double; // runtime calc
    Inter      : double; // runtime calc
    SliderSlope: double; // runtime calc
    SliderInter: double; // runtime calc
  end;

  TAnalogOutputParams = record
    CH  : array[1..2] of TAnalogOutChannelParams;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    BtnEdit_1: TBCButton;
    BtnSafe_1: TBCButton;
    BtnSafe_2: TBCButton;
    BtnEdit_2: TBCButton;
    Slider_1: TBCFluentSlider;
    Slider_2: TBCFluentSlider;
    Display_1: TLEDNumber;
    Display_2: TLEDNumber;
    EditValue_1: TEdit;
    EditValue_2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    lblMin_1: TLabel;
    lblMax_1: TLabel;
    lblMin_2: TLabel;
    lblMax_2: TLabel;
    ShapeLineBGRA1: TShapeLineBGRA;
    UMis_CH_1: TLabel;
    pts_CH_1: TLabel;
    pts_CH_2: TLabel;
    lblName: TLabel;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    UMis_CH_2: TLabel;
    procedure BtnEditClicked(Sender: TObject);
    procedure BtnSafeClicked(Sender: TObject);
    procedure EdValueExit(Sender: TObject);
    procedure EdValueKeypressed(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure SliderChangeValue(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    // Common
    FIndex                : integer;
    FName                 : string;
    FRunning              : boolean;
    Updating              : boolean;
    CommRegisterRead      : TCommRegisterRead;
    CommRegisterWrite     : TCommRegisterWrite;
    CommRegisterFastWrite : TCommRegisterFastWrite;
    CommReadRegisterAdd   : TCommReadRegisterAdd;
    CommWriteRegisterAdd  : TCommWriteRegisterAdd;
    CommRegisterStatus    : TCommRegisterStatus;
    LedCom                : array[1..2] of TuELED;
    // Specific
    Display               : array[1..2] of TLedNumber;
    Slider                : array[1..2] of TBCFluentSlider;
    LblCHUMis             : array[1..2] of TLabel;
    lblMin                : array[1..2] of TLabel;
    lblMax                : array[1..2] of TLabel;
    BtnEdit               : array[1..2] of TBCButton;
    BtnSafe               : array[1..2] of TBCButton;
    EdValue               : array[1..2] of TEdit;
    LblPoints             : array[1..2] of TLabel;
    AValues               : array[1..2] of Double;
    WValues               : array[1..2] of word;
    Regs                  : array[1..2] of TRegisterModule;
    Params                : TAnalogOutputParams;
    function GetAnalogValue(index : integer): double;
    function GetWordValue(index : integer): word;
    procedure SetAnalogValue(index : integer; AValue: double);
    procedure SetFIndex(AValue: integer);
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetWordValue(index : integer; AValue: word);
    procedure EnergyZero;
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
    property AnalogValue[index : integer] : double read GetAnalogValue write SetAnalogValue;
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
  LedCom[1] :=LedCom_1;
  LedCom[2] :=LedCom_2;
  Display[1]:=Display_1;
  Display[2]:=Display_2;
  LblCHUMis[1]:=UMis_CH_1;
  LblCHUMis[2]:=UMis_CH_2;
  LblPoints[1] :=pts_CH_1;
  LblPoints[2] :=pts_CH_2;
  lblMin[1] :=lblMin_1;
  lblMin[2] :=lblMin_2;
  lblMax[1] :=lblMax_1;
  lblMax[2] :=lblMax_2;
  Slider[1] :=Slider_1;
  Slider[2] :=Slider_2;
  BtnEdit[1]:=BtnEdit_1;
  BtnEdit[2]:=BtnEdit_2;
  BtnSafe[1]:=BtnSafe_1;
  BtnSafe[2]:=BtnSafe_2;
  EdValue[1]:=EditValue_1;
  EdValue[2]:=EditValue_2;
  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.BtnEditClicked(Sender: TObject);
Var
  c : integer;
  S : string;
begin
  C:=(Sender as TComponent).Tag;
  if C in [1,2] then
  begin
    Str(AValues[c]:0:Params.CH[c].Precision,S);
    EdValue[c].Text:=S;
    EdValue[c].Visible:=true;
    EdValue[c].SetFocus;
  end;
end;

procedure TVxForm.BtnSafeClicked(Sender: TObject);
Var
  c : integer;
begin
  C:=(Sender as TComponent).Tag;
  AnalogValue[c]:=Params.CH[c].SafeValue;
  Updating:=true;
  try
    Slider[c].Value:=Round((Params.CH[c].SafeValue-Params.CH[c].SliderInter)/Params.CH[c].SliderSlope);
  except
    Slider[c].Value:=0;
  end;
  Updating:=false;
end;

procedure TVxForm.EdValueExit(Sender: TObject);
begin
  EdValue[1].Visible:=false;
  EdValue[2].Visible:=false;
end;

procedure TVxForm.EdValueKeypressed(Sender: TObject; var Key: char);
Var
  c : integer;
  V : double;
  Code : integer;
begin
  C:=(Sender as TComponent).Tag;
  if not (C in[1,2]) or (Key=#27) then
  begin
    EdValue[1].Visible:=false;
    EdValue[2].Visible:=false;
    exit;
  end;

  if Key=#13 then
  begin
    Val(EdValue[c].Text, V, Code);
    if Code<>0 then
      V:=AValues[c];
    if V<Params.CH[c].X1 then V:=Params.CH[c].X1;
    if V>Params.CH[c].X2 then V:=Params.CH[c].X2;
    AnalogValue[C]:=V;
    Updating:=true;
    try
      Slider[c].Value:=Round((V-Params.CH[c].SliderInter)/Params.CH[c].SliderSlope);
    except
      Slider[c].Value:=0;
    end;
    Updating:=false;
    EdValue[c].Visible:=false;
  end;

end;

procedure TVxForm.SliderChangeValue(Sender: TObject);
Var
  c : integer;
begin
  C:=(Sender as TComponent).Tag;
  if (C in [1,2]) and not Updating then
    AnalogValue[c]:=Slider[c].Value*Params.CH[c].SliderSlope+Params.CH[c].SliderInter;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value  : word;
  c : integer;
begin
  for c:=1 to 2 do
  begin
    Regs[c].Status:=CommRegisterStatus(_rkWrite, Regs[c].Index);
    SetLedStatus(LedCom[c], Regs[c].Status);
  end;
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
      CH[c].FastWrite:=false;
      CH[c].Umis:='V';
      CH[c].Precision:=2;
      CH[c].X1:=0.0;
      CH[c].Y1:=0;
      CH[c].X2:=10.0;
      CH[c].Y2:=65535;
      CH[c].SafeValue:=0.0;
      CalcLine(CH[c].X1, CH[c].Y1, CH[c].X2, CH[c].Y2, CH[c].Slope, CH[c].Inter);
      CalcLine(0.0, CH[c].X1, 100.0, CH[c].X2, CH[c].SliderSlope, CH[c].SliderInter); // Slider is always 0..100
    end;
    CH[1].Register:=5;
    CH[2].Register:=6;
  end;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
  s : string;
begin
  for c:=1 to 2 do
  begin
    Display[c].Caption:=StrAnalogValue(Params.CH[c].X1, Params.CH[c].Precision,11);
    LblCHUMis[c].Caption:=Params.CH[c].Umis;
    Str(Params.CH[c].X1:0:Params.CH[c].Precision,S);
    lblMin[c].Caption:=S;
    Str(Params.CH[c].X2:0:Params.CH[c].Precision,S);
    LblMax[c].Caption:=S;
    with Params do
    begin
      CalcLine(CH[c].X1, CH[c].Y1, CH[c].X2, CH[c].Y2, CH[c].Slope, CH[c].Inter);
      CalcLine(0.0, CH[c].X1, 100.0, CH[c].X2, CH[c].SliderSlope, CH[c].SliderInter); // Slider is always 0..100
      LblPoints[c].Caption:=IntToStr(Round(CH[c].X1*CH[c].Slope+CH[c].Inter));
    end;
  end;
  lblName.Hint:='CH1 Reg : '+IntToStr(Params.CH[1].Register)+#13+
                'CH2 Reg : '+IntToStr(Params.CH[2].Register);
  EnergyZero;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

function TVxForm.GetAnalogValue(index : integer): double;
begin
  Result:=AValues[index];
end;

procedure TVxForm.SetAnalogValue(index : integer; AValue: double);
begin
  AValues[index]:=AValue;
  WordValue[index]:=Round(AValue*Params.CH[index].Slope+Params.CH[index].Inter);
  Display[index].Caption:=StrAnalogValue(AValue, Params.CH[index].Precision);
end;

procedure TVxForm.EnergyZero;
Var
  c : integer;
begin
  for c:=1 to 2 do
  begin
    AnalogValue[c]:=Params.CH[c].SafeValue;
    Updating:=true;
    try
      Slider[c].Value:=Round((Params.CH[c].SafeValue-Params.CH[c].SliderInter)/Params.CH[c].SliderSlope);
    except
      Slider[c].Value:=0;
    end;
    Updating:=false;
  end;
end;

procedure TVxForm.SetWordValue(index : integer; AValue: word);
begin
  if WValues[index]<>AValue then
  begin
    WValues[index]:=AValue;
    LblPoints[index].Caption:=IntToStr(AValue);

    if FRunning then
    begin
      if Params.CH[index].FastWrite then
      begin
        Regs[index].Status:=CommRegisterFastWrite(Regs[index].Index, AValue);
        SetLedStatus(LedCom[index],Regs[index].Status);
      end
      else
        CommRegisterWrite(Regs[index].Index, AValue);
    end;
  end;
end;

procedure TVxForm.Start;
Var
  c : integer;
  WSafeValue : word;
begin
  Timer.Enabled:=true;
  FRunning:=true;
  for c:=1 to 2 do
  begin
    WSafeValue:=Round(Params.CH[c].SafeValue*Params.CH[c].Slope+Params.CH[c].Inter);
    Regs[c].Status:=CommRegisterFastWrite(Regs[c].Index,WSafeValue);
    SetLedStatus(LedCom[c],Regs[c].Status);
  end;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.PrepareStart;
Var
  c : integer;
  WSafeValue : word;
begin
  for c:=1 to 2 do
  begin
    WSafeValue:=Round(Params.CH[c].SafeValue*Params.CH[c].Slope+Params.CH[c].Inter);
    Regs[c].Index:=CommWriteRegisterAdd(Params.CH[c].Register, integer(Params.CH[c].FastWrite), WSafeValue);
  end;
  EnergyZero;
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
      Params.CH[1].FastWrite:=ini.ReadBool(Section,'CH1.FastWrite',Params.CH[1].FastWrite);
      Params.CH[1].Umis:=ini.ReadString(Section,'CH1.Umis',Params.CH[1].Umis);
      Params.CH[1].Precision:=ini.ReadInteger(Section,'CH1.Precision',Params.CH[1].Precision);
      Params.CH[1].X1:=ini.ReadFloat(Section,'CH1.X1',Params.CH[1].X1);
      Params.CH[1].Y1:=ini.ReadFloat(Section,'CH1.Y1',Params.CH[1].Y1);
      Params.CH[1].X2:=ini.ReadFloat(Section,'CH1.X2',Params.CH[1].X2);
      Params.CH[1].Y2:=ini.ReadFloat(Section,'CH1.Y2',Params.CH[1].Y2);
      Params.CH[1].SafeValue:=ini.ReadFloat(Section,'CH1.SafeValue',Params.CH[1].SafeValue);

      Params.CH[2].Register:=ini.ReadInteger(Section,'CH2.Register',Params.CH[2].Register);
      Params.CH[2].FastWrite:=ini.ReadBool(Section,'CH2.FastWrite',Params.CH[2].FastWrite);
      Params.CH[2].Umis:=ini.ReadString(Section,'CH2.Umis',Params.CH[2].Umis);
      Params.CH[2].Precision:=ini.ReadInteger(Section,'CH2.Precision',Params.CH[2].Precision);
      Params.CH[2].X1:=ini.ReadFloat(Section,'CH2.X1',Params.CH[2].X1);
      Params.CH[2].Y1:=ini.ReadFloat(Section,'CH2.Y1',Params.CH[2].Y1);
      Params.CH[2].X2:=ini.ReadFloat(Section,'CH2.X2',Params.CH[2].X2);
      Params.CH[2].Y2:=ini.ReadFloat(Section,'CH2.Y2',Params.CH[2].Y2);
      Params.CH[2].SafeValue:=ini.ReadFloat(Section,'CH2.SafeValue',Params.CH[2].SafeValue);
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
    ini.WriteBool(Section,'CH1.FastWrite',Params.CH[1].FastWrite);
    ini.WriteString(Section,'CH1.Umis',Params.CH[1].Umis);
    ini.WriteInteger(Section,'CH1.Precision',Params.CH[1].Precision);
    ini.WriteFloat(Section,'CH1.X1',Params.CH[1].X1);
    ini.WriteFloat(Section,'CH1.Y1',Params.CH[1].Y1);
    ini.WriteFloat(Section,'CH1.X2',Params.CH[1].X2);
    ini.WriteFloat(Section,'CH1.Y2',Params.CH[1].Y2);
    ini.WriteFloat(Section,'CH1.SafeValue',Params.CH[1].SafeValue);

    ini.WriteInteger(Section,'CH2.Register',Params.CH[2].Register);
    ini.WriteBool(Section,'CH2.FastWrite',Params.CH[2].FastWrite);
    ini.WriteString(Section,'CH2.Umis',Params.CH[2].Umis);
    ini.WriteInteger(Section,'CH2.Precision',Params.CH[2].Precision);
    ini.WriteFloat(Section,'CH2.X1',Params.CH[2].X1);
    ini.WriteFloat(Section,'CH2.Y1',Params.CH[2].Y1);
    ini.WriteFloat(Section,'CH2.X2',Params.CH[2].X2);
    ini.WriteFloat(Section,'CH2.Y2',Params.CH[2].Y2);
    ini.WriteFloat(Section,'CH2.SafeValue',Params.CH[2].SafeValue);
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


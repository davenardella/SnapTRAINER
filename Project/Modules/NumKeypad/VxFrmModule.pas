unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, LedNumber, BGRABitmapTypes, VxUtils, ueled;

type

  TNumKeypadParams = record
    Output_Reg    : word;
    Instant       : boolean; // 1 : pushbuttons, 0 numeric
    NumericSigned : boolean;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    BTN_0: TBCButton;
    BTN_BS: TBCButton;
    BTN_OK: TBCButton;
    BTN_RI: TBCButton;
    BTN_UP: TBCButton;
    BTN_LE: TBCButton;
    BTN_DN: TBCButton;
    BTN_6: TBCButton;
    BTN_1: TBCButton;
    BTN_3: TBCButton;
    BTN_2: TBCButton;
    BTN_7: TBCButton;
    BTN_8: TBCButton;
    BTN_9: TBCButton;
    BTN_4: TBCButton;
    BTN_5: TBCButton;
    Display: TLEDNumber;
    Images: TImageList;
    lblValue: TLabel;
    pnlDisplay: TBCPanel;
    pnlKeyboard: TBCPanel;
    lblName: TLabel;
    pnlKeyboard1: TBCPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    // Common
    FIndex                : integer;
    FInstant              : boolean;
    FIValue               : integer;
    FName                 : string;
    FOutputValue: word;
    FRunning              : boolean;
    CommRegisterRead      : TCommRegisterRead;
    CommRegisterWrite     : TCommRegisterWrite;
    CommRegisterFastWrite : TCommRegisterFastWrite;
    CommReadRegisterAdd   : TCommReadRegisterAdd;
    CommWriteRegisterAdd  : TCommWriteRegisterAdd;
    CommRegisterStatus    : TCommRegisterStatus;
    LedCom                : array[1..1] of TuELED;
    // Specific
    Regs                  : array[1..1] of TRegisterModule;
    BTN                   : array[0..15] of TBCButton;
    Params                : TNumKeypadParams;
    LastTick              : QWord;
    procedure ButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ButtonClick(Sender: TObject);
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure SetFInstant(AValue: boolean);
    procedure SetFIvalue(AValue: integer);
    procedure SetFOutputValue(AValue: word);
  public
    procedure Start;
    procedure Stop;
    procedure PrepareStart;
    procedure LoadFromFile(Filename : string);
    procedure SaveToFile(Filename : string);
    procedure SetHooks(Hooks : PHooksRecord);
    function Edit : boolean;
    property OutputValue: word read FOutputValue write SetFOutputValue;
    property Index : integer read FIndex write SetFIndex;
    property Name : string read FName write FName;
    property Instant : boolean read FInstant write SetFInstant;
    property IValue : integer read FIValue write SetFIvalue;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

var
  VxForm: TVxForm;

Const

  ArrowColors : array[boolean] of TColor = (clGray, clLime);

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;

  BTN[0] :=BTN_0;
  BTN[1] :=BTN_1;
  BTN[2] :=BTN_2;
  BTN[3] :=BTN_3;
  BTN[4] :=BTN_4;
  BTN[5] :=BTN_5;
  BTN[6] :=BTN_6;
  BTN[7] :=BTN_7;
  BTN[8] :=BTN_8;
  BTN[9] :=BTN_9;
  BTN[10]:=BTN_BS;
  BTN[11]:=BTN_OK;
  BTN[12]:=BTN_UP;
  BTN[13]:=BTN_LE;
  BTN[14]:=BTN_DN;
  BTN[15]:=BTN_RI;

  pnlKeyboard.Color:=$00555555;
  pnlKeyboard.Background.Color:=$00454545;
  pnlKeyboard1.Color:=$00555555;
  pnlKeyboard1.Background.Color:=$00454545;

  pnlDisplay.Color:=$00555555;
  pnlDisplay.Background.Color:=$00292929;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
end;

procedure TVxForm.FormDestroy(Sender: TObject);
begin
  Timer.Enabled:=false;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
begin
  Regs[1].Status:=CommRegisterStatus(_rkWrite, Regs[1].Index);
  SetLedStatus(LedCom[1],Regs[1].Status);
end;

procedure TVxForm.ButtonMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  idx  : integer;
  STag : string;
begin
  if FRunning then
  begin
    idx := (Sender as TComponent).Tag;
    OutputValue:=FOutputValue or Mask[idx];
    STag:=IntToStr(idx);
    if idx<10 then
      Display.Caption:='Bit  '+Stag
    else
      Display.Caption:='Bit '+Stag;
  end;
end;

procedure TVxForm.ButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
  begin
    OutputValue:=FOutputValue and not Mask[(Sender as TComponent).Tag];
    Display.Caption:='Bit --';
  end;
end;

procedure TVxForm.ButtonClick(Sender: TObject);
Var
  idx     : integer;
  Value   : integer;
  siValue : smallint;
  WValue  : word absolute siValue;

  function digits(V : integer) : integer;
  begin
    Result:=Length(IntToStr(Abs(V)));
  end;

begin
  if FRunning then
  begin
    Value := IValue;
    idx := (Sender as TComponent).Tag;

    case idx of
      0..9 : begin
          if digits(Value)<5 then
          begin
            IValue:=Value*10 + idx;
          end;
      end;
      10 : begin // BS
          IValue:=Value div 10;
      end;
      11 : begin // OK
          if Params.NumericSigned then
          begin
            if Value<-32768 then Value:=-32768;
            if Value>32767 then Value:=32767;
          end
          else begin
            if Value<0 then Value:=0; // should never happen...
            if Value>65535 then Value:=65535;
          end;
          IValue:=Value;
          siValue:=IValue;
          OutputValue:=WValue;
      end;
      14 : begin // +/-
          IValue:=-Value;
      end;
    end;
  end;
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Output_Reg:=1;
  Params.Instant:=true;
  Params.NumericSigned:=false;
end;

procedure TVxForm.ApplyParams;
begin
  SetFInstant(Params.Instant);
  if not Params.Instant then
  begin
    if Params.NumericSigned then
      lblValue.Caption:='Signed value'
    else
      lblValue.Caption:='Unsigned value';
  end
  else
    lblValue.Caption:='Instant bit';
  lblName.Hint:=
  'Write Reg : '+IntToStr(Params.Output_Reg);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFInstant(AValue: boolean);
Var
  c : integer;
begin
  FInstant:=AValue;

  if FInstant then
  begin
    for c:=0 to 15 do
    begin
      BTN[c].OnClick:=nil;
      BTN[c].OnMouseDown:=ButtonMouseDown;
      BTN[c].OnMouseUp  :=ButtonMouseUP;
    end;

    BTN_BS.ShowCaption:=true;
    BTN_BS.ImageIndex:=-1;
    BTN_UP.Enabled:=true;
    BTN_UP.ImageIndex:=2;
    BTN_RI.Enabled:=true;
    BTN_RI.ImageIndex:=1;
    BTN_DN.ShowCaption:=false;
    BTN_DN.ImageIndex:=3;
    BTN_LE.Enabled:=true;
    BTN_LE.ImageIndex:=0;

    Display.OnColor:=clLime;
    Display.Caption:='BIT --';
  end
  else begin
    for c:=0 to 15 do
    begin
      BTN[c].OnClick:=ButtonClick;
      BTN[c].OnMouseDown:=nil;
      BTN[c].OnMouseUp  :=nil;
    end;

    BTN_BS.ShowCaption:=false;
    BTN_BS.ImageIndex:=4;
    BTN_UP.Enabled:=false;
    BTN_UP.ImageIndex:=-1;
    BTN_RI.Enabled:=false;
    BTN_RI.ImageIndex:=-1;
    BTN_LE.Enabled:=false;
    BTN_LE.ImageIndex:=-1;

    if not Params.NumericSigned then
    begin
      BTN_DN.ShowCaption:=false;
      BTN_DN.Enabled:=false;
    end
    else begin
      BTN_DN.ShowCaption:=true;
      BTN_DN.Enabled:=true;
    end;
    BTN_DN.ImageIndex:=-1;

    Display.OnColor:=clAqua;
    Display.Caption:='     0';
  end;

end;

procedure TVxForm.SetFIvalue(AValue: integer);
begin
  if not FInstant then
  begin
    FIValue:=AValue;
    Display.Caption:= StrIntValue(FIValue, 5, Params.NumericSigned);
  end;
end;

procedure TVxForm.SetFOutputValue(AValue: word);
begin
  FOutputValue:=AValue;
  if FRunning then
    Regs[1].Status:=CommRegisterFastWrite(Regs[1].Index,FOutputValue);
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  Timer.Enabled:=true;
  FRunning:=true;
  OutputValue:=0;
  IValue:=0;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommWriteRegisterAdd(Params.Output_Reg, 1, 0);
  OutputValue:=0;
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
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.Instant:=ini.ReadBool(Section,'Instant',Params.Instant);
      Params.NumericSigned:=ini.ReadBool(Section,'NumericSigned',Params.NumericSigned);
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
    ini.WriteInteger(Section,'Output_Reg',Params.Output_Reg);
    ini.WriteBool(Section,'Instant',Params.Instant);
    ini.WriteBool(Section,'NumericSigned',Params.NumericSigned);
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


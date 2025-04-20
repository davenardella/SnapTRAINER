unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, LedNumber, BGRABitmapTypes, VxUtils, ueled;

type

  TPushKeypadParams = record
    Input_Reg     : word;
    Output_Reg    : word;
    FastWrite     : boolean;
    NumericSigned : boolean;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    BTN_13: TBCButton;
    BTN_12: TBCButton;
    BTN_15: TBCButton;
    BTN_14: TBCButton;
    BTN_11: TBCButton;
    BTN_6: TBCButton;
    BTN_0: TBCButton;
    BTN_2: TBCButton;
    BTN_1: TBCButton;
    BTN_8: TBCButton;
    BTN_9: TBCButton;
    BTN_10: TBCButton;
    BTN_4: TBCButton;
    BTN_5: TBCButton;
    BTN_7: TBCButton;
    BTN_3: TBCButton;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LedCom_2: TuELED;
    Led_0: TuELED;
    Led_9: TuELED;
    Led_10: TuELED;
    Led_11: TuELED;
    Led_12: TuELED;
    Led_13: TuELED;
    Led_14: TuELED;
    Led_15: TuELED;
    Led_1: TuELED;
    Led_2: TuELED;
    Led_3: TuELED;
    Led_4: TuELED;
    Led_5: TuELED;
    Led_6: TuELED;
    Led_7: TuELED;
    Led_8: TuELED;
    pnlDisplay: TBCPanel;
    pnlKeyboard: TBCPanel;
    lblName: TLabel;
    Timer: TTimer;
    LedCom_1: TuELED;
    procedure BTN_0MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BTN_0MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    // Common
    FIndex                : integer;
    FInputValue: word;
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
    LedCom                : array[1..2] of TuELED;
    // Specific
    Regs                  : array[1..2] of TRegisterModule;
    BTN                   : array[0..15] of TBCButton;
    LED                   : array[0..15] of TuELED;
    Params                : TPushKeypadParams;
    LastTick              : QWord;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure SetFInputValue(AValue: word);
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
    property InputValue : word read FInputValue write SetFInputValue;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

var
  VxForm: TVxForm;

Const

  LedColor : array[boolean] of TColor =  ($003B3B3B, clRed);

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;

  BTN[0] :=BTN_0;
  BTN[1] :=BTN_1;
  BTN[2] :=BTN_2;
  BTN[3] :=BTN_3;
  BTN[4] :=BTN_4;
  BTN[5] :=BTN_5;
  BTN[6] :=BTN_6;
  BTN[7] :=BTN_7;
  BTN[8] :=BTN_8;
  BTN[9] :=BTN_9;;
  BTN[10]:=BTN_10;
  BTN[11]:=BTN_11;
  BTN[12]:=BTN_12;
  BTN[13]:=BTN_12;
  BTN[14]:=BTN_14;
  BTN[15]:=BTN_15;

  LED[0] :=LED_0;
  LED[1] :=LED_1;
  LED[2] :=LED_2;
  LED[3] :=LED_3;
  LED[4] :=LED_4;
  LED[5] :=LED_5;
  LED[6] :=LED_6;
  LED[7] :=LED_7;
  LED[8] :=LED_8;
  LED[9] :=LED_9;
  LED[10]:=LED_10;
  LED[11]:=LED_11;
  LED[12]:=LED_12;
  LED[13]:=LED_13;
  LED[14]:=LED_14;
  LED[15]:=LED_15;

  pnlKeyboard.Color:=$00555555;
  pnlKeyboard.Background.Color:=$00454545;

  pnlDisplay.Color:=$00555555;
  pnlDisplay.Background.Color:=$00292929;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.BTN_0MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
    OutputValue:=FOutputValue or Mask[(Sender as TComponent).Tag];
end;

procedure TVxForm.BTN_0MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
    OutputValue:=FOutputValue and not Mask[(Sender as TComponent).Tag];
end;

procedure TVxForm.FormDestroy(Sender: TObject);
begin
  Timer.Enabled:=false;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value : word;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}Value);
  if Regs[1].Status = _rsOK then
    InputValue:=Value;
  SetLedStatus(LedCom[1], Regs[1].Status);

  Regs[2].Status:=CommRegisterStatus(_rkWrite, Regs[2].Index);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg:=1;
  Params.Output_Reg:=2;
  Params.FastWrite:=true;
end;

procedure TVxForm.ApplyParams;
begin
  lblName.Hint:=
  'Write Reg : '+IntToStr(Params.Output_Reg)+#13+
  'Read  Reg : '+IntToStr(Params.Input_Reg);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFInputValue(AValue: word);
Var
  c : integer;
begin
  if FInputValue<>AValue then
  begin
    FInputValue:=AValue;
    for c:=0 to 15 do
      LED[c].Color:=LedColor[(FInputValue and Mask[c])<>0];
  end;
end;

procedure TVxForm.SetFOutputValue(AValue: word);
begin
  FOutputValue:=AValue;
  if FRunning then
    Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index,FOutputValue);
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  Timer.Enabled:=true;
  FRunning:=true;
  OutputValue:=0;
  InputValue:=0;
  SetLedStatus(LedCom[1],Regs[1].Status);
  SetLedStatus(LedCom[2],Regs[2].Status);
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommReadRegisterAdd(Params.Input_Reg);
  Regs[2].Index:=CommWriteRegisterAdd(Params.Output_Reg,Integer(Params.FastWrite),0);
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
      Params.Input_Reg:=ini.ReadInteger(Section,'Input_Reg',Params.Input_Reg);
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.FastWrite:=ini.ReadBool(Section,'FastWrite',Params.FastWrite);
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
    ini.WriteInteger(Section,'Input_Reg',Params.Input_Reg);
    ini.WriteInteger(Section,'Output_Reg',Params.Output_Reg);
    ini.WriteBool(Section,'FastWrite',Params.FastWrite);
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


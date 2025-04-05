unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, LedNumber, AdvLed, BGRABitmapTypes, VxUtils, ueled;

type

  TElevatorCallParams = record
    Input_Reg    : word;
    Floor_Reg    : word;
    Output_Reg   : word;
    FastWrite    : boolean;
    FloorLabel   : string;
    BtnUPEnabled : boolean;
    BtnDNEnabled : boolean;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    ArrowDN: TShape;
    ArrowUP_btn: TShape;
    ArrowDN_btn: TShape;
    ArrowUP: TShape;
    BTN_DN: TBCButton;
    BTN_UP: TBCButton;
    LedCom_2: TuELED;
    LedCom_3: TuELED;
    pnlDisplay: TBCPanel;
    pnlKeyboard: TBCPanel;
    lblName: TLabel;
    pnlLabel: TBCPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    FloorDisplay: TLEDNumber;
    StatusLED: TuELED;
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    // Common
    FIndex                : integer;
    FName                 : string;
    FOutputValue: word;
    FRunning              : boolean;
    CommRegisterRead      : TCommRegisterRead;
    CommRegisterWrite     : TCommRegisterWrite;
    CommRegisterFastWrite : TCommRegisterFastWrite;
    CommReadRegisterAdd   : TCommReadRegisterAdd;
    CommWriteRegisterAdd  : TCommWriteRegisterAdd;
    CommRegisterStatus    : TCommRegisterStatus;
    LedCom                : array[1..3] of TuELED;
    // Specific
    Regs                  : array[1..3] of TRegisterModule;
    Params                : TElevatorCallParams;
    LastTick              : QWord;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
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
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  LedCom[3]:=LedCom_3;

  pnlKeyboard.Color:=$00555555;
  pnlKeyboard.Background.Color:=$00454545; // Sometime BCPanel "forgets" something...
  pnlLabel.Color:=$00555555;
  pnlLabel.Background.Color:=$00454545;

  pnlDisplay.Color:=$00454545;
  pnlDisplay.Background.Color:=$00292929;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
  SetLedStatus(LedCom[3], 0);
end;

procedure TVxForm.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
    OutputValue:=FOutputValue or Mask[(Sender as TComponent).Tag]
end;

procedure TVxForm.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
    OutputValue:=FOutputValue and not Mask[(Sender as TComponent).Tag]
end;

procedure TVxForm.FormDestroy(Sender: TObject);
begin
  Timer.Enabled:=false;
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  InWord : word;
  BitArrowUPGreen,
  BitArrowUPOrange,
  BitArrowDNGreen,
  BitArrowDNOrange,
  BitStatusGreen,
  BitStatusRed      : boolean;

  FloorNum : word;
  SFloorNum : string;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}InWord);
  if Regs[1].Status <> _rsOK then
    InWord:=0;
  SetLedStatus(LedCom[1], Regs[1].Status);

  Regs[2].Status:=CommRegisterRead(Regs[2].Index, {%H-}FloorNum);
  if Regs[2].Status <> _rsOK then
    FloorNum:=100; // To force '--'
  SetLedStatus(LedCom[2], Regs[2].Status);

  BitArrowUPGreen  := (InWord and $0001)<>0;
  BitArrowUPOrange := (InWord and $0002)<>0;
  BitArrowDNGreen  := (InWord and $0004)<>0;
  BitArrowDNOrange := (InWord and $0008)<>0;
  BitStatusGreen   := (InWord and $0010)<>0;
  BitStatusRed     := (InWord and $0020)<>0;

  // Floor Number

  if FloorNum in [0..10] then
  begin
    SFloorNum:=IntToStr(FloorNum);
    if FLoorNum<10 then
      SFloorNum:=' '+SFloorNum;
  end
  else
    SFloorNum:='--';
  FloorDisplay.Caption:=SFloorNum;

  // Arrows
  if BitArrowUPGreen <> BitArrowUPOrange then
  begin
    if BitArrowUPGreen then
      ArrowUP.Brush.Color:=clLime
    else
      ArrowUP.Brush.Color:=$000080FF;
  end
  else
    ArrowUP.Brush.Color:=clGray;

  if BitArrowDNGreen <> BitArrowDNOrange then
  begin
    if BitArrowDNGreen then
      ArrowDN.Brush.Color:=clLime
    else
      ArrowDN.Brush.Color:=$000080FF;
  end
  else
    ArrowDN.Brush.Color:=clGray;

  // Status
  if BitStatusGreen<>BitStatusRed then
  begin
    if BitStatusGreen then
      StatusLED.Color:=clLime
    else
      StatusLED.Color:=clRed;
  end
  else
    StatusLED.Color:=$00555555;

  Regs[3].Status:=CommRegisterStatus(_rkWrite, Regs[3].Index);
  SetLedStatus(LedCom[3], Regs[3].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg:=1;
  Params.Floor_Reg:=2;
  Params.Output_Reg:=3;
  Params.FastWrite:=true;
  Params.FloorLabel:='Floor 1';
  Params.BtnUPEnabled := true;
  Params.BtnDNEnabled := true;
end;

procedure TVxForm.ApplyParams;
begin
  lblName.Hint:=
  'Read Registers'+#13+
  '  Control Reg : '+IntToStr(Params.Input_Reg)+#13+
  '  Floor   Reg : '+IntToStr(Params.Floor_Reg)+#13+
  'Write Registers'+#13+
  '  Status  Reg : '+IntToStr(Params.Output_Reg);
  pnlLabel.Caption:=Params.FloorLabel;

  BTN_UP.Enabled:=Params.BtnUPEnabled;
  BTN_DN.Enabled:=Params.BtnDNEnabled;

  ArrowUP_btn.Visible:=Params.BtnUPEnabled;
  ArrowDN_btn.Visible:=Params.BtnDNEnabled;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFOutputValue(AValue: word);
begin
  if FOutputValue<>AValue then
  begin
    FOutputValue:=AValue;
    if FRunning then
    begin
      if Params.FastWrite then
      begin
        Regs[3].Status:=CommRegisterFastWrite(Regs[3].Index,FOutputValue);
        SetLedStatus(LedCom[3],Regs[3].Status);
      end
      else
        CommRegisterWrite(Regs[3].Index,FOutputValue);
    end
  end;
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  Timer.Enabled:=true;
  FRunning:=true;
  Regs[3].Status:=CommRegisterFastWrite(Regs[3].Index,FOutputValue);
  SetLedStatus(LedCom[3],Regs[3].Status);
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
  SetLedStatus(LedCom[3], 0);
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommReadRegisterAdd(Params.Input_Reg);
  Regs[2].Index:=CommReadRegisterAdd(Params.Floor_Reg);
  Regs[3].Index:=CommWriteRegisterAdd(Params.Output_Reg,Integer(Params.FastWrite),0);
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
      Params.Floor_Reg:=ini.ReadInteger(Section,'Floor_Reg',Params.Floor_Reg);
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.FastWrite:=ini.ReadBool(Section,'FastWrite',Params.FastWrite);
      Params.FloorLabel:=ini.ReadString(Section,'FloorLabel',Params.FloorLabel);
      Params.BtnUPEnabled:=ini.ReadBool(Section,'BtnUPEnabled',Params.BtnUPEnabled);
      Params.BtnDNEnabled:=ini.ReadBool(Section,'BtnDNEnabled',Params.BtnDNEnabled);
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
    ini.WriteInteger(Section,'Floor_Reg',Params.Floor_Reg);
    ini.WriteInteger(Section,'Output_Reg',Params.Output_Reg);
    ini.WriteBool(Section,'FastWrite',Params.FastWrite);
    ini.WriteString(Section,'FloorLabel',Params.FloorLabel);
    ini.WriteBool(Section,'BtnUPEnabled',Params.BtnUPEnabled);
    ini.WriteBool(Section,'BtnDNEnabled',Params.BtnDNEnabled);
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


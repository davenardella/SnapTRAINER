unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, LedNumber, BGRABitmapTypes, VxUtils, ueled;

type

  TElevatorCabParams = record
    Input_Reg   : word;
    Floor_Reg   : word;
    Output_Reg  : word;
    FastWrite   : boolean;
    SlidingTime : integer;
  end;


  { TElevatorDoor }

  TElevatorDoor = class(TObject)
  private
    FSlidingTime: QWord;
    LastTick : QWord;
    TimeTotal: QWord;
    Width    : double;
    Slope    : double;
    inter    : double;
    Door     : TBCPanel;
  public
    constructor Create(DoorPanel : TBCPanel);
    procedure Start;
    procedure Update(BitClose, BitOpen : boolean; var BitClosed, BitOpened, BitSliding : boolean);
    property SlidingTime : QWord read FSlidingTime write FSlidingTime;
  end;


  { TVxForm }

  TVxForm = class(TForm)
    BTN_0: TBCButton;
    BTN_6: TBCButton;
    BTN_7: TBCButton;
    BTN_10: TBCButton;
    BTN_9: TBCButton;
    BTN_8: TBCButton;
    BTN_1: TBCButton;
    BTN_2: TBCButton;
    BTN_3: TBCButton;
    BTN_4: TBCButton;
    BTN_5: TBCButton;
    BTN_11: TBCButton;
    BTN_12: TBCButton;
    LedCom_2: TuELED;
    LedCom_3: TuELED;
    pnlDisplay: TBCPanel;
    pnlDoor: TBCPanel;
    pnlSlider: TBCPanel;
    pnlKeyboard: TBCPanel;
    lblName: TLabel;
    pnlCab: TBCPanel;
    ArrowUP: TShape;
    ArrowDN: TShape;
    Timer: TTimer;
    LedCom_1: TuELED;
    FloorDisplay: TLEDNumber;
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
    Params                : TElevatorCabParams;
    Door                  : TElevatorDoor;
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

Const

  ArrowColors : array[boolean] of TColor = (clGray, clLime);

  DoorWidth = 125;
  DoorStart = 10;

  // Btn_0             0
  // Btn_1             1
  // Btn_2             2
  // Btn_3             3
  // Btn_4             4
  // Btn_5             5
  // Btn_6             6
  // Btn_7             7
  // Btn_8             8
  // Btn_9             9
  // Btn_10            10
  // Btn_Open          11
  // Btn_Stop          12
  // DoorOpened        13
  // DoorClosed        14
  // DoorSliding       15

  // FloorNum 0..7
  // CloseDoor         8
  // OpenDoor          9
  // ArrowUP           10
  // ArrowDN           11


{ TElevatorDoor }


constructor TElevatorDoor.Create(DoorPanel: TBCPanel);
begin
  inherited create;
  FSlidingTime:=4000;
  TimeTotal:=0;
  Door := DoorPanel;
end;

procedure TElevatorDoor.Start;
begin
  LastTick:=GetTickCount64;
  Width:=0;
  Door.Width:=DoorStart;
end;

procedure TElevatorDoor.Update(BitClose, BitOpen : boolean; var BitClosed, BitOpened, BitSliding : boolean);
Var
  Time_ms       : QWord;
  DeltaTime_ms  : QWord;
  DeltaPx_ms    : double;
  W             : integer;
begin
  // Calc Delta Time
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  DeltaPx_ms := (DeltaTime_ms * DoorWidth)/ FSlidingTime;

  if BitOpen<>BitClose then
  begin
    if BitClose then
    begin
      Width:=Width + DeltaPx_ms;
      if Width > DoorWidth then Width := DoorWidth;
    end
    else begin
      Width:=Width - DeltaPx_ms;
      if Width < 0 then Width := 0;
    end;
    BitSliding:=true;
  end
  else
    BitSliding:=false;

  W:=Round(Width)+DoorStart;

  BitOpened:=W=DoorStart;
  BitClosed:=W=DoorWidth+DoorStart;

  Door.Width:=W;

  if BitOpened or BitClosed then
    BitSliding:=false;
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  LedCom[3]:=LedCom_3;
  Door := TElevatorDoor.Create(pnlSlider);

  pnlKeyboard.Color:=$00555555;
  pnlKeyboard.Background.Color:=$00454545;

  pnlSlider.Background.Color:=$006B6B6B;
  pnlDoor.Background.Color:=$00E9E9E9;

  pnlCab.Background.Gradient1EndPercent:=100;
  pnlCab.Background.Style:=bbsGradient;
  pnlCab.Background.Gradient1.EndColor:=clBlack;
  pnlCab.Background.Gradient1.StartColor:=clWhite;
  pnlCab.Background.Gradient1.GradientType:=gtReflected;
  pnlCab.Background.Gradient1.Point1XPercent:=50;
  pnlCab.Background.Gradient1.Point1YPercent:=100;
  pnlCab.Background.Gradient1.Point2XPercent:=100;
  pnlCab.Background.Gradient1.Point2YPercent:=100;

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
  Door.Free;
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  InWord : word;
  OutWord : word;
  BitClose,
  BitOpen,
  BitClosed,
  BitOpened,
  BitSliding : boolean;
  BitArrowUP,
  BitArrowDN : boolean;
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

  BitClose   := (InWord and $0001)<>0;
  BitOpen    := (InWord and $0002)<>0;
  BitArrowUP := (InWord and $0004)<>0;
  BitArrowDN := (InWord and $0008)<>0;

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
  ArrowUP.Brush.Color:=ArrowColors[BitArrowUP];
  ArrowDN.Brush.Color:=ArrowColors[BitArrowDN];

  // Sliding Door
  Door.Update(BitClose, BitOpen, BitClosed, BitOpened, BitSliding);

  OutWord:=FOutputValue;
  if BitClosed then
    OutWord:=OutWord or $2000
  else
    OutWord:=OutWord and not $2000;

  if BitOpened then
    OutWord:=OutWord or $4000
  else
    OutWord:=OutWord and not $4000;

  if BitSliding then
    OutWord:=OutWord or $8000
  else
    OutWord:=OutWord and not $8000;

  OutputValue:=OutWord;

  Regs[3].Status:=CommRegisterStatus(_rkWrite, Regs[3].Index);
  SetLedStatus(LedCom[3], Regs[3].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg:=1;
  Params.Floor_Reg:=2;
  Params.Output_Reg:=3;
  Params.FastWrite:=true;
  Params.SlidingTime:=4000;
end;

procedure TVxForm.ApplyParams;
begin
  lblName.Hint:='Control Reg : '+IntToStr(Params.Input_Reg)+#13+
                'Floor   Reg : '+IntToStr(Params.Floor_Reg)+#13+
                'Status  Reg : '+IntToStr(Params.Output_Reg);
  Door.SlidingTime:=QWord(Params.SlidingTime);
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
  Door.Start;
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
      Params.SlidingTime:=ini.ReadInteger(Section,'SlidingTime',Params.SlidingTime);
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
    ini.WriteInteger(Section,'SlidingTime',Params.SlidingTime);
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


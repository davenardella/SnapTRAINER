unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, BCRoundedImage, BGRAKnob,
  BGRABitmapTypes, VxUtils, ueled;

Const
  MaxSpeed_rpm      = 1500; // rpm
  MaxSteps          = 16777215; // 2^24-1

Type

  TMechanics = (mecLinear, mecRotary);

  TMotorParams = record
    Mechanics     : TMechanics;
    Ctrl_Reg      : word;  // input
    SetPos_Reg    : word;  // input
    Status_Reg    : word;  // output
    CurPos_Reg    : word;  // output
    SpeedSet      : word;  // units/sec
    ScrewLength   : word;  // units
  end;

  TMotorState = (msReady, msMoveUP, msMoveDN, msMovePOS, msNotReady);

  TDirection = (dirUP, dirDN);

  TMotorMission = record
    Done      : boolean;
    Direction : TDirection;
    TargetPos : double;
  end;

Type
{ TVxForm }

  TVxForm = class(TForm)
    BCRoundedImage3: TBCRoundedImage;
    Label22: TLabel;
    lblPosSet: TLabel;
    lblSpeed_umis1: TLabel;
    LedCom_4: TuELED;
    Motor: TBGRAKnob;
    lblStop: TLabel;
    Label10: TLabel;
    lblHome_OUT: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    lblHome_IN: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    lblMoveCCW: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    lblMoveCW: TLabel;
    lblMovePos: TLabel;
    Label5: TLabel;
    lblMovingCCW: TLabel;
    lblMovingCW: TLabel;
    lblDonePos: TLabel;
    Label9: TLabel;
    lblSpeed_umis: TLabel;
    lblStatus: TLabel;
    lblStatus_txt: TLabel;
    lblSpeedSet: TLabel;
    lblCurrentPos: TLabel;
    lblCurrentPos_umis: TLabel;
    LedCom_3: TuELED;
    Led_in_0: TuELED;
    Led_in_1: TuELED;
    Led_out_6: TuELED;
    Led_out_7: TuELED;
    Led_in_4: TuELED;
    Led_in_5: TuELED;
    Led_in_6: TuELED;
    Led_in_7: TuELED;
    Led_in_2: TuELED;
    Led_in_3: TuELED;
    Led_out_0: TuELED;
    Led_out_1: TuELED;
    Led_out_2: TuELED;
    Led_out_3: TuELED;
    Led_out_4: TuELED;
    Led_out_5: TuELED;
    PipeOutlet: TBCPanel;
    Bearing: TBCPanel;
    pnlLEds: TBCPanel;
    lblName: TLabel;
    pnlStatus: TBCPanel;
    pnlValues: TBCPanel;
    pnlScrew: TBCPanel;
    Shape1: TShape;
    Shape13: TShape;
    Shape15: TShape;
    Shape16: TShape;
    Shape17: TShape;
    MotorTimer: TTimer;
    Shape2: TShape;
    Plate: TShape;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    procedure FormCreate(Sender: TObject);
    procedure MotorTimerTimer(Sender: TObject);
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
    // Specific
    LedCom                : array[1..4] of TuELED;
    Regs                  : array[1..4] of TRegisterModule;
    Params                : TMotorParams;
    Leds_IN               : array[0..7] of TuELED;
    Leds_OUT              : array[0..7] of TuELED;
    FState                : TMotorState;
    LastTick              : QWord;
    XI                    : TWordBits;
    XQ                    : TWordBits;
    MotorMovingCW         : boolean;
    MotorMovingCCW        : boolean;
    MCurrentPos           : double;
    WCurrentPos           : word;
    SetPosWord            : word;
    FLinearPos            : double;
    MotorAngle            : double;
    ScrewSlope            : double;
    ScrewInter            : double;
    ParamsApplied         : boolean;
    Mission               : TMotorMission;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure SetFLinearPos(AValue: double);
    procedure SetFState(AValue: TMotorState);
    procedure Logic;
    procedure UpdatePanel;
    procedure UpdateBearing;
  public
    procedure Start;
    procedure Stop;
    procedure PrepareStart;
    procedure LoadFromFile(Filename : string);
    procedure SaveToFile(Filename : string);
    procedure SetHooks(Hooks : PHooksRecord);
    function Edit : boolean;
    property Index : integer read FIndex write SetFIndex;
    property Name : string read FName write FName;
    property State : TMotorState read FState write SetFState;
    property MLinearPos : double read FLinearPos write SetFLinearPos;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Const

  LedColorOff = $002C2C2C;

  PLCLEds   : array[0..7] of TColor = ($000080FF, clLime, clLime, clLime, clLime, clLime, clLime, clLime);

  TestULeds : array[0..7] of TColor = ($000080FF, clLime, clLime, clLime, clLime, clLime, clLime, clLime);

  StateTxtLin : array[TMotorState] of string = ('READY', 'MOVE UP', 'MOVE DN', 'MOVE POS', 'NOT READY');
  StateTxtRot : array[TMotorState] of string = ('READY', 'MOVE CCW', 'MOVE CW', 'MOVE POS', 'NOT READY');
  StateColors : array[TMotorState] of TColor = ( clLime, clAqua, clAqua, $000080FF, $00C080FF);

  I_STOP      = 0;
  I_MOVE_UP   = 1;
  I_MOVE_DN   = 2;
  I_MOVE_POS  = 3;
  I_4         = 4;
  I_5         = 5;
  I_6         = 6;
  I_7         = 7;

  Q_READY     = 0;
  Q_MOVING_UP = 1;
  Q_MOVING_DN = 2;
  Q_DONE_POS  = 3;
  Q_4         = 4;
  Q_5         = 5;
  Q_6         = 6;
  Q_7         = 7;

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
Var
  c : integer;
begin
  Timer.Enabled:=false;
  MotorTimer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  LedCom[3]:=LedCom_3;
  LedCom[4]:=LedCom_4;

  Leds_IN[0]:=Led_in_0;
  Leds_IN[1]:=Led_in_1;
  Leds_IN[2]:=Led_in_2;
  Leds_IN[3]:=Led_in_3;
  Leds_IN[4]:=Led_in_4;
  Leds_IN[5]:=Led_in_5;
  Leds_IN[6]:=Led_in_6;
  Leds_IN[7]:=Led_in_7;

  Leds_OUT[0]:=Led_Out_0;
  Leds_OUT[1]:=Led_Out_1;
  Leds_OUT[2]:=Led_Out_2;
  Leds_OUT[3]:=Led_Out_3;
  Leds_OUT[4]:=Led_Out_4;
  Leds_OUT[5]:=Led_Out_5;
  Leds_OUT[6]:=Led_Out_6;
  Leds_OUT[7]:=Led_Out_7;

  for c:=0 to 7 do
  begin
    Leds_IN[c].Tag:=PLCLEds[c];
    Leds_OUT[c].Tag:=TestULeds[c];
  end;

  // Sometime BCPanel "forgets" something...
  pnlLEds.Background.Color:=clBlack;
  pnlScrew.Background.Color:=clBlack;
  pnlStatus.Background.Color:=$007D7D7D;
  pnlValues.Background.Color:=$003B3B3B;
  Motor.MinValue:=0;
  Motor.MaxValue:=360;
  Motor.Value:=0;

  MCurrentPos  :=0;
  ParamsApplied:=false;

  State:=msNotReady;
  with Mission do
  begin
    TargetPos:=-1;
    Done:=false;
  end;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
  SetLedStatus(LedCom[3], _rsUnknown);
  SetLedStatus(LedCom[4], _rsUnknown);
end;

procedure TVxForm.MotorTimerTimer(Sender: TObject);
Var
  Delta : single;
begin
  if MotorMovingCW or MotorMovingCCW then
  begin
    Delta:=Params.SpeedSet/100;

    if Delta>0 then
    begin
      if Delta>100 then
        Delta:=100;
      if Delta<0.1 then
        Delta:=0.1;
    end;

    if MotorMovingCW then
    begin
      MotorAngle:=MotorAngle+Delta;
      while MotorAngle>360 do
        MotorAngle:=MotorAngle-360;
    end
    else begin
      MotorAngle:=MotorAngle-Delta;
      while MotorAngle<-360 do
        MotorAngle:=MotorAngle+360;
      if MotorAngle<0 then
        MotorAngle:=MotorAngle+360;
    end;
    Motor.Value:=MotorAngle;
  end;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Var
  ControlWord : word;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}ControlWord);
  if Regs[1].Status <> _rsOK then
    ControlWord:=0;

  XI:=WordToBits(ControlWord and $00FF);

  Regs[2].Status:=CommRegisterRead(Regs[2].Index, {%H-}SetPosWord);
  if Regs[2].Status = _rsOK then
  begin
    if SetPosWord>Params.ScrewLength then
      SetPosWord:=Params.ScrewLength;
  end
  else
    SetPosWord:=$FFFF;

  Logic;
  UpdatePanel;

  CommRegisterWrite(Regs[3].Index, BitsToWord(XQ) and $00FF);
  CommRegisterWrite(Regs[4].Index, WCurrentPos);

  Regs[3].Status:=CommRegisterStatus(_rkWrite,Regs[3].Index);
  Regs[4].Status:=CommRegisterStatus(_rkWrite,Regs[4].Index);

  SetLedStatus(LedCom[1], Regs[1].Status);
  SetLedStatus(LedCom[2], Regs[2].Status);
  SetLedStatus(LedCom[3], Regs[3].Status);
  SetLedStatus(LedCom[4], Regs[4].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  with Params do
  begin
    Mechanics     := mecLinear;
    Ctrl_Reg      := 1;
    SetPos_Reg    := 2;
    Status_Reg    := 3;
    CurPos_Reg    := 4;
    ScrewLength   := 10000; // units
    SpeedSet      := 1000;  // units/sec
  end;
end;

procedure TVxForm.ApplyParams;
begin
  MCurrentPos :=0.0;
  WCurrentPos :=0;
  MotorAngle  :=0;
  Mission.TargetPos:=-1;
  Mission.Done:=false;

  CalcLine(Params.ScrewLength,12,0,282,ScrewSlope,ScrewInter); // For screen Bearing position

  MLinearPos := MCurrentPos;

  ParamsApplied:=true;

  if Params.Mechanics = mecLinear then
  begin
    lblStop.Caption     :='STOP';
    lblMoveCW.Caption   :='MOVE DN';
    lblMoveCCW.Caption  :='MOVE UP';
    lblMovePos.Caption  :='MOVE POS';
    lblMovingCCW.Caption:='MOVING UP';
    lblMovingCW.Caption :='MOVING DN';
    lblDonePos.Caption  :='DONE POS';
    pnlScrew.Visible    :=true;
    pnlValues.Width     :=183;
    pnlStatus.Width     :=183;
  end
  else begin
    lblStop.Caption     :='-';
    lblMoveCW.Caption   :='MOVE CW';
    lblMoveCCW.Caption  :='MOVE CCW';
    lblMovePos.Caption  :='-';
    lblMovingCCW.Caption:='MOVING CCW';
    lblMovingCW.Caption :='MOVING CW';
    lblDonePos.Caption  :='-';

    pnlScrew.Visible    :=false;
    pnlValues.Width     :=256;
    pnlStatus.Width     :=256;
  end;

  UpdatePanel;
  UpdateBearing;

  lblName.Hint:=
    'Read Registers'+#13+
    '  Control Reg   : '+IntToStr(Params.Ctrl_Reg)+#13+
    '  Set Pos Reg   : '+IntToStr(Params.SetPos_Reg)+#13+
    'Write Registers'+#13+
    '  Status  Reg   : '+IntToStr(Params.Status_Reg)+#13+
    '  Cur Pos Reg   : '+IntToStr(Params.CurPos_Reg);

end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFLinearPos(AValue: double);
begin
  if FLinearPos<>AValue then
  begin
    FLinearPos:=AValue;
    UpdateBearing;
  end;
end;

procedure TVxForm.SetFState(AValue: TMotorState);
begin
  FState:=AValue;
  if Params.Mechanics=mecLinear then
    lblStatus.Caption:=StateTxtLin[FState]
  else
    lblStatus.Caption:=StateTxtRot[FState];
  lblStatus.Font.Color:=StateColors[FState];
end;

procedure TVxForm.UpdatePanel;

  procedure UpdateLed(Led : TueLED; Value : boolean);
  begin
    if Value then
      Led.Color:=Led.Tag
    else
      Led.Color:=LedColorOff;
  end;

Var
  c : integer;
begin
  lblSpeedSet.Caption:=inttostr(Params.SpeedSet);

  if Params.Mechanics = mecLinear then
    lblCurrentPos.Caption:=inttostr(WCurrentPos)
  else
    lblCurrentPos.Caption:='---';

  if Mission.TargetPos<0 then
    lblPosSet.Caption:='---'
  else
    lblPosSet.Caption:=inttostr(Round(Mission.TargetPos));

  Motor.PositionColor:=StateColors[State];

  for c:=0 to 7 do
  begin
    UpdateLed(Leds_IN[c],XI[c]);
    UpdateLed(Leds_OUT[c],XQ[c]);
  end;
end;

procedure TVxForm.UpdateBearing;
begin
  Bearing.Top:=Round(MCurrentPos*ScrewSlope+ScrewInter);
  Plate.Top:=Bearing.Top-8;
end;

procedure TVxForm.Logic;
Var
  Time_ms       : QWord;
  DeltaTime_ms  : QWord;
  Delta_Step    : double;
begin

  // Calc Delta Time
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  // How many steps we made in the time slice ?
  if MotorMovingCW or MotorMovingCCW then
    Delta_Step:=(Params.SpeedSet*DeltaTime_ms)/1000
  else
    Delta_Step:=0;

  if MotorMovingCW then
    MCurrentPos:=MCurrentPos-Delta_Step;

  if MotorMovingCCW then
    MCurrentPos:=MCurrentPos+Delta_Step;

//------------------------------------------------------------------------------

  // Wait everything zero -> Ready
  if (State = msNotReady) and
    not XI[I_STOP] and
    not XI[I_MOVE_UP] and
    not XI[I_MOVE_DN] and
    not XI[I_MOVE_POS] then
  begin
    State := msReady;
  end;

  // Move UP
  if (State = msReady) and XI[I_MOVE_UP] and not XI[I_MOVE_DN] and not XI[I_MOVE_POS] and not XI[I_STOP] then
  begin
    Mission.Done:=false;
    Mission.TargetPos:=-1;
    State := msMoveUP;
  end;

  if (State = msMoveUP) and not XI[I_MOVE_UP] then
  begin
    State := msReady;
  end;

  if (State = msMoveUP) and (Params.Mechanics=mecLinear) and (MCurrentPos>=Params.ScrewLength) then
  begin
    MCurrentPos:=Params.ScrewLength;
    State := msNotReady;
  end;


  // Move DN
  if (State = msReady) and XI[I_MOVE_DN] and not XI[I_MOVE_UP] and not XI[I_MOVE_POS] and not XI[I_STOP] then
  begin
    Mission.Done:=false;
    Mission.TargetPos:=-1;
    State := msMoveDN;
  end;

  if (State = msMoveDN) and not XI[I_MOVE_DN] then
  begin
    State := msReady;
  end;

  if (State = msMoveDN) and (Params.Mechanics=mecLinear) and (MCurrentPos<=0) then
  begin
    MCurrentPos:=0;
    State := msNotReady;
  end;

  // Move TO POS : start
  if (State = msReady) and (Params.Mechanics=mecLinear) and XI[I_MOVE_POS] and not XI[I_MOVE_UP] and not XI[I_MOVE_DN] and not XI[I_STOP] then
  begin
    if SetPosWord <> $FFFF then
    begin
      Mission.TargetPos:=SetPosWord;
      if Round(Mission.TargetPos) <> Round(MCurrentPos) then
      begin
        Mission.Done:=false;
        if Mission.TargetPos>MCurrentPos then
          Mission.Direction:=dirUP
        else
          Mission.Direction:=dirDN;
        State:=msMovePOS;
      end
      else begin
        State := msNotReady; // nothing to do, waiting I_MOVE_POS down
        Mission.Done:=true;
      end;
    end
    else begin // Register read error
      State := msNotReady;
      Mission.Done:=true;
      Mission.TargetPos:=-1;
    end;
  end;

  // Move TO POS : stop
  if (State = msMovePOS) and XI[I_STOP] then
  begin
    State := msNotReady;
    Mission.TargetPos:=-1;
    Mission.Done:=true;
  end;

  // Move TO POS : end
  if (State = msMovePOS) then
  begin
    if Mission.Direction = dirUP then
    begin
      if MCurrentPos>=Mission.TargetPos then
      begin
        MCurrentPos:=Mission.TargetPos;
        State := msNotReady;
        Mission.Done:=true;
      end;
    end
    else begin // dirDN
      if MCurrentPos<=Mission.TargetPos then
      begin
        MCurrentPos:=Mission.TargetPos;
        State := msNotReady;
        Mission.Done:=true;
      end;
    end;
  end;

  if MCurrentPos > Params.ScrewLength then
    MCurrentPos := Params.ScrewLength;

  if MCurrentPos < 0 then
    MCurrentPos := 0.0;

  if (Params.Mechanics=mecLinear) then
  begin
    MotorMovingCCW := ((State = msMoveUP) or ((State = msMovePOS) and (Mission.Direction = dirUP))) and (MCurrentPos<Params.ScrewLength);
    MotorMovingCW  := ((State = msMoveDN) or ((State = msMovePOS) and (Mission.Direction = dirDN))) and (MCurrentPos>0);
  end
  else begin
    MotorMovingCCW := (State = msMoveUP);
    MotorMovingCW  := (State = msMoveDN);
  end;

//-----------------------------------------------------------------
  MLinearPos  := MCurrentPos;         // Display
  WCurrentPos := Round(MCurrentPos);  // Reg write

  //----------------------------------------------------------------------------
  // IPU
  //----------------------------------------------------------------------------

  XQ[Q_READY]    := State = msReady;
  XQ[Q_MOVING_UP]:= MotorMovingCCW;
  XQ[Q_MOVING_DN]:= MotorMovingCW;
  XQ[Q_DONE_POS] := Mission.Done;
  XQ[Q_4]        := false;
  XQ[Q_5]        := false;
  XQ[Q_6]        := false;
  XQ[Q_7]        := false;
end;

procedure TVxForm.Start;
begin
  ApplyParams;
  Timer.Enabled:=true;
  MotorTimer.Enabled:=true;
  FRunning:=true;
  LastTick:=GetTickCount64;
  State:=msNotReady;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  MotorTimer.Enabled:=false;
  State:=msNotReady;
  Mission.TargetPos:=-1;
  XI:=WordToBits(0);
  XQ:=WordToBits(0);
  UpdatePanel;

  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
  SetLedStatus(LedCom[3], _rsUnknown);
  SetLedStatus(LedCom[4], _rsUnknown);
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommReadRegisterAdd(Params.Ctrl_Reg);
  Regs[2].Index:=CommReadRegisterAdd(Params.SetPos_Reg);
  Regs[3].Index:=CommWriteRegisterAdd(Params.Status_Reg,0,0);
  Regs[4].Index:=CommWriteRegisterAdd(Params.CurPos_Reg,0,0);
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
      Params.Mechanics    :=TMechanics(ini.ReadInteger(Section,'Mechanics',ord(Params.Mechanics)));
      Params.Ctrl_Reg     :=ini.ReadInteger(Section,'Ctrl_Reg',Params.Ctrl_Reg);
      Params.SetPos_Reg   :=ini.ReadInteger(Section,'SetPos_Reg',Params.SetPos_Reg);
      Params.Status_Reg   :=ini.ReadInteger(Section,'Status_Reg',Params.Status_Reg);
      Params.CurPos_Reg   :=ini.ReadInteger(Section,'CurPos_Reg',Params.CurPos_Reg);
      Params.ScrewLength  :=ini.ReadInteger(Section,'ScrewLength',Params.ScrewLength);
      Params.SpeedSet     :=ini.ReadInteger(Section,'SpeedSet',Params.SpeedSet);
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
    ini.WriteInteger(Section,'Mechanics',ord(Params.Mechanics));
    ini.WriteInteger(Section,'Ctrl_Reg',Params.Ctrl_Reg);
    ini.WriteInteger(Section,'SetPos_Reg',Params.SetPos_Reg);
    ini.WriteInteger(Section,'Status_Reg',Params.Status_Reg);
    ini.WriteInteger(Section,'CurPos_Reg',Params.CurPos_Reg);
    ini.WriteInteger(Section,'ScrewLength',Params.ScrewLength);
    ini.WriteInteger(Section,'SpeedSet',Params.SpeedSet);
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


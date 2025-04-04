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
  TMechanics = (mecRotary, mecLinear);

  TMotorParams = record
    Mechanics     : TMechanics;
    Speed_Reg     : word;   // input
    Ctrl_Reg      : word;   // input
    SetPos_Reg    : word;   // input
    Status_Reg    : word;   // output
    CurPos_Reg    : word;   // output
    ScrewLength   : double; // mm
    ScrewPitch    : double; // mm
    MotorPulseRev : integer;// Steps per revolution
  end;

  TMotorState = (msDisabled, msReady, msRunAbsCW, msRunAbsCCW, msRunRelCW, msRunRelCCW, msJogCW, msJogCCW, msHoming, msError, msNotReady);

  TMoveMode  = (mmAbsolute, mmRelative);
  TDirection = (dirCW, dirCCW);

  TMotorMission = record
    Mode      : TMoveMode;
    Direction : TDirection;
    Done      : boolean;
    TargetPos : double;
    CountPos  : double;
    DeltaPos  : double;
  end;

Const
  Umis : array[TMechanics] of string =('step/s','mm/s');

Type
{ TVxForm }

  TVxForm = class(TForm)
    BCRoundedImage3: TBCRoundedImage;
    btnForceError: TBCButton;
    ch_umis: TCheckBox;
    Label11: TLabel;
    Label15: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    lblTargetPos: TLabel;
    lblPosT_umis: TLabel;
    Motor: TBGRAKnob;
    Label1: TLabel;
    Label10: TLabel;
    lblHome_OUT: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    lblHome_IN: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblPos_umis: TLabel;
    lblSpeed_umis: TLabel;
    lblchumis: TLabel;
    lblStatus: TLabel;
    lblStatus_txt: TLabel;
    lblPosSet: TLabel;
    lblSpeedSet: TLabel;
    lblCurrentPos: TLabel;
    lblCurrentPos_umis: TLabel;
    LedCom_3: TuELED;
    LedCom_4: TuELED;
    LedCom_5: TuELED;
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
    ULS_Sensor: TShape;
    LLS_Sensor: TShape;
    Home_Sensor: TShape;
    Plate: TShape;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    procedure btnForceErrorClick(Sender: TObject);
    procedure ch_umisClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label19Click(Sender: TObject);
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
    FVisMode              : boolean;
    // Specific
    LedCom                : array[1..5] of TuELED;
    Regs                  : array[1..5] of TRegisterModule;
    Params                : TMotorParams;
    Leds_IN               : array[0..7] of TuELED;
    Leds_OUT              : array[0..7] of TuELED;
    FState                : TMotorState;
    ErrorSet              : boolean;
    LastTick              : QWord;
    XI                    : TWordBits;
    XQ                    : TWordBits;
    LLS_Pos               : integer;
    ULS_Pos               : integer;
    HOME_Pos              : integer;
    MPLCSpeedSet          : integer; // Runtime
    MPLCPosSet            : integer; // Runtime
    Mission               : TMotorMission;
    MotorMovingCW         : boolean;
    MotorMovingCCW        : boolean;
    MCurrentPos           : double;
    FLinearPos            : double;
    MaxSpeedSet           : integer;
    KTrans                : double;
    KAngle                : double;
    DeltaHome             : double;
    MotorAngle            : double;
    ScrewSlope            : double;
    ScrewInter            : double;
    ParamsApplied         : boolean;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure SetFLinearPos(AValue: double);
    procedure SetFState(AValue: TMotorState);
    procedure SetFVisMode(AValue: boolean);
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
    property VisMode : boolean read FVisMode write SetFVisMode;
    property MLinearPos : double read FLinearPos write SetFLinearPos;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Const

  LedColorOff = $002C2C2C;

  PLCLEds : array[0..7] of TColor = (clLime, $004080FF, clYellow, clLime, clLime, clAqua, clYellow, clLime);

  TestULeds : array[0..7] of TColor = (clLime, clLime, $004080FF, clLime, clRed, clRed, clYellow, clRed);

  StateTxt    : array[TMotorState] of string = ('DISABLED', 'READY', 'RUN ABS +', 'RUN ABS -', 'RUN REL +', 'RUN REL -', 'JOG +', 'JOG -', 'HOMING', 'ERROR', 'NOT READY');
  StateColors : array[TMotorState] of TColor = ( clSilver,   clLime,  clLime,      clLime,      $00FF80FF,   $00FF80FF,   clAqua,  clAqua,  clYellow, clRed, $00C080FF);

  I_ENABLE  = 0;
  I_START   = 1;
  I_STOP    = 2;
  I_RESET   = 3;
  I_ABSREL  = 4;
  I_DIR     = 5;
  I_HOME    = 6;
  I_JOG     = 7;

  Q_ENABLED = 0;
  Q_READY   = 1;
  Q_MOVING  = 2;
  Q_DONE    = 3;
  Q_ERROR   = 4;
  Q_LLS     = 5;
  Q_HOME    = 6;
  Q_ULS     = 7;

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
  LedCom[5]:=LedCom_5;

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
  MPLCSpeedSet :=0;
  MPLCPosSet   :=0;
  ErrorSet     :=false;
  ParamsApplied:=false;

  State:=msDisabled;
  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
  SetLedStatus(LedCom[3], _rsUnknown);
  SetLedStatus(LedCom[4], _rsUnknown);
  SetLedStatus(LedCom[5], _rsUnknown);
end;

procedure TVxForm.Label19Click(Sender: TObject);
begin

end;

procedure TVxForm.MotorTimerTimer(Sender: TObject);
Var
  Delta : single;
begin
  if MotorMovingCW or MotorMovingCCW then
  begin
    Delta:=MPLCSpeedSet/100;

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

procedure TVxForm.btnForceErrorClick(Sender: TObject);
begin
  if (MotorMovingCW or MotorMovingCCW) or (State in [msReady, msNotReady]) then
    ErrorSet:=true;
end;

procedure TVxForm.ch_umisClick(Sender: TObject);
begin
  VisMode:=ch_umis.Checked;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Var
  ValueIN  : array[1..3] of word;
  ValueOUT : array[1..2] of word;
  c     : integer;
  Error : boolean;
  ICurrentPos : integer;
begin
  Error := false;
  for c:=1 to 3 do
  begin
    Regs[c].Status:=CommRegisterRead(Regs[c].Index, {%H-}ValueIN[c]);
    if Regs[c].Status <> _rsOK then
      Error:=true;
  end;

 if Error then
   for c:=1 to 3 do
     ValueIN[c]:=0;

  MPLCSpeedSet:=ValueIN[1];
  if MPLCSpeedSet>MaxSpeedSet then
    MPLCSpeedSet:=MaxSpeedSet;

  MPLCPosSet:=ValueIN[2] and $FF00;
  MPLCPosSet:=(MPLCPosSet shl 8) + ValueIN[3];
  XI:=WordToBits(ValueIN[2] and $00FF);

  Logic;
  UpdatePanel;

  ICurrentPos:=Round(MCurrentPos);

  ValueOUT[1]:=BitsToWord(XQ) and $00FF;
  ValueOUT[1]:=ValueOUT[1] or ((ICurrentPos shr 8) and $FF00);
  ValueOUT[2]:=ICurrentPos and $0000FFFF;

  CommRegisterWrite(Regs[4].Index, ValueOUT[1]);
  CommRegisterWrite(Regs[5].Index, ValueOUT[2]);

  Regs[4].Status:=CommRegisterStatus(_rkWrite,Regs[4].Index);
  Regs[5].Status:=CommRegisterStatus(_rkWrite,Regs[5].Index);

  SetLedStatus(LedCom[1], Regs[1].Status);
  SetLedStatus(LedCom[2], Regs[2].Status);
  SetLedStatus(LedCom[3], Regs[3].Status);
  SetLedStatus(LedCom[4], Regs[4].Status);
  SetLedStatus(LedCom[5], Regs[5].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  with Params do
  begin
    Mechanics     := mecLinear;
    Speed_Reg     := 20;
    Ctrl_Reg      := 21;
    SetPos_Reg    := 22;
    Status_Reg    := 23;
    CurPos_Reg    := 24;
    ScrewLength   := 1000.0; // mm
    ScrewPitch    := 2.0;    // mm
    MotorPulseRev := 200;    // Steps per revolution
  end;
end;

procedure TVxForm.ApplyParams;
Var
  ScrewMaxSteps : integer;
begin
  VisMode      :=Params.Mechanics=mecLinear;
  ScrewMaxSteps:=Round((Params.ScrewLength*Params.MotorPulseRev)/Params.ScrewPitch);
  LLS_Pos      :=0;
  ULS_Pos      :=ScrewMaxSteps;
  DeltaHome    :=Params.ScrewLength/10; // 10%
  KTrans       :=Params.MotorPulseRev/Params.ScrewPitch;
  KAngle       :=360/Params.MotorPulseRev;
  MaxSpeedSet  :=Round((MaxSpeed_rpm*Params.MotorPulseRev)/60);

  if Params.Mechanics=mecLinear then
    HOME_Pos :=Round(DeltaHome*KTrans)
  else
    HOME_Pos :=0;

  CalcLine(ScrewMaxSteps,12,0,282,ScrewSlope,ScrewInter); // For screen Bearing position

  ch_umis.Visible:=FVisMode;
  ch_umis.Checked:=FVisMode;
  lblchumis.Visible:=FVisMode;

  if Params.Mechanics=mecLinear then
  begin
    pnlScrew.Visible:=true;
    pnlValues.Width:=187;
    pnlStatus.Width:=187;
    lblHome_IN.Caption:='HOME';
    lblHome_OUT.Caption:='HOME';
  end
  else begin
    pnlScrew.Visible:=false;
    pnlValues.Width:=259;
    pnlStatus.Width:=259;
    lblHome_IN.Caption:='SETREF';
    lblHome_OUT.Caption:='REF';
  end;

  MCurrentPos:=HOME_Pos;
  MLinearPos :=(MCurrentPos/KTrans) - DeltaHome;
  MotorAngle :=0;

  ParamsApplied:=true;
  UpdatePanel;
  UpdateBearing;
  lblName.Hint:=
    'Read Registers'+#13+
    '  Set Speed Reg : '+IntToStr(Params.Speed_Reg)+#13+
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
  lblStatus.Caption:=StateTxt[FState];
  lblStatus.Font.Color:=StateColors[FState];
end;

procedure TVxForm.SetFVisMode(AValue: boolean);
begin
  if FVisMode<>AValue then
  begin
    FVisMode:=AValue;
    if VisMode then
    begin
      lblPos_umis.Caption:='mm';
      lblPosT_umis.Caption:='mm';
      lblSpeed_umis.Caption:='mm/s';
      lblCurrentPos_umis.Caption:='mm';
    end
    else begin
      lblPos_umis.Caption:='step';
      lblPosT_umis.Caption:='step';
      lblSpeed_umis.Caption:='step/s';
      lblCurrentPos_umis.Caption:='step';
    end;
    if ParamsApplied then
      UpdatePanel;
  end;
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
  S : string;
begin
  if VisMode then
  begin
    lblPosSet.Caption :=StringReplace(FloatStr(MPLCPosSet/KTrans, 3),'.',',',[]);
    lblSpeedSet.Caption:=StringReplace(FloatStr(MPLCSpeedSet/KTrans, 3),'.',',',[]);
    lblTargetPos.Caption:=StringReplace(FloatStr((Mission.TargetPos/KTrans)-DeltaHome, 3),'.',',',[]);
    lblCurrentPos.Caption:=StringReplace(FloatStr(MLinearPos, 3),'.',',',[]);
  end
  else begin
    lblPosSet.Caption    :=inttostr(Round(MPLCPosSet));
    lblSpeedSet.Caption  :=inttostr(Round(MPLCSpeedSet));
    lblTargetPos.Caption :=inttostr(Round(Mission.TargetPos));
    lblCurrentPos.Caption:=inttostr(Round(MCurrentPos));
  end;

  if Params.Mechanics=mecLinear then
  begin
    if XQ[Q_LLS] then
      LLS_Sensor.Brush.Color:=clRed
    else
      LLS_Sensor.Brush.Color:=clSilver;

    if XQ[Q_ULS] then
      ULS_Sensor.Brush.Color:=clRed
    else
      ULS_Sensor.Brush.Color:=clSilver;

    if XQ[Q_HOME] then
      HOME_Sensor.Brush.Color:=clYellow
    else
      HOME_Sensor.Brush.Color:=clSilver;
  end;

  case State of
    msDisabled : Motor.PositionColor:=clSilver;
    msReady,
    msNotReady,
    msHoming,
    msRunAbsCW,
    msRunAbsCCW,
    msRunRelCW,
    msRunRelCCW : Motor.PositionColor:=clLime;
    msJogCW,
    msJogCCW    : Motor.PositionColor:=clAqua;
    msError     : Motor.PositionColor:=clRed;
  end;

  for c:=0 to 7 do
  begin
    UpdateLed(Leds_IN[c],XI[c]);
    UpdateLed(Leds_OUT[c],XQ[c]);
  end;
end;

procedure TVxForm.UpdateBearing;
begin
  if Params.Mechanics=mecLinear then
  begin
    Bearing.Top:=Round(MCurrentPos*ScrewSlope+ScrewInter);
    Plate.Top:=Bearing.Top-8;
  end;
end;

procedure TVxForm.Logic;
Var
  Time_ms       : QWord;
  DeltaTime_ms  : QWord;
  Delta_Step    : double;
  LLS_Error     : boolean;
  ULS_Error     : boolean;
begin
  LLS_Error := false;
  ULS_Error := false;

  // Calc Delta Time
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  // How many steps we made in the time slice ?
  if MotorMovingCW or MotorMovingCCW then
    Delta_Step:=(MPLCSpeedSet*DeltaTime_ms)/1000
  else
    Delta_Step:=0;

  if MotorMovingCW then
    MCurrentPos:=MCurrentPos+Delta_Step;

  if MotorMovingCCW then
    MCurrentPos:=MCurrentPos-Delta_Step;

  if State in [msRunRelCW, msRunRelCCW] then
  begin
    Mission.CountPos:=Mission.CountPos-Delta_Step;
    if Mission.CountPos<=0 then
      Mission.Done:=true;
  end;

  if Params.Mechanics = mecLinear then
  begin
    // Spiral Screw : we need to ensure to not breaking anything
    if MCurrentPos<=LLS_Pos then
    begin
      MCurrentPos:=LLS_Pos;
      LLS_Error:=true;
    end;
    if MCurrentPos>=ULS_Pos then
    begin
      MCurrentPos:=ULS_Pos;
      ULS_Error:=true;
    end;
  end
  else begin
    // Endless moving : rollover over the max and under the min
    if MCurrentPos<0 then
      MCurrentPos:=MaxSteps+MCurrentPos;

    if MCurrentPos>MaxSteps then
      MCurrentPos:=MCurrentPos-MaxSteps;
  end;

  MLinearPos :=(MCurrentPos/KTrans) - DeltaHome;

//==============================================================================
//  State Shift
//==============================================================================

  //----------------------------------------------------------------------------
  // ENABLE/DISABLE/READY
  //----------------------------------------------------------------------------
  if not XI[I_ENABLE] then
  begin
    State:=msDisabled;
    Mission.Done:=false;
  end;

  if (State=msDisabled) and XI[I_ENABLE] then
  begin
    State:=msNotReady;
  end;

  // At the end of every action the machine goes in NotReady state, this to avoid
  // of rerunning the same action because a Start/Home/Stop/Reset/Jog bit is not dropped.

  // No other bit must be present to be Ready
  if (State=msNotReady) and not XI[I_STOP] and not XI[I_RESET] and not XI[I_START] and not XI[I_HOME] and not XI[I_JOG] then
     State:=msReady;

  //----------------------------------------------------------------------------
  // JOG
  //----------------------------------------------------------------------------
  if (State=msReady) and XI[I_JOG] then
  begin
    Mission.Done:=false;
    if XI[I_DIR] then
    begin
      if not LLS_Error then
        State:=msJogCCW
      else
        State:=msNotReady;
    end
    else begin
      if not ULS_Error then
        State:=msJogCW
      else
        State:=msNotReady;
    end;
  end;

  if (State in [msJogCW, msJogCCW]) and not XI[I_JOG] then
  begin
    State:=msReady; // Jog released -> Redy
  end;

  // Lower Limit Switch
  if (State=msJogCW) and ULS_Error then
  begin
    State:=msNotReady; // no need to raise the error, simply stop the motor
  end;

  // Upper Limit Switch
  if (State=msJogCCW) and LLS_Error then
  begin
    State:=msNotReady; // no need to raise the error, simply stop the motor
  end;

  //----------------------------------------------------------------------------
  // SET REFERENCE (only in Endless movement)
  //----------------------------------------------------------------------------
  if (State=msReady) and (Params.Mechanics=mecRotary) and XI[I_HOME] then
  begin
    MCurrentPos:=0;
    Mission.Done:=false;
    State:=msNotReady;
  end;

  //----------------------------------------------------------------------------
  // MISSION
  //----------------------------------------------------------------------------

  // Relative movement : Current Pos = Current Pos +/- Delta
  if (State=msReady) and XI[I_ABSREL] and XI[I_START] then
  begin
    Mission.Done:=false;
    if XI[I_DIR] then // CCW
    begin
      State:=msRunRelCCW;
      Mission.Direction:=dirCCW;
      Mission.TargetPos:=MCurrentPos-MPLCPosSet;
      if Mission.TargetPos<0 then
        Mission.TargetPos:=MaxSteps+Mission.TargetPos;
    end
    else begin
      State:=msRunRelCW;
      Mission.Direction:=dirCW;
      Mission.TargetPos:=MCurrentPos+MPLCPosSet;
      if Mission.TargetPos>MaxSteps then
        Mission.TargetPos:=Mission.TargetPos-MaxSteps;
    end;
    Mission.Mode    :=mmRelative;
    Mission.CountPos:=MPLCPosSet;
    Mission.DeltaPos:=MPLCPosSet;
  end;

  if (State in [msRunRelCW, msRunRelCCW]) and Mission.Done then
  begin
    MCurrentPos:=Mission.TargetPos;
    State:=msNotReady;
  end;

  // Absolute movement : Current Pos = New Position
  if (State=msReady) and not XI[I_ABSREL] and XI[I_START] then
  begin
    Mission.Done:=false;
    Mission.Mode:=mmAbsolute;
    Mission.TargetPos:=MPLCPosSet;
    if MPLCPosSet<MCurrentPos then // CCW
    begin
      State:=msRunAbsCCW;
      Mission.Direction:=dirCCW;
    end
    else begin
      State:=msRunAbsCW;
      Mission.Direction:=dirCW;
    end;
  end;

  if (State = msRunAbsCW) and (MCurrentPos>=Mission.TargetPos) then
  begin
    MCurrentPos:=Mission.TargetPos;
    Mission.Done:=true;
    State:=msNotReady;
  end;

  if (State = msRunAbsCCW) and (MCurrentPos<=Mission.TargetPos) then
  begin
    MCurrentPos:=Mission.TargetPos;
    Mission.Done:=true;
    State:=msNotReady;
  end;

  if (State in [msRunAbsCW, msRunRelCW, msRunAbsCCW, msRunRelCCW]) and XI[I_STOP] then
    State:=msNotReady;
  //----------------------------------------------------------------------------
  // HOME
  //----------------------------------------------------------------------------
  if (State=msReady) and XI[I_HOME] and (Params.Mechanics=mecLinear) and (Round(MCurrentPos)<>HOME_Pos) then
  begin
    Mission.Done:=false;
    Mission.Mode:=mmAbsolute;
    Mission.TargetPos:=HOME_Pos;
    State:=msHoming;
    if Mission.TargetPos<MCurrentPos then // CCW
      Mission.Direction:=dirCCW
    else
      Mission.Direction:=dirCW
  end;

  if (State=msHoming) and XI[I_STOP] then
  begin
    State:=msNotReady;
  end;

  if (State=msHoming) and (Mission.Direction=dirCCW) and (MCurrentPos<=Mission.TargetPos) then
  begin
    MCurrentPos:=Mission.TargetPos;
    Mission.Done:=true;
    State:=msNotReady;
  end;

  if (State=msHoming) and (Mission.Direction=dirCW) and (MCurrentPos>=Mission.TargetPos) then
  begin
    MCurrentPos:=Mission.TargetPos;
    Mission.Done:=true;
    State:=msNotReady;
  end;

  //----------------------------------------------------------------------------
  // ERROR
  //----------------------------------------------------------------------------
  if (State in [msRunAbsCW, msRunRelCW]) and (ULS_Error or ErrorSet) then
  begin
    ErrorSet:=false;
    State:=msError;
  end;

  if (State in [msRunAbsCCW, msRunRelCCW]) and (LLS_Error or ErrorSet) then
  begin
    ErrorSet:=false;
    State:=msError;
  end;

  if (State in [msReady, msNotReady, msHoming]) and ErrorSet then
  begin
    ErrorSet:=false;
    State:=msError;
  end;

  if (State=msError) and XI[I_RESET] then
    State:=msNotReady;

  //----------------------------------------------------------------------------
  // IPU
  //----------------------------------------------------------------------------
  MotorMovingCW :=(State in [msRunAbsCW, msRunRelCW, msJogCW]) or ((State=msHoming) and (Mission.Direction=dirCW));
  MotorMovingCCW:=(State in [msRunAbsCCW, msRunRelCCW, msJogCCW]) or ((State=msHoming) and (Mission.Direction=dirCCW));

  XQ[Q_ENABLED]:=XI[I_ENABLE];
  XQ[Q_READY]  :=State=msReady;
  XQ[Q_MOVING] :=MotorMovingCW or MotorMovingCCW;
  XQ[Q_DONE]   :=Mission.Done;
  XQ[Q_ERROR]  :=State=msError;
  XQ[Q_LLS]    :=(Params.Mechanics=mecLinear) and (MCurrentPos<=LLS_Pos);
  XQ[Q_ULS]    :=(Params.Mechanics=mecLinear) and (MCurrentPos>=ULS_Pos);
  XQ[Q_HOME]   :=(Round(MCurrentPos)>=HOME_Pos-3*KTrans) and (Round(MCurrentPos)<=HOME_Pos+3*KTrans);
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  MotorTimer.Enabled:=true;
  FRunning:=true;
  LastTick:=GetTickCount64;
  State:=msDisabled;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  MotorTimer.Enabled:=false;
  State:=msDisabled;
//  CommRegisterFastWrite(Regs[2].Index, 0);
  XI:=WordToBits(0);
  XQ:=WordToBits(0);
  UpdatePanel;

  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
  SetLedStatus(LedCom[3], _rsUnknown);
  SetLedStatus(LedCom[4], _rsUnknown);
  SetLedStatus(LedCom[5], _rsUnknown);
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommReadRegisterAdd(Params.Speed_Reg);
  Regs[2].Index:=CommReadRegisterAdd(Params.Ctrl_Reg);
  Regs[3].Index:=CommReadRegisterAdd(Params.SetPos_Reg);
  Regs[4].Index:=CommWriteRegisterAdd(Params.Status_Reg,0,0);
  Regs[5].Index:=CommWriteRegisterAdd(Params.CurPos_Reg,0,0);
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
      Params.Speed_Reg    :=ini.ReadInteger(Section,'Speed_Reg',Params.Speed_Reg);
      Params.Ctrl_Reg     :=ini.ReadInteger(Section,'Ctrl_Reg',Params.Ctrl_Reg);
      Params.SetPos_Reg   :=ini.ReadInteger(Section,'SetPos_Reg',Params.SetPos_Reg);
      Params.Status_Reg   :=ini.ReadInteger(Section,'Status_Reg',Params.Status_Reg);
      Params.CurPos_Reg   :=ini.ReadInteger(Section,'CurPos_Reg',Params.CurPos_Reg);
      Params.ScrewLength  :=ini.ReadFloat(Section,'ScrewLength_mm',Params.ScrewLength);
      Params.ScrewPitch   :=ini.ReadFloat(Section,'ScrewPitch_mm',Params.ScrewPitch);
      Params.MotorPulseRev:=ini.ReadInteger(Section,'MotorPulseRev',Params.MotorPulseRev);
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
    ini.WriteInteger(Section,'Speed_Reg',Params.Speed_Reg);
    ini.WriteInteger(Section,'Ctrl_Reg',Params.Ctrl_Reg);
    ini.WriteInteger(Section,'SetPos_Reg',Params.SetPos_Reg);
    ini.WriteInteger(Section,'Status_Reg',Params.Status_Reg);
    ini.WriteInteger(Section,'CurPos_Reg',Params.CurPos_Reg);
    ini.WriteFloat(Section,'ScrewLength_mm',Params.ScrewLength);
    ini.WriteFloat(Section,'ScrewPitch_mm',Params.ScrewPitch);
    ini.WriteInteger(Section,'MotorPulseRev',Params.MotorPulseRev);
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


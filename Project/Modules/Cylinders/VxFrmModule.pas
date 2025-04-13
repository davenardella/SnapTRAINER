unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap, BGRACustomDrawn,
  BGRABitmapTypes, VxUtils, ueled;

type

  TInitialPosition = (ipRetracted, ipMiddle, ipExtended);

  TCylinderSet = record
    Caption         : string;
    Stroke          : double;
    SpeedExtend     : double;
    SpeedRetract    : double;
    SpringReturn    : boolean;
    HasExtended     : boolean;
    HasRetracted    : boolean;
    InitialPosition : TInitialPosition;
  end;

  TCylinderParams = record
    Input_Reg  : word;
    Output_Reg : word;
    CyAmount   : integer;
    CY         : array[1..4] of TCylinderSet;
  end;

  TCylinderStatus = (cysInactive, cysActive, cysStalled);

  { TCylinder }

  TCylinder = class(TComponent)
  private
    FIndex       : integer;
    FParams      : TCylinderSet;
    FParent      : TWincontrol;
    FLeft        : integer;
    FPosition    : double;
    FVisible     : boolean;
    KPos         : double;
    FStatus      : TCylinderStatus;
    FTop         : integer;
    pnlBody      : TBCPanel;
    pnlRod       : TBCPanel;
    SQ_R         : TShape;
    SQ_E         : TShape;
    EV_E         : TShape;
    EV_R         : TShape;
    lblStroke    : TLabel;
    lblSpeedE    : TLabel;
    lblSpeedR    : TLabel;
    FProxyR      : boolean;
    FProxyE      : boolean;
    StrokeExt_ms : double;
    StrokeRet_ms : double;
    LastTick     : QWord;
    function CreatePart(AColor, AParentColor : TColor) : TBCPanel;
    procedure SetFParams(AValue: TCylinderSet);
    procedure SetFPosition(AValue: double);
    procedure SetFVisible(AValue: boolean);
  public
    constructor Create(AOWner : TComponent; AParent : TWinControl; AParams : TCylinderSet; Index, ALeft, ATop : integer); reintroduce;
    destructor Destroy; override;
    procedure Update(EvE, EvR : boolean; var ProxyE, ProxyR : boolean);
    procedure Start;
    property Params : TCylinderSet read FParams write SetFParams;
    property Status : TCylinderStatus read FStatus;
    property Position : double read FPosition write SetFPosition;
    property Visible : boolean read FVisible write SetFVisible;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    lblStatus_1: TLabel;
    lblStatus_2: TLabel;
    lblStatus_3: TLabel;
    lblStatus_4: TLabel;
    pnlCylinders: TBCPanel;
    pnlStatus: TBCPanel;
    lblName: TLabel;
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
    Regs                  : array[1..2] of TRegisterModule;
    Params                : TCylinderParams;
    CY                    : array[1..4] of TCylinder;
    lblStatus             : array[1..4] of TLabel;
    EvBits                : TWordBits;
    ProxyBits             : TWordBits;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure CreateCylinders;
    procedure SetFIndex(AValue: integer);
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
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Const
  BitColor_R  : array[boolean] of TColor = (clGray, clLime);
  BitColor_E  : array[boolean] of TColor = (clGray, clRed);

  StatusColor : array[TCylinderStatus] of TColor = ($00D1D1D1, clLime, clRed);
  StatusText  : array[TCylinderStatus] of string = ('Inactive', 'Active', 'Stalled');

  Hysteresis  = 5; // Proximity Hysteresis (mm)

var
  VxForm: TVxForm;

  { TCylinder }

function TCylinder.CreatePart(AColor, AParentColor: TColor): TBCPanel;
begin
  Result:=TBCPanel.Create(Self);
  Result.Parent:=FParent;
  Result.Color:=APArentColor;
  Result.BorderBCStyle:=bpsBorder;
  Result.Border.Style:=bboNone;
  Result.Border.Color:=clBtnFace;
  Result.Background.Color:=clBtnFace;
  Result.Background.Style:=bbsGradient;
  Result.Background.Gradient1EndPercent:=50;
  Result.Background.Gradient1.StartColor:=clBlack;
  Result.Background.Gradient1.EndColor:=AColor;
  Result.Background.Gradient1.GradientType:=gtLinear;
  Result.Background.Gradient1.Point1XPercent:=0;
  Result.Background.Gradient1.Point1YPercent:=0;
  Result.Background.Gradient1.Point2XPercent:=0;
  Result.Background.Gradient1.Point2YPercent:=100;

  Result.Background.Gradient2.StartColor:=AColor;
  Result.Background.Gradient2.EndColor:=clBlack;
  Result.Background.Gradient2.GradientType:=gtLinear;
  Result.Background.Gradient2.Point1XPercent:=0;
  Result.Background.Gradient2.Point1YPercent:=0;
  Result.Background.Gradient2.Point2XPercent:=0;
  Result.Background.Gradient2.Point2YPercent:=100;
  Result.FontEx.Style:=[fsBold];
end;

procedure TCylinder.SetFParams(AValue: TCylinderSet);
Var
  FCaption : string;
begin
  FParams:=AValue;
  if FParams.Stroke<1 then FParams.Stroke:=1;
  lblStroke.Caption:=FloatStr(FParams.Stroke,0)+' mm';
  lblSpeedE.Caption:=FloatStr(FParams.SpeedExtend,0)+' mm/s';
  lblSpeedR.Caption:=FloatStr(FParams.SpeedRetract,0)+' mm/s';

  FCaption:=Trim(FParams.Caption);
  if FCaption<>'' then
    pnlBody.Caption:=FCaption
  else
    pnlBody.Caption:='Cylinder '+IntToStr(FIndex);

  StrokeExt_ms := FParams.SpeedExtend/1000;
  StrokeRet_ms := FParams.SpeedRetract/1000;
  KPos:=138/FParams.Stroke;

  EV_R.Visible:=not FParams.SpringReturn;
  if not FParams.SpringReturn then
  begin
    case FParams.InitialPosition of
      ipRetracted:Position:=0;
      ipMiddle   :Position:=FParams.Stroke/2;
      ipExtended :Position:=FParams.Stroke;
    end;
  end
  else
    Position:=0;

  SQ_E.Visible:=FParams.HasExtended;
  SQ_R.Visible:=FParams.HasRetracted;
end;

procedure TCylinder.SetFPosition(AValue: double);
Var
  FWidth : integer;
begin
  FPosition:=AValue;
  FWidth:=round(FPosition*KPos)+5;

  if pnlRod.Width<>FWidth then
    pnlRod.Width:=FWidth;

  if FParams.HasRetracted then
  begin
    FProxyR:=FPosition<Hysteresis;
    SQ_R.Brush.Color:=BitColor_R[FProxyR];
  end
  else
    FProxyR:=false;

  if FParams.HasExtended then
  begin
    FProxyE:=FPosition>(FParams.Stroke-Hysteresis);
    SQ_E.Brush.Color:=BitColor_R[FProxyE];
  end
  else
    FProxyE:=false;
end;

procedure TCylinder.SetFVisible(AValue: boolean);
begin
  if FVisible<>AValue then
  begin
    FVisible:=AValue;
    pnlBody.Visible:=FVisible;
    pnlRod.Visible:=FVisible;
    lblStroke.Visible:=FVisible;
    lblSpeedE.Visible:=FVisible;
    lblSpeedR.Visible:=FVisible;
    EV_E.Visible:=FVisible;
    EV_R.Visible:=FVisible and not FParams.SpringReturn;
    SQ_E.Visible:=FVisible and FParams.HasExtended;
    SQ_R.Visible:=FVisible and FParams.HasRetracted;
  end;
end;

constructor TCylinder.Create(AOWner : TComponent; AParent: TWinControl; AParams: TCylinderSet; Index,
  ALeft, ATop: integer);

  function CreateValve(ALeft, ATop : integer; AColor : TColor) : TShape;
  begin
    Result:=TShape.Create(Self);
    Result.Parent:=FParent;
    Result.Shape:=stTriangle;
    Result.Width:=18;
    Result.Height:=18;
    Result.Left:=ALeft;
    Result.Top:=ATop;
    Result.Brush.Color:=AColor;
  end;

  function CreateProximity(ALeft, ATop : integer; AColor : TColor) : TShape;
  begin
    Result:=TShape.Create(Self);
    Result.Parent:=pnlBody;
    Result.Shape:=stRectangle;
    Result.Width:=18;
    Result.Height:=10;
    Result.Left:=ALeft;
    Result.Top:=ATop;
    Result.Brush.Color:=AColor;
    Result.Pen.Style:=psClear;
  end;

begin
  inherited Create(AOwner);
  FIndex  :=Index;
  FParent :=AParent;
  FLeft   :=ALeft;
  FTop    :=ATop;
  FVisible:=true;
  pnlBody:=CreatePart(clWhite, clBlack);
  pnlBody.Left:=FLeft;
  pnlBody.Top:=FTop;
  pnlBody.Width:=154;
  pnlBody.Height:=38;

  pnlRod:=CreatePart($00FFE4C4, clBlack);
  pnlRod.Left:=FLeft+154;
  pnlRod.Top:=FTop+11;
  pnlRod.Width:=138;
  pnlRod.Height:=16;

  EV_E:= CreateValve(FLeft+2, FTop+39, BitColor_R[false]);
  EV_R:= CreateValve(FLeft+135, FTop+39, BitColor_E[false]);

  SQ_R:=CreateProximity(3, 4, BitColor_R[false]);
  SQ_E:=CreateProximity(135, 4, BitColor_E[false]);

  lblStroke:=TLabel.Create(Self);
  lblStroke.Parent:=FParent;
  lblStroke.AutoSize:=false;
  lblStroke.Alignment:=taCenter;
  lblStroke.Width:=113;
  lblStroke.Left:=FLeft+20;
  lblStroke.Top:=FTop+40;
  lblStroke.Font.Name:='Segoe UI';
  lblStroke.Font.Color:=clWhite;
  lblStroke.Font.Quality:=fqCleartypeNatural;

  lblSpeedE:=TLabel.Create(Self);
  lblSpeedE.Parent:=FParent;
  lblSpeedE.Left:=FLeft;
  lblSpeedE.Top:=FTop-13;
  lblSpeedE.Font.Name:='Segoe UI';
  lblSpeedE.Font.Color:=clWhite;
  lblSpeedE.Font.Quality:=fqCleartypeNatural;

  lblSpeedR:=TLabel.Create(Self);
  lblSpeedR.Parent:=FParent;
  lblSpeedR.AutoSize:=false;
  lblSpeedR.Alignment:=taRightJustify;
  lblSpeedR.Width:=82;
  lblSpeedR.Left:=FLeft+72;
  lblSpeedR.Top:=FTop-13;
  lblSpeedR.Font.Name:='Segoe UI';
  lblSpeedR.Font.Color:=clWhite;
  lblSpeedR.Font.Quality:=fqCleartypeNatural;

  Params:=AParams;
end;

destructor TCylinder.Destroy;
begin
  inherited Destroy;
end;

procedure TCylinder.Update(EvE, EvR: boolean; var ProxyE, ProxyR: boolean);
Var
  Time_ms          : QWord;
  DeltaTime_ms     : QWord;
  DeltaStroke_Ext  : double;
  DeltaStroke_Ret  : double;
  NewPosition      : double;

  function CalcPosition : double;
  begin
    Result:=FPosition;

    if FParams.SpringReturn then
    begin
      FStatus:=cysActive;
      if EvE then
        Result:=FPosition+DeltaStroke_Ext
      else
        Result:=FPosition-DeltaStroke_Ret;
      exit;
    end;

    if not EvE and not EvR then // Stopped
    begin
      FStatus:=cysInactive;
      exit;
    end;

    if EvE and not EvR then // Extending
    begin
      FStatus:=cysActive;
      Result:=FPosition+DeltaStroke_Ext;
      exit;
    end;

    if not EvE and EvR then // Retracting
    begin
      FStatus:=cysActive;
      Result:=FPosition-DeltaStroke_Ret;
      exit;
    end;

    FStatus:=cysStalled;
  end;

begin
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  DeltaStroke_Ext := StrokeExt_ms * DeltaTime_ms;
  DeltaStroke_Ret := StrokeRet_ms * DeltaTime_ms;

  EV_E.Brush.Color:=BitColor_E[EvE];
  EV_R.Brush.Color:=BitColor_R[EvR];

  NewPosition:=CalcPosition;
  if NewPosition<0 then NewPosition:=0.0;
  if NewPosition>FParams.Stroke then NewPosition:=FParams.Stroke;

  Position:=NewPosition;

  ProxyE:=FProxyE;
  ProxyR:=FProxyR;
end;

procedure TCylinder.Start;
begin
  LastTick:=GetTickCount64;
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  lblStatus[1]:=lblStatus_1;
  lblStatus[2]:=lblStatus_2;
  lblStatus[3]:=lblStatus_3;
  lblStatus[4]:=lblStatus_4;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  pnlCylinders.Background.Color:=clBlack; // Sometime BCPanel "forgets" something...
  pnlStatus.Background.Color:=$007D7D7D;

  SetDefaultParams;
  CreateCylinders;

  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  ProxyVal   : word;
  EvValue    : word;
  BitE, BitR : integer;
  c          : integer;
begin
  ProxyVal:=0;
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}EvValue);
  if Regs[1].Status <> _rsOK then
    EvValue:=0;

  EvBits:=WordToBits(EvValue);
  for c:=1 to Params.CyAmount do
  begin
    BitE:=(c-1)*2;
    BitR:=BitE+1;
    CY[c].Update(EvBits[BitE], EvBits[BitR], ProxyBits[BitE], ProxyBits[BitR]);
  end;

  ProxyVal:=BitsToWord(ProxyBits);

  for c:=1 to Params.CyAmount do
  begin
    lblStatus[c].Font.Color:=StatusColor[CY[C].Status];
    lblStatus[c].Caption:=StatusText[CY[C].Status];
  end;

  CommRegisterWrite(Regs[2].Index, ProxyVal);
  Regs[2].Status:=CommRegisterStatus(_rkWrite, Regs[2].Index);

  SetLedStatus(LedCom[1], Regs[1].Status);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;


procedure TVxForm.SetDefaultParams;
Var
  c : integer;
begin
  Params.Input_Reg:=9;
  Params.Output_Reg:=10;
  Params.CyAmount:=4;
  for c:=1 to 4 do
  begin
    Params.CY[c].Caption:='Cylinder '+IntToStr(c);
    Params.CY[c].Stroke:=100;
    Params.CY[c].SpeedExtend:=10;
    Params.CY[c].SpeedRetract:=10;
    Params.CY[c].SpringReturn:=false;
    Params.CY[c].HasExtended:=true;
    Params.CY[c].HasRetracted:=true;
    Params.CY[c].InitialPosition:=ipMiddle;
  end;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  for c:=1 to 4 do
  begin
    if C<=Params.CyAmount then
    begin
      CY[c].Visible:=true;
      lblStatus[c].Visible:=true;
      CY[c].Params:=Params.CY[c];
      lblStatus[c].Font.Color:=StatusColor[CY[C].Status];
      lblStatus[c].Caption:=StatusText[CY[C].Status];
    end
    else begin
      CY[c].Visible:=false;
      lblStatus[c].Visible:=false;
    end;
  end;
  lblName.Hint:='Read  Reg : '+IntToStr(Params.Input_Reg)+#13+
                'Write Reg : '+IntToStr(Params.Output_Reg);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.CreateCylinders;
var
  c, Y : integer;
begin
  Y:=20;
  for c:=1 to 4 do
  begin
    CY[c]:=TCylinder.Create(Self, pnlCylinders, Params.CY[c], C, 8, Y);
    Y:=Y+75;
  end;
end;

procedure TVxForm.Start;
begin
  ApplyParams;
  Timer.Enabled:=true;
  FRunning:=true;
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
  Regs[2].Index:=CommWriteRegisterAdd(Params.Output_Reg,0,0);
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
  c   : integer;
begin
  Section:='SLOT_'+IntToStr(FIndex);

  if Filename<>'' then
  begin
    ini:=TMemIniFile.Create(FileName);
    try
      Params.Input_Reg:=ini.ReadInteger(Section,'Input_Reg',Params.Input_Reg);
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.CyAmount:=ini.ReadInteger(Section,'CyAmount',Params.CyAmount);

      for c:=1 to 4 do
      begin
        Params.CY[c].Caption:=ini.ReadString(Section,'CY'+IntToStr(c)+'.Caption','');
        Params.CY[c].Stroke:=ini.ReadFloat(Section,'CY'+IntToStr(c)+'.Stroke',Params.CY[c].Stroke);
        Params.CY[c].SpeedExtend:=ini.ReadFloat(Section,'CY'+IntToStr(c)+'.SpeedExtend',Params.CY[c].SpeedExtend);
        Params.CY[c].SpeedRetract:=ini.ReadFloat(Section,'CY'+IntToStr(c)+'.SpeedRetract',Params.CY[c].SpeedRetract);
        Params.CY[c].SpringReturn:=ini.ReadBool(Section,'CY'+IntToStr(c)+'.SpringReturn',Params.CY[c].SpringReturn);
        Params.CY[c].HasExtended:=ini.ReadBool(Section,'CY'+IntToStr(c)+'.HasExtended',Params.CY[c].HasExtended);
        Params.CY[c].HasRetracted:=ini.ReadBool(Section,'CY'+IntToStr(c)+'.HasRetracted',Params.CY[c].HasRetracted);
        Params.CY[c].InitialPosition:=TInitialPosition(ini.ReadInteger(Section,'CY'+IntToStr(c)+'.InitialPosition',Ord(Params.CY[c].InitialPosition)));
      end;
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
  c : integer;
begin
  Section:='SLOT_'+IntToStr(FIndex);
  ini:=TMemIniFile.Create(FileName);
  try
    ini.WriteString(Section, 'ModuleName', FName);
    ini.WriteInteger(Section,'Input_Reg',Params.Input_Reg);
    ini.WriteInteger(Section,'Output_Reg',Params.Output_Reg);
    ini.WriteInteger(Section,'CyAmount',Params.CyAmount);
    for c:=1 to 4 do
    begin
      ini.WriteString(Section,'CY'+IntToStr(c)+'.Caption',Params.CY[c].Caption);
      ini.WriteFloat(Section,'CY'+IntToStr(c)+'.Stroke',Params.CY[c].Stroke);
      ini.WriteFloat(Section,'CY'+IntToStr(c)+'.SpeedExtend',Params.CY[c].SpeedExtend);
      ini.WriteFloat(Section,'CY'+IntToStr(c)+'.SpeedRetract',Params.CY[c].SpeedRetract);
      ini.WriteBool(Section,'CY'+IntToStr(c)+'.SpringReturn',Params.CY[c].SpringReturn);
      ini.WriteBool(Section,'CY'+IntToStr(c)+'.HasExtended',Params.CY[c].HasExtended);
      ini.WriteBool(Section,'CY'+IntToStr(c)+'.HasRetracted',Params.CY[c].HasRetracted);
      ini.WriteInteger(Section,'CY'+IntToStr(c)+'.InitialPosition',Ord(Params.CY[c].InitialPosition));
    end;
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


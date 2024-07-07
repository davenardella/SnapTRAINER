unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCButton, BGRACustomDrawn,
  VxUtils, ueled;

type

  TTankParams = record
    Input_Reg        : word;
    Output_Reg       : word;
    Capacity         : double;
    FlowInput        : double;
    FlowOutput       : double;
    LevelMin_100     : double;
    LevelMax_100     : double;
    WaterInit_100    : double;
    UsePLCOutputFlow : boolean;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    lblOutletDyn: TLabel;
    pnlTank: TBCPanel;
    pnlFlow: TBCPanel;
    pnlSensors: TBCPanel;
    pnlLevel: TBCPanel;
    lblMaxValue: TLabel;
    Label11: TLabel;
    lblMinValue: TLabel;
    Label13: TLabel;
    lblLevel_Val: TLabel;
    Label15: TLabel;
    lblLevel_100: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblInletVal: TLabel;
    Label6: TLabel;
    lblOutletVal: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ValveOutlet: TShape;
    ValveInlet: TShape;
    PipeOutlet: TBCPanel;
    PipeInlet: TBCPanel;
    TankFull: TBCPanel;
    TankEmpty: TBCPanel;
    Label1: TLabel;
    Label2: TLabel;
    lblCapacity: TLabel;
    lblWarning: TLabel;
    lblName: TLabel;
    SensorHigh: TShape;
    SensorLow: TShape;
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
    Params                : TTankParams;
    TankHeight            : integer;
    SensorTop             : integer;
    Water                 : double;
    LastWater             : double;
    Water_100             : double;
    LevelHigh             : boolean;
    LevelLow              : boolean;
    InletActive           : boolean;
    OutletActive          : boolean;
    SlopeTank             : double;
    InterTank             : double;
    LastTick              : QWord;
    RealFlowOutput        : double;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure InitTank;
    procedure UpdatePanel;
    function FlowString(Flow : double) : string;
    procedure SetFIndex(AValue: integer);
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
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Const
  WaterBaseColor = $00FFCA88;
  WaterColor : array[boolean] of TColor = (clGray, WaterBaseColor);
  SensorColor : array[boolean] of TColor = (clGray, clRed);
  ValveColor  : array[boolean] of TColor = (clGray, clLime);

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  pnlTank.Background.Color:=clBlack; // Sometime BCPanel "forgets" something...
  pnlFlow.Background.Color:=$002F8AFF;
  pnlSensors.Background.Color:=$004CC16C;

  TankHeight:=224;
  SensorTop:=9;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value  : word;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}Value);
  if Regs[1].Status = _rsOK then
  begin
    InletActive  :=(Value and $4000)<>0;
    OutletActive :=(Value and $8000)<>0;

    if Params.UsePLCOutputFlow then
      RealFlowOutput:=(Value and $3FFF)*1.0
    else
      RealFlowOutput:=Params.FlowOutput;

    if OutletActive then
      lblOutletDyn.Caption:=FlowString(RealFlowOutput)
    else
      lblOutletDyn.Caption:=FlowString(0.0);
  end;

  UpdatePanel;

  Value:=Round(Water);     // 14 bits -> 0..16383
  if LevelLow then
    Value:=Value or $4000; // 15Th bit

  if LevelHigh then
    Value:=Value or $8000; // 16Th bit

  CommRegisterWrite(Regs[2].Index, Value);
  Regs[2].Status:=CommRegisterStatus(_rkRead, Regs[2].Index);

  SetLedStatus(LedCom[1], Regs[1].Status);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;


procedure TVxForm.SetDefaultParams;
begin
  with Params do
  begin
    Input_Reg    :=11;
    Output_Reg   :=12;
    Capacity     :=1000.0;
    FlowInput    :=100.0;
    FlowOutput   :=10;
    LevelMin_100 :=10.0;
    LevelMax_100 :=90.0;
    WaterInit_100:=50.0;
    Caption      :='TANK';
  end;
end;

procedure TVxForm.ApplyParams;
Var
  Slope : double;
  Inter : double;
begin
  LastWater:=-1; // To force the first update
  Water:=Params.Capacity*(Params.WaterInit_100/100.0);
  lblCapacity.Caption:=IntToStr(Round(Params.Capacity))+' L';
  lblInletVal.Caption :=FlowString(Params.FlowInput);
  lblOutletVal.Caption:=FlowString(Params.FlowOutput);
  lblOutletDyn.Caption:=FlowString(0.0);
  lblMaxValue.Caption:=FloatStr(Params.LevelMax_100,1)+' %';
  lblMinValue.Caption:=FloatStr(Params.LevelMin_100,1)+' %';
  lblLevel_100.Caption:=FloatStr(Params.WaterInit_100,1)+' %';
  CalcLine(0,SensorTop+TankHeight,100,SensorTop,Slope,Inter);
  SensorHigh.Top:=Round(Params.LevelMax_100*Slope+Inter);
  SensorLow.Top :=Round(Params.LevelMin_100*Slope+Inter);
  CalcLine(0,TankHeight,Params.Capacity,0,SlopeTank,InterTank);

  InitTank;
  lblName.Hint:='Read  Reg : '+IntToStr(Params.Input_Reg)+#13+
                'Write Reg : '+IntToStr(Params.Output_Reg);
end;

procedure TVxForm.InitTank;
begin
  lblLevel_Val.Caption:=FloatStr(Water,1);
  Water_100:=(Water/Params.Capacity)*100;
  lblLevel_100.Caption:=FloatStr(Water_100,1)+' %';
  LevelHigh:=Water_100>=Params.LevelMax_100;
  LevelLow :=Water_100>=Params.LevelMin_100;
  SensorLow.Brush.Color :=SensorColor[LevelLow];
  SensorHigh.Brush.Color:=SensorColor[LevelHigh];
  TankEmpty.Height:=Round(Water*SlopeTank+InterTank);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.UpdatePanel;
Var
  Time_ms       : QWord;
  DeltaTime_ms  : QWord;
  Water_in      : double;
  Water_out     : double;
begin
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  ValveInlet.Brush.Color:=ValveColor[InletActive];
  if InletActive then
  begin
    Water_In:=(Params.FlowInput*DeltaTime_ms)/60000;
    PipeInlet.Background.Gradient1.EndColor:=WaterColor[true];
    PipeInlet.Background.Gradient2.StartColor:=WaterColor[true];
  end
  else begin
    Water_In:=0.0;
    PipeInlet.Background.Gradient1.EndColor:=clWhite;
    PipeInlet.Background.Gradient2.StartColor:=clWhite;
  end;

  ValveOutlet.Brush.Color:=ValveColor[OutletActive];
  if OutletActive then
  begin
    Water_Out:=(RealFlowOutput*DeltaTime_ms)/60000;
    PipeOutlet.Background.Gradient1.StartColor:=WaterColor[true];
  end
  else begin
    Water_Out:=0.0;
    PipeOutlet.Background.Gradient1.StartColor:=clWhite;
  end;

  Water:=Water+Water_In-Water_Out;

  if Water>=Params.Capacity then
    lblWarning.Caption:='Flooding'
  else
    if Water<=0 then
      lblWarning.Caption:='Empty'
    else
      lblWarning.Caption:='';

  if Water>Params.Capacity then
    Water:=Params.Capacity;
  if Water<0.0 then
    Water:=0.0;

  if Water<>LastWater then
  begin
    lblLevel_Val.Caption:=FloatStr(Water,1);
    Water_100:=(Water/Params.Capacity)*100;
    lblLevel_100.Caption:=FloatStr(Water_100,1)+' %';
    LevelHigh:=Water_100>=Params.LevelMax_100;
    LevelLow :=Water_100>=Params.LevelMin_100;
    SensorLow.Brush.Color :=SensorColor[LevelLow];
    SensorHigh.Brush.Color:=SensorColor[LevelHigh];
    TankEmpty.Height:=Round(Water*SlopeTank+InterTank);
    LastWater:=Water;
  end;
end;

function TVxForm.FlowString(Flow: double): string;
begin
  Result:=Format('%s L/min',[FloatStr(Flow,1)]);
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  FRunning:=true;
  LastTick:=GetTickCount64;
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
begin
  Section:='SLOT_'+IntToStr(FIndex);

  if Filename<>'' then
  begin
    ini:=TMemIniFile.Create(FileName);
    try
      Params.Input_Reg:=ini.ReadInteger(Section,'Input_Reg',Params.Input_Reg);
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.UsePLCOutputFlow:=ini.ReadBool(Section,'UsePLCOutputFlow',Params.UsePLCOutputFlow);

      Params.Capacity:=ini.ReadFloat(Section,'Capacity',Params.Capacity);
      Params.FlowInput:=ini.ReadFloat(Section,'FlowInput',Params.FlowInput);
      Params.FlowOutput:=ini.ReadFloat(Section,'FlowOutput',Params.FlowOutput);
      Params.LevelMin_100:=ini.ReadFloat(Section,'LevelMin_100',Params.LevelMin_100);
      Params.LevelMax_100:=ini.ReadFloat(Section,'LevelMax_100',Params.LevelMax_100);
      Params.WaterInit_100:=ini.ReadFloat(Section,'WaterInit_100',Params.WaterInit_100);

      if Params.Capacity>16383 then Params.Capacity:=16383;
      if Params.Capacity<1 then Params.Capacity:=1;

      if Params.LevelMin_100>100 then Params.LevelMin_100:=100;
      if Params.LevelMin_100<0 then Params.LevelMin_100:=0;

      if Params.LevelMax_100>100 then Params.LevelMin_100:=100;
      if Params.LevelMax_100<0 then Params.LevelMax_100:=0;

      if Params.WaterInit_100>100 then Params.WaterInit_100:=100;
      if Params.WaterInit_100<0 then Params.WaterInit_100:=0;
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
    ini.WriteBool(Section,'UsePLCOutputFlow',Params.UsePLCOutputFlow);
    ini.WriteFloat(Section,'Capacity',Params.Capacity);
    ini.WriteFloat(Section,'FlowInput',Params.FlowInput);
    ini.WriteFloat(Section,'FlowOutput',Params.FlowOutput);
    ini.WriteFloat(Section,'LevelMin_100',Params.LevelMin_100);
    ini.WriteFloat(Section,'LevelMax_100',Params.LevelMax_100);
    ini.WriteFloat(Section,'WaterInit_100',Params.WaterInit_100);
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


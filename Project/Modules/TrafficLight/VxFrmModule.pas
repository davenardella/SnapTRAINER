unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, LedNumber, BGRABitmapTypes, VxUtils, ueled;

type


  TTrafficLightParams = record
    Input_Reg  : word;
    CarMode    : boolean;
  end;


  { TTRafficLamp }

  TTRafficLamp = class(TObject)
  private
    FCarMode: boolean;
    FLed : TuELED;
    FDisplay : TLEDNumber;
    FColorOFF : TColor;
    FColorON : TColor;
    LastValue : boolean;
    LampTime  : double;
    procedure PrintTime(Time_ms : double);
    procedure LedColor(Color : TColor);
  public
    constructor Create(Led : TuELED; Display : TLEDNumber; ColorOFF, ColorON : TColor);
    procedure Update(Value : boolean; DeltaTime_ms : QWord);
    procedure Reset;
    property CarMode : boolean read FCarMode write FCarMode;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    Image1: TImage;
    Pedestrian: TImage;
    Images: TImageList;
    lblErrorP: TLabel;
    pnlPedestrian: TBCPanel;
    Time_G: TLEDNumber;
    Time_Y: TLEDNumber;
    Time_R: TLEDNumber;
    Label1: TLabel;
    lblYellow: TLabel;
    Label3: TLabel;
    lblError: TLabel;
    Led_R: TuELED;
    Led_Y: TuELED;
    Led_G: TuELED;
    pnlTrafficLight: TBCPanel;
    lblName: TLabel;
    pnlTimers: TBCPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
    LedCom                : array[1..1] of TuELED;
    // Specific
    Regs                  : array[1..2] of TRegisterModule;
    Params                : TTrafficLightParams;
    LastTick              : QWord;
    LampR                 : TTRafficLamp;
    LampY                 : TTRafficLamp;
    LampG                 : TTRafficLamp;
    LampStop              : TTRafficLamp;
    LampWalk              : TTRafficLamp;
    procedure SetDefaultParams;
    procedure ApplyParams;
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
  LampRColor : array[boolean] of TColor = ($00000040, clRed);
  LampYColor : array[boolean] of TColor = ($00005353, clYellow);
  LampGColor : array[boolean] of TColor = ($00003500, clLime);

var
  VxForm: TVxForm;

{ TTRafficLamp }

procedure TTRafficLamp.PrintTime(Time_ms: double);
Var
  TimeTenth : double;
  StrTime   : string;
begin
  TimeTenth:=Time_ms/100;
  Str(TimeTenth:0:1,StrTime);
  StrTime:=StringReplace(StrTime,'.',',',[]);
  while Length(StrTime)< (FDisplay.Columns+1) do
    StrTime:=' '+StrTime;
  FDisplay.Caption:=StrTime;
end;

procedure TTRafficLamp.LedColor(Color: TColor);
begin
  if FCarMode and Assigned(FLed) then
    FLed.Color:=Color;
end;

constructor TTRafficLamp.Create(Led: TuELED; Display: TLEDNumber; ColorOFF, ColorON : TColor);
begin
  inherited create;
  FLed      := Led;
  FDisplay  := Display;
  FColorOFF := ColorOFF;
  FColorON  := ColorON;
  Reset;
end;

procedure TTRafficLamp.Update(Value: boolean; DeltaTime_ms : QWord);
begin
  if Value then
    LampTime:=LampTime + DeltaTime_ms;

  if (Value <> LastValue) then
  begin
    LastValue:=Value;
    if Value then
    begin
      LampTime:=0.0;
      LedColor(FColorON);
    end
    else
      LedColor(FColorOFF);
  end;

  PrintTime(LampTime);
end;

procedure TTRafficLamp.Reset;
begin
  LastValue :=false;
  LampTime  :=0.0;
  LedColor(FColorOFF);
  PrintTime(LampTime);
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  pnlTrafficLight.Background.Color:=clSilver; // Sometime BCPanel "forgets" something...
  pnlTimers.Background.Color:=$00292929;

  LampR := TTRafficLamp.Create(Led_R, Time_R, LampRColor[false], LampRColor[true]);
  LampY := TTRafficLamp.Create(Led_Y, Time_Y, LampYColor[false], LampYColor[true]);
  LampG := TTRafficLamp.Create(Led_G, Time_G, LampGColor[false], LampGColor[true]);
  LampStop :=TTRafficLamp.Create(nil, Time_R, clBlack, clBlack);
  LampWalk :=TTRafficLamp.Create(nil, Time_G, clBlack, clBlack);

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
end;

procedure TVxForm.FormDestroy(Sender: TObject);
begin
  Timer.Enabled:=false;
  LampStop.Free;
  LampWalk.Free;
  LampG.Free;
  LampY.Free;
  LampR.Free;
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Time_ms          : QWord;
  DeltaTime_ms     : QWord;
  LampValues       : word;
  RVal, YVal, GVal : boolean;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}LampValues);
  if Regs[1].Status <> _rsOK then
    LampValues:=0;

  // Calc Delta Time
  Time_ms:=GetTickCount64;
  DeltaTime_ms:=Time_ms-LastTick;
  LastTick:=Time_ms;

  GVal:=LampValues and $0001 <> 0;
  YVal:=LampValues and $0002 <> 0;
  RVal:=LampValues and $0004 <> 0;

  if Params.CarMode then
  begin
    LampG.Update(GVal, DeltaTime_ms);
    LampY.Update(YVal, DeltaTime_ms);
    LampR.Update(RVal, DeltaTime_ms);
  end
  else begin
    LampWalk.Update(GVal, DeltaTime_ms);
    LampStop.Update(RVal, DeltaTime_ms);
    if GVal<>RVal then
    begin
      if GVal then
        Pedestrian.ImageIndex:=1
      else
        Pedestrian.ImageIndex:=2;
    end
    else
      Pedestrian.ImageIndex:=0;
  end;

  lblError.Visible:=((RVal=true) and (GVal=true)) or ((RVal=true) and (YVal=true));
  lblErrorP.Visible:=((RVal=true) and (GVal=true));

  SetLedStatus(LedCom[1], Regs[1].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg:=1;
  Params.CarMode:=true;
end;

procedure TVxForm.ApplyParams;
begin
  lblName.Hint:='Read Reg : '+IntToStr(Params.Input_Reg);
  if Params.CarMode then
  begin
    pnlPedestrian.Visible:=false;
    pnlTrafficLight.Visible:=true;
    lblYellow.Visible:=true;
    Time_Y.Visible:=true;
  end
  else begin
    pnlTrafficLight.Visible:=false;
    pnlPedestrian.Visible:=true;
    lblYellow.Visible:=false;
    Time_Y.Visible:=false;
  end;
  LampStop.CarMode:=Params.CarMode;
  LampWalk.CarMode:=Params.CarMode;
  LampG.CarMode:=Params.CarMode;
  LampY.CarMode:=Params.CarMode;
  LampR.CarMode:=Params.CarMode;

  if Params.CarMode then
  begin
    LampG.Reset;
    LampY.Reset;
    LampR.Reset;
  end
  else begin
    LampStop.Reset;
    LampWalk.Reset;
  end;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  if Params.CarMode then
  begin
    LampG.Reset;
    LampY.Reset;
    LampR.Reset;
  end
  else begin
    LampStop.Reset;
    LampWalk.Reset;
  end;
  Timer.Enabled:=true;
  FRunning:=true;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom[1], 0);
  lblError.Visible:=false;
end;

procedure TVxForm.PrepareStart;
begin
  Regs[1].Index:=CommReadRegisterAdd(Params.Input_Reg);
  lblError.Visible:=false;
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
      Params.CarMode:=ini.ReadBool(Section,'CarMode',Params.CarMode);
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
    ini.WriteBool(Section,'CarMode',Params.CarMode);
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


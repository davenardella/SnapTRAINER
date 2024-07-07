unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, BGRAFlashProgressBar, BGRABitmapTypes, VxUtils, ueled;

Type
  TTestUnitScrapMode = (usmRandom, usmCyclic);
  TTestUnitParams = record
    Input_Reg   : word;
    Output_Reg  : word;
    TestTime    : double;
    PercentPass : integer; // 0 : Random
    ScrapMode   : TTestUnitScrapMode;
  end;

  TMachineState = (msStopped, msReady, msRunning, msError, msNotReady);

{ TVxForm }

  TVxForm = class(TForm)
    btnForceError: TBCButton;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblTime: TLabel;
    lblResult: TLabel;
    lblStatus_txt: TLabel;
    lblStatus: TLabel;
    lblResult_txt: TLabel;
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
    Bar: TBGRAFlashProgressBar;
    pnlLEds: TBCPanel;
    pnlStatus: TBCPanel;
    lblName: TLabel;
    pnlTime: TBCPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    procedure btnForceErrorClick(Sender: TObject);
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
    Params                : TTestUnitParams;
    Leds_IN               : array[0..7] of TuELED;
    Leds_OUT              : array[0..7] of TuELED;
    FState                : TMachineState;
    ITestTime             : QWord;
    IRunTime              : QWord;
    ErrorSet              : boolean;
    Elapsed               : QWord;
    FTestResult           : integer;
    ScrapCode             : integer;
    XI                    : TWordBits;
    XQ                    : TWordBits;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure SetFState(AValue: TMachineState);
    procedure SetFTestResult(AValue: integer);
    procedure UpdatePanel;
    procedure ShiftState;
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
    property State : TMachineState read FState write SetFState;
    property TestResult  : integer read FTestResult write SetFTestResult;
  end;


implementation
{$R *.lfm}

Uses
  VxFrmSettings;

Type

  TLedDescriptor = record
    Caption : String;
    ColorON : TCOlor;
  end;

Const

  LedColorOff = $002C2C2C;

  PLCLEds : array[0..7] of TLedDescriptor = (
    (Caption:'START';ColorOn:clLime),
    (Caption:'STOP' ;ColorOn:clRed),
    (Caption:'RESET';ColorOn:clYellow),
    (Caption:'';     ColorOn:clNone),
    (Caption:'';     ColorOn:clNone),
    (Caption:'';     ColorOn:clNone),
    (Caption:'';     ColorOn:clNone),
    (Caption:'';     ColorOn:clNone)
  );

  TestULeds : array[0..7] of TLedDescriptor = (
    (Caption:'READY'; ColorOn:clLime),
    (Caption:'BUSY' ; ColorOn:$004080FF),
    (Caption:'DONE';  ColorOn:clLime),
    (Caption:'ERROR'; ColorOn:clRed),
    (Caption:'RES_0'; ColorOn:clAqua),
    (Caption:'RES_1'; ColorOn:clAqua),
    (Caption:'RES_2'; ColorOn:clAqua),
    (Caption:'RES_3'; ColorOn:clAqua)
  );

  StateTxt    : array[TMachineState] of string = ('STOPPED', 'READY', 'RUNNING', 'ERROR', 'NOT READY');
  StateColors : array[TMachineState] of TColor = (clSilver, clLime, clLime, clRed, $00C080FF);

  I_START = 0;
  I_STOP  = 1;
  I_RESET = 2;

  Q_READY = 0;
  Q_BUSY  = 1;
  Q_DONE  = 2;
  Q_ERROR = 3;
  Q_RES_0 = 4;
  Q_RES_1 = 5;
  Q_RES_2 = 6;
  Q_RES_3 = 7;

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
Var
  c : integer;
begin
  Timer.Enabled:=false;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;

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
    Leds_IN[c].Tag:=PLCLEds[c].ColorON;
    Leds_OUT[c].Tag:=TestULeds[c].ColorON;
  end;

  pnlLEds.Background.Color:=clBlack; // Sometime BCPanel "forgets" something...
  pnlStatus.Background.Color:=$007D7D7D;
  pnlTime.Background.Color:=$003B3B3B;

  IRunTime:=0;
  ErrorSet:=false;
  State:=msStopped;
  TestResult:=0;
  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.btnForceErrorClick(Sender: TObject);
begin
  if State=msRunning then
    ErrorSet:=true;
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  ValueIN,
  ValueOUT : word;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}ValueIN);
  if Regs[1].Status <> _rsOK then
    ValueIN:=0;

  XI:=WordToBits(ValueIN);

  ShiftState;
  UpdatePanel;

  ValueOUT:=BitsToWord(XQ);

  CommRegisterWrite(Regs[2].Index, ValueOUT);
  Regs[2].Status:=CommRegisterStatus(_rkWrite,Regs[2].Index);

  SetLedStatus(LedCom[1], Regs[1].Status);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  with Params do
  begin
    Input_Reg   := 13;
    Output_Reg  := 14;
    TestTime    := 5.0;
    PercentPass := 75;
    ScrapMode   := usmRandom;
  end;
end;

procedure TVxForm.ApplyParams;
begin
  ITestTime:=Round(Params.TestTime*1000);
  Bar.MaxValue:=ITestTime;
  lblName.Hint:='Read  Reg : '+IntToStr(Params.Input_Reg)+#13+
                'Write Reg : '+IntToStr(Params.Output_Reg);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFState(AValue: TMachineState);
begin
  FState:=AValue;
  lblStatus.Caption:=StateTxt[FState];
  lblStatus.Font.Color:=StateColors[FState];
end;

procedure TVxForm.SetFTestResult(AValue: integer);
begin
  FTestResult:=AValue;
  if FTestResult<>0 then
  begin
    if FTestResult = 1 then
    begin
      lblResult.Caption:='PASS';
      lblResult.Font.Color:=clLime;
    end
    else begin
      lblResult.Caption:='FAIL CODE '+IntToStr(FTestResult);
      lblResult.Font.Color:=clRed;
    end;
  end
  else begin
    lblResult.Caption:='-';
    lblResult.Font.Color:=clSilver;
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
begin
  lblTime.Caption:=FloatStr((IRunTime/1000),3)+' sec';
  Bar.Value:=IRunTime;

  for c:=0 to 7 do
  begin
    UpdateLed(Leds_IN[c],XI[c]);
    UpdateLed(Leds_OUT[c],XQ[c]);
  end;
end;

procedure TVxForm.ShiftState;

  function CalcResult : integer;
  Var
    V    : integer;
  begin
    V:=Random(100)+1;
    if V>Params.PercentPass then // Fail
    begin
      if Params.ScrapMode=usmCyclic then
      begin
        Result:=ScrapCode;
        inc(ScrapCode);
        if ScrapCode>15 then
          ScrapCode:=2;
      end
      else
        Result:=Random(13)+2;
    end
    else
      Result:=1;
  end;

begin
  if (State=msReady) and XI[I_START] then
  begin
    Elapsed:=GetTickCount64;
    TestResult:=0;
    State:=msRunning;
  end;

  if (State=msRunning) and XI[I_STOP] then
  begin
    TestResult:=0;
    State:=msNotReady;
  end;

  if (State=msRunning) and ErrorSet then
  begin
    ErrorSet:=false;
    State:=msError;
  end;

  if (State=msError) and XI[I_RESET] then
  begin
    State:=msNotReady;
  end;

  if (State=msRunning) then
  begin
    IRunTime:=GetTickCount64-Elapsed;
    if IRunTime>=ITestTime then
    begin
      IRunTime:=ITestTime;
      TestResult:=CalcResult;
      State:=msNotReady;
    end;
  end;

  if (State=msNotReady) and not (XI[I_START] or XI[I_STOP] or XI[I_RESET]) then
  begin
    State := msReady;
  end;

  XQ[Q_READY]:=State=msReady;
  XQ[Q_BUSY] :=State=msRunning;
  XQ[Q_ERROR]:=State=msError;
  XQ[Q_DONE] :=TestResult<>0;

  XQ[Q_RES_0]:=(TestResult and $0001)<>0;
  XQ[Q_RES_1]:=(TestResult and $0002)<>0;
  XQ[Q_RES_2]:=(TestResult and $0004)<>0;
  XQ[Q_RES_3]:=(TestResult and $0008)<>0;
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  FRunning:=true;
  State:=msReady;
  ScrapCode:=2;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  State:=msStopped;
  TestResult:=0;
  CommRegisterFastWrite(Regs[2].Index, 0);
  XI:=WordToBits(0);
  XQ:=WordToBits(0);
  UpdatePanel;
  SetLedStatus(LedCom[1], _rsUnknown);
  SetLedStatus(LedCom[2], _rsUnknown);
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
      Params.TestTime:=ini.ReadFloat(Section,'TestTime',Params.TestTime);
      Params.PercentPass:=ini.ReadInteger(Section,'PercentPass',Params.PercentPass);
      Params.ScrapMode:=TTestUnitScrapMode(ini.ReadInteger(Section,'ScrapMode',Ord(Params.ScrapMode)));
      if Params.TestTime<1.0 then Params.TestTime:=1.0;
      if Params.PercentPass<0 then Params.PercentPass:=0;
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
    ini.WriteFloat(Section,'TestTime',Params.TestTime);
    ini.WriteInteger(Section,'PercentPass',Params.PercentPass);
    ini.WriteInteger(Section,'ScrapMode',Ord(Params.ScrapMode));
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


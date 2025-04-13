unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, BCLabel, LedNumber, AdvLed, BGRABitmapTypes, VxUtils, ueled;

type

  TVendingMachineParams = record
    Input_Reg    : word;
    Output_Reg   : word;
    FastWrite    : boolean;
    CurrencyEur  : boolean;
    Price_1      : integer;
    Price_2      : integer;
    Price_3      : integer;
    Price_4      : integer;
    Price_5      : integer;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    Price_1: TBCLabel;
    Price_2: TBCLabel;
    Price_3: TBCLabel;
    Price_4: TBCLabel;
    Price_5: TBCLabel;
    BTN_1: TBCButton;
    BTN_10: TBCButton;
    BTN_12: TBCButton;
    BTN_14: TBCButton;
    BTN_2: TBCButton;
    BTN_3: TBCButton;
    BTN_4: TBCButton;
    BTN_5: TBCButton;
    BTN_6: TBCButton;
    BTN_8: TBCButton;
    Display: TLEDNumber;
    Image1: TImage;
    Label3: TLabel;
    lblCurrency: TLabel;
    Label2: TLabel;
    LedCom_2: TuELED;
    LedRent: TuELED;
    CoinLed_5: TuELED;
    CoinLed_4: TuELED;
    CoinLed_3: TuELED;
    CoinLed_2: TuELED;
    CoinLed_1: TuELED;
    pnlDisplay: TBCPanel;
    pnlKeyboard: TBCPanel;
    lblName: TLabel;
    pnlCoin: TBCPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LedRentMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LedRentMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimerTimer(Sender: TObject);
  private
    FDisplayValue: word;
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
    LedCom                : array[1..2] of TuELED;
    // Specific
    Regs                  : array[1..2] of TRegisterModule;
    CoinLeds              : array[1..5] of TuELED;
    Params                : TVendingMachineParams;
    LastTick              : QWord;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFDisplayValue(AValue: word);
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
    property DisplayValue : word read FDisplayValue write SetFDisplayValue;
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

  CoinLeds[1]:=CoinLed_1;
  CoinLeds[2]:=CoinLed_2;
  CoinLeds[3]:=CoinLed_3;
  CoinLeds[4]:=CoinLed_4;
  CoinLeds[5]:=CoinLed_5;

  pnlKeyboard.Color:=$00555555;
  pnlKeyboard.Background.Color:=$00161616; // Sometime BCPanel "forgets" something...
  pnlCoin.Color:=$00555555;
  pnlCoin.Background.Color:=$00161616;
  pnlDisplay.Color:=$00555555;
  pnlDisplay.Background.Color:=$00161616;

  Display.OffColor:=$000E3432;
  Display.OnColor :=clLime;
  Display.BgColor :=$00161616;

  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  idx : integer;
begin
  if ssLeft in Shift then
  begin
    idx :=(Sender as TComponent).Tag;
    if FRunning then
      OutputValue:=FOutputValue or Mask[idx];

    if idx in [5..9] then
      CoinLeds[idx-4].Color:=clRed;
  end;
end;

procedure TVxForm.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  idx : integer;
begin
  idx :=(Sender as TComponent).Tag;
  if FRunning then
    OutputValue:=FOutputValue and not Mask[idx];

  if idx in [5..9] then
    CoinLeds[idx-4].Color:=$003B3B3B;
end;

procedure TVxForm.FormDestroy(Sender: TObject);
begin
  Timer.Enabled:=false;
end;

procedure TVxForm.LedRentMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ssLeft in Shift then
  begin
    if FRunning then
      OutputValue:=FOutputValue or Mask[(Sender as TComponent).Tag];
    LedRent.Color:=$000000B7;
  end;
end;

procedure TVxForm.LedRentMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FRunning then
    OutputValue:=FOutputValue and not Mask[(Sender as TComponent).Tag];
  LedRent.Color:=clRed;
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  InWord : word;
begin
  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}InWord);
  if Regs[1].Status <> _rsOK then
    InWord:=$FFFE;
  SetLedStatus(LedCom[1], Regs[1].Status);
  DisplayValue:=InWord;

  Regs[2].Status:=CommRegisterStatus(_rkWrite, Regs[2].Index);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg:=1;
  Params.Output_Reg:=3;
  Params.FastWrite:=true;
  Params.CurrencyEur:=true;
  Params.Price_1:=25;
  Params.Price_2:=75;
  Params.Price_3:=90;
  Params.Price_4:=100;
  Params.Price_5:=175;
end;

procedure TVxForm.ApplyParams;

  function Price(Value : integer) : string;
  Var
    D : double;
  begin
    if Value > 0 then
    begin
      D:=Value/100;
      Str(D:0:2,Result);
      Result:=StringReplace(Result,'.',',',[]);
    end
    else
      Result:='--,--';
  end;

begin
  lblName.Hint:=
  'Read Registers'+#13+
  '  Amount  Reg : '+IntToStr(Params.Input_Reg)+#13+
  'Write Registers'+#13+
  '  Buttons Reg : '+IntToStr(Params.Output_Reg);
  if Params.CurrencyEur then
  begin
    lblCurrency.Caption:='€';
    BTN_1.Caption:='1 €';
  end
  else begin
    lblCurrency.Caption:='$';
    BTN_1.Caption:='1 $';
  end;

  Price_1.Caption:=Price(Params.Price_1);
  Price_2.Caption:=Price(Params.Price_2);
  Price_3.Caption:=Price(Params.Price_3);
  Price_4.Caption:=Price(Params.Price_4);
  Price_5.Caption:=Price(Params.Price_5);
end;

procedure TVxForm.SetFDisplayValue(AValue: word);
Var
  S : string;
  D : double;
begin
  FDisplayValue:=AValue;

  if FDisplayValue<$FFFF then
  begin
    if FDisplayValue<10000 then
    begin
      D:=FDisplayValue/100;
      Str(D:0:2,S);
      if FDisplayValue<1000 then
        S:=' '+S;
       S:=StringReplace(S,'.',',',[]);
    end
    else
      S:='--,--';

    lblCurrency.Visible:=true;
  end
  else begin
    S:='WAIT';
    lblCurrency.Visible:=false;
  end;

  Display.Caption:=S;
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
        Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index,FOutputValue);
        SetLedStatus(LedCom[2],Regs[2].Status);
      end
      else
        CommRegisterWrite(Regs[2].Index,FOutputValue);
    end
  end;
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  Timer.Enabled:=true;
  FRunning:=true;
  Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index,FOutputValue);
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
      Params.CurrencyEur:=ini.ReadBool(Section,'CurrencyEur',Params.CurrencyEur);
      Params.Price_1:=ini.ReadInteger(Section,'Price_1',Params.Price_1);
      Params.Price_2:=ini.ReadInteger(Section,'Price_2',Params.Price_2);
      Params.Price_3:=ini.ReadInteger(Section,'Price_3',Params.Price_3);
      Params.Price_4:=ini.ReadInteger(Section,'Price_4',Params.Price_4);
      Params.Price_5:=ini.ReadInteger(Section,'Price_5',Params.Price_5);
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
    ini.WriteBool(Section,'CurrencyEur',Params.CurrencyEur);
    ini.WriteInteger(Section,'Price_1',Params.Price_1);
    ini.WriteInteger(Section,'Price_2',Params.Price_2);
    ini.WriteInteger(Section,'Price_3',Params.Price_3);
    ini.WriteInteger(Section,'Price_4',Params.Price_4);
    ini.WriteInteger(Section,'Price_5',Params.Price_5);
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


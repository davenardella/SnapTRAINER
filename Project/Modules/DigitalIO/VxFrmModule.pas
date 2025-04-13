unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCButton, BGRACustomDrawn,
  BGRAFlashProgressBar, ECSwitch, LedNumber, VxUtils, ueled;

type

  TDigitalIOParams = record
    Input_Reg  : word;
    Output_Reg : word;
    Input_Ena  : boolean;
    Output_Ena : boolean;
    FastWrite  : boolean;
  end;


  TDisplayMode = (dmHex, dmDec, dmSigned);

  { TVxForm }

  TVxForm = class(TForm)
    InputBar: TBGRAFlashProgressBar;
    btn_H: TBCButton;
    btn_D: TBCButton;
    btn_S: TBCButton;
    OutputBar: TBGRAFlashProgressBar;
    SW_15: TECSwitch;
    SW_6: TECSwitch;
    SW_5: TECSwitch;
    SW_4: TECSwitch;
    SW_3: TECSwitch;
    SW_2: TECSwitch;
    SW_1: TECSwitch;
    SW_0: TECSwitch;
    SW_14: TECSwitch;
    SW_13: TECSwitch;
    SW_12: TECSwitch;
    SW_11: TECSwitch;
    SW_10: TECSwitch;
    SW_9: TECSwitch;
    SW_8: TECSwitch;
    SW_7: TECSwitch;
    KEY_17: TBCButton;
    KEY_18: TBCButton;
    KEY_19: TBCButton;
    KEY_20: TBCButton;
    KEY_21: TBCButton;
    KEY_22: TBCButton;
    KEY_23: TBCButton;
    KEY_24: TBCButton;
    KEY_25: TBCButton;
    KEY_26: TBCButton;
    KEY_27: TBCButton;
    KEY_28: TBCButton;
    KEY_29: TBCButton;
    KEY_30: TBCButton;
    KEY_31: TBCButton;
    KEY_32: TBCButton;
    btnOK: TBCButton;
    btnForceON: TBCButton;
    btnForceOFF: TBCButton;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    lblNameDI: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label3: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    lblNameDO: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    InputDisplay: TLEDNumber;
    OutputDisplay: TLEDNumber;
    PnlOutput: TPanel;
    TempDisplay: TPanel;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    Led_15: TuELED;
    Led_6: TuELED;
    Led_5: TuELED;
    Led_4: TuELED;
    Led_3: TuELED;
    Led_2: TuELED;
    Led_1: TuELED;
    Led_0: TuELED;
    Led_14: TuELED;
    Led_13: TuELED;
    Led_12: TuELED;
    Led_11: TuELED;
    Led_10: TuELED;
    Led_9: TuELED;
    Led_8: TuELED;
    Led_7: TuELED;
    procedure btnForceOFFClick(Sender: TObject);
    procedure btnForceONClick(Sender: TObject);
    procedure btnOKButtonClick(Sender: TObject);
    procedure DisplayModeChange(Sender: TObject);
    procedure KeyPressed(Sender: TObject);
    procedure SwitchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FDisplayMode: TDisplayMode;
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
    Params                : TDigitalIOParams;
    FInputValue           : word;
    FOutputValue          : word;
    TempValue             : word;
    Leds                  : array[0..15] of TuELED;
    Switches              : array[0..15] of TECSwitch;
    Regs                  : array[1..2] of TRegisterModule;
    Updating              : boolean;
    procedure EnergyZero;
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFDisplayMode(AValue: TDisplayMode);
    procedure SetFIndex(AValue: integer);
    procedure SetFInputValue(AValue: word);
    procedure SetFOutputValue(AValue: word);
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
    property InputValue : word read FInputValue write SetFInputValue;
    property OutputValue: word read FOutputValue write SetFOutputValue;
    property DisplayMode : TDisplayMode read FDisplayMode write SetFDisplayMode;
  end;


implementation
{$R *.lfm}
Uses
  VxFrmSettings;

Const
  LedColor : array[boolean] of TColor =  ($003B3B3B, clRed);

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;

  // Map Led and Switches in array
  Leds[0] :=Led_0;
  Leds[1] :=Led_1;
  Leds[2] :=Led_2;
  Leds[3] :=Led_3;
  Leds[4] :=Led_4;
  Leds[5] :=Led_5;
  Leds[6] :=Led_6;
  Leds[7] :=Led_7;
  Leds[8] :=Led_8;
  Leds[9] :=Led_9;
  Leds[10]:=Led_10;
  Leds[11]:=Led_11;
  Leds[12]:=Led_12;
  Leds[13]:=Led_13;
  Leds[14]:=Led_14;
  Leds[15]:=Led_15;

  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;

  Switches[0] :=SW_0;
  Switches[1] :=SW_1;
  Switches[2] :=SW_2;
  Switches[3] :=SW_3;
  Switches[4] :=SW_4;
  Switches[5] :=SW_5;
  Switches[6] :=SW_6;
  Switches[7] :=SW_7;
  Switches[8] :=SW_8;
  Switches[9] :=SW_9;
  Switches[10]:=SW_10;
  Switches[11]:=SW_11;
  Switches[12]:=SW_12;
  Switches[13]:=SW_13;
  Switches[14]:=SW_14;
  Switches[15]:=SW_15;

  SetDefaultParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.SwitchChange(Sender: TObject);
begin
  if not Updating then
  begin
    if (Sender as TECSwitch).Checked then
      OutputValue:=FOutputValue or Mask[(Sender as TECSwitch).Tag]
    else
      OutputValue:=FOutputValue and not Mask[(Sender as TECSwitch).Tag];
  end;
end;

procedure TVxForm.btnForceONClick(Sender: TObject);
begin
  OutputValue:=$FFFF;
end;

procedure TVxForm.btnOKButtonClick(Sender: TObject);
begin
  OutputValue:=TempValue;
end;

procedure TVxForm.DisplayModeChange(Sender: TObject);
Var
  index : integer;
begin
  if not Updating then
  begin
    index := (Sender as TComponent).Tag;
    case index of
      0 : DisplayMode:=dmHex;
      1 : DisplayMode:=dmDec;
      2 : DisplayMode:=dmSigned;
    end;
  end;
end;

procedure TVxForm.KeyPressed(Sender: TObject);
begin
  TempValue:=(TempValue SHL 4) + (Sender as TComponent).Tag;
  TempDisplay.Caption:=IntToHex(TempValue, 4);
end;

procedure TVxForm.btnForceOFFClick(Sender: TObject);
begin
  OutputValue:=$0000;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value  : word;
begin
  if Params.Input_Ena then
  begin
    Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}Value);
    if Regs[1].Status = _rsOK then
      InputValue:=Value;
    SetLedStatus(LedCom[1], Regs[1].Status);
  end;

  if Params.Output_Ena then
  begin
    Regs[2].Status:=CommRegisterStatus(_rkWrite, Regs[2].Index);
    SetLedStatus(LedCom[2], Regs[2].Status);
  end;
end;

procedure TVxForm.EnergyZero;
begin
  OutputValue:=0;
end;

procedure TVxForm.SetDefaultParams;
begin
  Params.Input_Reg :=1;
  Params.Output_Reg:=2;
  Params.Input_Ena:=true;
  Params.Output_Ena:=true;
  Params.FastWrite:=true;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  if Params.Input_Ena then
  begin
    btn_H.Enabled:=true;
    btn_D.Enabled:=true;
    btn_S.Enabled:=true;
    InputDisplay.Caption:='  0000';
    lblNameDI.Hint:='Read Reg : '+IntToStr(Params.Input_Reg);
  end
  else begin
    btn_H.Enabled:=false;
    btn_D.Enabled:=false;
    btn_S.Enabled:=false;
    InputDisplay.Caption:='------';
    lblNameDI.Hint:='Read Reg : Disabled';
    SetLedStatus(LedCom[1], 0);
    for c:=0 to 15 do
      Leds[c].Color:=LedColor[false];
    InputBar.Value:=0;
  end;

  if Params.Output_Ena then
  begin
    PnlOutput.Enabled:=true;
    OutputDisplay.Caption:='0000';
    TempDisplay.Caption:='0000';
    lblNameDO.Hint:='Write Reg : '+IntToStr(Params.Output_Reg);
  end
  else begin
    PnlOutput.Enabled:=false;
    lblNameDO.Hint:='Write Reg : Disabled';
    SetLedStatus(LedCom[2], 0);
    Updating:=true;
    for c:=0 to 15 do
      Switches[c].Checked:=false;
    Updating:=false;
    OutputDisplay.Caption:='----';
    TempDisplay.Caption:='----';
    OutputBar.Value:=0;
  end;
end;

procedure TVxForm.SetFDisplayMode(AValue: TDisplayMode);
Var
  OldInputValue : word;
begin
  if FDisplayMode<>AValue then
  begin
    FDisplayMode:=AValue;
    OldInputValue:=FinputValue;
    inc(FInputValue);     // To force
    InputValue:=OldInputValue;
    Updating:=true;
    case FDisplayMode of
      dmHex : begin
        btn_H.Down:=true;
        btn_D.Down:=false;
        btn_S.Down:=false;
      end;
      dmDec : begin
        btn_H.Down:=false;
        btn_D.Down:=true;
        btn_S.Down:=false;
      end;
      dmSigned : begin
        btn_H.Down:=false;
        btn_D.Down:=false;
        btn_S.Down:=true;
      end;
    end;
    Updating:=false;
  end;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.SetFInputValue(AValue: word);
Var
  c  : integer;
  Si : smallint absolute AValue;
begin
  if FInputValue<>AValue then
  begin
    FInputValue:=AValue;
    for c:=0 to 15 do
      Leds[c].Color:=LedColor[(FInputValue and Mask[c])<>0];
      case FDisplayMode of
        dmHex : begin
          InputDisplay.Caption:=RightJustify(IntToHex(FInputValue,4),6);
        end;
        dmDec : begin
          InputDisplay.Caption:=RightJustify(IntToStr(FInputValue), 6);
        end;
        dmSigned : begin
          Si:=FInputValue;
          InputDisplay.Caption:=StrIntValue(si, 5);
        end;
      end;
    InputBar.Value:=FInputValue;
  end;
end;

procedure TVxForm.SetFOutputValue(AValue: word);
Var
  c : integer;
begin
  if Params.Output_Ena then
  begin
    if FOutputValue<>AValue then
    begin
      FOutputValue:=AValue;
      OutputDisplay.Caption:=IntToHex(FOutputValue,4);
      OutputBar.Value:=FOutputValue;
      Updating:=true;
      for c:=0 to 15 do
        Switches[c].Checked:=(FOutputValue and Mask[c])<>0;
      Updating:=false;

      if FRunning then
      begin
        if Params.FastWrite then
        begin
          Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index,FOutputValue);
          SetLedStatus(LedCom[2],Regs[2].Status);
        end
        else
          CommRegisterWrite(Regs[2].Index,FOutputValue);
      end;
    end;
  end;
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  FRunning:=true;
  if Params.Output_Ena then
  begin
    Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index,FOutputValue);
    SetLedStatus(LedCom[2],Regs[2].Status);
  end
  else
    SetLedStatus(LedCom[2],0);
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
  if Params.Input_Ena then
    Regs[1].Index:=CommReadRegisterAdd(Params.Input_Reg);
  if Params.Output_Ena then
    Regs[2].Index:=CommWriteRegisterAdd(Params.Output_Reg,Integer(Params.FastWrite),0);
  EnergyZero;
end;

function TVxForm.Edit: boolean;
begin
 Result:=EditParams(FIndex, Params);
 if Result then
 begin
   ApplyParams;
   EnergyZero;
 end;
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
      Params.Input_Ena:=ini.ReadBool(Section,'Input_Ena',Params.Input_Ena);
      Params.Output_Reg:=ini.ReadInteger(Section,'Output_Reg',Params.Output_Reg);
      Params.Output_Ena:=ini.ReadBool(Section,'Output_Ena',Params.Output_Ena);
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
    ini.WriteBool(Section,'Input_Ena',Params.Input_Ena);
    ini.WriteInteger(Section,'Output_Reg',Params.Output_Reg);
    ini.WriteBool(Section,'Output_Ena',Params.Output_Ena);
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


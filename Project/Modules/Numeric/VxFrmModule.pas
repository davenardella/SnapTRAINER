unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Classes, Math, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ueled, BCPanel, BCButton, LedNumber, VxTypes, IniFiles, VxUtils;

type

  TNumberMode = (nmHex, nmDec, nmFloat);

  TNumberParams = record
    Name : string;
    Mode : TNumberMode;
    Decimals : integer;
    Reg_HI  : integer;
    Reg_LO  : integer;
    Enabled : boolean;
  end;

  TNumericParams = record
    CH : array[1..3] of TNumberParams;
  end;


  { TNumber }

  TNumber = class
  private
    FActive  : boolean;
    FColor   : TColor;
    FMode    : TNumberMode;
    Updating : boolean;
    FValue   : longWord;
    FOnModeClick: TNotifyEvent;
    procedure SetFActive(AValue: boolean);
    procedure SetFValue(AValue: LongWord);
    function ToFloat : string;
    function ToHex : string;
    function ToDec : string;
    procedure SetButtons;
    procedure SetFMode(AValue: TNumberMode);
    procedure BtnModeClicked(Sender: TObject);
  protected
    procedure PrintValue;
  public
    Display  : TLEDNumber;
    Name     : TLabel;
    BtnMode  : array[1..3] of TBCButton;
    Decimals : integer;
    constructor Create(Color : TColor);
    procedure Setup;
    property Mode : TNumberMode read FMode write SetFMode;
    property Value : LongWord read FValue write SetFValue;
    property Active : boolean read FActive write SetFActive;
    property OnModeClick : TNotifyEvent read FOnModeClick write FOnModeClick;
  end;

  { TVxForm }

  TVxForm = class(TForm)
    BtnMode_1_1: TBCButton;
    EditBtn: TBCButton;
    BtnMode_3_1: TBCButton;
    BtnMode_3_2: TBCButton;
    BtnMode_3_3: TBCButton;
    BtnMode_1_2: TBCButton;
    BtnMode_1_3: TBCButton;
    BtnMode_2_1: TBCButton;
    BtnMode_2_2: TBCButton;
    BtnMode_2_3: TBCButton;
    EditValue: TEdit;
    LedCom_3: TuELED;
    LedCom_4: TuELED;
    LedCom_5: TuELED;
    LedCom_6: TuELED;
    Name_1: TLabel;
    Name_3: TLabel;
    Name_2: TLabel;
    lblName: TLabel;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    Display_1: TLEDNumber;
    Display_3: TLEDNumber;
    Display_2: TLEDNumber;
    pnlDisplay: TBCPanel;
    Timer: TTimer;
    procedure EditBtnClick(Sender: TObject);
    procedure EditValueExit(Sender: TObject);
    procedure EditValueKeyPress(Sender: TObject; var Key: char);
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
    LedCom                : array[1..6] of TuELED;
    // Specific
    Numbers               : array[1..3] of TNumber;
    Params                : TNumericParams;
    Regs                  : array[1..6] of TRegisterModule;
    procedure OutputModeChanged(Sender : TObject);
    function GetEditMode: TNumberMode;
    function GetHexValue(index : integer): longword;
    procedure SetFIndex(AValue: integer);
    procedure SetHexValue(index : integer; AValue: longword);
    procedure SendValue(AValue : longword);
    procedure SetDefaultParams;
    procedure ApplyParams;
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
    property HexValue[index : integer] : longword read GetHexValue write SetHexValue;
    property EditMode : TNumberMode read GetEditMode;
  end;

var
  VxForm: TVxForm;

implementation
Uses
  VxFrmSettings;

const
  HexChars : set of char = ['0'..'9','A'..'F'];
  DecChars : set of char = ['0'..'9','-'];
  FloChars : set of char = ['0'..'9','-','.'];

  DisabledColor = clSilver;

{$R *.lfm}

{ TNumber }

function TNumber.ToFloat: string;
Var
  HV : longWord;
  FV : single absolute HV;
  Sign : boolean;
  MaxChars : integer;
begin
  HV:=FValue;
  if not IsNan(FV) then
  begin
    Str(FV:0:Decimals,Result);
    if FV<0 then
    begin
      Sign:=true;
      Result[1]:=' ';
    end
    else
      Sign:=false;

    if Pos('.',Result)>0 then
      MaxChars:=Display.Columns+1
    else
      MaxChars:=Display.Columns;

    while Length(Result)<MaxChars do
      Result:=' '+Result;
    if Sign then
      Result[1]:='-';
  end
  else
    Result:='NAN';
end;

procedure TNumber.SetFValue(AValue: LongWord);
begin
  if FActive and (FValue<>AValue) then
  begin
    FValue:=AValue;
    PrintValue;
  end;
end;

procedure TNumber.SetFActive(AValue: boolean);
Var
  c : integer;
begin
  if FActive<>AValue then
  begin
    FActive:=AValue;
    if FActive then
    begin
      Display.OnColor:=FColor;
      Name.Font.Color:=FColor;
      for c:=1 to 3 do
        BtnMode[c].Enabled:=true;
      SetButtons;
    end
    else begin
      Display.OnColor:=DisabledColor;
      Name.Font.Color:=DisabledColor;
      Name.Caption:='DISABLED';
      for c:=1 to 3 do
      begin
        BtnMode[c].Enabled:=false;
        BtnMode[c].Down:=false;
      end;
    end;
    PrintValue;
  end;
end;

procedure TNumber.PrintValue;
begin
  if FActive then
  begin
    case FMode of
      nmHex : Display.Caption:=ToHex;
      nmDec : Display.Caption:=ToDec;
      nmFloat : Display.Caption:=ToFloat;
    end;
  end
  else
    Display.Caption:='-';
end;

function TNumber.ToHex: string;
begin
  Result:='    '+IntToHex(FValue,8);
end;

function TNumber.ToDec: string;
Var
  HV : longWord;
  IV : longint absolute HV;
  Sign : boolean;
begin
  HV:=FValue;
  Result:=IntToStr(IV);
  if IV<0 then
  begin
    Sign:=true;
    Result[1]:=' ';
  end
  else
    Sign:=false;
  while Length(Result)<Display.Columns do
    Result:=' '+Result;
  if Sign then
    Result[1]:='-';
end;

procedure TNumber.SetButtons;
begin
  Updating:=true;
  case FMode of
    nmHex : begin
      BtnMode[1].Down:=true;
      BtnMode[2].Down:=false;
      BtnMode[3].Down:=false;
    end;
    nmDec : begin
      BtnMode[1].Down:=false;
      BtnMode[2].Down:=true;
      BtnMode[3].Down:=false;
    end;
    nmFloat : begin
      BtnMode[1].Down:=false;
      BtnMode[2].Down:=false;
      BtnMode[3].Down:=true;
    end;
  end;
  Updating:=false;
end;

procedure TNumber.SetFMode(AValue: TNumberMode);
begin
  if FMode<>AValue then
  begin
    FMode:=AValue;
    SetButtons;
    PrintValue;
  end;
end;

procedure TNumber.BtnModeClicked(Sender: TObject);
begin
  Mode:=TNumberMode((Sender as TComponent).Tag);
  if Assigned(FOnModeClick) then
    FOnModeClick(Self);
end;

constructor TNumber.Create(Color: TColor);
begin
  FColor :=Color;
  FActive:=true;
  FMode  :=nmHex;
  FValue :=$FFFFFFFF;
  FOnModeClick:=nil;
end;

procedure TNumber.Setup;
Var
  c : integer;
begin
  BtnMode[1].Down:=true;
  BtnMode[2].Down:= false;
  BtnMode[3].Down:= false;
  for c:=1 to 3 do
  begin
    BtnMode[c].Tag:=c-1;
    BtnMode[c].OnClick:=BtnModeClicked;
  end;
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
Var
  c : integer;
begin
  pnlDisplay.Background.Color:=clBlack;

  Numbers[1]:=TNumber.Create(clAqua);
  Numbers[1].Display :=Display_1;
  Numbers[1].Name    :=Name_1;
  Numbers[1].Decimals:=3;
  Numbers[1].BtnMode[1]:=BtnMode_1_1;
  Numbers[1].BtnMode[2]:=BtnMode_1_2;
  Numbers[1].BtnMode[3]:=BtnMode_1_3;
  Numbers[1].Value   :=0;
  Numbers[1].Mode    :=nmHex;
  Numbers[1].Setup;

  Numbers[2]:=TNumber.Create(clAqua);
  Numbers[2].Display :=Display_2;
  Numbers[2].Name    :=Name_2;
  Numbers[2].Decimals:=3;
  Numbers[2].BtnMode[1]:=BtnMode_2_1;
  Numbers[2].BtnMode[2]:=BtnMode_2_2;
  Numbers[2].BtnMode[3]:=BtnMode_2_3;
  Numbers[2].Value   :=0;
  Numbers[2].Mode    :=nmHex;
  Numbers[2].Setup;

  Numbers[3]:=TNumber.Create($000080FF);
  Numbers[3].Display :=Display_3;
  Numbers[3].Name    :=Name_3;
  Numbers[3].Decimals:=3;
  Numbers[3].BtnMode[1]:=BtnMode_3_1;
  Numbers[3].BtnMode[2]:=BtnMode_3_2;
  Numbers[3].BtnMode[3]:=BtnMode_3_3;
  Numbers[3].Value   :=0;
  Numbers[3].Mode    :=nmHex;
  Numbers[3].OnModeClick:=OutputModeChanged;
  Numbers[3].Setup;

  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  LedCom[3]:=LedCom_3;
  LedCom[4]:=LedCom_4;
  LedCom[5]:=LedCom_5;
  LedCom[6]:=LedCom_6;

  SetDefaultParams;
  ApplyParams;

  for c:=1 to 6 do
    SetLedStatus(LedCom[c], _rsUnknown);
end;

procedure TVxForm.FormDestroy(Sender: TObject);
Var
  c : integer;
begin
  for c:=1 to 3 do
    Numbers[c].Free;
end;

procedure TVxForm.TimerTimer(Sender: TObject);
Type
  TWValue = packed record
    LO_Value : word;
    HI_Value : word;
  end;

Var
  C        : integer;
  WValue   : TWValue;
  LValue   : longword absolute WValue;
begin
  if Params.CH[1].Enabled then
  begin
    Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}WValue.LO_Value);
    Regs[2].Status:=CommRegisterRead(Regs[2].Index, {%H-}WValue.HI_Value);
    if (Regs[1].Status =_rsOK) and (Regs[2].Status =_rsOK) then
      HexValue[1]:=LValue;
    SetLedStatus(LedCom[1], Regs[1].Status);
    SetLedStatus(LedCom[2], Regs[2].Status);
  end;

  if Params.CH[2].Enabled then
  begin
    Regs[3].Status:=CommRegisterRead(Regs[3].Index, {%H-}WValue.LO_Value);
    Regs[4].Status:=CommRegisterRead(Regs[4].Index, {%H-}WValue.HI_Value);
    if (Regs[3].Status =_rsOK) and (Regs[4].Status =_rsOK) then
      HexValue[2]:=LValue;
    SetLedStatus(LedCom[3], Regs[3].Status);
    SetLedStatus(LedCom[4], Regs[4].Status);
  end;

  if Params.CH[3].Enabled then
  begin
    Regs[5].Status:=CommRegisterStatus(_rkWrite, Regs[5].Index);
    Regs[6].Status:=CommRegisterStatus(_rkWrite, Regs[6].Index);
    SetLedStatus(LedCom[5], Regs[5].Status);
    SetLedStatus(LedCom[6], Regs[6].Status);
  end;

  for C:=1 to 6 do
    SetLedStatus(LedCom[C], Regs[C].Status);
end;

procedure TVxForm.OutputModeChanged(Sender: TObject);
begin
  EditValue.Visible:=false;
end;

function TVxForm.GetEditMode: TNumberMode;
begin
  Result:=Numbers[3].Mode;
end;

procedure TVxForm.EditValueKeyPress(Sender: TObject; var Key: char);
Var
  S : string;
  c : integer;
  Error  : boolean;
  WValue : longword;
  IValue : integer absolute WValue;
  FValue : single absolute WValue;
begin
  Key:=UpCase(Key);
  if Key=#8 then
    exit;

  if Key=#27 then
  begin
    EditValue.Visible:=false;
    exit;
  end;

  S:=EditValue.Text;;

  if Key<>#13 then
  begin
    case EditMode of
      nmHex : begin
        if not (Key in HexChars) or (Length(S)>8) then
          key:=#0;
      end;
      nmDec : begin
        if not (Key in DecChars) then
          Key:=#0;

        if Key='-' then
        begin
          if Pos('-',S)>0 then
            Key:=#0;
        end;

        if Key='-' then
        begin
          if EditValue.SelStart>0 then
          Key:=#0;
        end;
      end;
      nmFloat : begin
        if not (Key in FloChars) then
          Key:=#0;

        if Key='-' then
        begin
          if Pos('-',S)>0 then
            Key:=#0;
        end;

        if Key='-' then
        begin
          if EditValue.SelStart>0 then
          Key:=#0;
        end;

        if Key='.' then
        begin
          if Pos('.',S)>0 then
            Key:=#0;
        end;

      end;
    end;
  end
  else begin
    Error:=false;
    case EditMode of
      nmHex : begin
        S:='$'+S;
        Val(S,WValue,C);
        Error:=C>0;
      end;
      nmDec : begin
        Val(S,IValue,C);
        Error:=C>0;
      end;
      nmFloat : begin
        Val(S,FValue,C);
        Error:=C>0;
      end;
    end;
    if not Error then
    begin
      HexValue[3]:=WValue{%H-};
      SendValue(WValue);
    end;

    EditValue.Visible:=false;
  end;
end;

procedure TVxForm.EditBtnClick(Sender: TObject);
Var
  S : string;
  WValue : longword;
  IValue : integer absolute WValue;
  FValue : single absolute WValue;
begin
  if not EditValue.Visible then
  begin
    WValue:=HexValue[3];
    case EditMode of
      nmHex : begin
        EditValue.Caption:=IntToHex(WValue,8);
      end;
      nmDec : begin
        EditValue.Caption:=IntToStr(IValue);
      end;
      nmFloat : begin
        if not IsNan(FValue) then
        begin
          Str(FValue:0:Numbers[3].Decimals,S);
          EditValue.Caption:=S;
        end
        else
          EditValue.Caption:='';
      end;
    end;
    EditValue.Visible:=true;
    EditValue.SetFocus;
  end;
end;

procedure TVxForm.EditValueExit(Sender: TObject);
begin
  EditValue.Visible:=false;
end;

function TVxForm.GetHexValue(index : integer): longword;
begin
  Result:=Numbers[index].Value;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;


procedure TVxForm.SetHexValue(index : integer; AValue: longword);
begin
  Numbers[index].Value:=AValue;
end;

procedure TVxForm.SendValue(AValue: longword);
Type
  TWValue = packed record
    LO_Value : word;
    HI_Value : word;
  end;
Var
  WValue   : TWValue absolute AValue;
begin
  if FRunning then
  begin
    Regs[5].Status:=CommRegisterFastWrite(Regs[5].Index, WValue.LO_Value);
    Regs[6].Status:=CommRegisterFastWrite(Regs[6].Index, WValue.HI_Value);
    SetLedStatus(LedCom[5],Regs[5].Status);
    SetLedStatus(LedCom[6],Regs[6].Status);
  end;
end;

procedure TVxForm.SetDefaultParams;
Var
  c : integer;
  x : integer;
begin
  x:=1024;
  for c:=1 to 3 do
  begin
    Params.CH[c].Enabled:=true;
    Params.CH[c].Mode:=nmHex;
    Params.CH[c].Decimals:=3;
    Params.CH[c].Reg_LO:=X;
    inc(X);
    Params.CH[c].Reg_HI:=X;
    inc(X);
  end;
  Params.CH[1].Name:='INPUT VALUE 1';
  Params.CH[2].Name:='INPUT VALUE 2';
  Params.CH[3].Name:='OUTPUT VALUE';
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  for c:=1 to 3 do
  begin
    Numbers[c].Decimals:=Params.CH[c].Decimals;
    Numbers[c].Mode:=Params.CH[c].Mode;
    Numbers[c].Active:=Params.CH[c].Enabled;
    if Params.CH[c].Enabled then
      Numbers[c].Name.Caption:=Params.CH[c].Name
    else
      Numbers[c].Name.Caption:='DISABLED';
  end;
  lblName.Hint:=
    'Read Registers'+#13+
    '  CH 1 LO Reg : '+IntToStr(Params.CH[1].Reg_LO)+#13+
    '  CH 1 HI Reg : '+IntToStr(Params.CH[1].Reg_HI)+#13+
    '  CH 2 LO Reg : '+IntToStr(Params.CH[2].Reg_LO)+#13+
    '  CH 2 HI Reg : '+IntToStr(Params.CH[2].Reg_HI)+#13+
    'Write Registers'+#13+
    '  CH 3 LO Reg : '+IntToStr(Params.CH[3].Reg_LO)+#13+
    '  CH 3 HI Reg : '+IntToStr(Params.CH[3].Reg_HI);
end;

procedure TVxForm.Start;
begin
  Timer.Enabled:=true;
  FRunning:=true;
end;

procedure TVxForm.Stop;
Var
  c : integer;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  for c:=1 to 6 do
    SetLedStatus(LedCom[c], _rsUnknown);
end;

procedure TVxForm.PrepareStart;
Var
  c : integer;
begin
  for c:=1 to 6 do
    Regs[c].Status:=_rsUnknown;

  if Params.CH[1].Enabled then
  begin
    Regs[1].Index:=CommReadRegisterAdd(Params.CH[1].Reg_LO);
    Regs[2].Index:=CommReadRegisterAdd(Params.CH[1].Reg_HI);
  end;

  if Params.CH[2].Enabled then
  begin
    Regs[3].Index:=CommReadRegisterAdd(Params.CH[2].Reg_LO);
    Regs[4].Index:=CommReadRegisterAdd(Params.CH[2].Reg_HI);
  end;

  if Params.CH[2].Enabled then
  begin
    Regs[5].Index:=CommWriteRegisterAdd(Params.CH[3].Reg_LO, 1, 0);
    Regs[6].Index:=CommWriteRegisterAdd(Params.CH[3].Reg_HI, 1, 0);
  end;
end;

function TVxForm.Edit: boolean;
Var
  c : integer;
begin
  Result:=EditParams(FIndex, Params);
  if Result then
  begin
    ApplyParams;
    for c:=1 to 3 do
      Numbers[c].PrintValue;
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
      Params.CH[1].Name:=ini.ReadString(Section,'CH1.Name',Params.CH[1].Name);
      Params.CH[1].Mode:=TNumberMode(ini.ReadInteger(Section,'CH1.Mode',Ord(Params.CH[1].Mode)));
      Params.CH[1].Decimals:=ini.ReadInteger(Section,'CH1.Decimals',Params.CH[1].Decimals);
      Params.CH[1].Reg_LO:=ini.ReadInteger(Section,'CH1.Reg_LO',Params.CH[1].Reg_LO);
      Params.CH[1].Reg_HI:=ini.ReadInteger(Section,'CH1.Reg_HI',Params.CH[1].Reg_HI);
      Params.CH[1].Enabled:=ini.ReadBool(Section,'CH1.Enabled',Params.CH[1].Enabled);

      Params.CH[2].Name:=ini.ReadString(Section,'CH2.Name',Params.CH[2].Name);
      Params.CH[2].Mode:=TNumberMode(ini.ReadInteger(Section,'CH2.Mode',Ord(Params.CH[2].Mode)));
      Params.CH[2].Decimals:=ini.ReadInteger(Section,'CH2.Decimals',Params.CH[2].Decimals);
      Params.CH[2].Reg_LO:=ini.ReadInteger(Section,'CH2.Reg_LO',Params.CH[2].Reg_LO);
      Params.CH[2].Reg_HI:=ini.ReadInteger(Section,'CH2.Reg_HI',Params.CH[2].Reg_HI);
      Params.CH[2].Enabled:=ini.ReadBool(Section,'CH2.Enabled',Params.CH[2].Enabled);

      Params.CH[3].Name:=ini.ReadString(Section,'CH3.Name',Params.CH[3].Name);
      Params.CH[3].Mode:=TNumberMode(ini.ReadInteger(Section,'CH3.Mode',Ord(Params.CH[3].Mode)));
      Params.CH[3].Decimals:=ini.ReadInteger(Section,'CH3.Decimals',Params.CH[3].Decimals);
      Params.CH[3].Reg_LO:=ini.ReadInteger(Section,'CH3.Reg_LO',Params.CH[3].Reg_LO);
      Params.CH[3].Reg_HI:=ini.ReadInteger(Section,'CH3.Reg_HI',Params.CH[3].Reg_HI);
      Params.CH[3].Enabled:=ini.ReadBool(Section,'CH3.Enabled',Params.CH[3].Enabled);
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

    ini.WriteString(Section,'CH1.Name',Params.CH[1].Name);
    ini.WriteInteger(Section,'CH1.Mode',Ord(Params.CH[1].Mode));
    ini.WriteInteger(Section,'CH1.Decimals',Params.CH[1].Decimals);
    ini.WriteInteger(Section,'CH1.Reg_LO',Params.CH[1].Reg_LO);
    ini.WriteInteger(Section,'CH1.Reg_HI',Params.CH[1].Reg_HI);
    ini.WriteBool(Section,'CH1.Enabled',Params.CH[1].Enabled);

    ini.WriteString(Section,'CH2.Name',Params.CH[2].Name);
    ini.WriteInteger(Section,'CH2.Mode',Ord(Params.CH[2].Mode));
    ini.WriteInteger(Section,'CH2.Decimals',Params.CH[2].Decimals);
    ini.WriteInteger(Section,'CH2.Reg_LO',Params.CH[2].Reg_LO);
    ini.WriteInteger(Section,'CH2.Reg_HI',Params.CH[2].Reg_HI);
    ini.WriteBool(Section,'CH2.Enabled',Params.CH[2].Enabled);

    ini.WriteString(Section,'CH3.Name',Params.CH[3].Name);
    ini.WriteInteger(Section,'CH3.Mode',Ord(Params.CH[3].Mode));
    ini.WriteInteger(Section,'CH3.Decimals',Params.CH[3].Decimals);
    ini.WriteInteger(Section,'CH3.Reg_LO',Params.CH[3].Reg_LO);
    ini.WriteInteger(Section,'CH3.Reg_HI',Params.CH[3].Reg_HI);
    ini.WriteBool(Section,'CH3.Enabled',Params.CH[3].Enabled);
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

end.


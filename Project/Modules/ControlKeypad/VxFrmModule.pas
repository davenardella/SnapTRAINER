unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap, BGRACustomDrawn,
  BGRABitmapTypes, VxUtils, ueled, uESelector;

Type

  TLightButtonColor = (llcGreen, llcRed, llcBlue, llcYellow, llcOrange, llcWhite);

Const
  TLightLedColorON_up  : array[TLightButtonColor] of TColor = ($0000FF00, $000000FF, $00FFC800, $0000FFFF, $000080FF, $00FFFFFF);
  TLightLedColorON_dn  : array[TLightButtonColor] of TColor = ($0000B700, $000000B7, $00B98F00, $0000B7B7, $000069D2, $00C0C0C0);

  TLightLedColorOFF_up : array[TLightButtonColor] of TColor = ($00005B00, $0000005B, $00800000, $00008080, $000059B3, $00808080);
  TLightLedColorOFF_dn : array[TLightButtonColor] of TColor = ($00003E00, $0000003E, $00520000, $00004040, $00004F9D, $00404040);

  MushroomColor        : array[boolean] of TColor = (clRed, $000000BF);

  TLedColor            : array[TLightButtonColor] of TColor = (clLime, clRed, clBlue, clYellow, $000080FF, clWhite);
  LedColorOFF          = $001B1B1B;

Type

 TButtonMode = (bmButton, bmSwitch);

 TControlButtonParams = record
   Color   : TLightButtonColor;
   Mode    : TButtonMode;
   Caption : string;
 end;

 TLedParams = record
   Color   : TLightButtonColor;
   Caption : string;
 end;

 TKeypadParams = record
   Input_Reg    : word;
   Output_Reg   : word;
   MushCaption  : string;
   MushroomNC   : boolean;
   ShowSelector : boolean; // if false -> shows LEDs
   SelInit      : integer;
   SelCaption   : array[1..3] of string;
   SelLabel     : string;
   BTN          : array[1..4] of TControlButtonParams;
   LED          : array[1..2] of TLedParams;
 end;

 TButtonChangedEvent = procedure(Sender : TObject; pressed : boolean) of object;

 { TLightButton }

 TLightButton = class(TCustomuELED)
 private
   FButtonMode: TButtonMode;
   FLedColor : TLightButtonColor;
   FLight    : boolean;
   FPressed  : boolean;
   FDown     : boolean;
   FOnButtonChanged: TButtonChangedEvent;
   procedure BtnMouseDown(Sender: TObject; {%H-}Button: TMouseButton;
     {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
   procedure BtnMouseUp(Sender: TObject; {%H-}Button: TMouseButton;
     {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
   procedure SetFLight(AValue: boolean);
   procedure SetFLedColor(AValue: TLightButtonColor);
   procedure SetAspect(Down : boolean);
   procedure SetFPressed(AValue: boolean);
 public
   constructor Create(AOwner : TComponent; AParent: TWinControl; AColor : TLightButtonColor); reintroduce;
   procedure Reset;
   property LedColor : TLightButtonColor read FLedColor write SetFLedColor;
   property Light : boolean read FLight write SetFLight;
   property ButtonMode : TButtonMode read FButtonMode write FButtonMode;
   property Pressed : boolean read FPressed write SetFPressed;
   property OnButtonChanged : TButtonChangedEvent read FOnButtonChanged write FOnButtonChanged;
 end;

 { TMushroom }

 TMushroom = class(TBCButton)
 private
   FNormallyClosed: boolean;
   FOnButtonChanged: TButtonChangedEvent;
   procedure BtnMouseDown(Sender: TObject; {%H-}Button: TMouseButton;
     {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
   procedure BtnMouseUp(Sender: TObject; {%H-}Button: TMouseButton;
     {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
 public
   constructor Create(AOwner : TComponent; AParent: TWinControl; AWidth : integer); reintroduce;
   property OnButtonChanged : TButtonChangedEvent read FOnButtonChanged write FOnButtonChanged;
   property NormallyClosed : boolean read FNormallyClosed write FNormallyClosed;
 end;

  { TVxForm }

  TVxForm = class(TForm)
    Led_1: TuELED;
    Led_2: TuELED;
    MushLabel: TLabel;
    SelLabel: TLabel;
    pnlCtrl: TBCPanel;
    lblName: TLabel;
    pnlYellow: TBCPanel;
    Lbl_Led_1: TLabel;
    Lbl_Led_2: TLabel;
    Timer: TTimer;
    LedCom_1: TuELED;
    LedCom_2: TuELED;
    Selector: TuESelector;
    procedure FormCreate(Sender: TObject);
    procedure SelChanged(Sender: TObject);
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
    Buttons               : array[1..4] of TLightButton;
    lblButton             : array[1..4] of TLabel;
    Mushroom              : TMushroom;
    Params                : TKeypadParams;
    WValue                : word;
    Updating              : boolean;
    Blink                 : boolean;
    LastTick              : QWord;
    procedure ButtonChanged(Sender : TObject; pressed : boolean);
    procedure SetDefaultParams;
    procedure ApplyParams;
    procedure SetFIndex(AValue: integer);
    procedure CreateControlPanel;
    procedure CreateButtons;
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

var
  VxForm: TVxForm;

{ TLightButton }

procedure TLightButton.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Pressed:=true;
  if FButtonMode = bmSwitch then
    FDown:=not FDown
  else
    FDown:=false;
  SetAspect(true);
end;

procedure TLightButton.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FButtonMode = bmButton then
    Pressed:=false
  else
    Pressed:=FDown;
  SetAspect(FPressed);
end;

procedure TLightButton.SetFLight(AValue: boolean);
begin
  if FLight<>AValue then
  begin
    FLight:=AValue;
    SetAspect(FPressed);
  end;
end;

procedure TLightButton.SetFLedColor(AValue: TLightButtonColor);
begin
  if FLedColor<>AValue then
  begin
    FLedColor:=AValue;
    SetAspect(FPressed);
  end;
end;

procedure TLightButton.SetAspect(Down: boolean);
begin
  Bright:=FLight;
  if FLight then
  begin
    if Down then
      Self.Color:=TLightLedColorON_dn[FLedColor]
    else
      Self.Color:=TLightLedColorON_up[FLedColor];
  end
  else begin
    if Down then
      Self.Color:=TLightLedColorOFF_dn[FLedColor]
    else
      Self.Color:=TLightLedColorOFF_up[FLedColor]
  end;
end;

procedure TLightButton.SetFPressed(AValue: boolean);
begin
  if FPressed <> AValue then
  begin
    FPressed:=AValue;
    if Assigned(FOnButtonChanged) then
      FOnButtonChanged(Self, FPressed);
  end;
end;

constructor TLightButton.Create(AOwner: TComponent; AParent: TWinControl;
  AColor: TLightButtonColor);
begin
  inherited Create(AOwner);
  LedType:=ledSquare;
  Cursor:=crHandPoint;
  Reflection:=true;
  FLight:=false;
  FLedColor:=AColor;
  FButtonMode:=bmButton;
  FPressed:=false;
  FDown   :=false;
  SetAspect(False);
  Parent:=AParent;
  Self.OnMouseDown:=BtnMouseDown;
  Self.OnMouseUp:=BtnMouseUp;
end;

procedure TLightButton.Reset;
begin
  FDown:=false;
  FPressed:=false;
  SetAspect(false);
end;

{ TMushroom }

procedure TMushroom.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FOnButtonChanged) then
    FOnButtonChanged(Self, true xor FNormallyClosed);
end;

procedure TMushroom.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FOnButtonChanged) then
    FOnButtonChanged(Self, false xor FNormallyClosed);
end;

constructor TMushroom.Create(AOwner: TComponent; AParent: TWinControl;
  AWidth: integer);
begin
  inherited Create(AOwner);
  Width:=AWidth;
  Height:=AWidth;
  Rounding.RoundX:=AWidth div 2;
  Rounding.RoundY:=AWidth div 2;
  Cursor:=crHandPoint;
  with StateNormal do
  begin
    BackGround.Gradient1EndPercent:=50;
    BackGround.Gradient1.ColorCorrection:=false;
    BackGround.Gradient1.GradientType:=gtRadial;
    BackGround.Gradient1.EndColor:=clBlack;
    BackGround.Gradient1.StartColor:=MushroomColor[false];
    BackGround.Gradient1.Point1XPercent:=50;
    BackGround.Gradient1.Point1YPercent:=100;
    BackGround.Gradient1.Point2XPercent:=0;
    BackGround.Gradient1.Point2YPercent:=0;
    BackGround.Gradient2.ColorCorrection:=false;
    BackGround.Gradient2.GradientType:=gtRadial;
    BackGround.Gradient2.EndColor:=clBlack;
    BackGround.Gradient2.StartColor:=MushroomColor[false];
    BackGround.Gradient2.Point1XPercent:=50;
    BackGround.Gradient2.Point1YPercent:=0;
    BackGround.Gradient2.Point2XPercent:=0;
    BackGround.Gradient2.Point2YPercent:=100;
  end;

  with StateClicked do
  begin
    BackGround.Gradient1EndPercent:=50;
    BackGround.Style:=bbsGradient;
    BackGround.Gradient1.ColorCorrection:=false;
    BackGround.Gradient1.GradientType:=gtRadial;
    BackGround.Gradient1.EndColor:=clBlack;
    BackGround.Gradient1.StartColor:=MushroomColor[true];
    BackGround.Gradient1.Point1XPercent:=50;
    BackGround.Gradient1.Point1YPercent:=100;
    BackGround.Gradient1.Point2XPercent:=0;
    BackGround.Gradient1.Point2YPercent:=0;
    BackGround.Gradient2.ColorCorrection:=false;
    BackGround.Gradient2.GradientType:=gtRadial;
    BackGround.Gradient2.EndColor:=clBlack;
    BackGround.Gradient2.StartColor:=MushroomColor[true];
    BackGround.Gradient2.Point1XPercent:=50;
    BackGround.Gradient2.Point1YPercent:=0;
    BackGround.Gradient2.Point2XPercent:=0;
    BackGround.Gradient2.Point2YPercent:=100;
    Border.Style:=bboNone;
    FontEx.Shadow:=false;
  end;

  StateHover.Assign(StateNormal);
  Self.OnMouseDown:=BtnMouseDown;
  Self.OnMouseUp:=BtnMouseUp;
  Self.Parent:=AParent;
end;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  pnlCtrl.Background.Color:=$00373737;
  pnlYellow.Color:=$00373737;
  pnlYellow.Background.Color:=clYellow;
  LedCom[1]:=LedCom_1;
  LedCom[2]:=LedCom_2;
  Led_1.Color:=LedColorOFF;
  Led_2.Color:=LedColorOFF;
  CreateControlPanel;
  CreateButtons;
  SetDefaultParams;
  ApplyParams;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.SelChanged(Sender: TObject);
begin
  WValue:=WValue and $FF9F; // Reset Selector bits
  WValue:=WValue or ((Selector.Index+1) shl 5);
  Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index, WValue);
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value   : word;
  Time_ms : QWord;
  c       : integer;
  XI      : TWordBits;
begin
  Time_ms:=GetTickCount64;
  if Time_ms-LastTick > 400 then
  begin
    LastTick:=Time_ms;
    Blink:=not Blink;
  end;

  Regs[1].Status:=CommRegisterRead(Regs[1].Index, {%H-}Value);
  if Regs[1].Status <> _rsOK then
    Value:=0;

  XI:=WordToBits(Value);
  for c:=0 to 3 do
  begin
    if XI[c+4] then
      Buttons[c+1].Light:=XI[c] and not Blink
    else
      Buttons[c+1].Light:=XI[c];
  end;

  if XI[8] then
  begin
    if XI[10] then
    begin
      if Blink then
        Led_1.Color:=TLedColor[Params.LED[1].Color]
      else
        Led_1.Color:=LedColorOFF;
    end
    else
      Led_1.Color:=TLedColor[Params.LED[1].Color]
  end
  else
    Led_1.Color:=LedColorOFF;

  if XI[9] then
  begin
    if XI[11] then
    begin
      if Blink then
        Led_2.Color:=TLedColor[Params.LED[2].Color]
      else
        Led_2.Color:=LedColorOFF;
    end
    else
      Led_2.Color:=TLedColor[Params.LED[2].Color]
  end
  else
    Led_2.Color:=LedColorOFF;

  SetLedStatus(LedCom[1], Regs[1].Status);

  Regs[2].Status:=CommRegisterStatus(_rkWrite,Regs[2].Index);
  SetLedStatus(LedCom[2], Regs[2].Status);
end;

procedure TVxForm.ButtonChanged(Sender: TObject; pressed: boolean);
Var
  mask : word;
begin
  mask :=(Sender as TComponent).tag;
  if pressed then
    WValue:=WValue or mask
  else
    WValue:=WValue and not mask;

  if FRunning then
    Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index, WValue);
end;

procedure TVxForm.SetDefaultParams;
begin
  with Params do
  begin
    Input_Reg    :=7;
    Output_Reg   :=8;
    MushCaption  :='EMERGENCY';
    MushroomNC   :=true;
    ShowSelector :=true;
    SelInit      := 2;
    SelCaption[1]:='SETUP';
    SelCaption[2]:='MAN';
    SelCaption[3]:='AUTO';
    SelLabel     :='MODE';
    BTN[1].Caption:='START';
    BTN[1].Color:=llcGreen;
    BTN[1].Mode:=bmButton;
    BTN[2].Caption:='STOP';
    BTN[2].Color:=llcRed;
    BTN[2].Mode:=bmButton;
    BTN[3].Caption:='RESET';
    BTN[3].Color:=llcYellow;
    BTN[3].Mode:=bmButton;
    BTN[4].Caption:='POWER';
    BTN[4].Color:=llcWhite;
    BTN[4].Mode:=bmButton;
    LED[1].Color:=llcGreen;
    LED[1].Caption:='PASS';
    LED[2].Color:=llcRed;
    LED[2].Caption:='FAIL';
  end;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  MushLabel.Caption:=Params.MushCaption;
  Mushroom.NormallyClosed:=Params.MushroomNC;
  Updating := true;

  SelLabel.Caption:=Params.SelLabel;
  Selector.Index:=Params.SelInit-1;

  for c:=1 to 3 do
    Selector.Items[c-1]:=Params.SelCaption[c];
  Selector.ShowValues:=false;
  Selector.ShowValues:=true;

  for c:=1 to 4 do
  begin
    Buttons[c].LedColor:=Params.BTN[c].Color;
    Buttons[c].ButtonMode:=Params.BTN[c].Mode;
    lblButton[c].Caption:=Params.BTN[c].Caption;
  end;

  Led_1.Color:=LedColorOFF;
  Lbl_Led_1.Caption:=Params.LED[1].Caption;
  Led_2.Color:=LedColorOFF;
  Lbl_Led_2.Caption:=Params.LED[2].Caption;

  if Params.ShowSelector then
  begin
    Selector.Visible:=true;
    SelLabel.Visible:=true;
    Led_1.Visible:=false;
    Led_2.Visible:=false;
    Lbl_Led_1.Visible:=false;
    Lbl_Led_2.Visible:=false;
  end
  else begin
    Selector.Visible:=false;
    SelLabel.Visible:=false;
    Led_1.Visible:=true;
    Led_2.Visible:=true;
    Lbl_Led_1.Visible:=true;
    Lbl_Led_2.Visible:=true;
  end;

  lblName.Hint:='Read  Reg : '+IntToStr(Params.Input_Reg)+#13+
                'Write Reg : '+IntToStr(Params.Output_Reg);

  Updating := false;
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.CreateControlPanel;
begin
  Mushroom:=TMushroom.Create(Self, pnlYellow, 120);
  Mushroom.Left:=16;
  Mushroom.Top:=56;
  MushRoom.Tag:=$10; // 5Th bit
  MushRoom.OnButtonChanged:=ButtonChanged;
end;

procedure TVxForm.CreateButtons;
Var
  c, X, idx : integer;
begin
  X:=6;
  idx:=1;
  for c:=1 to 4 do
  begin
    Buttons[c]:=TLightButton.Create(Self, Self,Params.BTN[c].Color);
    Buttons[c].SetBounds(X,258,117,54);
    Buttons[c].Tag:=idx;
    Buttons[c].ButtonMode:=Params.BTN[c].Mode;
    Buttons[c].OnButtonChanged:=ButtonChanged;
    idx := idx shl 1;

    lblButton[c]:=TLabel.Create(Self);
    lblButton[c].AutoSize:=false;
    lblButton[c].Alignment:=taCenter;
    lblButton[c].Font.Name:='Segoe UI';
    lblButton[c].Font.Color:=$00F5F5F5;
    lblButton[c].Font.Size:=12;
    lblButton[c].Font.Quality:=fqCleartypeNatural;
    lblButton[c].Font.Style:=[fsBold];
    lblButton[c].SetBounds(X,234,117,21);
    lblButton[c].Parent:=Self;

    X:=X+116;
  end;
end;

procedure TVxForm.Start;
begin
  LastTick:=GetTickCount64;
  Timer.Enabled:=true;
  FRunning:=true;

  WValue:=(Selector.Index+1) shl 5;
  if Params.MushroomNC then
    WValue:=WValue or $0010;
  Regs[2].Status:=CommRegisterFastWrite(Regs[2].Index, WValue);
end;

procedure TVxForm.Stop;
Var
  c : integer;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  for c:=1 to 4 do
  begin
    Buttons[c].Light:=false;
    Buttons[c].Reset;
  end;
  SetLedStatus(LedCom[1], 0);
  SetLedStatus(LedCom[2], 0);
end;

procedure TVxForm.PrepareStart;
Var
  c : integer;
begin
  WValue:=Params.SelInit shl 5;
  if Params.MushroomNC then
    WValue:=WValue or $0010;
  Regs[1].Index:=CommReadRegisterAdd(Params.Input_Reg);
  Regs[2].Index:=CommWriteRegisterAdd(Params.Output_Reg,1,WValue);
  for c:=1 to 4 do
  begin
    Buttons[c].Light:=false;
    Buttons[c].Reset;
  end;
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
      Params.MushCaption:=ini.ReadString(Section,'MushCaption',Params.MushCaption);
      Params.MushroomNC:=ini.ReadBool(Section, 'MushroomNC', Params.MushroomNC);
      Params.SelInit:=ini.ReadInteger(Section,'SelInit',Params.SelInit);
      Params.SelLabel:=ini.ReadString(Section,'SelLabel',Params.SelLabel);
      for c:=1 to 3 do
        Params.SelCaption[c]:=ini.ReadString(Section,'SelCaption.'+inttostr(c),Params.SelCaption[c]);
      for c:=1 to 4 do
      begin
        Params.BTN[C].Color:=TLightButtonColor(ini.ReadInteger(Section,'BtnColor.'+IntToStr(c),ord(Params.BTN[C].Color)));
        Params.BTN[C].Mode:=TButtonMode(ini.ReadInteger(Section,'BtnMode.'+IntToStr(c),ord(Params.BTN[C].Mode)));
        Params.BTN[C].Caption:=ini.ReadString(Section,'BtnCaption.'+IntToStr(c),Params.BTN[C].Caption);
      end;
      for c:=1 to 2 do
      begin
        Params.LED[C].Color:=TLightButtonColor(ini.ReadInteger(Section,'LedColor.'+IntToStr(c),ord(Params.LED[C].Color)));
        Params.LED[C].Caption:=ini.ReadString(Section,'LedCaption.'+IntToStr(c),Params.LED[C].Caption);
      end;
      Params.ShowSelector:=ini.ReadBool(Section,'ShowSelector',Params.ShowSelector);
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
    ini.WriteString(Section,'MushCaption',Params.MushCaption);
    ini.WriteBool(Section, 'MushroomNC', Params.MushroomNC);
    ini.WriteInteger(Section,'SelInit',Params.SelInit);
    ini.WriteString(Section,'SelLabel',Params.SelLabel);
    for c:=1 to 3 do
      ini.WriteString(Section,'SelCaption.'+inttostr(c),Params.SelCaption[c]);
    for c:=1 to 4 do
    begin
      ini.WriteInteger(Section,'BtnColor.'+IntToStr(c),ord(Params.BTN[C].Color));
      ini.WriteInteger(Section,'BtnMode.'+IntToStr(c),ord(Params.BTN[C].Mode));
      ini.WriteString(Section,'BtnCaption.'+IntToStr(c),Params.BTN[C].Caption);
    end;
    for c:=1 to 2 do
    begin
      ini.WriteInteger(Section,'LedColor.'+IntToStr(c),ord(Params.LED[C].Color));
      ini.WriteString(Section,'LedCaption.'+IntToStr(c),Params.LED[C].Caption);
    end;
    ini.WriteBool(Section,'ShowSelector',Params.ShowSelector);

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


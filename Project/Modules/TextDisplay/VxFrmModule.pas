unit VxFrmModule;

{$MODE DELPHI}

interface

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Spin, VxTypes, IniFiles, BCPanel, BCTypes, BCButton, BGRABitmap,
  BGRACustomDrawn, BGRABitmapTypes, VxUtils, ueled;

type

  TDisplayParams = record
    TextColor     : TColor;
    TextHeight    : integer;
    TextAlignment : TBCAlignment;
    Text          : array[0..255] of String;
  end;

  TTextParams = record
    Input_Reg : word;
    T : Array[1..2] of TDisplayParams;
  end;

  TTextDisplay = record
    Panel   : TBCPanel;
    LblCode : Tlabel;
  end;


  { TVxForm }

  TVxForm = class(TForm)
    lblTest_1: TLabel;
    lblTest_2: TLabel;
    PnlText_1: TBCPanel;
    PnlText_2: TBCPanel;
    Label1: TLabel;
    Label2: TLabel;
    LblCode_1: TLabel;
    LblCode_2: TLabel;
    lblName: TLabel;
    speTest_1: TSpinEdit;
    speTest_2: TSpinEdit;
    Timer: TTimer;
    LedCom_1: TuELED;
    procedure FormCreate(Sender: TObject);
    procedure speTest_1Change(Sender: TObject);
    procedure speTest_2Change(Sender: TObject);
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
    Reg                   : TRegisterModule;
    Params                : TTextParams;
    Display               : array[1..2] of TTextDisplay;
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

var
  VxForm: TVxForm;

{ TVxForm }

procedure TVxForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:=false;
  PnlText_1.Background.Color:=clBlack; // Sometime BCPanel "forgets" something...
  PnlText_2.Background.Color:=clBlack;

  Display[1].Panel:=PnlText_1;
  Display[1].LblCode:=LblCode_1;
  Display[2].Panel:=PnlText_2;
  Display[2].LblCode:=LblCode_2;

  SetDefaultParams;

  ApplyParams;
  SetLedStatus(LedCom_1, 0);
end;

procedure TVxForm.speTest_1Change(Sender: TObject);
begin
  PnlText_1.Caption:=Params.T[1].Text[speTest_1.Value];
end;

procedure TVxForm.speTest_2Change(Sender: TObject);
begin
  PnlText_2.Caption:=Params.T[2].Text[speTest_2.Value];
end;


procedure TVxForm.TimerTimer(Sender: TObject);
Var
  Value : word;
  V_1   : byte;
  V_2   : byte;
begin
  Reg.Status:=CommRegisterRead(Reg.Index, {%H-}Value);
  if Reg.Status = _rsOK then
  begin
    V_1:=Value and $00FF;
    V_2:=(Value shr 8) and $00FF;
    Display[1].Panel.Caption:=Params.T[1].Text[V_1];
    Display[1].LblCode.Caption:='Code : '+inttostr(V_1);
    Display[2].Panel.Caption:=Params.T[2].Text[V_2];
    Display[2].LblCode.Caption:='Code : '+inttostr(V_2);
  end;
  SetLedStatus(LedCom_1, Reg.Status);
end;


procedure TVxForm.SetDefaultParams;
Var
  x, y : integer;
begin
  Params.Input_Reg:=9;
  for x:=1 to 2 do
    for y:=0 to 255 do
      Params.T[x].Text[y]:='';

  Params.T[1].TextColor:=clAqua;
  Params.T[1].TextHeight:=30;
  Params.T[1].TextAlignment:=bcaCenter;;
  Params.T[2].TextColor:=$000080FF;
  Params.T[2].TextHeight:=30;
  Params.T[2].TextAlignment:=bcaCenter;;
end;

procedure TVxForm.ApplyParams;
Var
  c : integer;
begin
  for c:=1 to 2 do
  begin
    Display[c].Panel.FontEx.TextAlignment:=Params.T[c].TextAlignment;
    Display[c].Panel.FontEx.Color:=Params.T[c].TextColor;
    Display[c].Panel.FontEx.Height:=Params.T[c].TextHeight;
    Display[c].Panel.Caption:=Params.T[c].Text[0];
    Display[c].LblCode.Caption:='Code : 0';
  end;
  lblName.Hint:='Read Reg : '+IntToStr(Params.Input_Reg);
end;

procedure TVxForm.SetFIndex(AValue: integer);
begin
  FIndex:=AValue;
end;

procedure TVxForm.Start;
begin
  speTest_1.Visible:=false;
  speTest_2.Visible:=false;
  lblTest_1.Visible:=false;
  lblTest_2.Visible:=false;
  PnlText_1.Caption:='';
  PnlText_2.Caption:='';
  Timer.Enabled:=true;
  FRunning:=true;
end;

procedure TVxForm.Stop;
begin
  FRunning:=false;
  Timer.Enabled:=false;
  SetLedStatus(LedCom_1, _rsUnknown);
  speTest_1.Visible:=true;
  speTest_2.Visible:=true;
  lblTest_1.Visible:=true;
  lblTest_2.Visible:=true;
  PnlText_1.Caption:=Params.T[1].Text[speTest_1.Value];
  PnlText_2.Caption:=Params.T[2].Text[speTest_2.Value];
end;

procedure TVxForm.PrepareStart;
begin
  Reg.Index:=CommReadRegisterAdd(Params.Input_Reg);
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

      Params.T[1].TextAlignment:=TBCAlignment(ini.ReadInteger(Section,'TextAlignment.A',ord(Params.T[1].TextAlignment)));
      Params.T[1].TextHeight:=ini.ReadInteger(Section,'TextHeight.A',Params.T[1].TextHeight);
      Params.T[1].TextColor:=ini.ReadInteger(Section,'TextColor.A',Params.T[1].TextColor);
      for c:=0 to 255 do
        Params.T[1].Text[c]:=ini.ReadString(Section,'Text_A.'+inttoStr(c),Params.T[1].Text[c]);

      Params.T[2].TextAlignment:=TBCAlignment(ini.ReadInteger(Section,'TextAlignment.B',ord(Params.T[2].TextAlignment)));
      Params.T[2].TextHeight:=ini.ReadInteger(Section,'TextHeight.B',Params.T[2].TextHeight);
      Params.T[2].TextColor:=ini.ReadInteger(Section,'TextColor.B',Params.T[2].TextColor);
      for c:=0 to 255 do
        Params.T[2].Text[c]:=ini.ReadString(Section,'Text_B.'+inttoStr(c),Params.T[2].Text[c]);
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

    ini.WriteInteger(Section,'TextAlignment.A',ord(Params.T[1].TextAlignment));
    ini.WriteInteger(Section,'TextHeight.A',Params.T[1].TextHeight);
    ini.WriteInteger(Section,'TextColor.A',Params.T[1].TextColor);
    for c:=0 to 255 do
      if Trim(Params.T[1].Text[c])<>'' then
        ini.WriteString(Section,'Text_A.'+inttoStr(c),Params.T[1].Text[c]);

    ini.WriteInteger(Section,'TextAlignment.B',ord(Params.T[2].TextAlignment));
    ini.WriteInteger(Section,'TextHeight.B',Params.T[2].TextHeight);
    ini.WriteInteger(Section,'TextColor.B',Params.T[2].TextColor);
    for c:=0 to 255 do
      if Trim(Params.T[2].Text[c])<>'' then
        ini.WriteString(Section,'Text_B.'+inttoStr(c),Params.T[2].Text[c]);

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


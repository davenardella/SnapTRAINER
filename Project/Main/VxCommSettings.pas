unit VxCommSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, atshapelinebgra, SnapMB, VxCommTypes;

const
  ParityChar : array [0..2] of char = ('N','E','O');

type

  { TCommSettingsForm }

  TCommSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbBaudRate: TComboBox;
    cbProtocol: TComboBox;
    cbMode: TComboBox;
    cbConnectionType: TComboBox;
    cbDataBits: TComboBox;
    cbFlow: TComboBox;
    cbParity: TComboBox;
    cbPort: TComboBox;
    cbStopBits: TComboBox;
    chkAutosave: TCheckBox;
    ChkBaseAddressZero: TCheckBox;
    ChkDisOnError: TCheckBox;
    ChkUseIReg: TCheckBox;
    edMBAddress: TEdit;
    edS7Address: TEdit;
    gbAddress1: TGroupBox;
    gbAddress0: TGroupBox;
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
    Label19: TLabel;
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
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    lblUnit: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblError: TLabel;
    pnlClient: TPanel;
    PC: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    ShapeLineBGRA1: TShapeLineBGRA;
    ShapeLineBGRA2: TShapeLineBGRA;
    speRefreshInterval: TSpinEdit;
    speSlot: TSpinEdit;
    speUnitID: TSpinEdit;
    speRack: TSpinEdit;
    spePort: TSpinEdit;
    StaticText1: TStaticText;
    StaticText10: TStaticText;
    StaticText11: TStaticText;
    StaticText12: TStaticText;
    StaticText13: TStaticText;
    StaticText14: TStaticText;
    StaticText15: TStaticText;
    StaticText16: TStaticText;
    StaticText17: TStaticText;
    StaticText18: TStaticText;
    StaticText19: TStaticText;
    StaticText2: TStaticText;
    StaticText20: TStaticText;
    StaticText21: TStaticText;
    StaticText22: TStaticText;
    StaticText23: TStaticText;
    StaticText24: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StaticText5: TStaticText;
    StaticText6: TStaticText;
    StaticText7: TStaticText;
    StaticText8: TStaticText;
    StaticText9: TStaticText;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbProtocolCloseUp(Sender: TObject);
    procedure cbModeCloseUp(Sender: TObject);
    procedure ChkBaseAddressZeroClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label18Click(Sender: TObject);
  private
    procedure InitComboBoxes;
    procedure SetAddressLegend;
    procedure UpdateCBProtocol;
    procedure UpdateProtocol;
  protected
    Settings : TCommSettings;
  public
    function CheckSettings : boolean;
    procedure SettingsToForm;
    procedure FormToSettings;
  end;


procedure SetDefaults(var Settings : TCommSettings);
function EditParams(var Settings : TCommSettings) : boolean;

var
  SettingsForm: TCommSettingsForm;

implementation
{$R *.lfm}

procedure SetDefaults(var Settings : TCommSettings);
begin
  // Common
  Settings.Autosave:=true;
  Settings.Mode:=cmClient;
  Settings.UseInputRegs:=true;
  Settings.ProtocolType:=ctMBTCP;
  Settings.RefreshInterval:=100;
  Settings.UnitID_DB:=255;
  Settings.DisOnError:=true;
  Settings.BaseAddressZero:=false;
  // Modbus/TCP
  Settings.MBTCPParams.Address:='127.0.0.1';
  Settings.MBTCPParams.Port:=502;
  // Modbus/RTU
  Settings.MBRTUParams.Port:='COM1';
  Settings.MBRTUParams.BaudRate:=19200;
  Settings.MBRTUParams.Parity:='E';
  Settings.MBRTUParams.DataBits:=8;
  Settings.MBRTUParams.StopBits:=1;
  Settings.MBRTUParams.Flow:=flowNone;
  // S7
  Settings.S7ISOParams.Address:='127.0.0.1';
  Settings.S7ISOParams.Rack:=0;
  Settings.S7ISOParams.Slot:=0;
  Settings.S7ISOParams.ConnectionType:=1; // PG
end;

function EditParams(var Settings : TCommSettings) : boolean;
begin
  SettingsForm:=TCommSettingsForm.Create(Application);
  try
    SettingsForm.Settings:=Settings;
    Result:=SettingsForm.ShowModal = mrOk;
    if Result then
      Settings:=SettingsForm.Settings;
  finally
    SettingsForm.Free;
  end;
end;

{ TCommSettingsForm }

procedure TCommSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToSettings;
    ModalResult:=mrOK;
  end;
end;

procedure TCommSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TCommSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TCommSettingsForm.cbProtocolCloseUp(Sender: TObject);
begin
  UpdateProtocol;
end;

procedure TCommSettingsForm.cbModeCloseUp(Sender: TObject);
begin
  if cbMode.ItemIndex=0 then
    cbProtocol.Items[2]:='S7 Protocol'
  else
    cbProtocol.Items[2]:='-';
  UpdateCBProtocol;
  UpdateProtocol;
end;

procedure TCommSettingsForm.ChkBaseAddressZeroClick(Sender: TObject);
begin
  SetAddressLegend;
end;

procedure TCommSettingsForm.FormCreate(Sender: TObject);
begin
  InitComboBoxes;
end;

procedure TCommSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TCommSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poScreenCenter;
  SettingsToForm;
end;

procedure TCommSettingsForm.Label18Click(Sender: TObject);
begin

end;

procedure TCommSettingsForm.InitComboBoxes;
Var
  c : integer;
begin
  cbPort.Items.Clear;
  for c:=1 to 64 do
    cbPort.Items.Add('COM'+IntToStr(c));
  cbPort.ItemIndex:=0;
end;

procedure TCommSettingsForm.SetAddressLegend;
begin
  if chkBaseAddressZero.Checked then
  begin
    gbAddress1.Visible:=false;
    gbAddress0.Visible:=true;
  end
  else begin
    gbAddress0.Visible:=false;
    gbAddress1.Visible:=true;
  end;
end;

procedure TCommSettingsForm.UpdateCBProtocol;
begin
  cbProtocol.Items.Clear;
  cbProtocol.Items.Add('Modbus TCP');
  cbProtocol.Items.Add('Modbus RTU');
  if cbMode.ItemIndex = 0 then
    cbProtocol.Items.Add('S7 Protocol');
  cbProtocol.ItemIndex:=0;
end;

procedure TCommSettingsForm.UpdateProtocol;
begin
  PC.ActivePageIndex:=cbProtocol.ItemIndex;
  if cbMode.ItemIndex = 0 then
  begin
    pnlClient.Visible:=true;
    if (cbProtocol.ItemIndex<2) then
      lblUnit.Caption:='Unit ID'
    else
      lblUnit.Caption:='DB Number'
  end
  else begin
    pnlClient.Visible:=false;
    lblUnit.Caption:='Slave ID'
  end;
end;

function TCommSettingsForm.CheckSettings: boolean;
Var
  port : integer;
begin
  Result:=false;
  if cbProtocol.ItemIndex = -1 then
  begin
    lblError.Caption:='Invalid Data Link';
    exit;
  end;
  if trim(edMBAddress.Text) = '' then
  begin
    lblError.Caption:='Invalid IP Address';
    exit;
  end;
  port := spePort.Value;
  if (port < 1) or (port > $FFFF) then
  begin
    lblError.Caption:='Invalid IP Port (see Ethernet settings)';
    exit;
  end;

  if (cbPort.ItemIndex=-1) or
     (cbBaudRate.ItemIndex=-1) or
     (cbParity.ItemIndex=-1) or
     (cbDataBits.ItemIndex=-1) or
     (cbStopBits.ItemIndex=-1) or
     (cbFlow.ItemIndex=-1) then
  begin
    lblError.Caption:='Invalid Serial settings (see Serial settings)';
    exit;
  end;
  Result:=true;
end;

procedure TCommSettingsForm.SettingsToForm;
Var
  ch : char;
begin
  // Common
  chkAutosave.Checked:=Settings.Autosave;
  cbMode.ItemIndex:=ord(Settings.Mode);
  ChkUseIReg.Checked:=Settings.UseInputRegs;
  cbProtocol.ItemIndex:=ord(Settings.ProtocolType);
  speUnitID.Value:=Settings.UnitID_DB;
  speRefreshInterval.Value:=Settings.RefreshInterval;
  ChkDisOnError.Checked:=Settings.DisOnError;
  ChkBaseAddressZero.Checked:=Settings.BaseAddressZero;
  // Modbus/TCP
  edMBAddress.Text:=Settings.MBTCPParams.Address;
  spePort.Value :=Settings.MBTCPParams.Port;
  // Modbus/RTU
  cbPort.ItemIndex:=cbPort.Items.IndexOf(Settings.MBRTUParams.Port);
  cbBaudRate.ItemIndex:=cbBaudRate.Items.IndexOf(IntToStr(Settings.MBRTUParams.BaudRate));

  ch:=UpCase(Settings.MBRTUParams.Parity);
  if ch='N' then cbParity.ItemIndex:=0 else
  if ch='E' then cbParity.ItemIndex:=1 else
  if ch='O' then cbParity.ItemIndex:=2 else
    cbParity.ItemIndex:=0;

  cbDataBits.ItemIndex:=cbDataBits.Items.IndexOf(IntToStr(Settings.MBRTUParams.DataBits));
  cbStopBits.ItemIndex:=cbStopBits.Items.IndexOf(IntToStr(Settings.MBRTUParams.StopBits));
  cbFlow.ItemIndex:=ord(Settings.MBRTUParams.Flow);

  // S7
  edS7Address.Text:=Settings.S7ISOParams.Address;
  speRack.Value:=Settings.S7ISOParams.Rack;
  speSlot.Value:=Settings.S7ISOParams.Slot;
  cbConnectionType.ItemIndex:=Settings.S7ISOParams.ConnectionType-1;

  UpdateCBProtocol;
  cbProtocol.ItemIndex:=ord(Settings.ProtocolType);
  UpdateProtocol;
  SetAddressLegend;
end;

procedure TCommSettingsForm.FormToSettings;
begin
  // Common
  Settings.Autosave:=chkAutosave.Checked;
  Settings.Mode:=TControllerMode(cbMode.ItemIndex);
  Settings.UseInputRegs:=ChkUseIReg.Checked;
  Settings.ProtocolType:=TProtocolType(cbProtocol.ItemIndex);
  Settings.UnitID_DB:=speUnitID.Value;
  Settings.RefreshInterval:=speRefreshInterval.Value;
  Settings.DisOnError:=ChkDisOnError.Checked;
  Settings.BaseAddressZero:=ChkBaseAddressZero.Checked;
  // Modbus/TCP
  Settings.MBTCPParams.Address:=edMBAddress.Text;
  Settings.MBTCPParams.Port:=spePort.Value;
  // Modbus/RTU
  Settings.MBRTUParams.Port:=cbPort.Text;
  Settings.MBRTUParams.BaudRate:=StrToIntDef(cbBaudRate.Text,19200);
  Settings.MBRTUParams.Parity:=ParityChar[cbParity.ItemIndex];
  Settings.MBRTUParams.DataBits:=StrToIntDef(cbDataBits.Text,8);
  Settings.MBRTUParams.StopBits:=StrToIntDef(cbStopBits.Text,1);
  Settings.MBRTUParams.Flow:=TMBSerialFlow(cbFlow.ItemIndex);
  // S7
  Settings.S7ISOParams.Address:=edS7Address.Text;
  Settings.S7ISOParams.Rack:=speRack.Value;
  Settings.S7ISOParams.Slot:=speSlot.Value;
  Settings.S7ISOParams.ConnectionType:=cbConnectionType.ItemIndex+1;
end;

end.


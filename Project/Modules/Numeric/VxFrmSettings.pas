unit VxFrmSettings;

{$mode DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, VxFrmModule;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbCH1_Enabled: TComboBox;
    cbCH1_Mode: TComboBox;
    cbCH2_Enabled: TComboBox;
    cbCH2_Mode: TComboBox;
    cbCH3_Enabled: TComboBox;
    cbCH3_Mode: TComboBox;
    edCH1_Name: TEdit;
    edCH2_Name: TEdit;
    edCH3_Name: TEdit;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label14: TLabel;
    Label18: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label26: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speCH1_HiReg: TSpinEdit;
    speCH2_HiReg: TSpinEdit;
    speCH3_HiReg: TSpinEdit;
    speCH2_LoReg: TSpinEdit;
    speCH1_LoReg: TSpinEdit;
    speCH3_LoReg: TSpinEdit;
    speCH1_Decimals: TSpinEdit;
    speCH2_Decimals: TSpinEdit;
    speCH3_Decimals: TSpinEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
  protected
    Params : TNumericParams;
  public
  end;


function EditParams(Index : integer; var Params : TNumericParams) : boolean;

implementation
{$R *.lfm}

var
  SettingsForm: TSettingsForm;

function EditParams(Index : integer; var Params : TNumericParams) : boolean;
begin
  SettingsForm:=TSettingsForm.Create(Application);
  SettingsForm.PanelTop.Caption:='32 bit Numeric I/O - Module '+IntToStr(Index);
  try
    SettingsForm.Params := Params;
    Result:=SettingsForm.ShowModal = mrOk;
    if Result then
      Params:=SettingsForm.Params;
  finally
    SettingsForm.Free;
  end;
end;

{ TSettingsForm }

procedure TSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TSettingsForm.CheckSettings: boolean;
begin
  if (speCH1_LoReg.Value = speCH1_HiReg.Value) or
     (speCH2_LoReg.Value = speCH2_HiReg.Value) or
     (speCH3_LoReg.Value = speCH3_HiReg.Value) then
    Result:=MessageDlg('Warning','You are using the same HI/LO part for some registers. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TSettingsForm.ParamsToForm;
begin
  speCH1_LoReg.Value:=Params.CH[1].Reg_LO;
  speCH1_HiReg.Value:=Params.CH[1].Reg_HI;
  speCH2_LoReg.Value:=Params.CH[2].Reg_LO;
  speCH2_HiReg.Value:=Params.CH[2].Reg_HI;
  speCH3_LoReg.Value:=Params.CH[3].Reg_LO;
  speCH3_HiReg.Value:=Params.CH[3].Reg_HI;

  cbCH1_Enabled.ItemIndex:=Integer(Params.CH[1].Enabled);
  cbCH2_Enabled.ItemIndex:=Integer(Params.CH[2].Enabled);
  cbCH3_Enabled.ItemIndex:=Integer(Params.CH[3].Enabled);

  cbCH1_Mode.ItemIndex:=Ord(Params.CH[1].Mode);
  cbCH2_Mode.ItemIndex:=Ord(Params.CH[2].Mode);
  cbCH3_Mode.ItemIndex:=Ord(Params.CH[3].Mode);

  speCH1_Decimals.Value:=Params.CH[1].Decimals;
  speCH2_Decimals.Value:=Params.CH[2].Decimals;
  speCH3_Decimals.Value:=Params.CH[3].Decimals;

  edCH1_Name.Text:=Params.CH[1].Name;
  edCH2_Name.Text:=Params.CH[2].Name;
  edCH3_Name.Text:=Params.CH[3].Name;
end;

procedure TSettingsForm.FormToParams;
begin
  Params.CH[1].Reg_LO:=speCH1_LoReg.Value;
  Params.CH[1].Reg_HI:=speCH1_HiReg.Value;

  Params.CH[2].Reg_LO:=speCH2_LoReg.Value;
  Params.CH[2].Reg_HI:=speCH2_HiReg.Value;

  Params.CH[3].Reg_LO:=speCH3_LoReg.Value;
  Params.CH[3].Reg_HI:=speCH3_HiReg.Value;

  Params.CH[1].Enabled:=boolean(cbCH1_Enabled.ItemIndex);
  Params.CH[2].Enabled:=boolean(cbCH2_Enabled.ItemIndex);
  Params.CH[3].Enabled:=boolean(cbCH3_Enabled.ItemIndex);

  Params.CH[1].Mode:=TNumberMode(cbCH1_Mode.ItemIndex);
  Params.CH[2].Mode:=TNumberMode(cbCH2_Mode.ItemIndex);
  Params.CH[3].Mode:=TNumberMode(cbCH3_Mode.ItemIndex);

  Params.CH[1].Decimals:=speCH1_Decimals.Value;
  Params.CH[2].Decimals:=speCH2_Decimals.Value;
  Params.CH[3].Decimals:=speCH3_Decimals.Value;

  Params.CH[1].Name:=edCH1_Name.Text;
  Params.CH[2].Name:=edCH2_Name.Text;
  Params.CH[3].Name:=edCH3_Name.Text;
end;

end.


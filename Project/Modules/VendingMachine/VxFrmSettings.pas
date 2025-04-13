unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TVendingMachineSettingsForm }

  TVendingMachineSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbCurrency: TComboBox;
    ChWriteFast: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
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
    Label4: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speReadReg: TSpinEdit;
    spePrice_1: TSpinEdit;
    spePrice_2: TSpinEdit;
    spePrice_3: TSpinEdit;
    spePrice_4: TSpinEdit;
    spePrice_5: TSpinEdit;
    speWriteReg: TSpinEdit;
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
    Params : TVendingMachineParams;
  public
  end;


function EditParams(Index : integer; var Params : TVendingMachineParams) : boolean;

implementation

{$R *.lfm}

var
  VendingMachineSettingsForm: TVendingMachineSettingsForm;

function EditParams(Index : integer; var Params : TVendingMachineParams) : boolean;
begin
  VendingMachineSettingsForm:=TVendingMachineSettingsForm.Create(Application);
  VendingMachineSettingsForm.PanelTop.Caption:='Vending Machine - Module '+IntToStr(Index);
  try
    VendingMachineSettingsForm.Params := Params;
    Result:=VendingMachineSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=VendingMachineSettingsForm.Params;
  finally
    VendingMachineSettingsForm.Free;
  end;
end;

{ TVendingMachineSettingsForm }

procedure TVendingMachineSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TVendingMachineSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TVendingMachineSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TVendingMachineSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TVendingMachineSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TVendingMachineSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TVendingMachineSettingsForm.CheckSettings: boolean;
begin
  if (speReadReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register(s) for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TVendingMachineSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  ChWriteFast.Checked:=Params.FastWrite;
  if Params.CurrencyEur then
    cbCurrency.ItemIndex:=0
  else
    cbCurrency.ItemIndex:=1;

  spePrice_1.Value:=Params.Price_1;
  spePrice_2.Value:=Params.Price_2;
  spePrice_3.Value:=Params.Price_3;
  spePrice_4.Value:=Params.Price_4;
  spePrice_5.Value:=Params.Price_5;
end;

procedure TVendingMachineSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.FastWrite:=ChWriteFast.Checked;
  Params.CurrencyEur:=cbCurrency.ItemIndex = 0;

  Params.Price_1:=spePrice_1.Value;
  Params.Price_2:=spePrice_2.Value;
  Params.Price_3:=spePrice_3.Value;
  Params.Price_4:=spePrice_4.Value;
  Params.Price_5:=spePrice_5.Value;
end;

end.


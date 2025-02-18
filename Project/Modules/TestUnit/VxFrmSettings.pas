unit VxFrmSettings;

{$mode DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, VxFrmModule;

type

  { TTestUnitSettingsForm }

  TTestUnitSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbScrapMode: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label2: TLabel;
    lblError: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speTestTime: TFloatSpinEdit;
    speWriteReg: TSpinEdit;
    speReadReg: TSpinEdit;
    spePercentPass: TSpinEdit;
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
    Params : TTestUnitParams;
  public
  end;


function EditParams(Index : integer; var Params : TTestUnitParams) : boolean;

implementation

{$R *.lfm}

var
  TestUnitSettingsForm: TTestUnitSettingsForm;

function EditParams(Index : integer; var Params : TTestUnitParams) : boolean;
begin
  TestUnitSettingsForm:=TTestUnitSettingsForm.Create(Application);
  TestUnitSettingsForm.PanelTop.Caption:='Test Unit - Module '+IntToStr(Index);
  try
    TestUnitSettingsForm.Params := Params;
    Result:=TestUnitSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TestUnitSettingsForm.Params;
  finally
    TestUnitSettingsForm.Free;
  end;
end;

{ TTestUnitSettingsForm }

procedure TTestUnitSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTestUnitSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTestUnitSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTestUnitSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TTestUnitSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTestUnitSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTestUnitSettingsForm.CheckSettings: boolean;
begin
  if (speReadReg.Value = speWriteReg.Value) then
  begin
    lblError.Caption:='Registers must be different';
    Result:=false;
  end
  else
    Result:=true;
end;

procedure TTestUnitSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  speTestTime.Value:=Params.TestTime;
  spePercentPass.Value:=Params.PercentPass;
  cbScrapMode.ItemIndex:=ord(Params.ScrapMode);
end;

procedure TTestUnitSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.TestTime:=speTestTime.Value;
  Params.PercentPass:=spePercentPass.Value;
  Params.ScrapMode:=TTestUnitScrapMode(cbScrapMode.ItemIndex);
end;

end.


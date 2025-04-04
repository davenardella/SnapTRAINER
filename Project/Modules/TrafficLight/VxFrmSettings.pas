unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TTTLSettingsForm }

  TTTLSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label13: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    rbCarMode: TRadioButton;
    rbPedMode: TRadioButton;
    speReadReg: TSpinEdit;
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
    Params : TTrafficLightParams;
  public
  end;


function EditParams(Index : integer; var Params : TTrafficLightParams) : boolean;

implementation

{$R *.lfm}

var
  TTLSettingsForm: TTTLSettingsForm;

function EditParams(Index : integer; var Params : TTrafficLightParams) : boolean;
begin
  TTLSettingsForm:=TTTLSettingsForm.Create(Application);
  TTLSettingsForm.PanelTop.Caption:='Traffic Light simulator - Module '+IntToStr(Index);
  try
    TTLSettingsForm.Params := Params;
    Result:=TTLSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TTLSettingsForm.Params;
  finally
    TTLSettingsForm.Free;
  end;
end;

{ TTTLSettingsForm }

procedure TTTLSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTTLSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTTLSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTTLSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TTTLSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTTLSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTTLSettingsForm.CheckSettings: boolean;
begin
  Result:=true;
end;

procedure TTTLSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  rbCarMode.Checked:=Params.CarMode;
  rbPedMode.Checked:=not Params.CarMode;
end;

procedure TTTLSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.CarMode:=rbCarMode.Checked;
end;

end.


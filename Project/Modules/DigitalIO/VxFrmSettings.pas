unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, VxFrmModule;

type

  { TVxSettingsForm }

  TVxSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    ChOutput_Ena: TCheckBox;
    ChWriteFast: TCheckBox;
    ChInput_Ena: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    lblError: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speWriteReg: TSpinEdit;
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
    Params : TDigitalIOParams;
  public
  end;


function EditParams(Index : integer; var Params : TDigitalIOParams) : boolean;

implementation

{$R *.lfm}

var
  VxSettingsForm: TVxSettingsForm;

function EditParams(Index : integer; var Params : TDigitalIOParams) : boolean;
begin
  VxSettingsForm:=TVxSettingsForm.Create(nil);
  VxSettingsForm.PanelTop.Caption:='Digital I/O - Module '+IntToStr(Index);
  try
    VxSettingsForm.Params := Params;
    Result:=VxSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=VxSettingsForm.Params;
  finally
    VxSettingsForm.Free;
  end;
end;

{ TVxSettingsForm }

procedure TVxSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TVxSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TVxSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TVxSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TVxSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TVxSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TVxSettingsForm.CheckSettings: boolean;
begin
  if ChInput_Ena.Checked and ChOutput_Ena.Checked then
  begin
    if (speReadReg.Value = speWriteReg.Value) then
      Result:=MessageDlg('Warning','You are using the same register for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
    else
      Result:=true;
  end
  else
    Result:=true;
end;

procedure TVxSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  ChInput_Ena.Checked:=Params.Input_Ena;
  ChOutput_Ena.Checked:=Params.Output_Ena;
  ChWriteFast.Checked:=Params.FastWrite;
end;

procedure TVxSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.Input_Ena:=ChInput_Ena.Checked;
  Params.Output_Ena:=ChOutput_Ena.Checked;
  Params.FastWrite:=ChWriteFast.Checked;
end;

end.


unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TTElevatorCallSettingsForm }

  TTElevatorCallSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    ChkBtnUP: TCheckBox;
    ChkBtnDN: TCheckBox;
    ChWriteFast: TCheckBox;
    edLabel: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speFloorReg: TSpinEdit;
    speReadReg: TSpinEdit;
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
    Params : TElevatorCallParams;
  public
  end;


function EditParams(Index : integer; var Params : TElevatorCallParams) : boolean;

implementation

{$R *.lfm}

var
  TElevatorCallSettingsForm: TTElevatorCallSettingsForm;

function EditParams(Index : integer; var Params : TElevatorCallParams) : boolean;
begin
  TElevatorCallSettingsForm:=TTElevatorCallSettingsForm.Create(Application);
  TElevatorCallSettingsForm.PanelTop.Caption:='Elevator Call - Module '+IntToStr(Index);
  try
    TElevatorCallSettingsForm.Params := Params;
    Result:=TElevatorCallSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TElevatorCallSettingsForm.Params;
  finally
    TElevatorCallSettingsForm.Free;
  end;
end;

{ TTElevatorCallSettingsForm }

procedure TTElevatorCallSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTElevatorCallSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTElevatorCallSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTElevatorCallSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TTElevatorCallSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTElevatorCallSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTElevatorCallSettingsForm.CheckSettings: boolean;
begin
  if (speReadReg.Value = speFloorReg.Value) then
  begin
    lblError.Caption:='Registers Control and Floor must be different';
    Result:=false;
    exit;
  end;
  if (speReadReg.Value = speWriteReg.Value) or (speFloorReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register(s) for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TTElevatorCallSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speFloorReg.Value:=Params.Floor_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  ChWriteFast.Checked:=Params.FastWrite;
  edLabel.Text:=Params.FloorLabel;
  chkBtnUP.Checked:=Params.BtnUPEnabled;
  chkBtnDN.Checked:=Params.BtnDNEnabled;
end;

procedure TTElevatorCallSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Floor_Reg:=speFloorReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.FastWrite:=ChWriteFast.Checked;
  Params.FloorLabel:=edLabel.Text;
  Params.BtnUPEnabled:=chkBtnUP.Checked;
  Params.BtnDNEnabled:=chkBtnDN.Checked;
end;

end.


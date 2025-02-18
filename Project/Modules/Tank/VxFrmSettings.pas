unit VxFrmSettings;

{$mode DELPHI}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, atshapelinebgra, VxFrmModule;

type

  { TTankSettingsForm }

  TTankSettingsForm = class(TForm)
    BCPanel13: TBCPanel;
    BCPanel9: TBCPanel;
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbOutletFlow: TComboBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblError: TLabel;
    Label13: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    Shape15: TShape;
    Shape16: TShape;
    Shape17: TShape;
    Shape18: TShape;
    ShapeLineBGRA2: TShapeLineBGRA;
    speReadReg: TSpinEdit;
    speLevelMax: TFloatSpinEdit;
    speLevelMin: TFloatSpinEdit;
    speCapacity: TFloatSpinEdit;
    speFlowOutput: TFloatSpinEdit;
    speFlowInput: TFloatSpinEdit;
    speWaterInit: TFloatSpinEdit;
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
    Params : TTankParams;
  public
  end;


function EditParams(Index : integer; var Params : TTankParams) : boolean;

implementation

{$R *.lfm}

var
  TankSettingsForm: TTankSettingsForm;

function EditParams(Index : integer; var Params : TTankParams) : boolean;
begin
  TankSettingsForm:=TTankSettingsForm.Create(Application);
  TankSettingsForm.PanelTop.Caption:='Tank simulator - Module '+IntToStr(Index);
  try
    TankSettingsForm.Params := Params;
    Result:=TankSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TankSettingsForm.Params;
  finally
    TankSettingsForm.Free;
  end;
end;

{ TTankSettingsForm }

procedure TTankSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTankSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTankSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTankSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TTankSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTankSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTankSettingsForm.CheckSettings: boolean;
begin
  if speLevelMin.Value>=speLevelMax.Value then
  begin
    lblError.Caption:='Level Max must be greater than Level Min';
    Result:=false;
    exit;
  end;

  if (speReadReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;

  if (speFlowOutput.Value>speFlowInput.Value) then
    Result:=MessageDlg('Warning','Output Flow is greater then Input Flow. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TTankSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  speCapacity.Value:=Params.Capacity;
  speLevelMax.Value:=Params.LevelMax_100;
  speLevelMin.Value:=Params.LevelMin_100;
  speFlowInput.Value:=Params.FlowInput;
  speFlowOutput.Value:=Params.FlowOutput;
  speWaterInit.Value:=Params.WaterInit_100;
  cbOutletFlow.ItemIndex:=integer(Params.UsePLCOutputFlow);
end;

procedure TTankSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.Capacity:=speCapacity.Value;
  Params.LevelMax_100:=speLevelMax.Value;
  Params.LevelMin_100:=speLevelMin.Value;
  Params.FlowInput:=speFlowInput.Value;
  Params.FlowOutput:=speFlowOutput.Value;
  Params.WaterInit_100:=speWaterInit.Value;
  Params.UsePLCOutputFlow:=cbOutletFlow.ItemIndex=1;
end;

end.


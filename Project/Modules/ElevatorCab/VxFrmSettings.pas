unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TTElevatorCabSettingsForm }

  TTElevatorCabSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    ChWriteFast: TCheckBox;
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
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    speReadReg: TSpinEdit;
    speFloorReg: TSpinEdit;
    speSlidingTime: TSpinEdit;
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
    Params : TElevatorCabParams;
  public
  end;


function EditParams(Index : integer; var Params : TElevatorCabParams) : boolean;

implementation

{$R *.lfm}

var
  TElevatorCabSettingsForm: TTElevatorCabSettingsForm;

function EditParams(Index : integer; var Params : TElevatorCabParams) : boolean;
begin
  TElevatorCabSettingsForm:=TTElevatorCabSettingsForm.Create(Application);
  TElevatorCabSettingsForm.PanelTop.Caption:='Elevator Cab - Module '+IntToStr(Index);
  try
    TElevatorCabSettingsForm.Params := Params;
    Result:=TElevatorCabSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TElevatorCabSettingsForm.Params;
  finally
    TElevatorCabSettingsForm.Free;
  end;
end;

{ TTElevatorCabSettingsForm }

procedure TTElevatorCabSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTElevatorCabSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTElevatorCabSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTElevatorCabSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TTElevatorCabSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTElevatorCabSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTElevatorCabSettingsForm.CheckSettings: boolean;
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

procedure TTElevatorCabSettingsForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speFloorReg.Value:=Params.Floor_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  ChWriteFast.Checked:=Params.FastWrite;
  speSlidingTime.Value:=Params.SlidingTime;
end;

procedure TTElevatorCabSettingsForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Floor_Reg:=speFloorReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.FastWrite:=ChWriteFast.Checked;
  Params.SlidingTime:=speSlidingTime.Value;
end;

end.


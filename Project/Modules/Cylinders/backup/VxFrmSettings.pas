unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TTCylindersSettingsForm }

  TTCylindersSettingsForm = class(TForm)
    BCPanel60: TBCPanel;
    BCPanel61: TBCPanel;
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbInitPos_1: TComboBox;
    cbType_1: TComboBox;
    cbType_2: TComboBox;
    cbType_3: TComboBox;
    cbType_4: TComboBox;
    cbRSensor_2: TComboBox;
    cbRSensor_3: TComboBox;
    cbRSensor_4: TComboBox;
    cbCyNumber: TComboBox;
    cbInitPos_2: TComboBox;
    cbInitPos_3: TComboBox;
    cbInitPos_4: TComboBox;
    cbESensor_1: TComboBox;
    cbESensor_2: TComboBox;
    cbESensor_3: TComboBox;
    cbESensor_4: TComboBox;
    cbRSensor_1: TComboBox;
    edCaption_1: TEdit;
    edCaption_2: TEdit;
    edCaption_3: TEdit;
    edCaption_4: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblError: TLabel;
    Label13: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    Shape100: TShape;
    Shape97: TShape;
    Shape98: TShape;
    Shape99: TShape;
    speReadReg: TSpinEdit;
    speWriteReg: TSpinEdit;
    speStroke_1: TFloatSpinEdit;
    speSpeedR_1: TFloatSpinEdit;
    speSpeedR_2: TFloatSpinEdit;
    speSpeedR_3: TFloatSpinEdit;
    speSpeedR_4: TFloatSpinEdit;
    speSpeedE_1: TFloatSpinEdit;
    speStroke_2: TFloatSpinEdit;
    speSpeedE_2: TFloatSpinEdit;
    speStroke_3: TFloatSpinEdit;
    speSpeedE_3: TFloatSpinEdit;
    speStroke_4: TFloatSpinEdit;
    speSpeedE_4: TFloatSpinEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    Captions        : array[1..4] of TEdit;
    Stroke          : array[1..4] of TFloatSpinEdit;
    SpeedExtend     : array[1..4] of TFloatSpinEdit;
    SpeedRetract    : array[1..4] of TFloatSpinEdit;
    SpringReturn    : array[1..4] of TComboBox;
    HasExtended     : array[1..4] of TComboBox;
    HasRetracted    : array[1..4] of TComboBox;
    InitialPosition : array[1..4] of TComboBox;

    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
  protected
    Params : TCylinderParams;
  public
  end;


function EditParams(Index : integer; var Params : TCylinderParams) : boolean;

implementation

{$R *.lfm}

var
  TCylindersSettingsForm: TTCylindersSettingsForm;

function EditParams(Index : integer; var Params : TCylinderParams) : boolean;
begin
  TCylindersSettingsForm:=TTCylindersSettingsForm.Create(Application);
  TCylindersSettingsForm.PanelTop.Caption:='Pneumatic Cylinders simulator - Module '+IntToStr(Index);
  try
    TCylindersSettingsForm.Params := Params;
    Result:=TCylindersSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=TCylindersSettingsForm.Params;
  finally
    TCylindersSettingsForm.Free;
  end;
end;

{ TTCylindersSettingsForm }

procedure TTCylindersSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TTCylindersSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTCylindersSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TTCylindersSettingsForm.FormCreate(Sender: TObject);
begin
  Captions[1]:=edCaption_1;
  Captions[2]:=edCaption_2;
  Captions[3]:=edCaption_3;
  Captions[4]:=edCaption_4;

  Stroke[1]:=speStroke_1;
  Stroke[2]:=speStroke_2;
  Stroke[3]:=speStroke_3;
  Stroke[4]:=speStroke_4;

  SpeedExtend[1]:=speSpeedE_1;
  SpeedExtend[2]:=speSpeedE_2;
  SpeedExtend[3]:=speSpeedE_3;
  SpeedExtend[4]:=speSpeedE_4;

  SpeedRetract[1]:=speSpeedR_1;
  SpeedRetract[2]:=speSpeedR_2;
  SpeedRetract[3]:=speSpeedR_3;
  SpeedRetract[4]:=speSpeedR_4;

  SpringReturn[1]:=cbType_1;
  SpringReturn[2]:=cbType_2;
  SpringReturn[3]:=cbType_3;
  SpringReturn[4]:=cbType_4;

  HasExtended[1]:=cbESensor_1;
  HasExtended[2]:=cbESensor_2;
  HasExtended[3]:=cbESensor_3;
  HasExtended[4]:=cbESensor_4;

  HasRetracted[1]:=cbRSensor_1;
  HasRetracted[2]:=cbRSensor_2;
  HasRetracted[3]:=cbRSensor_3;
  HasRetracted[4]:=cbRSensor_4;

  InitialPosition[1]:=cbInitPos_1;
  InitialPosition[2]:=cbInitPos_2;
  InitialPosition[3]:=cbInitPos_3;
  InitialPosition[4]:=cbInitPos_4;

end;

procedure TTCylindersSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TTCylindersSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TTCylindersSettingsForm.CheckSettings: boolean;
begin
  if (speReadReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TTCylindersSettingsForm.ParamsToForm;
Var
  c : integer;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  cbCyNumber.ItemIndex:=Params.CyAmount-1;
  for c:=1 to 4 do
  begin
    Captions[c].Text:=Params.CY[c].Caption;
    Stroke[c].Value:=Params.CY[c].Stroke;
    SpeedExtend[c].Value:=Params.CY[c].SpeedExtend;
    SpeedRetract[c].Value:=Params.CY[c].SpeedRetract;
    SpringReturn[c].ItemIndex:=integer(Params.CY[c].SpringReturn);
    HasExtended[c].ItemIndex:=Integer(Params.CY[c].HasExtended);
    HasRetracted[c].ItemIndex:=Integer(Params.CY[c].HasRetracted);
    InitialPosition[c].ItemIndex:=ord(Params.CY[c].InitialPosition);
  end;
end;

procedure TTCylindersSettingsForm.FormToParams;
Var
  c : integer;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.CyAmount:=cbCyNumber.ItemIndex+1;
  for c:=1 to 4 do
  begin
    Params.CY[c].Caption:=Captions[c].Text;
    Params.CY[c].Stroke:=Stroke[c].Value;
    Params.CY[c].SpeedExtend:=SpeedExtend[c].Value;
    Params.CY[c].SpeedRetract:=SpeedRetract[c].Value;
    Params.CY[c].SpringReturn:=boolean(SpringReturn[c].ItemIndex);
    Params.CY[c].HasExtended:=boolean(HasExtended[c].ItemIndex);
    Params.CY[c].HasRetracted:=boolean(HasRetracted[c].ItemIndex);
    Params.CY[c].InitialPosition:=TInitialPosition(InitialPosition[c].ItemIndex);
  end;

end;

end.


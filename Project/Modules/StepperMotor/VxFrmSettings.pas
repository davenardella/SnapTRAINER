unit VxFrmSettings;

{$mode DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, atshapelinebgra, VxFrmModule, VxUtils;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbMechanics: TComboBox;
    cbPulseRev: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Img_mm: TImage;
    Label1: TLabel;
    Label9: TLabel;
    lblKTrans: TLabel;
    lblMin: TLabel;
    Label10: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label22: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblMax: TLabel;
    lblError: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Panel1: TPanel;
    pnl_mm: TPanel;
    PanelTop: TPanel;
    ShapeLineBGRA1: TShapeLineBGRA;
    ShapeLineBGRA2: TShapeLineBGRA;
    ShapeLineBGRA3: TShapeLineBGRA;
    ShapeLineBGRA4: TShapeLineBGRA;
    ShapeLineBGRA5: TShapeLineBGRA;
    ShapeLineBGRA6: TShapeLineBGRA;
    ShapeLineBGRA7: TShapeLineBGRA;
    speCtrl_Reg: TSpinEdit;
    speScrewPitch: TFloatSpinEdit;
    speSetPos_Reg: TSpinEdit;
    speCurPos_Reg: TSpinEdit;
    speScrewLength: TFloatSpinEdit;
    speStatus_Reg: TSpinEdit;
    speSpeed_Reg: TSpinEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbMechanicsCloseUp(Sender: TObject);
    procedure cbPulseRevCloseUp(Sender: TObject);
    procedure cbResolverBitsCloseUp(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure speScrewLengthEditingDone(Sender: TObject);
  private
    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
    procedure UpdateValues;
  protected
    Params : TMotorParams;
  public
  end;


function EditParams(Index : integer; var Params : TMotorParams) : boolean;

implementation
Const
  PulseRevs : array[0..4] of integer = (64, 200, 400, 800, 1000);
{$R *.lfm}

var
  SettingsForm: TSettingsForm;

function EditParams(Index : integer; var Params : TMotorParams) : boolean;
begin
  SettingsForm:=TSettingsForm.Create(Application);
  SettingsForm.PanelTop.Caption:='Stepper Motor - Module '+IntToStr(Index);
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

procedure TSettingsForm.cbMechanicsCloseUp(Sender: TObject);
begin
  pnl_mm.Visible  :=cbMechanics.ItemIndex=1;
  Img_mm.Visible  :=cbMechanics.ItemIndex=1;
end;

procedure TSettingsForm.cbPulseRevCloseUp(Sender: TObject);
begin
  UpdateValues;
end;

procedure TSettingsForm.cbResolverBitsCloseUp(Sender: TObject);
begin
  UpdateValues;
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

procedure TSettingsForm.Label3Click(Sender: TObject);
begin

end;

procedure TSettingsForm.speScrewLengthEditingDone(Sender: TObject);
begin
  UpdateValues;
end;

function TSettingsForm.CheckSettings: boolean;
begin
  if (speStatus_Reg.Value = speCurPos_Reg.Value) then
  begin
    lblError.Caption:='Write Registers must be different';
    Result:=false;
    exit;
  end;

  Result:=true;
end;

procedure TSettingsForm.ParamsToForm;

  function PulseRevIndex(PR : integer) : integer;
  begin
    for Result:=0 to High(PulseRevs) do
      if PulseRevs[Result]=PR then
        exit;
    Result:=1;
  end;

begin
  speSpeed_Reg.Value :=Params.Speed_Reg;
  speCtrl_Reg.Value  :=Params.Ctrl_Reg;
  speSetPos_Reg.Value:=Params.SetPos_Reg;
  speStatus_Reg.Value:=Params.Status_Reg;
  speCurPos_Reg.Value:=Params.CurPos_Reg;
  speScrewLength.Value:=Params.ScrewLength;
  speScrewPitch.Value:=Params.ScrewPitch;
  cbPulseRev.ItemIndex:=PulseRevIndex(Params.MotorPulseRev);
  cbMechanics.ItemIndex:=ord(Params.Mechanics);
  UpdateValues;
end;

procedure TSettingsForm.FormToParams;
begin
  Params.Speed_Reg :=speSpeed_Reg.Value;
  Params.Ctrl_Reg  :=speCtrl_Reg.Value;
  Params.SetPos_Reg:=speSetPos_Reg.Value;
  Params.Status_Reg:=speStatus_Reg.Value;
  Params.CurPos_Reg:=speCurPos_Reg.Value;
  Params.ScrewLength:=speScrewLength.Value;
  Params.ScrewPitch:=speScrewPitch.Value;
  Params.MotorPulseRev:=PulseRevs[cbPulseRev.ItemIndex];
  Params.Mechanics:=TMechanics(cbMechanics.ItemIndex);
end;

procedure TSettingsForm.UpdateValues;
Var
  Delta,k : double;
begin
  pnl_mm.Visible  :=cbMechanics.ItemIndex=1;
  Delta:=speScrewLength.Value/10;
  lblMin.Caption:='-'+FloatStr(Delta,2)+' mm';
  lblMax.Caption:=FloatStr(speScrewLength.Value-Delta,2)+' mm';
  K:=PulseRevs[cbPulseRev.ItemIndex]/speScrewPitch.Value;
  lblKTrans.Caption:=format('K Transmission = %s (step/mm)',[FloatStr(k,3)]);
end;

end.


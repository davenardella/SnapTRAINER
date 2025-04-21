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
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Img_mm: TImage;
    Label18: TLabel;
    Label20: TLabel;
    lblMin: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label22: TLabel;
    Label3: TLabel;
    lblMax: TLabel;
    lblError: TLabel;
    Label12: TLabel;
    Panel1: TPanel;
    pnl_mm: TPanel;
    PanelTop: TPanel;
    Shape1: TShape;
    ShapeLineBGRA1: TShapeLineBGRA;
    ShapeLineBGRA2: TShapeLineBGRA;
    ShapeLineBGRA3: TShapeLineBGRA;
    speCtrl_Reg: TSpinEdit;
    speCurPos_Reg: TSpinEdit;
    speSetPos_Reg: TSpinEdit;
    speScrewLength: TFloatSpinEdit;
    speSpeedSet: TSpinEdit;
    speStatus_Reg: TSpinEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbMechanicsCloseUp(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
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
  SettingsForm.PanelTop.Caption:='Simple Motor - Module '+IntToStr(Index);
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
  pnl_mm.Visible  :=cbMechanics.ItemIndex=0;
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
  if (speStatus_Reg.Value = speCurPos_Reg.Value) then
  begin
    lblError.Caption:='Write Registers must be different';
    Result:=false;
    exit;
  end;

  Result:=true;
end;

procedure TSettingsForm.ParamsToForm;
begin
  speCtrl_Reg.Value  :=Params.Ctrl_Reg;
  speSetPos_Reg.Value:=Params.SetPos_Reg;
  speStatus_Reg.Value:=Params.Status_Reg;
  speCurPos_Reg.Value:=Params.CurPos_Reg;
  speSpeedSet.Value  :=Params.SpeedSet;
  speScrewLength.Value:=Params.ScrewLength;
  cbMechanics.ItemIndex:=ord(Params.Mechanics);
  pnl_mm.Visible  :=cbMechanics.ItemIndex=0;
end;

procedure TSettingsForm.FormToParams;
begin
  Params.Ctrl_Reg  :=speCtrl_Reg.Value;
  Params.SetPos_Reg:=speSetPos_Reg.Value;
  Params.Status_Reg:=speStatus_Reg.Value;
  Params.CurPos_Reg:=speCurPos_Reg.Value;
  Params.SpeedSet  :=speSpeedSet.Value;
  Params.ScrewLength:=round(speScrewLength.Value);
  Params.Mechanics:=TMechanics(cbMechanics.ItemIndex);
end;

end.


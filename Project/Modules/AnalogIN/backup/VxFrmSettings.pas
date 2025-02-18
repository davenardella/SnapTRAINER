unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, Buttons, BCButton, VxFrmModule, SpinEx,
  TAGraph, TASeries;

type

  { TAINSettingsForm }

  TAINSettingsForm = class(TForm)
    BtnRecalc_1: TBCButton;
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    BtnRecalc_2: TBCButton;
    Chart_1: TChart;
    Chart_2: TChart;
    EdUmis_2: TEdit;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Series_1: TLineSeries;
    EdUmis_1: TEdit;
    Series_2: TLineSeries;
    spePrecision_2: TSpinEdit;
    speScopeMax_2: TFloatSpinEdit;
    speWriteReg_2: TSpinEdit;
    speX1_1: TFloatSpinEdit;
    speX1_2: TFloatSpinEdit;
    speScopeMax_1: TFloatSpinEdit;
    speY1_1: TFloatSpinEdit;
    speX2_1: TFloatSpinEdit;
    Label1: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblError: TLabel;
    PC: TPageControl;
    Panel1: TPanel;
    PanelTop: TPanel;
    speWriteReg_1: TSpinEdit;
    speX2_2: TFloatSpinEdit;
    spePrecision_1: TSpinEdit;
    speY1_2: TFloatSpinEdit;
    speY2_1: TFloatSpinEdit;
    speY2_2: TFloatSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure BtnRecalc_1Click(Sender: TObject);
    procedure BtnRecalc_2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure spePrecision_1Change(Sender: TObject);
    procedure spePrecision_2Change(Sender: TObject);
  private
    function CheckSettings_1 : boolean;
    function CheckSettings_2 : boolean;
    function CheckSettings : boolean;
    procedure Recalc_1;
    procedure Recalc_2;
    procedure ParamsToForm;
    procedure FormToParams_1;
    procedure FormToParams_2;
    procedure FormToParams;
  protected
    Params : TAnalogInputParams;
  public
  end;


function EditParams(Index : integer; var Params : TAnalogInputParams) : boolean;

implementation

{$R *.lfm}

var
  AINSettingsForm: TAINSettingsForm;

function EditParams(Index : integer; var Params : TAnalogInputParams) : boolean;
begin
  AINSettingsForm:=TAINSettingsForm.Create(Application);
  AINSettingsForm.PanelTop.Caption:='Analog IN - Module '+IntToStr(Index);
  try
    AINSettingsForm.Params := Params;
    Result:=AINSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=AINSettingsForm.Params;
  finally
    AINSettingsForm.Free;
  end;
end;

{ TAINSettingsForm }

procedure TAINSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TAINSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAINSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAINSettingsForm.BtnRecalc_1Click(Sender: TObject);
begin
  Recalc_1;
end;

procedure TAINSettingsForm.BtnRecalc_2Click(Sender: TObject);
begin
  Recalc_2;
end;

procedure TAINSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TAINSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TAINSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
  Recalc_1;
  Recalc_2;
  PC.ActivePageIndex:=0;
end;

procedure TAINSettingsForm.spePrecision_1Change(Sender: TObject);
begin
  speY1_1.DecimalPlaces:=spePrecision_1.Value;
  speY2_1.DecimalPlaces:=spePrecision_1.Value;
end;

procedure TAINSettingsForm.spePrecision_2Change(Sender: TObject);
begin
  speY1_2.DecimalPlaces:=spePrecision_2.Value;
  speY2_2.DecimalPlaces:=spePrecision_2.Value;
end;

function TAINSettingsForm.CheckSettings_1: boolean;
begin
  if speX1_1.Value>speX2_1.Value then
  begin
    lblError.Caption:='X2 must be greater then X1';
    PC.ActivePageIndex:=0;
    Result:=false;
    exit;
  end;

  if Round(speX1_1.Value)=Round(speX2_1.Value) then
  begin
    lblError.Caption:='X1 and X2 must be different';
    PC.ActivePageIndex:=0;
    Result:=false;
    exit;
  end;

  lblError.Caption:='';
  Result:=true;
end;

function TAINSettingsForm.CheckSettings_2: boolean;
begin
  if speX1_2.Value>speX2_2.Value then
  begin
    lblError.Caption:='X2 must be greater then X1';
    PC.ActivePageIndex:=1;
    Result:=false;
    exit;
  end;

  if Round(speX1_2.Value)=Round(speX2_2.Value) then
  begin
    lblError.Caption:='X1 and X2 must be different';
    PC.ActivePageIndex:=1;
    Result:=false;
    exit;
  end;

  lblError.Caption:='';
  Result:=true;
end;

function TAINSettingsForm.CheckSettings: boolean;
begin
  if (speWriteReg_1.Value = speWriteReg_2.Value) then
  begin
    Result:=MessageDlg('Warning','You are using the same register for both channels. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes;
    if not Result then
      exit;
  end;
  Result:=CheckSettings_1 and CheckSettings_2;
end;

procedure TAINSettingsForm.Recalc_1;
Var
  TenPercent : double;
  Min,Max    : double;
begin
  Series_1.Clear;
  if not CheckSettings_1 then
    exit;
  FormToParams_1;
  Series_1.AddXY(Params.CH[1].X1,Params.CH[1].Y1);
  Series_1.AddXY(Params.CH[1].X2,Params.CH[1].Y2);
  TenPercent:=(Params.CH[1].X2-Params.CH[1].X1)/10;
  Min:=Params.CH[1].X1-TenPercent;
  Max:=Params.CH[1].X2+TenPercent;
  Chart_1.BottomAxis.Range.Min:=Min;
  Chart_1.BottomAxis.Range.Max:=Max;
  TenPercent:=(Params.CH[1].Y2-Params.CH[1].Y1)/10;
  Min:=Params.CH[1].Y1-TenPercent;
  Max:=Params.CH[1].Y2+TenPercent;
  Chart_1.LeftAxis.Range.Min:=Min;
  Chart_1.LeftAxis.Range.Max:=Max;
  Chart_1.ZoomFull(true);
end;

procedure TAINSettingsForm.Recalc_2;
Var
  TenPercent : double;
  Min,Max    : double;
begin
  Series_2.Clear;
  if not CheckSettings_2 then
    exit;
  FormToParams_2;
  Series_2.AddXY(Params.CH[2].X1,Params.CH[2].Y1);
  Series_2.AddXY(Params.CH[2].X2,Params.CH[2].Y2);
  TenPercent:=(Params.CH[2].X2-Params.CH[2].X1)/10;
  Min:=Params.CH[2].X1-TenPercent;
  Max:=Params.CH[2].X2+TenPercent;
  Chart_2.BottomAxis.Range.Min:=Min;
  Chart_2.BottomAxis.Range.Max:=Max;
  TenPercent:=(Params.CH[2].Y2-Params.CH[2].Y1)/10;
  Min:=Params.CH[2].Y1-TenPercent;
  Max:=Params.CH[2].Y2+TenPercent;
  Chart_2.LeftAxis.Range.Min:=Min;
  Chart_2.LeftAxis.Range.Max:=Max;
  Chart_2.ZoomFull(true);
end;

procedure TAINSettingsForm.ParamsToForm;
begin
  speWriteReg_1.Value:=Params.CH[1].Register;
  EdUmis_1.Text:=Params.CH[1].Umis;
  spePrecision_1.Value:=Params.CH[1].Precision;
  speX1_1.Value:=Params.CH[1].X1;
  speY1_1.Value:=Params.CH[1].Y1;
  speX2_1.Value:=Params.CH[1].X2;
  speY2_1.Value:=Params.CH[1].Y2;
  speScopeMax_1.Value:=Params.CH[1].ScopeMax;
  speY1_1.DecimalPlaces:=Params.CH[1].Precision;
  speY2_1.DecimalPlaces:=Params.CH[1].Precision;

  speWriteReg_2.Value:=Params.CH[2].Register;
  EdUmis_2.Text:=Params.CH[2].Umis;
  spePrecision_2.Value:=Params.CH[2].Precision;
  speX1_2.Value:=Params.CH[2].X1;
  speY1_2.Value:=Params.CH[2].Y1;
  speX2_2.Value:=Params.CH[2].X2;
  speY2_2.Value:=Params.CH[2].Y2;
  speScopeMax_2.Value:=Params.CH[2].ScopeMax;
  speY1_2.DecimalPlaces:=Params.CH[2].Precision;
  speY2_2.DecimalPlaces:=Params.CH[2].Precision;
end;

procedure TAINSettingsForm.FormToParams_1;
begin
  Params.CH[1].Register:=speWriteReg_1.Value;
  Params.CH[1].Umis:=EdUmis_1.Text;
  Params.CH[1].Precision:=spePrecision_1.Value;
  Params.CH[1].X1:=speX1_1.Value;
  Params.CH[1].Y1:=speY1_1.Value;
  Params.CH[1].X2:=speX2_1.Value;
  Params.CH[1].Y2:=speY2_1.Value;
  Params.CH[1].ScopeMax:=speScopeMax_1.Value;
end;

procedure TAINSettingsForm.FormToParams_2;
begin
  Params.CH[2].Register:=speWriteReg_2.Value;
  Params.CH[2].Umis:=EdUmis_2.Text;
  Params.CH[2].Precision:=spePrecision_2.Value;
  Params.CH[2].X1:=speX1_2.Value;
  Params.CH[2].Y1:=speY1_2.Value;
  Params.CH[2].X2:=speX2_2.Value;
  Params.CH[2].Y2:=speY2_2.Value;
  Params.CH[2].ScopeMax:=speScopeMax_2.Value;
end;

procedure TAINSettingsForm.FormToParams;
begin
  FormToParams_1;
  FormToParams_2;
end;

end.


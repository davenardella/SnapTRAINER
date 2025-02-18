unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, Buttons, BCButton, VxFrmModule, SpinEx,
  TAGraph, TASeries;

type

  { TAOUTSettingsForm }

  TAOUTSettingsForm = class(TForm)
    BtnRecalc_1: TBCButton;
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    BtnRecalc_2: TBCButton;
    Chart_1: TChart;
    Chart_2: TChart;
    ChWriteFast_1: TCheckBox;
    ChWriteFast_2: TCheckBox;
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
    Label7: TLabel;
    Label8: TLabel;
    Series_1: TLineSeries;
    EdUmis_1: TEdit;
    Series_2: TLineSeries;
    spePrecision_2: TSpinEdit;
    speSafeValue_2: TFloatSpinEdit;
    speWriteReg_2: TSpinEdit;
    speX1_1: TFloatSpinEdit;
    speX1_2: TFloatSpinEdit;
    speSafeValue_1: TFloatSpinEdit;
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
    Params : TAnalogOutputParams;
  public
  end;


function EditParams(Index : integer; var Params : TAnalogOutputParams) : boolean;

implementation

{$R *.lfm}

var
  AOUTSettingsForm: TAOUTSettingsForm;

function EditParams(Index : integer; var Params : TAnalogOutputParams) : boolean;
begin
  AOUTSettingsForm:=TAOUTSettingsForm.Create(Application);
  AOUTSettingsForm.PanelTop.Caption:='Analog OUT - Module '+IntToStr(Index);
  try
    AOUTSettingsForm.Params := Params;
    Result:=AOUTSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=AOUTSettingsForm.Params;
  finally
    AOUTSettingsForm.Free;
  end;
end;

{ TAOUTSettingsForm }

procedure TAOUTSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TAOUTSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAOUTSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAOUTSettingsForm.BtnRecalc_1Click(Sender: TObject);
begin
  Recalc_1;
end;

procedure TAOUTSettingsForm.BtnRecalc_2Click(Sender: TObject);
begin
  Recalc_2;
end;

procedure TAOUTSettingsForm.FormCreate(Sender: TObject);
begin
end;

procedure TAOUTSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TAOUTSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
  Recalc_1;
  Recalc_2;
  PC.ActivePageIndex:=0;
end;

procedure TAOUTSettingsForm.spePrecision_1Change(Sender: TObject);
begin
  speX1_1.DecimalPlaces:=spePrecision_1.Value;
  speX2_1.DecimalPlaces:=spePrecision_1.Value;
  speSafeValue_1.DecimalPlaces:=spePrecision_1.Value;
end;

procedure TAOUTSettingsForm.spePrecision_2Change(Sender: TObject);
begin
  speX1_2.DecimalPlaces:=spePrecision_2.Value;
  speX2_2.DecimalPlaces:=spePrecision_2.Value;
  speSafeValue_2.DecimalPlaces:=spePrecision_2.Value;
end;

function TAOUTSettingsForm.CheckSettings_1: boolean;
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

  if (speSafeValue_1.Value<speX1_1.Value) or (speSafeValue_1.Value>speX2_1.Value) then
  begin
    lblError.Caption:='Safe Value must be inside the range [X1, X2]';
    PC.ActivePageIndex:=0;
    Result:=false;
    exit;
  end;

  lblError.Caption:='';
  Result:=true;
end;

function TAOUTSettingsForm.CheckSettings_2: boolean;
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

  if (speSafeValue_2.Value<speX1_2.Value) or (speSafeValue_2.Value>speX2_2.Value) then
  begin
    lblError.Caption:='Safe Value must be inside the range [X1, X2]';
    PC.ActivePageIndex:=1;
    Result:=false;
    exit;
  end;

  lblError.Caption:='';
  Result:=true;
end;

function TAOUTSettingsForm.CheckSettings: boolean;
begin
  if (speWriteReg_1.Value = speWriteReg_2.Value) then
  begin
    lblError.Caption:='Registers must be different';
    Result:=false;
    exit;
  end;
  Result:=CheckSettings_1 and CheckSettings_2;
end;

procedure TAOUTSettingsForm.Recalc_1;
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

procedure TAOUTSettingsForm.Recalc_2;
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

procedure TAOUTSettingsForm.ParamsToForm;
begin
  speWriteReg_1.Value:=Params.CH[1].Register;
  ChWriteFast_1.Checked:=Params.CH[1].FastWrite;
  EdUmis_1.Text:=Params.CH[1].Umis;
  spePrecision_1.Value:=Params.CH[1].Precision;
  speX1_1.Value:=Params.CH[1].X1;
  speY1_1.Value:=Params.CH[1].Y1;
  speX2_1.Value:=Params.CH[1].X2;
  speY2_1.Value:=Params.CH[1].Y2;
  speSafeValue_1.Value:=Params.CH[1].SafeValue;
  speX1_1.DecimalPlaces:=Params.CH[1].Precision;
  speX2_1.DecimalPlaces:=Params.CH[1].Precision;
  speSafeValue_1.DecimalPlaces:=Params.CH[1].Precision;

  speWriteReg_2.Value:=Params.CH[2].Register;
  ChWriteFast_2.Checked:=Params.CH[2].FastWrite;
  EdUmis_2.Text:=Params.CH[2].Umis;
  spePrecision_2.Value:=Params.CH[2].Precision;
  speX1_2.Value:=Params.CH[2].X1;
  speY1_2.Value:=Params.CH[2].Y1;
  speX2_2.Value:=Params.CH[2].X2;
  speY2_2.Value:=Params.CH[2].Y2;
  speSafeValue_2.Value:=Params.CH[2].SafeValue;
  speX1_2.DecimalPlaces:=Params.CH[2].Precision;
  speX2_2.DecimalPlaces:=Params.CH[2].Precision;
  speSafeValue_2.DecimalPlaces:=Params.CH[2].Precision;
end;

procedure TAOUTSettingsForm.FormToParams_1;
begin
  Params.CH[1].Register:=speWriteReg_1.Value;
  Params.CH[1].FastWrite:=ChWriteFast_1.Checked;
  Params.CH[1].Umis:=EdUmis_1.Text;
  Params.CH[1].Precision:=spePrecision_1.Value;
  Params.CH[1].X1:=speX1_1.Value;
  Params.CH[1].Y1:=speY1_1.Value;
  Params.CH[1].X2:=speX2_1.Value;
  Params.CH[1].Y2:=speY2_1.Value;
  Params.CH[1].SafeValue:=speSafeValue_1.Value;
end;

procedure TAOUTSettingsForm.FormToParams_2;
begin
  Params.CH[2].Register:=speWriteReg_2.Value;
  Params.CH[2].FastWrite:=ChWriteFast_2.Checked;
  Params.CH[2].Umis:=EdUmis_2.Text;
  Params.CH[2].Precision:=spePrecision_2.Value;
  Params.CH[2].X1:=speX1_2.Value;
  Params.CH[2].Y1:=speY1_2.Value;
  Params.CH[2].X2:=speX2_2.Value;
  Params.CH[2].Y2:=speY2_2.Value;
  Params.CH[2].SafeValue:=speSafeValue_2.Value;
end;

procedure TAOUTSettingsForm.FormToParams;
begin
  FormToParams_1;
  FormToParams_2;
end;

end.


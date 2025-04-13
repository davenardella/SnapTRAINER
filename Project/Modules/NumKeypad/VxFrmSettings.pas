unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TNumericKeypadForm }

  TNumericKeypadForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label14: TLabel;
    Label4: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    rbInstant: TRadioButton;
    rbNumeric: TRadioButton;
    rbSigned: TRadioButton;
    rbUnsigned: TRadioButton;
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
    Params : TNumKeypadParams;
  public
  end;


function EditParams(Index : integer; var Params : TNumKeypadParams) : boolean;

implementation

{$R *.lfm}

var
  NumericKeypadForm: TNumericKeypadForm;

function EditParams(Index : integer; var Params : TNumKeypadParams) : boolean;
begin
  NumericKeypadForm:=TNumericKeypadForm.Create(Application);
  NumericKeypadForm.PanelTop.Caption:='Numeric Keypad - Module '+IntToStr(Index);
  try
    NumericKeypadForm.Params := Params;
    Result:=NumericKeypadForm.ShowModal = mrOk;
    if Result then
      Params:=NumericKeypadForm.Params;
  finally
    NumericKeypadForm.Free;
  end;
end;

{ TNumericKeypadForm }

procedure TNumericKeypadForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TNumericKeypadForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TNumericKeypadForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TNumericKeypadForm.FormCreate(Sender: TObject);
begin
end;

procedure TNumericKeypadForm.FormDestroy(Sender: TObject);
begin
end;

procedure TNumericKeypadForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TNumericKeypadForm.CheckSettings: boolean;
begin
  Result:=true;
end;

procedure TNumericKeypadForm.ParamsToForm;
begin
  speWriteReg.Value:=Params.Output_Reg;
  rbInstant.Checked:=Params.Instant;
  rbNumeric.Checked:=not Params.Instant;

  rbSigned.Checked:=Params.NumericSigned;
  rbUnsigned.Checked:=not Params.NumericSigned;
end;

procedure TNumericKeypadForm.FormToParams;
begin
  Params.Output_Reg:=speWriteReg.Value;
  Params.Instant:=rbInstant.Checked;
  Params.NumericSigned:=rbSigned.Checked;
end;

end.


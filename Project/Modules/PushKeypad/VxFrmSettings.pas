unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, VxFrmModule;

type

  { TPushKeypadForm }

  TPushKeypadForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    ChWriteFast: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
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
    Params : TPushKeypadParams;
  public
  end;


function EditParams(Index : integer; var Params : TPushKeypadParams) : boolean;

implementation

{$R *.lfm}

var
  PushKeypadForm: TPushKeypadForm;

function EditParams(Index : integer; var Params : TPushKeypadParams) : boolean;
begin
  PushKeypadForm:=TPushKeypadForm.Create(Application);
  PushKeypadForm.PanelTop.Caption:='Push Keypad - Module '+IntToStr(Index);
  try
    PushKeypadForm.Params := Params;
    Result:=PushKeypadForm.ShowModal = mrOk;
    if Result then
      Params:=PushKeypadForm.Params;
  finally
    PushKeypadForm.Free;
  end;
end;

{ TPushKeypadForm }

procedure TPushKeypadForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TPushKeypadForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TPushKeypadForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TPushKeypadForm.FormCreate(Sender: TObject);
begin
end;

procedure TPushKeypadForm.FormDestroy(Sender: TObject);
begin
end;

procedure TPushKeypadForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

function TPushKeypadForm.CheckSettings: boolean;
begin
  if (speReadReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TPushKeypadForm.ParamsToForm;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  ChWriteFast.Checked:=Params.FastWrite;
end;

procedure TPushKeypadForm.FormToParams;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  Params.FastWrite:=ChWriteFast.Checked;
end;

end.


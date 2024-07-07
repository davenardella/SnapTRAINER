unit VxFrmSettings;

{$mode DELPHI}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, BCButton, BCPanel, uESelector, VxFrmModule;

type

  { TControllerSettingsForm }

  TControllerSettingsForm = class(TForm)
    cbColor_Led_1: TComboBox;
    cbColor_Led_2: TComboBox;
    cbMode_1: TComboBox;
    cbMode_2: TComboBox;
    cbMode_3: TComboBox;
    cbMode_4: TComboBox;
    edCaption_Led_1: TEdit;
    edCaption_Led_2: TEdit;
    EdSelector: TEdit;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label22: TLabel;
    Label23: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Mushroom: TBCButton;
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    cbColor_2: TComboBox;
    cbColor_3: TComboBox;
    cbColor_4: TComboBox;
    cbColor_1: TComboBox;
    cbNegated: TCheckBox;
    edCaption_1: TEdit;
    edCaption_2: TEdit;
    edCaption_3: TEdit;
    edCaption_4: TEdit;
    EdSel_1: TEdit;
    EdSel_2: TEdit;
    EdSel_3: TEdit;
    EdMushroom: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    lblIndex: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label26: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    lblError: TLabel;
    Panel1: TPanel;
    PanelTop: TPanel;
    pnlChannel9: TBCPanel;
    rbShowSelector: TRadioButton;
    rbShowLeds: TRadioButton;
    Selector: TuESelector;
    speReadReg: TSpinEdit;
    speWriteReg: TSpinEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SelectorChange(Sender: TObject);
  private
    SelCaptions  : array[1..3] of TEdit;
    BtnCaptions  : array[1..4] of TEdit;
    ButtonColors : array[1..4] of TComboBox;
    ButtonModes  : array[1..4] of TComboBox;
    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
  protected
    Params : TKeypadParams;
  public
  end;


function EditParams(Index : integer; var Params : TKeypadParams) : boolean;

implementation

{$R *.lfm}

var
  ControllerSettingsForm: TControllerSettingsForm;

function EditParams(Index : integer; var Params : TKeypadParams) : boolean;
begin
  ControllerSettingsForm:=TControllerSettingsForm.Create(Application);
  ControllerSettingsForm.PanelTop.Caption:='Control Keypad - Module '+IntToStr(Index);
  try
    ControllerSettingsForm.Params := Params;
    Result:=ControllerSettingsForm.ShowModal = mrOk;
    if Result then
      Params:=ControllerSettingsForm.Params;
  finally
    ControllerSettingsForm.Free;
  end;
end;


{ TTCylindersSettingsForm }

procedure TControllerSettingsForm.btnAcceptClick(Sender: TObject);
begin
  if CheckSettings then
  begin
    FormToParams;
    ModalResult:=mrOK;
  end;
end;

procedure TControllerSettingsForm.btnBackClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TControllerSettingsForm.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TControllerSettingsForm.FormCreate(Sender: TObject);
begin
  Mushroom.StateClicked.Assign(Mushroom.StateNormal);
  Mushroom.StateHover.Assign(Mushroom.StateNormal);

  BtnCaptions[1]:=edCaption_1;
  BtnCaptions[2]:=edCaption_2;
  BtnCaptions[3]:=edCaption_3;
  BtnCaptions[4]:=edCaption_4;

  SelCaptions[1]:=EdSel_1;
  SelCaptions[2]:=EdSel_2;
  SelCaptions[3]:=EdSel_3;

  ButtonColors[1]:=cbColor_1;
  ButtonColors[2]:=cbColor_2;
  ButtonColors[3]:=cbColor_3;
  ButtonColors[4]:=cbColor_4;


  ButtonModes[1]:=cbMode_1;
  ButtonModes[2]:=cbMode_2;
  ButtonModes[3]:=cbMode_3;
  ButtonModes[4]:=cbMode_4;
end;

procedure TControllerSettingsForm.FormDestroy(Sender: TObject);
begin
end;

procedure TControllerSettingsForm.FormShow(Sender: TObject);
begin
  lblError.Caption:='';
  Position:=poWorkAreaCenter;
  ParamsToForm;
end;

procedure TControllerSettingsForm.SelectorChange(Sender: TObject);
begin
  lblIndex.Caption:=IntToStr(Selector.Index + 1);
end;

function TControllerSettingsForm.CheckSettings: boolean;

begin
  if (speReadReg.Value = speWriteReg.Value) then
    Result:=MessageDlg('Warning','You are using the same register for Read and Write. Do you confirm the chosen?',mtWarning,[mbYes, mbCancel],0) = mrYes
  else
    Result:=true;
end;

procedure TControllerSettingsForm.ParamsToForm;
Var
  c : integer;
begin
  speReadReg.Value:=Params.Input_Reg;
  speWriteReg.Value:=Params.Output_Reg;
  for c:=1 to 4 do
  begin
    BtnCaptions[c].Text:=Params.BTN[c].Caption;
    ButtonColors[c].ItemIndex:=ord(Params.BTN[c].Color);
    ButtonModes[c].ItemIndex :=ord(Params.BTN[c].Mode);
  end;
  EdSelector.Text:=Params.SelLabel;
  for c:=1 to 3 do
    SelCaptions[c].Text:=Params.SelCaption[c];
  Selector.Index:=Params.SelInit-1;
  EdMushroom.Caption:=Params.MushCaption;
  cbNegated.Checked:=Params.MushroomNC;


  cbColor_Led_1.ItemIndex:=ord(Params.LED[1].Color);
  edCaption_Led_1.Text:=Params.LED[1].Caption;
  cbColor_Led_2.ItemIndex:=ord(Params.LED[2].Color);
  edCaption_Led_2.Text:=Params.LED[2].Caption;

  rbShowSelector.Checked:=Params.ShowSelector;
  rbShowLeds.Checked:=not Params.ShowSelector;
end;

procedure TControllerSettingsForm.FormToParams;
Var
  c : integer;
begin
  Params.Input_Reg:=speReadReg.Value;
  Params.Output_Reg:=speWriteReg.Value;
  for c:=1 to 4 do
  begin
    Params.BTN[c].Caption:=BtnCaptions[c].Text;
    Params.BTN[c].Color:=TLightButtonColor(ButtonColors[c].ItemIndex);
    Params.BTN[c].Mode:=TButtonMode(ButtonModes[c].ItemIndex);
  end;
  Params.SelLabel:=EdSelector.Text;
  for c:=1 to 3 do
    Params.SelCaption[c]:=SelCaptions[c].Text;

  Params.LED[1].Color:=TLightButtonColor(cbColor_Led_1.ItemIndex);
  Params.LED[1].Caption:=edCaption_Led_1.Text;
  Params.LED[2].Color:=TLightButtonColor(cbColor_Led_2.ItemIndex);
  Params.LED[2].Caption:=edCaption_Led_2.Text;
  Params.ShowSelector:=rbShowSelector.Checked;

  Params.SelInit:=Selector.Index+1;
  Params.MushCaption:=EdMushroom.Caption;
  Params.MushroomNC:=cbNegated.Checked;
end;

end.


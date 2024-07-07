unit VxFrmSettings;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Spin, Grids, BCButton, BCPanel, BCTypes, VxFrmModule;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    btnCancel: TBCButton;
    btnAccept: TBCButton;
    btnBack: TBCButton;
    ColorButton_1: TColorButton;
    ColorButton_2: TColorButton;
    cbTextAlign_1: TComboBox;
    cbTextAlign_2: TComboBox;
    Grid_1: TStringGrid;
    Grid_2: TStringGrid;
    Label1: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblError: TLabel;
    PC: TPageControl;
    Panel1: TPanel;
    PanelTop: TPanel;
    speReadReg: TSpinEdit;
    speTextHeight_1: TSpinEdit;
    speTextHeight_2: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Grid_1EditingDone(Sender: TObject);
    procedure Grid_1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid_2EditingDone(Sender: TObject);
    procedure Grid_2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    Buffer : array[1..256] of string;
    SelStart : integer;
    SelCount : integer;
    function CheckSettings : boolean;
    procedure ParamsToForm;
    procedure FormToParams;
    function Del(Grid : TStringGrid) : boolean;
    function Ctrl_A(Grid : TStringGrid) : boolean;
    function Ctrl_C(Grid : TStringGrid) : boolean;
    function Ctrl_V(Grid : TStringGrid) : boolean;
  protected
    Params : TTextParams;
  public
  end;


function EditParams(Index : integer; var Params : TTextParams) : boolean;

implementation

{$R *.lfm}

var
  SettingsForm: TSettingsForm;

function EditParams(Index : integer; var Params : TTextParams) : boolean;
begin
  SettingsForm:=TSettingsForm.Create(Application);
  SettingsForm.PanelTop.Caption:='Text Display - Module '+IntToStr(Index);
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

procedure TSettingsForm.FormCreate(Sender: TObject);
Var
  c : integer;
begin
  for c:=0 to 255 do
  begin
    Grid_1.Cells[0,c+1]:=intToStr(c);
    Grid_2.Cells[0,c+1]:=intToStr(c);
  end;
  Grid_1.Cells[0,0]:='Code';
  Grid_2.Cells[0,0]:='Code';
  PC.ActivePageIndex:=0;
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

procedure TSettingsForm.Grid_1EditingDone(Sender: TObject);
begin
  if Grid_1.Row<257 then
    Grid_1.Row:=Grid_1.Row+1;
end;

procedure TSettingsForm.Grid_1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Del
  if (Key = 46) then
  begin
    if Del(Grid_1) then
      Key:=0;
  end;

  // Ctrl-A
  if (Key = 65) and (Shift = [ssCtrl]) then
  begin
    Ctrl_A(Grid_1);
    Key:=0;
  end;

  // Ctrl-C
  if (Key = 67) and (Shift = [ssCtrl]) then
  begin
    if Ctrl_C(Grid_1) then
      Key:=0;
  end;

  // Ctrl-V
  if (Key = 86) and (Shift = [ssCtrl]) then
  begin
    if Ctrl_V(Grid_1) then
      Key:=0;
  end;
end;

procedure TSettingsForm.Grid_2EditingDone(Sender: TObject);
begin
  if Grid_2.Row<257 then
    Grid_2.Row:=Grid_2.Row+1;
end;

procedure TSettingsForm.Grid_2KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Del
  if (Key = 46) then
  begin
    if Del(Grid_2) then
      Key:=0;
  end;

  // Ctrl-A
  if (Key = 65) and (Shift = [ssCtrl]) then
  begin
    Ctrl_A(Grid_2);
    Key:=0;
  end;

  // Ctrl-C
  if (Key = 67) and (Shift = [ssCtrl]) then
  begin
    if Ctrl_C(Grid_2) then
      Key:=0;
  end;

  // Ctrl-V
  if (Key = 86) and (Shift = [ssCtrl]) then
  begin
    if Ctrl_V(Grid_2) then
      Key:=0;
  end;

end;

function TSettingsForm.CheckSettings: boolean;
begin
  Result:=true;
end;

procedure TSettingsForm.ParamsToForm;
Var
  c : integer;
begin
  speReadReg.Value:=Params.Input_Reg;
  for c:=0 to 255 do
  begin
    Grid_1.Cells[1,c+1]:=Params.T[1].Text[c];
    Grid_2.Cells[1,c+1]:=Params.T[2].Text[c];
  end;

  ColorButton_1.ButtonColor:=Params.T[1].TextColor;
  speTextHeight_1.Value:=Params.T[1].TextHeight;
  cbTextAlign_1.ItemIndex:=ord(Params.T[1].TextAlignment);

  ColorButton_2.ButtonColor:=Params.T[2].TextColor;
  speTextHeight_2.Value:=Params.T[2].TextHeight;
  cbTextAlign_2.ItemIndex:=ord(Params.T[2].TextAlignment);
end;

procedure TSettingsForm.FormToParams;
Var
  c : integer;
begin
  Params.Input_Reg:=speReadReg.Value;
  for c:=0 to 255 do
  begin
    Params.T[1].Text[c]:=Grid_1.Cells[1,c+1];
    Params.T[2].Text[c]:=Grid_2.Cells[1,c+1];
  end;

  Params.T[1].TextColor:=ColorButton_1.ButtonColor;
  Params.T[1].TextHeight:=speTextHeight_1.Value;
  Params.T[1].TextAlignment:=TBCAlignment(cbTextAlign_1.ItemIndex);

  Params.T[2].TextColor:=ColorButton_2.ButtonColor;
  Params.T[2].TextHeight:=speTextHeight_2.Value;
  Params.T[2].TextAlignment:=TBCAlignment(cbTextAlign_2.ItemIndex);

end;

function TSettingsForm.Del(Grid: TStringGrid): boolean;
Var
  c, Delta : integer;
begin
  Delta:=Grid.Selection.Bottom-Grid.Selection.Top;
  if Delta<1 then
    exit(false);
  for c:=Grid.Selection.Top to Grid.Selection.Bottom-1 do
    Grid.Cells[1,c]:='';
  Result:=true;
end;

function TSettingsForm.Ctrl_A(Grid: TStringGrid): boolean;
Var
  GridRect : TGridRect;
begin
  GridRect.Top := 1;
  GridRect.Left := 1;
  GridRect.Right := 1;
  GridRect.Bottom := 256;
  Grid.Selection := GridRect;
end;

function TSettingsForm.Ctrl_C(Grid: TStringGrid): boolean;
Var
  c, y, Delta : integer;
begin
  Delta:=Grid.Selection.Bottom-Grid.Selection.Top;
  if Delta<1 then
    exit(false);
  Y:=1;
  for c:=Grid.Selection.Top to Grid.Selection.Bottom-1 do
  begin
    Buffer[y]:=Grid.Cells[1,c];
    inc(y);
  end;
  SelStart:=Grid.Selection.Top;
  SelCount:=Delta;
  Result:=true;
end;

function TSettingsForm.Ctrl_V(Grid: TStringGrid): boolean;
Var
  c : integer;
begin
  if SelCount<1 then
    exit(false);
  for c:=1 to SelCount do
  begin
    Grid.Cells[1,Grid.Row]:=Buffer[c];
    if Grid.Row=256 then
      exit(true);
    Grid.Row:=Grid.Row+1;
  end;
  Result:=true;
end;

end.


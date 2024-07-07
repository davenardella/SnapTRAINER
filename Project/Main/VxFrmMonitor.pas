unit VxFrmMonitor;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids, BCButton,
  VxController, SnapMB;

type

  { TCommMonitor }

  TCommMonitor = class(TForm)
    btnAccept: TBCButton;
    btnBack: TBCButton;
    btnOnTop: TBCButton;
    Panel1: TPanel;
    PanelTop: TPanel;
    Grid: TStringGrid;
    Timer: TTimer;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnOnTopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    Rebuilding : boolean;
    Controller: TCommController;
    procedure Rebuild;
  public
    procedure Start;
    procedure Stop;
  end;

var
  CommMonitor: TCommMonitor;

implementation
Uses
  VxFrmMain;
{$R *.lfm}

{ TCommMonitor }

procedure TCommMonitor.FormCreate(Sender: TObject);
begin
  Controller:=MainForm.CommController;
end;

procedure TCommMonitor.btnOnTopClick(Sender: TObject);
begin
  btnOnTop.Down:= not btnOnTop.Down;
  if btnOnTop.Down then
    FormStyle:=fsSystemStayOnTop
  else
    FormStyle:=fsNormal;
end;

procedure TCommMonitor.btnAcceptClick(Sender: TObject);
begin
  Close;
end;

procedure TCommMonitor.TimerTimer(Sender: TObject);

  procedure UpdateStatus;
  Var
    Row, C : integer;
    msg : string;
  begin
    Row:=1;
    for C:=0 to Controller.RD_RegCount-1 do
    begin
      if Controller.Connected then
      begin
        case Controller.RD_Registers[c].Status of
          rsUnknown : msg:='Unknown';
          rsOk      : msg:='OK';
          else
            msg:=Controller.ErrorText(Controller.RD_Registers[c].LastError);
        end;
      end
      else
        msg:='Controller not connected';
      Grid.Cells[4,Row]:=IntToHex(Controller.RD_Registers[c].Value,4);
      Grid.Cells[5,Row]:=msg;

      inc(Row);
    end;

    for C:=0 to Controller.WR_RegCount-1 do
    begin
      if Controller.Connected then
      begin
        case Controller.WR_Registers[c].Status of
          rsUnknown : msg:='Unknown';
          rsOk      : msg:='OK';
          else
            msg:=Controller.ErrorText(Controller.WR_Registers[c].LastError);
        end;
      end
      else
        msg:='Controller not connected';
      Grid.Cells[4,Row]:=IntToHex(Controller.WR_Registers[c].Value,4);
      Grid.Cells[5,Row]:=msg;
      inc(Row);
    end;
  end;


begin
  if Controller.Started then
  begin
    if Controller.Connected then
      PanelTop.Caption:='Communication - Active'
    else
      PanelTop.Caption:='Communication - Error'
  end
  else
    PanelTop.Caption:='Communication - Stopped';

  try
    UpdateStatus;
  except
  end;

end;

procedure TCommMonitor.Rebuild;
Var
  Row, C : integer;
begin
  Rebuilding:=true;
  Grid.RowCount:=Controller.RD_RegCount+Controller.WR_RegCount+1;
  Row:=1;
  for C:=0 to Controller.RD_RegCount-1 do
  begin
    Grid.Cells[1,Row]:=IntToStr(Controller.RD_Registers[c].Address);
    Grid.Cells[2,Row]:='R';
    Grid.Cells[3,Row]:='Cyclic';
    inc(Row);
  end;

  for C:=0 to Controller.WR_RegCount-1 do
  begin
    Grid.Cells[1,Row]:=IntToStr(Controller.WR_Registers[c].Address);
    Grid.Cells[2,Row]:='W';
    if Controller.WR_Registers[c].Fast then
      Grid.Cells[3,Row]:='Immediate'
    else
      Grid.Cells[3,Row]:='Cyclic';
    inc(Row);
  end;
  Rebuilding:=false;
end;

procedure TCommMonitor.Start;
begin
  Rebuild;
  Timer.Enabled:=true;
end;

procedure TCommMonitor.Stop;
begin
  Timer.Enabled:=false;
  Hide;
end;

end.


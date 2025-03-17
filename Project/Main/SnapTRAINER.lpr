program SnapTRAINER;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uecontrols, VxFrmMain, VxFrmMonitor, VxFrmAbout;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  VxFrmMain.CmdlineFilename:=ParamStr(1);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TCommMonitor, CommMonitor);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.Run;
end.


unit VxFrmAbout;

{$mode ObjFPC}{$H+}

interface

uses
  LclIntf, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  BCButton, BCRoundedImage, ueled;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    BCRoundedImage1: TBCRoundedImage;
    BCRoundedImage2: TBCRoundedImage;
    btnAccept: TBCButton;
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Shape1: TShape;
    uELED10: TuELED;
    uELED11: TuELED;
    uELED9: TuELED;
    procedure GitHubClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure LinkedinClick(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.btnAcceptClick(Sender: TObject);
begin
  Close;
end;

procedure TAboutForm.LinkedinClick(Sender: TObject);
begin
  OpenURL('https://www.linkedin.com/in/davidenardella');
end;

procedure TAboutForm.GitHubClick(Sender: TObject);
begin
  OpenURL('https://github.com/davenardella/SnapTRAINER');
end;

end.





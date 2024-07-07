unit VxFrmMain;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, IniFiles,
  ExtCtrls, Buttons, Menus, BCButton, ueled, VxModule, VxCommTypes,
  VxController;

Const
  MaxSlot    = 24;
  MaxModules = 64;

Const

  DefaultExt = '.str';
  CommSection='Communication';

  StartX = 18;
  StartY = 4;
  SpanX  = 514;
  SpanY  = 370;

type

  TModuleItem = record
    Name    : string;
    Caption : string;
  end;

  TRailSlot = record
    Module   : TVirtualModule;
    Button   : TBCButton;
    Modlabel : TLabel;
    Shape    : TShape;
    Left     : integer;
    Top      : integer;
  end;

  { TMainForm }

  TMainForm = class(TForm)
    AddModuleItem: TMenuItem;
    BtnMonitor: TBCButton;
    btnOnTop: TBCButton;
    btnPlay: TBCButton;
    btnAbout: TBCButton;
    BtnPlayImages: TImageList;
    btnSettings: TBCButton;
    ExchangeItem: TMenuItem;
    RenameItem: TMenuItem;
    ModMenuImages: TImageList;
    MainMenu: TPopupMenu;
    MainMenuImages: TImageList;
    MenuBtn: TBCButton;
    mnuExit: TMenuItem;
    mnuLoadProject: TMenuItem;
    mnuNewProject: TMenuItem;
    mnuCommSettings: TMenuItem;
    mnuSaveProject: TMenuItem;
    mnuSaveProjectAs: TMenuItem;
    ModMenu: TPopupMenu;
    OpenDialog: TOpenDialog;
    Panel2: TPanel;
    RailImage: TImageList;
    RemoveModuleItem: TMenuItem;
    SaveDialog: TSaveDialog;
    SB: TScrollBox;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Separator3: TMenuItem;
    SettingsItem: TMenuItem;
    procedure btnAboutClick(Sender: TObject);
    procedure BtnMonitorClick(Sender: TObject);
    procedure btnOnTopClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MainMenuPopup(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuLoadProjectClick(Sender: TObject);
    procedure mnuNewProjectClick(Sender: TObject);
    procedure mnuCommSettingsClick(Sender: TObject);
    procedure mnuSaveProjectAsClick(Sender: TObject);
    procedure mnuSaveProjectClick(Sender: TObject);
    procedure ModMenuPopup(Sender: TObject);
    procedure RemoveModuleItemClick(Sender: TObject);
    procedure RenameItemClick(Sender: TObject);
    procedure SettingsItemClick(Sender: TObject);
  private
    CommSettings     : TCommSettings;
    FChanged         : boolean;
    FRunning         : boolean;
    Slots            : array[1..MaxSlot] of TRailSlot;
    DinRails         : array[1..MaxSlot div 3] of TImage;
    Modules          : array[1..MaxModules] of TModuleItem;
    ModuleCount      : integer;
    CurrentIndex     : integer;
    ApplicationPath  : string;
    ModulesPath      : string;
    FDefaultFilename : string;
    FCurrentFilename : string;
    FWorkingDir      : string;
    FAppdataDir      : string;
    function CheckSave : boolean;
    function CheckSaveForExit : integer;
    function ModuleBusy : boolean;
    procedure MenuButtonMouseDown(Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure SetLastProject;
    procedure SetFChanged(AValue: boolean);
    procedure SetFCurrentFilename(AValue: string);
    procedure NewModule(Sender: TObject);
    procedure ExchangeSlot(Sender: TObject);
    procedure SetCaption;
    procedure InitCabinet;
    procedure InitModules;
    procedure InitFiles;
    procedure NewProject;
    procedure OpenProject;
    procedure CloseProject;
    procedure SaveProject;
    procedure SaveToFile;
    procedure LoadFromFile;
    procedure SaveProjectAs;
    procedure Start;
    procedure Stop;
  public
    CommController : TCommController;
    property ProjectChanged : boolean read FChanged write SetFChanged;
    property CurrentFilename : string read FCurrentFilename write SetFCurrentFilename;
  end;


var
  MainForm: TMainForm;

implementation
{$R *.lfm}
Uses
  VxCommSettings, VxFrmMonitor, VxFrmAbout, SnapMB, windirs;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitModules;
  SetDefaults(CommSettings);
  CommController:=VxController.ControllerCreate(CommSettings);
  InitCabinet;
  InitFiles;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not ModuleBusy then
  begin
    if FChanged then
      case CheckSaveForExit of
        mrCancel : CanClose:=false;
        mrYes : begin
          SaveProject;
          SetLastProject;
        end;
      end
  end
  else
    CanClose:=false;
end;

procedure TMainForm.BtnMonitorClick(Sender: TObject);
begin
  CommMonitor.Show;
end;

procedure TMainForm.btnAboutClick(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TMainForm.btnOnTopClick(Sender: TObject);
Var
  c : integer;
begin
  btnOnTop.Down:= not btnOnTop.Down;

  if btnOnTop.Down then
    FormStyle:=fsSystemStayOnTop
  else begin
    for c:=1 to MaxSlot do
      if Assigned(Slots[c].Module) then
        Slots[c].Module.BeginRefresh;

    FormStyle:=fsNormal;

    for c:=1 to MaxSlot do
      if Assigned(Slots[c].Module) then
        Slots[c].Module.EndRefresh;
  end;
end;

procedure TMainForm.btnPlayClick(Sender: TObject);
begin
  if not FRunning then
  begin
    if not ModuleBusy then
    begin
      if FChanged then
      begin
        if MessageDlg('Project changed','Do you want to save it before Run',mtConfirmation,[mbYes, mbNo],0)= mrYes then
          SaveProject;
      end;
      Start;
    end;
  end
  else
    Stop;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  CloseProject;
  VxController.ControllerDestroy;
end;

procedure TMainForm.MainMenuPopup(Sender: TObject);
Var
  c : integer;
begin
  if ModuleBusy then
  begin
    for c:=0 to MainMenu.items.Count-1 do
      MainMenu.Items[c].Visible:=false;
  end
  else
    for c:=0 to MainMenu.items.Count-1 do
      MainMenu.Items[c].Visible:=true;
end;

procedure TMainForm.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.mnuLoadProjectClick(Sender: TObject);
begin
  OpenProject;
end;

procedure TMainForm.mnuNewProjectClick(Sender: TObject);
begin
  if FChanged then
  begin
    if CheckSave then
      SaveProject;
  end;
  NewProject;
end;

procedure TMainForm.mnuCommSettingsClick(Sender: TObject);
begin
  if EditParams(CommSettings) then
  begin
    CommController.ChangeTo(CommSettings);
    ProjectChanged:=true;
  end;
end;

procedure TMainForm.mnuSaveProjectAsClick(Sender: TObject);
begin
  SaveProjectAs;
end;

procedure TMainForm.mnuSaveProjectClick(Sender: TObject);
begin
  if FChanged then
    SaveProject;
end;

procedure TMainForm.ModMenuPopup(Sender: TObject);
begin
  if ModuleBusy then
  begin
    RemoveModuleItem.Visible:=false;
    AddModuleItem.Visible:=false;
    ExchangeItem.Visible:=false;
    RenameItem.Visible:=false;
    SettingsItem.Visible:=false;
    exit;
  end;

  if CurrentIndex in [1..MaxSlot] then
  begin
    if Assigned(Slots[CurrentIndex].Module) then
    begin
      RemoveModuleItem.Visible:=true;
      AddModuleItem.Visible:=false;
      ExchangeItem.Visible:=true;
      RenameItem.Visible:=true;
      SettingsItem.Visible:=true;
    end
    else begin
      RemoveModuleItem.Visible:=false;
      AddModuleItem.Visible:=true;
      ExchangeItem.Visible:=false;
      RenameItem.Visible:=false;
      SettingsItem.Visible:=false;
    end;
  end
  else begin
    AddModuleItem.Visible:=false;
    ExchangeItem.Visible:=false;
    RenameItem.Visible:=false;
    SettingsItem.Visible:=false;
  end;

end;

procedure TMainForm.RemoveModuleItemClick(Sender: TObject);
begin
  if Assigned(Slots[CurrentIndex].Module) then
  begin
    Slots[CurrentIndex].Module.Free;
    Slots[CurrentIndex].Module:=nil;
    ProjectChanged:=true;
  end;
end;

procedure TMainForm.RenameItemClick(Sender: TObject);
Var
  OldCaption : string;
  NewCaption : string;
begin
  if Assigned(Slots[CurrentIndex].Module) then
  begin
    OldCaption:=Slots[CurrentIndex].Module.ModuleCaption;
    NewCaption:=InputBox('Change Caption','New Caption',OldCaption);
    if NewCaption<>OldCaption then
    begin
      Slots[CurrentIndex].Module.ModuleCaption:=NewCaption;
      ProjectChanged:=true;
    end;
  end;
end;

procedure TMainForm.SettingsItemClick(Sender: TObject);
begin
  if (CurrentIndex in [1..MaxSlot]) and Assigned(Slots[CurrentIndex].Module) then
    if Slots[CurrentIndex].Module.Edit then
      ProjectChanged:=true;
 end;

function TMainForm.CheckSave: boolean;
begin
  Result:=MessageDlg('Project changed','Do you want to save current Project',mtConfirmation,[mbYes, mbNo],0)= mrYes;
end;

function TMainForm.CheckSaveForExit: integer;
begin
  Result := MessageDlg('Project changed','Do you want to save current Project',mtConfirmation,[mbYes, mbNo, mbCancel],0);
end;

function TMainForm.ModuleBusy: boolean;
Var
  c : integer;
begin
  Result:=false;
  for c:=1 to MaxSlot do
    if Assigned(Slots[c].Module) then
      if Slots[c].Module.Busy then
      begin
        messagedlg('Warning','The Module at Slot '+IntToStr(c)+' has the Setting form active. Close it first.',mtWarning,[mbOk],0);
        exit(true);
      end;
end;

procedure TMainForm.MenuButtonMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  CurrentIndex:=(Sender as TComponent).Tag;
end;

procedure TMainForm.SetLastProject;
Var
  ini : TMemIniFile;
  FileName : string;
begin
  FileName:=FAppdatadir+StringReplace(ExtractFileName(Application.ExeName),'.exe','.ini',[rfIgnoreCase]);
  ini:=TMemIniFile.Create(FileName);
  try
    try
      ini.WriteString('General','LastProject',FCurrentFileName);
      ini.UpdateFile;;
    except
    end;
  finally
    ini.Free;
  end;
end;

procedure TMainForm.SetCaption;
begin
  if FChanged then
    Caption:='*'+FCurrentFilename
  else
    Caption:=FCurrentFilename;
end;

procedure TMainForm.NewModule(Sender: TObject);
Var
  index : integer;
  Item : TMenuItem;
  NewCaption : string;
begin
  Item:=TMenuItem(Sender);
  Index:=Item.Tag;
  NewCaption:=Item.Caption;
  Slots[CurrentIndex].Module:=TVirtualModule.Create(Self, CurrentIndex, SB, Slots[CurrentIndex].Left, Slots[CurrentIndex].Top, Modules[Index].Name,'',NewCaption);
  NewCaption:=InputBox('Assign Caption','Caption',NewCaption);
  Slots[CurrentIndex].Module.ModuleCaption:=NewCaption;
  ProjectChanged:=true;
end;

procedure TMainForm.ExchangeSlot(Sender: TObject);
Var
  TargetIndex : integer;
  SourceIndex : integer;
  TempModule  : TVirtualModule;
begin
  SourceIndex:=CurrentIndex;
  TargetIndex:=(Sender as TComponent).Tag;
  if not (SourceIndex in[1..MaxSlot]) or not (TargetIndex in[1..MaxSlot]) or (SourceIndex = TargetIndex) then
    exit;
  // <- Here Slots[SourceIndex] exists
  if Assigned(Slots[TargetIndex].Module) then
  begin
    TempModule:=Slots[TargetIndex].Module;
    Slots[SourceIndex].Module.MoveTo(TargetIndex, Slots[TargetIndex].Left, Slots[TargetIndex].Top);
    Slots[TargetIndex].Module:=Slots[SourceIndex].Module;
    TempModule.MoveTo(SourceIndex, Slots[SourceIndex].Left, Slots[SourceIndex].Top);
    Slots[SourceIndex].Module:=TempModule;
  end
  else begin
    Slots[SourceIndex].Module.MoveTo(TargetIndex, Slots[TargetIndex].Left, Slots[TargetIndex].Top);
    Slots[TargetIndex].Module:=Slots[SourceIndex].Module;
    Slots[SourceIndex].Module:=nil;
  end;
  ProjectChanged:=true;
end;

procedure TMainForm.InitCabinet;
Var
  C,X,Y,Z : integer;
  Item : TMenuItem;
begin
  Position:=poScreenCenter;
  Width:=1625;
  Height:=793;
  fillchar(Slots, SizeOf(Slots), #0);

  X:=StartX;
  Y:=StartY;
  Z:=1;
  for c:=1 to MaxSlot do
  begin
    Slots[c].Left:=X;
    Slots[c].Top :=Y+23;

    Slots[c].Button:=TBCButton.Create(Self);
    Slots[c].Button.Assign(MenuBtn);
    Slots[c].Button.Glyph.Assign(MenuBtn.Glyph);
    Slots[c].Button.Tag :=C;
    Slots[c].Button.OnMouseDown:=MenuButtonMouseDown;
    Slots[c].Button.DropDownMenu:=ModMenu;
    Slots[c].Button.SetBounds(X,Y,MenuBtn.Width,MenuBtn.Height);
    Slots[c].Button.Parent:=SB;

    Slots[c].Modlabel:=TLabel.Create(Self);
    Slots[c].Modlabel.AutoSize:=false;
    Slots[c].Modlabel.Alignment:=taCenter;
    Slots[c].Modlabel.Caption:='SLOT '+IntToStr(c);
    Slots[c].Modlabel.Font.Name:='Segoe UI';
    Slots[c].Modlabel.Font.Size:= 20;
    Slots[c].Modlabel.Font.Style:=[fsBold];
    Slots[c].Modlabel.Font.Quality:=fqCleartypeNatural;
    Slots[c].Modlabel.Font.Color:=clGray;
    Slots[c].Modlabel.SetBounds(X,Y+56,486,32);
    Slots[c].Modlabel.Parent:=SB;

    Slots[c].Shape:=TShape.Create(Self);
    Slots[c].Shape.Brush.Style:=bsClear;
    Slots[c].Shape.Pen.Color:=clGray;
    Slots[c].Shape.Pen.Style:=psDash;
    Slots[c].Shape.Pen.Width:=3;
    Slots[c].Shape.Shape:=stRectangle;
    Slots[c].Shape.SetBounds(X,Y+23,486,338);
    Slots[c].Shape.Parent:=SB;

    X:=X+SpanX;
    if (c mod 3) = 0 then
    begin
      DinRails[Z]:=TImage.Create(self);
      DinRails[Z].AutoSize:=false;
      DinRails[Z].Stretch:=false;
      DinRails[Z].Images:=RailImage;
      DinRails[Z].ImageIndex:=0;
      DinRails[Z].SetBounds(0,Y+132,1600,118);
      DinRails[Z].Parent:=SB;
      DinRails[Z].SendToBack;
      X:=StartX;
      Y:=Y+SpanY;
    end;

    Item:=TMenuItem.Create(ExchangeItem);
    Item.Caption:=IntToStr(c);
    Item.Tag:=c;
    Item.OnClick:=ExchangeSlot;
    ExchangeItem.Add(Item);
  end;
end;

procedure TMainForm.InitModules;
Var
  ini  : TMemIniFile;
  Item : TMenuItem;
  Done : boolean;
  ConfigFilename : string;
  ModuleName : string;
  Section    : string;
begin
  ApplicationPath:=ExtractFileDir(Application.ExeName)+'\';
  ModulesPath:=ApplicationPath+'Modules\';
  ConfigFilename:=StringReplace(Application.ExeName,'.exe','.ini',[rfIgnoreCase]);
  if not FileExists(ConfigFileName) then
  begin
    MessageDlg('Fatal Error',ConfigFilename+' not found.',mtError,[MbOk],0);
    Application.Terminate;
  end;
  ModuleCount:=0;
  Done := false;
  ini:=TMemIniFile.Create(ConfigFilename);
  try
    repeat
      Section:='MODULE_'+IntToStr(ModuleCount+1);
      Done:=not ini.SectionExists(Section);
      if not Done then
      begin
        inc(ModuleCount);
        ModuleName:=ini.ReadString(Section,'Name','');
        if Trim(ModuleName)<>'' then
        begin
          Modules[ModuleCount].Name:=ModulesPath+ModuleName;
          Modules[ModuleCount].Caption:=ini.ReadString(Section,'Caption',ModuleName);
          Item:=TMenuItem.Create(AddModuleItem);
          Item.Caption:=Modules[ModuleCount].Caption;
          Item.ImageIndex:=4;
          Item.Tag:=ModuleCount;
          Item.OnClick:=NewModule;
          AddModuleItem.Add(Item);
        end
        else
          Done:=true;
      end;
    until Done;
  finally
    ini.Free;
  end;
  Caption:=ConfigFilename;
end;

procedure TMainForm.InitFiles;
Var
  AppName : string;
  FDocDir : string;

  function GetLastProject : string;
  Var
    ini : TMemIniFile;
  begin
    ini:=TMemIniFile.Create(FAppdataDir+AppName+'.ini');
    try
      Result:=ini.ReadString('General','LastProject',FDefaultFileName);
    finally
      ini.Free;
    end;
  end;

begin
  AppName:=StringReplace(ExtractFileName(Application.ExeName),'.exe','',[rfIgnoreCase]);
  FDocDir:=GetWindowsSpecialDir(CSIDL_PERSONAL);
  FWorkingDir:=GetWindowsSpecialDir(CSIDL_PERSONAL)+AppName+'\';
  FAppdataDir:=GetWindowsSpecialDir(CSIDL_LOCAL_APPDATA)+AppName+'\';

  if not DirectoryExists(FWorkingDir) then
    if not CreateDir(FWorkingDir) then
      FWorkingDir:=FDocDir;

  if not DirectoryExists(FAppdataDir) then
    if not CreateDir(FAppdataDir) then
      FAppdataDir:=FDocDir;

  FDefaultFilename:=FWorkingDir+'Project1'+DefaultExt;
  CurrentFilename:=GetLastProject;

  if FCurrentFilename <> FDefaultFilename then
  begin
    FWorkingDir:=IncludeTrailingPathDelimiter(ExtractFilePath(FCurrentFilename));
  end;

  if FileExists(FCurrentFilename) then
    LoadFromFile;
end;

procedure TMainForm.NewProject;
begin
  CloseProject;
  CurrentFilename:=FDefaultFilename;
end;

procedure TMainForm.OpenProject;
begin
  if FChanged and CheckSave then
  begin
    SaveProject;
    SetLastProject;
  end;
  OpenDialog.InitialDir:=FWorkingDir;
  if OpenDialog.Execute then
  begin
    CloseProject;
    CurrentFilename:=OpenDialog.FileName;
    LoadFromFile;
    SetLastProject;
  end;
end;

procedure TMainForm.CloseProject;
Var
  c : integer;
begin
  for c:=1 to MaxSlot do
    if Assigned(Slots[c].Module) then
    begin
      Slots[c].Module.Free;
      Slots[c].Module:=nil;
    end;
end;

procedure TMainForm.SaveProject;
begin
  if FCurrentFilename=FDefaultFilename then
    SaveProjectAs
  else
    SaveToFile;
end;

procedure TMainForm.SaveToFile;
Var
  ini : TMemIniFile;
  c : integer;
begin
  ini:=TMemIniFile.Create(FCurrentFilename);
  try
    ini.Clear;
    // Common
    ini.WriteInteger(CommSection,'Mode',ord(CommSettings.Mode));
    ini.WriteBool(CommSection,'UseInputRegs',CommSettings.UseInputRegs);
    ini.WriteInteger(CommSection,'ClientType',ord(CommSettings.ProtocolType));
    ini.WriteInteger(CommSection,'UnitID_DB',CommSettings.UnitID_DB);
    ini.WriteInteger(CommSection,'RefreshInterval',CommSettings.RefreshInterval);
    ini.WriteBool(CommSection,'DisOnError',CommSettings.DisOnError);
    // Modbus/TCP
    ini.WriteString(CommSection,'MBTCPParams.Address',CommSettings.MBTCPParams.Address);
    ini.WriteInteger(CommSection,'MBTCPParams.Port',CommSettings.MBTCPParams.Port);
    // Modbus/RTU
    ini.ReadString(CommSection,'MBRTUParams.Port',CommSettings.MBRTUParams.Port);
    ini.ReadInteger(CommSection,'MBRTUParams.BaudRate',CommSettings.MBRTUParams.BaudRate);
    ini.WriteString(CommSection,'MBRTUParams.Parity',CommSettings.MBRTUParams.Parity);
    ini.WriteInteger(CommSection,'MBRTUParams.DataBits',CommSettings.MBRTUParams.DataBits);
    ini.WriteInteger(CommSection,'MBRTUParams.StopBits',CommSettings.MBRTUParams.StopBits);
    ini.WriteInteger(CommSection,'MBRTUParams.Flow',ord(CommSettings.MBRTUParams.Flow));
    // S7
    ini.WriteString(CommSection,'S7ISOParams.Address',CommSettings.S7ISOParams.Address);
    ini.WriteInteger(CommSection,'S7ISOParams.Rack',CommSettings.S7ISOParams.Rack);
    ini.WriteInteger(CommSection,'S7ISOParams.Slot',CommSettings.S7ISOParams.Slot);
    ini.WriteInteger(CommSection,'S7ISOParams.ConnectionType',CommSettings.S7ISOParams.ConnectionType);
    ini.UpdateFile;
  finally
    ini.Free;
  end;
  for c:=1 to MaxSlot do
    if Assigned(Slots[c].Module) then
      Slots[c].Module.SaveToFile(FCurrentFilename);
  ProjectChanged:=false;
end;

procedure TMainForm.LoadFromFile;
Var
  ini      : TMemIniFile;
  c        : integer;
  Section  : string;
  ModName  : string;
  ModCap   : string;
  FileName : string;
  Error    : boolean;

  Procedure ReadCommParams;
  begin
    // Common
    CommSettings.Mode:=TControllerMode(ini.ReadInteger(CommSection,'Mode',ord(CommSettings.Mode)));
    CommSettings.UseInputRegs:=ini.ReadBool(CommSection,'UseInputRegs',CommSettings.UseInputRegs);
    CommSettings.ProtocolType:=TProtocolType(ini.ReadInteger(CommSection,'ClientType',ord(CommSettings.ProtocolType)));
    CommSettings.UnitID_DB:=ini.ReadInteger(CommSection,'UnitID_DB',CommSettings.UnitID_DB);
    CommSettings.RefreshInterval:=ini.ReadInteger(CommSection,'RefreshInterval',CommSettings.RefreshInterval);
    CommSettings.DisOnError:=ini.ReadBool(CommSection,'DisOnError',CommSettings.DisOnError);
    // Modbus/TCP
    CommSettings.MBTCPParams.Address:=ini.ReadString(CommSection,'MBTCPParams.Address',CommSettings.MBTCPParams.Address);
    CommSettings.MBTCPParams.Port:=ini.ReadInteger(CommSection,'MBTCPParams.Port',CommSettings.MBTCPParams.Port);
    // Modbus/RTU
    CommSettings.MBRTUParams.Port:=ini.ReadString(CommSection,'MBRTUParams.Port',CommSettings.MBRTUParams.Port);
    CommSettings.MBRTUParams.BaudRate:=ini.ReadInteger(CommSection,'MBRTUParams.BaudRate',CommSettings.MBRTUParams.BaudRate);
    CommSettings.MBRTUParams.Parity:=ini.ReadString(CommSection,'MBRTUParams.Parity',CommSettings.MBRTUParams.Parity)[1];
    CommSettings.MBRTUParams.DataBits:=ini.ReadInteger(CommSection,'MBRTUParams.DataBits',CommSettings.MBRTUParams.DataBits);
    CommSettings.MBRTUParams.StopBits:=ini.ReadInteger(CommSection,'MBRTUParams.StopBits',CommSettings.MBRTUParams.StopBits);
    CommSettings.MBRTUParams.Flow:=TMBSerialFlow(ini.ReadInteger(CommSection,'MBRTUParams.Flow',ord(CommSettings.MBRTUParams.Flow)));
    // S7
    CommSettings.S7ISOParams.Address:=ini.ReadString(CommSection,'S7ISOParams.Address',CommSettings.S7ISOParams.Address);
    CommSettings.S7ISOParams.Rack:=ini.ReadInteger(CommSection,'S7ISOParams.Rack',CommSettings.S7ISOParams.Rack);
    CommSettings.S7ISOParams.Slot:=ini.ReadInteger(CommSection,'S7ISOParams.Slot',CommSettings.S7ISOParams.Slot);
    CommSettings.S7ISOParams.ConnectionType:=ini.ReadInteger(CommSection,'S7ISOParams.ConnectionType',CommSettings.S7ISOParams.ConnectionType);

    CommController.ChangeTo(CommSettings);
  end;

begin
  ini:=TMemIniFile.Create(FCurrentFilename);
  c:=1;
  Error:=false;
  try
    while (c<=MaxSlot) and not Error do
    begin
      Section:='SLOT_'+IntToStr(c);
      if ini.SectionExists(Section) then
      begin
        ModName:=ini.ReadString(Section,'ModuleName','');
        ModCap :=ini.ReadString(Section,'ModuleCaption','');
        FileName:=ModulesPath+ModName;
        Slots[c].Module:=TVirtualModule.Create(Self,C,SB,Slots[c].Left,Slots[c].Top,FileName,FCurrentFilename, ModCap)
      end;
      inc(c);
    end;
    if not Error then
      ReadCommParams;
  finally
    ini.Free;
  end;
end;

procedure TMainForm.SaveProjectAs;
begin
  SaveDialog.InitialDir:=FWorkingDir;
  if SaveDialog.Execute then
  begin
    CurrentFilename:=SaveDialog.FileName;
    SetLastProject;
    SaveToFile;
  end;
end;

procedure TMainForm.Start;

  function SomeModules : boolean;
  Var
    c : integer;
  begin
    Result:=true;
    for c:=1 to MaxSlot do
      if Assigned(Slots[c].Module) then
        exit;
    Result:=false;
  end;

  procedure StartError;
  begin
    if CommSettings.ProtocolType=ctMBTCP then
      MessageDlg('Communication Error','The Device cannot bind the address '+ CommSettings.MBTCPParams.Address, mtError, [mbOk], 0)
    else
      MessageDlg('Communication Error','The Device cannot bind the port '+ CommSettings.MBRTUParams.Port, mtError, [mbOk], 0)
  end;

  function OffendingWriteRegister(idx : integer): integer;
  Var
    S : string;
  begin
    for Result:=0 to CommController.WR_RegCount-1 do
      if CommController.WR_Registers[Result].LastError=RegCollision then
      begin
        S:=Format('The module in Slot %d referenced the already used Write register %d',[idx, CommController.WR_Registers[Result].Address]);
        MessageDlg('Error',S, mtError, [mbOk], 0);
        exit;
      end;
    Result:=-1;
  end;

Var
  c : integer;

begin
  if not FRunning and SomeModules then
  begin
    CommController.Clear;
    for c:=1 to MaxSlot do
      if Assigned(Slots[c].Module) then
      begin
        Slots[c].Module.PreStart;
        if OffendingWriteRegister(c)<>-1 then
          exit;
      end;

    if CommController.Start then
    begin
      for c:=1 to MaxSlot do
        if Assigned(Slots[c].Module) then
          Slots[c].Module.Start;

      for c:=1 to SB.ControlCount-1 do
        if SB.Controls[c].InheritsFrom(TBCButton) or (SB.Controls[c].InheritsFrom(TLabel) and (SB.Controls[c].Owner=Self)) or SB.Controls[c].InheritsFrom(TShape) then
          SB.Controls[c].Visible:=false;

      btnPlay.ImageIndex:=1;
      btnSettings.Enabled:=false;
      BtnMonitor.Visible:=true;
      CommMonitor.Start;
      FRunning:=true;
    end
    else
      StartError;
  end;
end;

procedure TMainForm.Stop;
Var
  c : integer;
begin
  if FRunning then
  begin
    CommMonitor.Stop;
    for c:=1 to MaxSlot do
      if Assigned(Slots[c].Module) then
        Slots[c].Module.Stop;

    CommController.Stop;

    for c:=1 to SB.ControlCount-1 do
      SB.Controls[c].Visible:=true;

    btnPlay.ImageIndex:=0;
    btnSettings.Enabled:=true;
    btnMonitor.Visible:=false;
    FRunning:=false;
  end;
end;

procedure TMainForm.SetFChanged(AValue: boolean);
begin
  if FChanged<>AValue then
  begin
    FChanged:=AValue;
    SetCaption;
  end;
end;

procedure TMainForm.SetFCurrentFilename(AValue: string);
begin
  if FCurrentFilename<>AValue then
  begin
    FCurrentFilename:=AValue;
    SetCaption;
  end;
end;


begin

end.


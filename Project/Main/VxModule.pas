unit VxModule;

{$MODE DELPHI}

interface

uses
  Windows, Classes, SysUtils, StdCtrls, IniFiles, Controls, Graphics, BCTypes, BCPanel,
  VxTypes, VxController;

Const
  DefaultWidth  = 488;
  DefaultHeight = 338;
  PadX          = 4;
  PadY          = 4;
  DefaultColor  = $00555555;

Type

  TModuleCreate   = function(index: integer; PHooks : PHooksRecord; AModuleName, AFileName: PChar; Var Handle : THandle): integer; stdcall;
  TModuleDestroy  = procedure(UID : integer); stdcall;
  TModuleNewindex = procedure(UID, NewIndex : integer); stdcall;
  TModuleStart    = procedure(UID : integer); stdcall;
  TModuleStop     = procedure(UID : integer); stdcall;
  TModulePrestart = procedure(UID : integer); stdcall;
  TModuleSave     = procedure(UID : integer; AFileName: PChar); stdcall;
  TModuleEdit     = function(UID : integer) : integer; stdcall;
  TModuleBusy     = function : integer; stdcall;

  { TVirtualModule }

  TVirtualModule = class(TBCPanel)
  private
    FModuleCaption : string;
    FUID           : integer;
    FIndex         : integer;
    HLib           : THandle;
    HModule        : THandle;
    LblInstance    : TLabel;
    // Module wrappers
    ModuleCreate   : TModuleCreate;
    ModuleDestroy  : TModuleDestroy;
    ModuleNewindex : TModuleNewindex;
    ModuleStart    : TModuleStart;
    ModuleStop     : TModuleStop;
    ModulePrestart : TModulePrestart;
    ModuleSave     : TModuleSave;
    ModuleEdit     : TModuleEdit;
    ModuleBusy     : TModuleBusy;
    function GetFBusy: boolean;
    procedure SetAspect(AParent : TWinControl; X, Y : integer);
    function LoadModule(ModuleFilename, ProjectFilename : string) : integer;
    procedure SetFModuleCaption(AValue: string);
  public
    constructor Create(AOwner : TComponent; Index : integer; AParent : TWinControl; X, Y : integer;
      ModuleFilename, ProjectFilename, AModuleCaption : string); reintroduce;
    destructor Destroy; override;
    procedure PreStart;
    procedure Start;
    procedure Stop;
    procedure BeginRefresh;
    procedure EndRefresh;
    function Edit : boolean;
    procedure SaveToFile(FileName : string);
    procedure MoveTo(NewIndex, NewLeft, NewTop : integer);
    property Busy : boolean read GetFBusy;
    property ModuleCaption : string read FModuleCaption write SetFModuleCaption;
  end;


implementation

Const
  _errModNotFound = 1;
  _errDLLLoad     = 2;
  _errDLLProc     = 3;
  _errTooManyMod  = 4;


{ TVirtualModule }

procedure TVirtualModule.SetAspect(AParent: TWinControl; X, Y: integer);
begin
  // Aspect
  Caption:='';
  BevelInner:=bvNone;
  BevelOuter:=bvNone;
  Border.Style:=bboSolid;
  Border.Color:=clBlack;
  BorderBCStyle:=bpsBorder;
  Color:=AParent.Color;
  FontEx.Color:=$004080FF;
  FontEx.Height:=20;
  FontEx.Style:=[fsBold];
  FontEx.SingleLine:=false;
  FontEx.WordBreak:=true;
  Background.Color:=DefaultColor;
  Rounding.RoundX:=10;
  Rounding.RoundY:=10;
  SetBounds(X, Y, DefaultWidth, DefaultHeight);
  Parent:=AParent;
end;

function TVirtualModule.GetFBusy: boolean;
begin
  Result:=false;
  if (FUID<>-1) and Assigned(ModuleStart) then
  begin
    try
      Result:=ModuleBusy<>0;
    except
    end;
  end;
end;

function TVirtualModule.LoadModule(ModuleFilename, ProjectFilename: string
  ): integer;
Var
  Hooks : THooksRecord;
  ModuleName : string;
  Error : boolean;

  function GPA(H : TLibHandle; ProcName : AnsiString) : pointer;
  begin
    Result:=GetProcedureAddress(H, ProcName);
    if not Assigned(Result) then
      Error:=true;
  end;

begin
  Result:=0;
  Error :=false;
  // Comm methods (must be win32 stdcall plain functions)
  Hooks.CommRegisterRead     :=@VxController.CommRegisterRead;
  Hooks.CommRegisterWrite    :=@VxController.CommRegisterWrite;
  Hooks.CommRegisterFastWrite:=@VxController.CommRegisterFastWrite;
  Hooks.CommReadRegisterAdd  :=@VxController.CommReadRegisterAdd;
  Hooks.CommWriteRegisterAdd :=@VxController.CommWriteRegisterAdd;
  Hooks.CommRegisterStatus   :=@VxController.CommRegisterStatus;
  // Library
  ModuleName:=ExtractFileName(ModuleFilename);
  if FileExists(ModuleFilename) then
  begin
    HLib:=LoadLibrary(PChar(ModuleFilename));
    if HLib<>nilHandle then
    begin
      ModuleCreate   :=GPA(HLib,'module_create');
      ModuleDestroy  :=GPA(HLib,'module_destroy');
      ModuleNewindex :=GPA(HLib,'module_newindex');
      ModuleStart    :=GPA(HLib,'module_start');
      ModuleStop     :=GPA(HLib,'module_stop');
      ModulePrestart :=GPA(HLib,'module_prestart');
      ModuleSave     :=GPA(HLib,'module_save');
      ModuleEdit     :=GPA(HLib,'module_edit');
      ModuleBusy     :=GPA(HLib,'module_busy');
      if not Error then
      begin
        try
          FUID:=ModuleCreate(FIndex, @Hooks, pchar(ModuleName), pchar(ProjectFilename),HModule);
        except
          FUID:=-1;
        end;
        if FUID<>-1 then
        begin
          Windows.SetParent(HModule, Self.Handle);
          SetWindowPos(HModule,0,PadX,PadY,0,0,SWP_NOSIZE+SWP_NOZORDER);
          ShowWindow(HModule, SW_SHOW);
        end
        else
          Result:=_errTooManyMod;
      end
      else
        Result:=_errDLLProc;
    end
    else
      Result:=_errDLLLoad;
  end
  else
    Result:=_errModNotFound;
end;

procedure TVirtualModule.SetFModuleCaption(AValue: string);
begin
  if FModuleCaption<>AValue then
  begin
    FModuleCaption:=AValue;
    LblInstance.Caption:=FModuleCaption;
  end;
end;

constructor TVirtualModule.Create(AOwner: TComponent; Index: integer;
  AParent: TWinControl; X, Y: integer; ModuleFilename, ProjectFilename,
  AModuleCaption: string);
Var
  ErrorCode : integer;
begin
  inherited Create(AOwner);
  FModuleCaption:=AModuleCaption;

  LblInstance:=TLabel.Create(Self);
  LblInstance.AutoSize:=false;
  LblInstance.Alignment:=taRightJustify;
  LblInstance.Font.Name:='Segoe UI';
  LblInstance.Font.Size:=12;
  LblInstance.Font.Color:=clGray;
  LblInstance.Font.Quality:=fqCleartypeNatural;
  LblInstance.Font.Style:=[fsBold];

  LblInstance.SetBounds(X+30, Y-22, DefaultWidth-38, 22);
  LblInstance.Caption:=FModuleCaption;
  LblInstance.Parent:=AParent;
  LblInstance.Visible:=true;

  FIndex:=Index;
  HLib :=nilHandle;
  FUID:=-1;
  SetAspect(AParent, X, Y);
  ErrorCode:=LoadModule(ModuleFilename, ProjectFilename);
  case ErrorCode of
    0               : Caption:='oops something went wrong...';
    _errModNotFound : Caption:=ModuleFilename+' not found';
    _errDLLLoad     : Caption:='Error loading '+ModuleFilename;
    _errDLLProc     : Caption:='Procedure Entry not found in '+ModuleFilename;
    _errTooManyMod  : Caption:='Too many same modules in '+ModuleFilename;
  end;
end;

destructor TVirtualModule.Destroy;
begin
  if HLib<>nilHandle then
  begin
    if (FUID<>-1) and Assigned(ModuleDestroy) then
    try
      ModuleDestroy(FUID);
    except
    end;
    try
      FreeLibrary(HLib);
    except
    end;
  end;
  inherited Destroy;
end;

procedure TVirtualModule.PreStart;
begin
  if (FUID<>-1) and Assigned(ModulePrestart) then
  try
    ModulePreStart(FUID);
  except
  end;
end;

procedure TVirtualModule.Start;
begin
  if (FUID<>-1) and Assigned(ModuleStart) then
  try
    ModuleStart(FUID);
  except
  end;
end;

procedure TVirtualModule.Stop;
begin
  if (FUID<>-1) and Assigned(ModuleStop) then
  try
    ModuleStop(FUID);
  except
  end;
end;

procedure TVirtualModule.BeginRefresh;
begin
  Windows.SetParent(HModule, 0);
  ShowWindow(HModule, SW_HIDE);
  Visible:=false;
end;

procedure TVirtualModule.EndRefresh;
begin
  Visible:=true;
  Windows.SetParent(HModule, Self.Handle);
  SetWindowPos(HModule,0,PadX,PadY,0,0,SWP_NOSIZE+SWP_NOZORDER);
  ShowWindow(HModule, SW_SHOW);
end;

function TVirtualModule.Edit: boolean;
begin
  if (FUID<>-1) and Assigned(ModuleEdit) then
  try
    Result:=boolean(ModuleEdit(FUID));
  except
    Result:=false;
  end;
end;

procedure TVirtualModule.SaveToFile(FileName: string);
Var
  ini : TMemIniFile;
begin
  if (FUID<>-1) and Assigned(ModuleSave) then
  try
    ModuleSave(FUID, PChar(FileName));
  except
  end;

  ini:=TMemIniFile.Create(FileName);
  try
    ini.WriteString('SLOT_'+IntToStr(FIndex),'ModuleCaption',FModuleCaption);
    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

procedure TVirtualModule.MoveTo(NewIndex, NewLeft, NewTop: integer);
begin
  if (FUID<>-1) and Assigned(ModuleNewindex) then
  try
    ModuleNewindex(FUID, NewIndex);
  except
  end;
  FIndex:=NewIndex;
  SetBounds(NewLeft, NewTop, DefaultWidth, DefaultHeight);
  LblInstance.SetBounds(NewLeft+30, NewTop-22, DefaultWidth-38, 22);
end;

end.


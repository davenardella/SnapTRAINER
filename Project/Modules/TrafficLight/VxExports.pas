unit VxExports;

{$MODE DELPHI}

interface

uses
  Windows, Forms, VxTypes, VxFrmModule;

function module_create(Index: integer; PHooks : PHooksRecord; AModuleName, AFileName: PChar; Var Handle : THandle): integer; stdcall;
procedure module_destroy(UID : integer); stdcall;
procedure module_newindex(UID, NewIndex : integer); stdcall;
procedure module_start(UID : integer); stdcall;
procedure module_stop(UID : integer); stdcall;
procedure module_prestart(UID : integer); stdcall;
procedure module_save(UID : integer; AFileName: PChar); stdcall;
function module_edit(UID : integer) : integer; stdcall;
function module_busy : integer; stdcall;


implementation
Const
  MaxInstances = 128;

Var
  Instances : array[0..MaxInstances-1] of TVxForm;
  ModuleBusy : boolean = false;

function FindSlot : integer;
begin
  for Result:=0 to MaxInstances-1 do
    if not Assigned(Instances[Result]) then
      exit;
  Result:=-1;
end;

function module_create(Index: integer; PHooks: PHooksRecord; AModuleName,
  AFileName: PChar; var Handle: THandle): integer; stdcall;
begin
  Result:=FindSlot;
  if Result=-1 then // no Room
    exit;
  Instances[Result]:=TVxForm.Create(nil);
  Instances[Result].Index:=Index;
  Instances[Result].Name:=AModuleName;
  Instances[Result].SetHooks(PHooks);
  Instances[Result].Left:=-1000;
  Instances[Result].Top:=-1000;
  Instances[Result].LoadFromFile(AFilename);
  Instances[Result].Show;
  Handle:=Instances[Result].Handle;
end;

procedure module_destroy(UID: integer); stdcall;
begin
  if Assigned(Instances[UID]) then
  begin
    Instances[UID].free;
    Instances[UID]:=nil;
  end;
end;

procedure module_newindex(UID, NewIndex: integer); stdcall;
begin
  if Assigned(Instances[UID]) then
    Instances[UID].Index:=NewIndex;
end;

procedure module_start(UID: integer); stdcall;
begin
  if Assigned(Instances[UID]) then
    Instances[UID].Start;
end;

procedure module_stop(UID: integer); stdcall;
begin
  if Assigned(Instances[UID]) then
    Instances[UID].Stop;
end;

procedure module_prestart(UID: integer); stdcall;
begin
  if Assigned(Instances[UID]) then
    Instances[UID].PrepareStart;
end;

procedure module_save(UID: integer; AFileName: PChar); stdcall;
begin
  if Assigned(Instances[UID]) then
    Instances[UID].SaveToFile(AFileName);
end;

function module_edit(UID: integer): integer; stdcall;
begin
  if Assigned(Instances[UID]) then
  begin
    ModuleBusy:=true;
    try
      Result:=integer(Instances[UID].Edit)
    finally
      ModuleBusy:=false;
    end;
  end
  else
    Result:=0;
end;

function module_busy: integer; stdcall;
begin
  Result:=integer(ModuleBusy);
end;

initialization

  FillChar(Instances{%H-}, SizeOf(Instances), #0);

end.


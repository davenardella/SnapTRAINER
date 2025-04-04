unit VxController;

{$MODE DELPHI}

interface

uses
  Windows, Classes, SysUtils, VxCommTypes, VxClient, SnapMB, Snap7;

Const
  DeviceRegsAmount = 32768;
  MaxRegisters     = 128;
  RegCollision     = 1;
  s7OK = 0;

Type
  TRegisterStatus = (rsUnknown, rsOK, rsDataError, rsNetError);
  THoldingRegister = record
    Address   : word;
    Value     : word;
    Last      : word;
    Fast      : boolean;
    LastError : integer;
    Status    : TRegisterStatus;
  end;

  THoldingRegisters = array[0..MaxRegisters-1] of THoldingRegister;
  TDeviceRegisters  = packed array[0..DeviceRegsAmount-1] of word;

  TCommController = class;

  { TCommWorker }

  TCommWorker = class(TThread)
  private
    FController : TCommController;
    FWorkDelay: cardinal;
  protected
    procedure Execute; override;
  public
    constructor Create(Owner : TCommController);
    destructor Destroy; override;
    property WorkDelay : cardinal read FWorkDelay write FWorkDelay;
  end;

  { TCommController }

  TCommController = class(TObject)
  private
    Client       : TMultiProtocolClient;
    Device       : TSnapMBDevice;
    cs           : TRTLCriticalSection;
    FConnected   : boolean;
    FWorker      : TCommWorker;
    FSettings    : TCommSettings;
    FStarted     : boolean;
    FStopping    : boolean;
    FInit        : boolean;
    function IndexOf(Address : word; Registers : THoldingRegisters; Count : integer) : integer;
    procedure CreateWorker;
    procedure DestroyWorker;
    function TryLock: boolean;
    procedure Lock;
    procedure UnLock;
    procedure SetAll(Status : TRegisterStatus);
    procedure ExecuteRead;
    procedure ExecuteWrite;
    function CreateDevice(Settings : TCommSettings) : TSnapMBDevice;
    procedure DeviceChangeTo;
  public
    RD_Registers : THoldingRegisters;
    RD_RegCount  : integer;
    WR_Registers : THoldingRegisters;
    WR_RegCount  : integer;
    DEV_HRegisters: TDeviceRegisters;
    DEV_IRegisters: TDeviceRegisters;
    constructor Create(Settings : TCommSettings);
    destructor Destroy; override;
    procedure ChangeTo(Settings : TCommSettings);
    procedure Clear;
    function Start : boolean;
    procedure Stop;
    procedure ExecuteCyclic;
    function Connect : boolean;
    function AddReadRegister(Address : Word) : integer;
    function AddWriteRegister(Address : Word; Fast : boolean; const InitValue : word = 0) : integer;
    function ReadRegister(Index : integer; var Value : word) : TRegisterStatus;
    procedure WriteRegister(Index : integer; Value : word);
    function FastWriteRegister(Index : integer; Value : word) : TRegisterStatus;
    function GetReadRegisterStatus(Index : integer) : TRegisterStatus;
    function GetWriteRegisterStatus(Index : integer) : TRegisterStatus;
    function ErrorText(Error : integer) : string;
    property Connected : boolean read FConnected;
    property Started : boolean read FStarted;
  end;

  // Exported
  function CommRegisterRead(index : integer; var Value : Word) : integer; stdcall;
  procedure CommRegisterWrite(index : integer; Value : Word); stdcall;
  function CommRegisterFastWrite(index : integer; Value : Word) : integer; stdcall;
  function CommReadRegisterAdd(Address : Word) : integer; stdcall;
  function CommWriteRegisterAdd(Address : Word; Fast : integer; InitValue : word) : integer; stdcall;
  function CommRegisterStatus(Kind : integer; Index : integer) : integer; stdcall;

  // Internals
  function ControllerCreate(Settings : TCommSettings) : TCommController;
  procedure ControllerDestroy;

implementation

const
  _rkRead  = 0;
  _rkWrite = 1;

Var
  VxController : TCommController = nil;

function ControllerCreate(Settings: TCommSettings): TCommController;
begin
  if not Assigned(VxController) then
    VxController := TCommController.Create(Settings);
  Result:= VxController;
end;

procedure ControllerDestroy;
begin
  if Assigned(VxController) then
    VxController.Free;
end;

function CommRegisterRead(index: integer; var Value: Word): integer; stdcall;
begin
   Result:=ord(VxController.ReadRegister(index, Value));
end;

procedure CommRegisterWrite(index: integer; Value: Word); stdcall;
begin
  VxController.WriteRegister(Index, Value);
end;

function CommRegisterFastWrite(index: integer; Value: Word): integer; stdcall;
begin
  Result:=ord(VxController.FastWriteRegister(Index, Value));
end;

function CommReadRegisterAdd(Address: Word): integer; stdcall;
begin
  Result:=VxController.AddReadRegister(Address);
end;

function CommWriteRegisterAdd(Address: Word; Fast: integer; InitValue: word
  ): integer; stdcall;
begin
  Result:=VxController.AddWriteRegister(Address, boolean(Fast), InitValue);
end;

function CommRegisterStatus(Kind: integer; Index: integer): integer; stdcall;
begin
  if Kind = _rkRead then
    Result:=ord(VxController.GetReadRegisterStatus(Index))
  else
    Result:=ord(VxController.GetWriteRegisterStatus(Index));
end;

{ TCommController }

procedure TCommController.Lock;
begin
  EnterCriticalSection(cs);
end;

procedure TCommController.UnLock;
begin
  LeaveCriticalSection(cs);
end;

procedure TCommController.SetAll(Status: TRegisterStatus);
Var
  c : integer;
begin
  for c:=0 to RD_RegCount do
    RD_Registers[c].Status:=Status;
  for c:=0 to WR_RegCount do
    WR_Registers[c].Status:=Status;
end;

procedure TCommController.ExecuteRead;
Var
  Value : Word;
  c : integer;
begin
  c:=0;
  while (c < RD_RegCount) and FConnected do
  begin
    RD_Registers[c].LastError:=Client.ReadWord(FSettings.UnitID_DB, RD_Registers[c].Address, Value);
    if RD_Registers[c].LastError <> CommOK then
    begin
      FConnected:=Client.Connected;
      if not FConnected then
        RD_Registers[c].Status:=rsNetError
      else
        RD_Registers[c].Status:=rsDataError;
    end
    else begin
      RD_Registers[c].Value:=Value;
      RD_Registers[c].Status:=rsOk;
    end;
    inc(c);
  end;

  if not FConnected then
    SetAll(rsNetError);
end;

procedure TCommController.ExecuteWrite;
Var
  c : integer;
begin
  c:=0;

  if FInit then
  begin
    while (c < WR_RegCount) and FConnected do
    begin
      WR_Registers[c].LastError:=Client.WriteWord(FSettings.UnitID_DB, WR_Registers[c].Address, WR_Registers[c].Value);
      if WR_Registers[c].LastError <> mbNoError then
      begin
        FConnected:=Client.Connected;
        if not FConnected then
          WR_Registers[c].Status:=rsNetError
        else
          WR_Registers[c].Status:=rsDataError;
      end
      else begin
        WR_Registers[c].Status:=rsOk;
        WR_Registers[c].Last:=WR_Registers[c].Value;
      end;
      inc(c);
    end;

    if not FConnected then
      SetAll(rsNetError)
    else
      FInit:=false;

    exit;
  end;

  while (c < WR_RegCount) and FConnected do
  begin
    if (not WR_Registers[c].Fast) and (WR_Registers[c].Value<>WR_Registers[c].Last) then
    begin
      WR_Registers[c].LastError:=Client.WriteWord(FSettings.UnitID_DB, WR_Registers[c].Address, WR_Registers[c].Value);
      if WR_Registers[c].LastError <> mbNoError then
      begin
        FConnected:=Client.Connected;
        if not FConnected then
          WR_Registers[c].Status:=rsNetError
        else
          WR_Registers[c].Status:=rsDataError;
      end
      else begin
        WR_Registers[c].Status:=rsOk;
        WR_Registers[c].Last:=WR_Registers[c].Value;
      end;
    end;
    inc(c);
  end;

  if not FConnected then
    SetAll(rsNetError);
end;

function TCommController.CreateDevice(Settings: TCommSettings): TSnapMBDevice;
begin
  Result:=TSnapMBDevice.Create(mbTCP,Settings.UnitID_DB,Settings.MBTCPParams.Address,Settings.MBTCPParams.Port);
  Result.RegisterArea(mbAreaHoldingRegisters, @DEV_HRegisters, DeviceRegsAmount);
  Result.RegisterArea(mbAreaInputRegisters,   @DEV_IRegisters, DeviceRegsAmount);
end;

procedure TCommController.DeviceChangeTo;
begin
  if FSettings.ProtocolType = ctMBTCP then
    Device.ChangeTo(mbTCP,FSettings.UnitID_DB,FSettings.MBTCPParams.Address,FSettings.MBTCPParams.Port)
  else
    Device.ChangeTo(sfRTU,FSettings.UnitID_DB, FSettings.MBRTUParams.Port,
          FSettings.MBRTUParams.BaudRate,FSettings.MBRTUParams.Parity,FSettings.MBRTUParams.DataBits,
          FSettings.MBRTUParams.StopBits,FSettings.MBRTUParams.Flow);
end;

function TCommController.IndexOf(Address : word; Registers: THoldingRegisters; Count: integer): integer;
begin
  for Result:=0 to Count-1 do
    if Registers[Result].Address=Address then
      exit;
  Result:=-1;
end;

procedure TCommController.CreateWorker;
begin
  if Assigned(FWorker) then
    DestroyWorker;
  FWorker:=TCommWorker.Create(Self);
  FWorker.WorkDelay:=FSettings.RefreshInterval;;
  FWorker.Start;
end;

procedure TCommController.DestroyWorker;
begin
  if Assigned(FWOrker) then
  begin
    if not FWorker.Suspended then
    begin
      FWorker.Terminate;
      WaitForSingleObject(ulong(FWorker.Handle), 3000);
    end;
    FreeAndNil(FWorker);
  end;
end;

function TCommController.TryLock : boolean;
begin
  Result:=TryEnterCriticalSection(cs);
end;

constructor TCommController.Create(Settings: TCommSettings);
begin
  inherited create;
  FSettings:=Settings;
  InitializeCriticalSection(cs);
  Client:=TMultiProtocolClient.Create(FSettings);
  Device:=CreateDevice(FSettings);
  FStarted   := false;
  FStopping  := false;
  FConnected := false;
  FWorker:=NIL;
end;

destructor TCommController.Destroy;
begin
  Stop;
  Client.Free;
  Device.Free;
  DeleteCriticalSection(cs);
  inherited Destroy;
end;

procedure TCommController.ChangeTo(Settings: TCommSettings);
begin
  FSettings:=Settings;
  if FSettings.Mode = cmClient then
    Client.ChangeTo(FSettings)
  else
    DeviceChangeTo;
end;

procedure TCommController.Clear;
begin
  FillChar(DEV_HRegisters, SizeOf(DEV_HRegisters), #0);
  FillChar(DEV_IRegisters, SizeOf(DEV_IRegisters), #0);
  FillChar(RD_Registers, SizeOf(RD_Registers), #0);
  FillChar(WR_Registers, SizeOf(WR_Registers), #0);
  RD_RegCount :=0;
  WR_RegCount :=0;
end;

function TCommController.Start: boolean;
begin
  Result:=true;
  if not FStarted then
  begin
    FInit:=true;
    if FSettings.Mode = cmDevice then
    begin
      Result:=Device.Start = 0;
      FConnected:=Result;
      if FConnected then
        SetAll(rsOk);
    end
    else
      CreateWorker;
    FStarted:=Result;
  end;
end;

procedure TCommController.Stop;
begin
  if FStarted then
  begin
    FStopping:=true;
    if FSettings.Mode = cmClient then
    begin
      DestroyWorker;
      Client.Disconnect;
    end
    else
      Device.Stop;
    FStarted:=false;
    FStopping:=false;
    FConnected:=false;
    SetAll(rsUnknown);
  end;
end;

procedure TCommController.ExecuteCyclic;
begin
  Lock;
  try
    if FConnected then
      ExecuteRead;
    if FConnected then
      ExecuteWrite;
  finally
    Unlock;
  end;
end;

function TCommController.Connect: boolean;
begin
  Result:=Client.Connect;
  FConnected:=Result;
  if not Result then
    SetAll(rsNetError)
  else
    FInit:=true;
end;

function TCommController.FastWriteRegister(Index: integer; Value: word
  ): TRegisterStatus;
begin
  if not FStarted or FStopping or (Index>=WR_RegCount) then
    exit(rsUnknown);

  if not FConnected then
    exit(rsNetError);

  if FSettings.Mode=cmDevice then
  begin
    WriteRegister(Index, Value);
    exit(rsOk);
  end;

  Lock;
  try
    WR_Registers[index].Value:=Value;
    WR_Registers[index].LastError:=Client.WriteWord(FSettings.UnitID_DB, WR_Registers[index].Address, WR_Registers[index].Value);

    if WR_Registers[index].LastError <> mbNoError then
    begin
      FConnected:=Client.Connected;
      if not FConnected then
        WR_Registers[index].Status:=rsNetError
      else
        WR_Registers[index].Status:=rsDataError;
    end
    else
      WR_Registers[index].Status:=rsOk;

  finally
    Unlock;
  end;
  Result:=WR_Registers[index].Status;
end;

function TCommController.GetReadRegisterStatus(Index: integer): TRegisterStatus;
begin
  if Index < RD_RegCount then
    Result:=RD_Registers[Index].Status
  else
    Result:=rsUnknown;
end;

function TCommController.GetWriteRegisterStatus(Index: integer): TRegisterStatus;
begin
  if Index < WR_RegCount then
    Result:=WR_Registers[Index].Status
  else
    Result:=rsUnknown;
end;

function TCommController.ErrorText(Error: integer): string;
begin
  if FSettings.ProtocolType=ctS7 then
    Result:=Snap7.CliErrorText(Error)
  else
    Result:=SnapMB.ErrorText(Error);
end;

function TCommController.AddReadRegister(Address: Word): integer;
begin
  Result:=IndexOf(Address, RD_Registers, RD_RegCount);
  if Result=-1 then
  begin
    RD_Registers[RD_RegCount].Address:=Address;
    RD_Registers[RD_RegCount].Status :=rsUnknown;
    RD_Registers[RD_RegCount].Fast   :=false;
    RD_Registers[RD_RegCount].Value  :=0;
    Result:=RD_RegCount;
    if RD_RegCount<MaxRegisters-1 then
      inc(RD_RegCount);
  end;
end;

function TCommController.AddWriteRegister(Address: Word; Fast: boolean;
  const InitValue: word): integer;
begin
  Result:=IndexOf(Address, WR_Registers, WR_RegCount);
  if Result=-1 then // Register not found
  begin
    WR_Registers[WR_RegCount].Address:=Address;
    WR_Registers[WR_RegCount].Status :=rsUnknown;
    WR_Registers[WR_RegCount].Value  :=InitValue;
    WR_Registers[WR_RegCount].Fast   :=Fast;
    Result:=WR_RegCount;
    if WR_RegCount<MaxRegisters-1 then
      inc(WR_RegCount);
  end
  else
    WR_Registers[Result].LastError:=RegCollision;
end;

function TCommController.ReadRegister(Index: integer; var Value: word
  ): TRegisterStatus;
begin
  if Index < RD_RegCount then
  begin
    if FSettings.Mode = cmClient then
    begin
      Value :=RD_Registers[Index].Value;
      Result:=RD_Registers[Index].Status;
    end
    else begin
      Value:=DEV_HRegisters[RD_Registers[Index].Address];
      RD_Registers[Index].Value:=Value;
      if FConnected then
        Result:=rsOk
      else
        Result:=rsNetError;
    end;
  end
  else
    Result:=rsUnknown;
end;

procedure TCommController.WriteRegister(Index: integer; Value: word);
begin
  if Index < WR_RegCount then
  begin
    if FSettings.Mode = cmDevice then
    begin
      if FSettings.UseInputRegs then
        DEV_IRegisters[WR_Registers[Index].Address]:=Value
      else
        DEV_HRegisters[WR_Registers[Index].Address]:=Value;
      end;
    end;
    WR_Registers[Index].Value:=Value;
  end;
end;

{ TCommWorker }

procedure TCommWorker.Execute;

  procedure SleepOrExit(DelayTime : cardinal);
  Var
    cnt : cardinal;
  begin
    cnt:=0;
    repeat
      sleep(10);
      inc(cnt, 10);
    until Terminated or (cnt>=DelayTime);
  end;

  procedure CheckControllerConnection;
  begin
    if not FController.Connected then
    begin
      repeat
        if not Terminated then
          SleepOrExit(1000);
      until Terminated or FController.Connect;
    end;
  end;

begin
  FController.Connect;
  while not Terminated do
  begin
    CheckControllerConnection;
    if not Terminated then
      FController.ExecuteCyclic;
    if not Terminated then
      Sleep(FWorkDelay);
  end;
end;

constructor TCommWorker.Create(Owner: TCommController);
begin
  inherited Create(true);
  FController:=Owner;
  FreeOnTerminate:=false;
  FWorkDelay:=100;
end;

destructor TCommWorker.Destroy;
begin
  inherited Destroy;
end;

end.


unit VxClient;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, VxCommTypes, SnapMB, Snap7;

Const
  CommOK = 0;

Type

  { TMultiProtocolClient }

  TMultiProtocolClient = class(TObject)
  private
    FConnected: boolean;
    S7Client : TS7Client;
    MBClient : TSnapMBBroker;
    FSettings: TCommSettings;
  public
    constructor Create(Settings : TCommSettings);
    destructor Destroy; override;
    procedure ChangeTo(Settings : TCommSettings);
    function ReadWord(UnitID_DB : integer; Address : integer; var Value : Word): integer;
    function WriteWord(UnitID_DB : integer; Address : integer; Value : Word): integer;
    function Connect : boolean;
    procedure Disconnect;
    property Connected : boolean read FConnected;
  end;


implementation

function SwapWord(W : word) : word;
Var
  IW : packed array[0..1]of byte absolute W;
  QW : packed array[0..1]of byte absolute Result;
begin
  QW[0]:=IW[1];
  QW[1]:=IW[0];
end;

{ TMultiProtocolClient }

constructor TMultiProtocolClient.Create(Settings: TCommSettings);
begin
  inherited Create;
  S7Client:=nil;
  MBClient:=nil;
  ChangeTo(Settings);
end;

destructor TMultiProtocolClient.Destroy;
begin
  if Assigned(MBClient) then
    MBClient.Free;

  if Assigned(S7Client) then
    S7Client.Free;

  inherited Destroy;
end;

procedure TMultiProtocolClient.ChangeTo(Settings: TCommSettings);
begin
  FSettings:=Settings;

  if Assigned(MBClient) then
  begin
    MBClient.Free;
    MBClient:=nil;
  end;

  if Assigned(S7Client) then
  begin
    S7Client.Free;
    S7Client:=nil;
  end;

  case FSettings.ProtocolType of
    ctMBTCP : begin
      MBClient:=TSnapMBBroker.Create(mbTCP,FSettings.MBTCPParams.Address,FSettings.MBTCPParams.Port);
      MBClient.SetLocalParam(par_DisconnectOnError, integer(FSettings.DisOnError));
    end;
    ctMBRTU : begin
      with FSettings.MBRTUParams do
        MBClient:=TSnapMBBroker.Create(sfRTU, Port, BaudRate, Parity, DataBits, StopBits, Flow);
    end;
    ctS7 : begin
      S7Client:=TS7Client.Create;
      S7Client.SetConnectionType(FSettings.S7ISOParams.ConnectionType);
    end;
  end;
end;

function TMultiProtocolClient.ReadWord(UnitID_DB: integer; Address: integer;
  var Value: Word): integer;
Var
  ValueRead : word;
  DBW : integer;
begin
  if FSettings.ProtocolType = ctS7 then
  begin
    DBW:=(Address-1)*2; // Convert Register Number to DBWord Address
    Result:=S7Client.DBRead(UnitID_DB, DBW, 2, @ValueRead);
    if Result<>CommOK then
    begin
      if FSettings.DisOnError or ((Result and $0000FFFF)<>0) then
        Disconnect;
    end
    else
      Value:=SwapWord(ValueRead);
  end
  else begin
    Result:=MBClient.ReadHoldingRegisters(FSettings.UnitID_DB, Address, 1, @ValueRead);
    if Result<>CommOK then
      FConnected := MBClient.GetDeviceStatus.Connected
    else
       Value:=ValueRead;
  end;
end;

function TMultiProtocolClient.WriteWord(UnitID_DB: integer; Address: integer;
  Value: Word): integer;
Var
  DBW : integer;
  W   : Word;
begin
  if FSettings.ProtocolType = ctS7 then
  begin
    DBW:=(Address-1)*2; // Convert Register Number to DBWord Address
    W:=SwapWord(Value);
    Result:=S7Client.DBWrite(UnitID_DB, DBW, 2, @W);

    if Result<>CommOK then
    begin
      if FSettings.DisOnError or ((Result and $0000FFFF)<>0) then
        Disconnect;
    end;
  end
  else begin
    Result:=MBClient.WriteSingleRegister(FSettings.UnitID_DB, Address, Value);
    if Result<>CommOK then
      FConnected := MBClient.GetDeviceStatus.Connected
  end;
end;

function TMultiProtocolClient.Connect: boolean;
begin
  if FSettings.ProtocolType = ctS7 then
    Result:=S7Client.ConnectTo(FSettings.S7ISOParams.Address, FSettings.S7ISOParams.Rack, FSettings.S7ISOParams.Slot)=0
  else
    Result:=MBClient.Connect = 0;
  FConnected:=Result;
end;

procedure TMultiProtocolClient.Disconnect;
begin
  if FSettings.ProtocolType = ctS7 then
     S7Client.Disconnect
  else
     MBClient.Disconnect;
  FConnected := false;
end;

end.


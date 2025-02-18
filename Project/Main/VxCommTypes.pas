unit VxCommTypes;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, SnapMB;

Type

  TProtocolType = (ctMBTCP, ctMBRTU, ctS7);

  TS7ISOParams = record
    Address        : string;
    Rack           : integer;
    Slot           : integer;
    ConnectionType : integer;
  end;

  TMBTCPParams = record
    Address    : string;
    Port       : word;
  end;

  TMBRTUParams = record
    Port     : string;
    BaudRate : integer;
    Parity   : Char;
    DataBits : integer;
    StopBits : integer;
    Flow     : TMBSerialFlow;
  end;

  TControllerMode = (cmClient, cmDevice);

  TCommSettings = record
    Mode            : TControllerMode;
    UseInputRegs    : boolean;
    UnitID_DB       : integer;
    ProtocolType    : TProtocolType;
    RefreshInterval : integer;
    DisOnError      : boolean;
    BaseAddressZero : boolean;
    MBTCPParams     : TMBTCPParams;
    MBRTUParams     : TMBRTUParams;
    S7ISOParams     : TS7ISOParams;
  end;



implementation

end.


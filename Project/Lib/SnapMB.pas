unit SnapMB;
interface
{$IFDEF FPC}
   {$MODE DELPHI}
{$ENDIF}

// Old compilers don't define MSWINDOWS
{$IFDEF WIN32}
  {$IFNDEF MSWINDOWS}
    {$DEFINE MSWINDOWS}
  {$ENDIF}
{$ENDIF}

Const
// Library name
{$IFDEF MSWINDOWS}
  snaplib = 'snapmb.dll';
{$ELSE}
  snaplib = 'libsnapmb.so';  // valid for all Unix platforms
{$ENDIF}

// Native integrals
{$IFNDEF FPC}
  {$IF CompilerVersion<21} // below Delphi 7
    Type
      NativeUint = LongWord;
      NativeInt  = LongInt;
  {$IFEND}
{$ENDIF}

Type
  SNAP_Object = NativeUint; // Platform independent Object reference
                            // DON'T CONFUSE IT WITH AN OLE OBJECT, IT'S SIMPLY
                            // AN INTEGER (32 OR 64 BIT) VALUE USED AS HANDLE.

  XOBJECT = packed record
    MBObject   : NativeUint;
    MBSelector : NativeUint;
  end;


  TBufferKind = (
    BkSnd,  // Buffer Sent
    BkRcv   // Buffer Received
  );

  TMBArea = (
    mbAreaDiscreteInputs,
    mbAreaCoils,
    mbAreaInputRegisters,
    mbAreaHoldingRegisters
  );

  TCallbackID = (
    cbkDeviceEvent,
    cbkPacketLog,
    cbkDiscreteInputs,
    cbkCoils,
    cbkInputRegisters,
    cbkHoldingRegisters,
    cbkReadWriteRegisters,
    cbkMaskRegister,
    cbkFileRecord,
    cbkExceptionStatus,
    cbkDiagnostics,
    cbkGetCommEventCounter,
    cbkGetCommEventLog,
    cbkReportServerID,
    cbkReadFIFOQueue,
    cbkEncapsulatedIT,
    cbkUsrFunction
  );

  TMBNetProto = (mbTCP, mbUDP, mbRTUOverTCP, mbRTUOverUDP);

  TMBSerialFormat = (sfRTU, sfASCII);

  TMBDataLink = (dlEthernet, dlSerial);

  TMBBrokerType = (btNetClient, btSerController);

  TMBEthParams = record
    Address    : string;
    Port       : word;
    DisTimeout : integer; // Disconnection of an inactive Client (Only for Device)
    DisOnError : boolean; // Disconnection of error (Only for Broker)
  end;

  TMBSerialFlow = (flowNone, flowRTSCTS);

  TMBSerParams = record
     Port     : string;
     BaudRate : integer;
     Parity   : Char;
     DataBits : integer;
     StopBits : integer;
     Flow     : TMBSerialFlow;
     Format   : TMBSerialFormat;
  end;

  time_t = NativeInt;

  TSrvEvent = packed record
    EvtTime    : time_t;    // Timestamp
    EvtSender  : longword;  // Sender
    EvtCode    : longword;  // Event code
    EvtRetCode : word;      // Event result
    EvtParam1  : word;      // Param 1
    EvtParam2  : word;      // Param 2
    EvtParam3  : word;      // Param 3
    EvtParam4  : word;      // Param 4
  end;
  PSrvEvent = ^TSrvEvent;

  TDeviceStatus = packed record
    LastError : longint;
    Status    : longint;
    Connected : longBool;
    Time      : longword;
  end;

  TDeviceInfo = packed record
    Running        : longBool;
    ClientsCount   : longint;  // only for TCP
    ClientsBlocked : longint;  // only for TCP/UDP
    LastError      : longint;
  end;

const
   MaxBinPDUSize         = 253;
   def_Modbus_Port       = 502;

   mbNoError             = 0;

   par_TCP_UDP_Port      = 1;
   par_DeviceID          = 2;
   par_TcpPersistence    = 3;
   par_DisconnectOnError = 4;
   par_SendTimeout       = 5;
   par_SerialFormat      = 6;
   par_AutoTimeout       = 7;
   par_AutoTimeLimitMin  = 8;
   par_FixedTimeout      = 9; 
   par_BaseAddressZero   = 10;
   par_DevPeerListMode   = 11;
   par_PacketLog         = 12;
   par_InterframeDelay   = 13;
   par_WorkInterval      = 14;
   par_AllowSerFunOnEth  = 15;
   par_MaxRetries        = 16;
   par_DisconnectTimeout = 17;
   par_AttemptSleep      = 18;
   par_DevicePassthrough = 19;

   // Callbacks Actions
   cbActionRead          = 0;
   cbActionWrite         = 1;

   PacketLog_NONE        = 0;
   PacketLog_IN          = 1;
   PacketLog_OUT         = 2;
   PacketLog_BOTH        = 3;

// Events
// Device Base
  evcDeviceStarted         = $00000001;
  evcDeviceStopped         = $00000002;
  evcDeviceCannotStart     = $00000004;
  evcDevClientAdded        = $00000008;
  evcDevClientRejected     = $00000010;
  evcDevClientNoRoom       = $00000020;
  evcDevClientException    = $00000040;
  evcDevClientDisconnected = $00000080;
  evcDevClientTerminated   = $00000100;
  evcDevClientsDropped     = $00000200;
  evcDevClientRefused      = $00000400;
  evcDevClientDisTimeout   = $00000800;
  evcPortError             = $00001000;
  evcPortReset             = $00002000;
  evcInvalidADUReceived    = $00004000;
  evcNetworkError          = $00008000;
  evcCRCError              = $00010000;
  evcInvalidFunction       = $00020000;
// Functions
  evcReadCoils             = $00100000;
  evcReadDiscrInputs       = $00200000;
  evcReadHoldingRegs       = $00400000;
  evcReadInputRegs         = $00500000;
  evcWriteSingleCoil       = $00600000;
  evcWriteSingleReg        = $00700000;
  evcReadExcpStatus        = $00800000;
  evcDiagnostics           = $00900000;
  evcGetCommEvtCnt         = $00A00000;
  evcGetCommEvtLog         = $00B00000;
  evcWriteMultiCoils       = $00C00000;
  evcWriteMultiRegs        = $00D00000;
  evcReportServerID        = $00E00000;
  evcReadFileRecord        = $00F00000;
  evcWriteFileRecord       = $01000000;
  evcMaskWriteReg          = $01100000;
  evcReadWriteMultiRegs    = $01200000;
  evcReadFifoQueue         = $01300000;
  evcEncIntTransport       = $01400000;
  evcCustomFunction        = $01500000;


//******************************************************************************
// POLYMORPHIC BROKER WRAPPERS
//******************************************************************************
procedure broker_CreateFieldController(var Broker : XOBJECT);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
procedure broker_CreateEthernetClient(var Broker : XOBJECT; Proto : integer; Address : PAnsiChar; Port : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
procedure broker_CreateSerialClient(var Broker : XOBJECT; Format : integer; PortName : PAnsiChar; BaudRate : integer; Parity : AnsiChar; DataBits, Stops, Flow : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
procedure broker_Destroy(var Broker : XOBJECT);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_AddControllerNetDevice(var Broker : XOBJECT; Proto : integer; DeviceID : byte; Address : PAnsiChar; Port : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_AddControllerSerDevice(var Broker : XOBJECT; Format : integer; DeviceID : byte; PortName : PAnsiChar; BaudRate : integer; Parity : AnsiChar; DataBits, Stops, Flow : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_Connect(var Broker : XOBJECT) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_Disconnect(var Broker : XOBJECT) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_SetLocalParam(var Broker : XOBJECT; LocalID : byte; ParamIndex, Value : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_SetRemoteDeviceParam(var Broker : XOBJECT; DeviceID : byte; ParamIndex, Value : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_GetIOBufferPtr(var Broker : XOBJECT; DeviceID : byte; BufferKind : integer; var Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_GetIOBuffer(var Broker : XOBJECT; DeviceID : byte; BufferKind : integer; Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_GetDeviceStatus(var Broker : XOBJECT; DeviceID : byte; Var Status : TDeviceStatus) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}

// MODBUS Functions
function broker_ReadHoldingRegisters(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_WriteMultipleRegisters(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadCoils(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadDiscreteInputs(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadInputRegisters(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_WriteSingleCoil(var Broker : XOBJECT; DeviceID : byte; Address : word; Value : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_WriteSingleRegister(var Broker : XOBJECT; DeviceID : byte; Address : word; Value : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadWriteMultipleRegisters(var Broker : XOBJECT; DeviceID : byte; RDAddress, RDAmount, WRAddress, WRAmount : word; pRDUsrData : Pointer; pWRUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_WriteMultipleCoils(var Broker : XOBJECT; DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_MaskWriteRegister(var Broker : XOBJECT; DeviceID : byte; Address : word; AND_Mask, OR_Mask : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadFileRecord(var Broker : XOBJECT; DeviceID : byte; RefType : byte; FileNumber, RecNumber, RegsAmount : word; RecData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_WriteFileRecord(var Broker : XOBJECT; DeviceID : byte; RefType : byte; FileNumber, RecNumber, RegsAmount : word; RecData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadFIFOQueue(var Broker : XOBJECT; DeviceID : byte; Address : word; var FifoCount : word; FIFO : pword) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReadExceptionStatus(var Broker : XOBJECT; DeviceID : byte; var Data : byte) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_Diagnostics(var Broker : XOBJECT; DeviceID : byte; SubFunction : word; pSendData : pword; pRecvData : pword; ItemsToSend: word; var ItemsReceived : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_GetCommEventCounter(var Broker : XOBJECT; DeviceID : byte; var Status : word; var EventCount : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_GetCommEventLog(var Broker : XOBJECT; DeviceID : byte; var Status : word; var EventCount : word; var MessageCount : word; var NumItems : word; Events : pbyte) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ReportServerID(var Broker : XOBJECT; DeviceID : byte; pUsrData : Pointer; var DataSize : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_ExecuteMEIFunction(var Broker : XOBJECT; DeviceID : byte; MEI_Type : byte; pWRUsrData : Pointer; WRSize : word; pRDUsrData : Pointer; var RDSize : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_CustomFunctionRequest(var Broker : XOBJECT; DeviceID : byte; UsrFunction : byte; pUsrPDUWrite : Pointer; SizePDUWrite : word; pUsrPDURead : Pointer; var SizePDURead : word; SizePDUExpected : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function broker_RawRequest(var Broker : XOBJECT; DeviceID : byte; pUsrPDUWrite : Pointer; SizePDUWrite : word; pUsrPDURead : Pointer; var SizePDURead : word; SizePDUExpected : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}

Type

  { TSnapMBBroker }

  TSnapMBBroker = class(TObject)
  private
    Broker : XOBJECT;
  public
    constructor Create; overload;
    constructor Create(Proto : TMBNetProto; Address : string; Port : integer); overload;
    constructor Create(Format : TMBSerialFormat; PortName : string; BaudRate : integer; Parity : Char; DataBits, Stops : integer; Flow : TMBSerialFlow); overload;

    procedure ChangeTo; overload;
    procedure ChangeTo(Proto : TMBNetProto; Address : string; Port : integer); overload;
    procedure ChangeTo(Format : TMBSerialFormat; PortName : string; BaudRate : integer; Parity : Char; DataBits, Stops : integer; Flow : TMBSerialFlow); overload;

    destructor Destroy; override;
    function AddDevice(Proto : TMBNetProto; DeviceID : byte; Address : string; Port : integer) : integer; overload;
    function AddDevice(Format : TMBSerialFormat; DeviceID : byte; PortName : string; BaudRate : integer; Parity : Char; DataBits, Stops : integer; Flow : TMBSerialFlow) : integer; overload;

    function Connect : integer;
    function Disconnect : integer;

    function SetLocalParam(LocalID : byte; ParamIndex, Value : integer) : integer; overload;
    function SetLocalParam(ParamIndex, Value : integer) : integer; overload;
    function SetRemoteDeviceParam(DeviceID : byte; ParamIndex, Value : integer) : integer; overload;

    function GetBufferSent(DeviceID : byte; Data : Pointer; var Size : integer) : boolean; overload;
    function GetBufferSent(Data : Pointer; var Size : integer) : boolean; overload;
    function GetBufferRecv(DeviceID : byte; Data : Pointer; var Size : integer) : boolean; overload;
    function GetBufferRecv(Data : Pointer; var Size : integer) : boolean; overload;
    // Modbus functions
    function ReadHoldingRegisters(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function WriteMultipleRegisters(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function ReadCoils(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function ReadDiscreteInputs(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function ReadInputRegisters(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function WriteSingleCoil(DeviceID : byte; Address : word; Value : word) : integer;
    function WriteSingleRegister(DeviceID : byte; Address : word; Value : word) : integer;
    function ReadWriteMultipleRegisters(DeviceID : byte; RDAddress, RDAmount, WRAddress, WRAmount : word; pRDUsrData : Pointer; pWRUsrData : Pointer) : integer;
    function WriteMultipleCoils(DeviceID : byte; Address : word; Amount : word; pUsrData : Pointer) : integer;
    function MaskWriteRegister(DeviceID : byte; Address : word; AND_Mask, OR_Mask : word) : integer;
    function ReadFileRecord(DeviceID : byte; RefType : byte; FileNumber, RecNumber, RegsAmount : word; RecData : Pointer) : integer;
    function WriteFileRecord(DeviceID : byte; RefType : byte; FileNumber, RecNumber, RegsAmount : word; RecData : Pointer) : integer;
    function ReadFIFOQueue(DeviceID : byte; Address : word; var FifoCount : word; FIFO : pword) : integer;
    function ReadExceptionStatus(DeviceID : byte; var Data : byte) : integer;
    function Diagnostics(DeviceID : byte; SubFunction : word; pSendData : pword; pRecvData : pword; ItemsToSend: word; var ItemsReceived : word) : integer;
    function GetCommEventCounter(DeviceID : byte; var Status : word; var EventCount : word) : integer;
    function GetCommEventLog(DeviceID : byte; var Status : word; var EventCount : word; var MessageCount : word; var NumItems : word; Events : pbyte) : integer;
    function ReportServerID(DeviceID : byte; pUsrData : Pointer; var DataSize : integer) : integer;
    function ExecuteMEIFunction(DeviceID : byte; MEI_Type : byte; pWRUsrData : Pointer; WRSize : word; pRDUsrData : Pointer; var RDSize : word) : integer;
    function CustomFunctionRequest(DeviceID : byte; UsrFunction : byte; pUsrPDUWrite: Pointer; SizePDUWrite : word; pUsrPDURead : Pointer; var SizePDURead : word; SizePDUExpected : word) : integer;
    function GetDeviceStatus(DeviceID : byte) : TDeviceStatus; overload;
    function GetDeviceStatus : TDeviceStatus; overload;
  end;

//******************************************************************************
// Device Events prototypes
//------------------------------------------------------------------------------
// Note :
//        The Multiplex function device_RegisterCallback() accepts a generic
//        pointer which is casted later, anyway is very important that the
//        function reference passed is *exactly* the same prototype.
//        So, the aim of the next definitions is to be copy-pasted in your code.
//        UsrPtr can be nil or the reference of an object (VCL or other..). Look
//        at the examples, it's very easy ;)
//******************************************************************************
Type
pfn_DeviceEvent = procedure(usrPtr : Pointer; var Event : TSrvEvent; Size : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_PacketLog = procedure(usrPtr : Pointer; Peer : Longword; Direction : integer; Data : Pointer; Size : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_DiscreteInputsRequest = function(usrPtr : Pointer; Address : word; Amount : word; Data : Pointer): integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_CoilsRequest = function(usrPtr : Pointer; Action : integer; Address : word; Amount : word; Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_InputRegistersRequest = function(usrPtr : Pointer; Address : word; Amount : word; Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_HoldingRegistersRequest = function(usrPtr : Pointer; Action : integer; Address : word; Amount : word; Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_ReadWriteMultipleRegistersRequest = function(usrPtr : Pointer; RDAddress : word; RDAmount : word; RDData : Pointer; WRAddress : word; WRAmount : word; WRData : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_MaskRegisterRequest = function(usrPtr : Pointer; Address : word; AND_Mask : word; OR_Mask : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_FileRecordRequest = function(usrPtr : Pointer; Action : integer; RefType : word; FileNumber : word; RecNumber : word; RegsAmount : word; Data : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_ExceptionStatusRequest = function(usrPtr : Pointer; var Status : byte) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_DiagnosticsRequest = function(usrPtr : Pointer; SubFunction : word; RxItems : Pointer; TxItems : Pointer; ItemsSent : integer; var ItemsRecvd : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_GetCommEventCounterRequest = function(usrPtr : Pointer; var Status : word; var EventCount : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_GetCommEventLogRequest = function(usrPtr : Pointer; var Status : word; var EventCount : word; var MessageCount : word; Data : Pointer; var EventsAmount : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_ReportServerIDRequest = function(usrPtr : Pointer; Data : Pointer; var DataSize : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_ReadFIFOQueueRequest = function(usrPtr : Pointer; PtrAddress : word; FIFOValues : Pointer; var FifoCount : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_EncapsulatedIT = function(usrPtr : Pointer; MEI_Type : byte; MEI_DataReq : pointer; ReqDataSize : word; MEI_DataRes : Pointer; var ResDataSize : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_UsrFunctionRequest = function(usrPtr : Pointer; UsrFunction : byte; RxPDU : Pointer; RxPDUSize : word; TxPDU : Pointer; var TxPDUSize : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
pfn_Passthrough = function(usrPtr : Pointer; DeviceID : byte; RxPDU : Pointer; RxPDUSize : word; TxPDU : Pointer; var TxPDUSize : word) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}

//******************************************************************************
// POLYMORPHIC DEVICE WRAPPERS
//******************************************************************************
procedure device_CreateEthernet(Var Device: XOBJECT; Proto : integer; DeviceID : byte; Address : PAnsiChar; Port : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
procedure device_CreateSerial(Var Device: XOBJECT; Format : integer; DeviceID : byte; PortName : PAnsiChar; BaudRate : integer; Parity : AnsiChar; DataBits, Stops, Flow : integer);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
procedure device_Destroy(Var Device: XOBJECT);
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_SetParam(var Device: XOBJECT; ParamIndex, Value : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_BindEthernet(var Device: XOBJECT; DeviceID : byte; Address : PAnsiChar; Port : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_BindSerial(var Device: XOBJECT; DeviceID : byte; PortName : PAnsiChar; BaudRate : integer; Parity : AnsiChar; DataBits, Stops, Flow : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_GetSerialInterframe(var Device: XOBJECT; var InterframeDelay : integer; var MaxInterframeDetected : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_AddPeer(var Device : XOBJECT; Address : PAnsiChar) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_SetUserFunction(var Device : XOBJECT; FunctionID : byte; Value : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_Start(var Device : XOBJECT) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_Stop(var Device : XOBJECT) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_RegisterArea(var Device : XOBJECT; AreaID : integer; Data : Pointer; Amount : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_CopyArea(var Device : XOBJECT; AreaID : integer; Address : word; Amount : Word; Data : Pointer; CopyMode : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_LockArea(var Device : XOBJECT; AreaID : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_UnlockArea(var Device : XOBJECT; AreaID : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_RegisterCallback(var Device : XOBJECT; CallbackID : integer; cbRequest, UsrPtr : Pointer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_PickEvent(var Device : XOBJECT; var Event : TSrvEvent) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_PickEventAsText(var Device : XOBJECT; Text : PAnsiChar; TextSize : integer) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function device_GetDeviceInfo(var Device : XOBJECT; Var Info : TDeviceInfo) : integer;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}

//******************************************************************************
// COMMON
//******************************************************************************
function _ErrorText(Error : integer; Text : PAnsiChar; TextLen : integer) : PAnsiChar;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}
function _EventText(var Event : TSrvEvent; Text : PAnsiChar; TextLen : integer) : PAnsiChar;
{$IFDEF MSWINDOWS}stdcall;{$ELSE}cdecl;{$ENDIF}

type

  { TSnapMBDevice }

  TSnapMBDevice = class(TObject)
  private
    Device : XOBJECT;
  public
    constructor Create(Proto : TMBNetProto; DeviceID : byte; Address : Ansistring; const Port : integer = def_Modbus_Port); overload;
    constructor Create(Format : TMBSerialFormat; DeviceID : byte; PortName : Ansistring; BaudRate : integer; Parity : AnsiChar; DataBits, Stops : integer; Flow : TMBSerialFlow); overload;
    procedure ChangeTo(Proto : TMBNetProto; DeviceID : byte; Address : Ansistring; const Port : integer = def_Modbus_Port); overload;
    procedure ChangeTo(Format : TMBSerialFormat; DeviceID : byte; PortName : Ansistring; BaudRate : integer; Parity : AnsiChar; DataBits, Stops : integer; Flow : TMBSerialFlow); overload;
    destructor Destroy; override;
    function AddPeer(Address : string) : integer;
    function Bind(DeviceID : byte; Address : Ansistring; const Port : integer = def_Modbus_Port) : integer; overload;
    function Bind(DeviceID : byte; PortName : AnsiString; BaudRate : integer; Parity : AnsiChar; DataBits, Stops, Flow : integer) : integer; overload;
    function SetParam(ParamIndex, Value : integer) : integer;
    function GetSerialInterframe(var InterframeDelay : integer; var MaxInterframeDetected : integer): integer;
    function SetUserFunction(FunctionID : byte; Value : boolean) : integer;
    function Start : integer;
    function Stop : integer;
    function RegisterArea(AreaID : TMBArea; Data : Pointer; Amount : integer) : integer;
    function CopyArea(AreaID : integer; Address : word; Amount : Word; Data : Pointer; CopyMode : integer) : integer;
    function LockArea(AreaID : TMBArea) : integer;
    function UnlockArea(AreaID : TMBArea) : integer;
    function RegisterCallback(CallbackID : TCallbackID; cbRequest, UsrPtr : Pointer) : integer;
    function PickEvent(var Event : TSrvEvent) : boolean;
    function PickEventAsText(var Text : String) : boolean;
    function GetDeviceInfo(Var Info : TDeviceInfo) : integer;
  end;

function ErrorText(Error : integer) : string;
function EventText(var Event : TSrvEvent) : string;

implementation
const
  TextLen = 1024;

//******************************************************************************
// POLYMORPHIC BROKER EXTERNALS
//******************************************************************************
procedure broker_CreateFieldController;     external snaplib name 'broker_CreateFieldController';
procedure broker_CreateEthernetClient;      external snaplib name 'broker_CreateEthernetClient';
procedure broker_CreateSerialClient;        external snaplib name 'broker_CreateSerialClient';
procedure broker_Destroy;                   external snaplib name 'broker_Destroy';
function broker_AddControllerNetDevice;     external snaplib name 'broker_AddControllerNetDevice';
function broker_AddControllerSerDevice;     external snaplib name 'broker_AddControllerSerDevice';
function broker_SetLocalParam;              external snaplib name 'broker_SetLocalParam';
function broker_SetRemoteDeviceParam;       external snaplib name 'broker_SetRemoteDeviceParam';
function broker_Connect;                    external snaplib name 'broker_Connect';
function broker_Disconnect;                 external snaplib name 'broker_Disconnect';
function broker_GetIOBufferPtr;             external snaplib name 'broker_GetIOBufferPtr';
function broker_GetIOBuffer;                external snaplib name 'broker_GetIOBuffer';
function broker_GetDeviceStatus;            external snaplib name 'broker_GetDeviceStatus';
// MODBUS Functions
function broker_ReadHoldingRegisters;       external snaplib name 'broker_ReadHoldingRegisters';
function broker_WriteMultipleRegisters;     external snaplib name 'broker_WriteMultipleRegisters';
function broker_ReadCoils;                  external snaplib name 'broker_ReadCoils';
function broker_ReadDiscreteInputs;         external snaplib name 'broker_ReadDiscreteInputs';
function broker_ReadInputRegisters;         external snaplib name 'broker_ReadInputRegisters';
function broker_WriteSingleCoil;            external snaplib name 'broker_WriteSingleCoil';
function broker_WriteSingleRegister;        external snaplib name 'broker_WriteSingleRegister';
function broker_ReadWriteMultipleRegisters; external snaplib name 'broker_ReadWriteMultipleRegisters';
function broker_WriteMultipleCoils;         external snaplib name 'broker_WriteMultipleCoils';
function broker_MaskWriteRegister;          external snaplib name 'broker_MaskWriteRegister';
function broker_ReadFileRecord;             external snaplib name 'broker_ReadFileRecord';
function broker_WriteFileRecord;            external snaplib name 'broker_WriteFileRecord';
function broker_ReadFIFOQueue;              external snaplib name 'broker_ReadFIFOQueue';
function broker_ReadExceptionStatus;        external snaplib name 'broker_ReadExceptionStatus';
function broker_Diagnostics;                external snaplib name 'broker_Diagnostics';
function broker_GetCommEventCounter;        external snaplib name 'broker_GetCommEventCounter';
function broker_GetCommEventLog;            external snaplib name 'broker_GetCommEventLog';
function broker_ReportServerID;             external snaplib name 'broker_ReportServerID';
function broker_ExecuteMEIFunction;         external snaplib name 'broker_ExecuteMEIFunction';
function broker_CustomFunctionRequest;      external snaplib name 'broker_CustomFunctionRequest';
function broker_RawRequest;                 external snaplib name 'broker_RawRequest';
//******************************************************************************
// POLYMORPHIC DEVICE EXTERNALS
//******************************************************************************
procedure device_CreateEthernet;      external snaplib name 'device_CreateEthernet';
procedure device_CreateSerial;        external snaplib name 'device_CreateSerial';
procedure device_Destroy;             external snaplib name 'device_Destroy';
function device_SetParam;             external snaplib name 'device_SetParam';
function device_BindEthernet;         external snaplib name 'device_BindEthernet';
function device_BindSerial;           external snaplib name 'device_BindSerial';
function device_GetSerialInterframe;  external snaplib name 'device_GetSerialInterframe';
function device_AddPeer;              external snaplib name 'device_AddPeer';
function device_SetUserFunction;      external snaplib name 'device_SetUserFunction';
function device_Start;                external snaplib name 'device_Start';
function device_Stop;                 external snaplib name 'device_Stop';
function device_RegisterArea;         external snaplib name 'device_RegisterArea';
function device_CopyArea;             external snaplib name 'device_CopyArea';
function device_LockArea;             external snaplib name 'device_LockArea';
function device_UnlockArea;           external snaplib name 'device_UnlockArea';
function device_RegisterCallback;     external snaplib name 'device_RegisterCallback';
function device_PickEvent;            external snaplib name 'device_PickEvent';
function device_PickEventAsText;      external snaplib name 'device_PickEventAsText';
function device_GetDeviceInfo;        external snaplib name 'device_GetDeviceInfo';
//******************************************************************************
// COMMON EXTERNALS
//******************************************************************************
function _ErrorText;                   external snaplib name 'ErrorText';
function _EventText;                   external snaplib name 'EventText';

{ TSnapMBBroker }

constructor TSnapMBBroker.Create;
begin
  broker_CreateFieldController(Broker);
end;

constructor TSnapMBBroker.Create(Proto: TMBNetProto; Address: string; Port : integer );
begin
  broker_CreateEthernetClient(Broker, Ord(Proto), PAnsiChar(Address), Port);
end;

constructor TSnapMBBroker.Create(Format : TMBSerialFormat; PortName: string; BaudRate: integer;
  Parity: Char; DataBits, Stops : integer; Flow : TMBSerialFlow);
begin
  broker_CreateSerialClient(Broker, Ord(Format), PAnsiChar(PortName), BaudRate, AnsiChar(Parity), DataBits, Stops, ord(Flow));
end;

function TSnapMBBroker.Connect: integer;
begin
  Result := broker_Connect(Broker);
end;

procedure TSnapMBBroker.ChangeTo;
begin
  if Broker.MBObject<>0 then
    broker_Destroy(Broker);
  broker_CreateFieldController(Broker);
end;

procedure TSnapMBBroker.ChangeTo(Proto: TMBNetProto; Address: string; Port: integer);
begin
  if Broker.MBObject<>0 then
    broker_Destroy(Broker);
  broker_CreateEthernetClient(Broker, Ord(Proto), PAnsiChar(Address), Port);
end;

procedure TSnapMBBroker.ChangeTo(Format : TMBSerialFormat; PortName: string; BaudRate: integer;
  Parity: Char; DataBits, Stops: integer; Flow: TMBSerialFlow);
begin
  if Broker.MBObject<>0 then
    broker_Destroy(Broker);
  broker_CreateSerialClient(Broker, Ord(Format), PAnsiChar(PortName), BaudRate, AnsiChar(Parity), DataBits, Stops, ord(Flow));
end;

function TSnapMBBroker.CustomFunctionRequest(DeviceID: byte;
  UsrFunction : byte; pUsrPDUWrite: Pointer; SizePDUWrite: word;
  pUsrPDURead: Pointer; var SizePDURead: word; SizePDUExpected: word): integer;
begin
  Result := broker_CustomFunctionRequest(Broker, DeviceID, UsrFunction, pUsrPDUWrite, SizePDUWrite, pUsrPDURead, SizePDURead, SizePDUExpected);
end;

function TSnapMBBroker.GetDeviceStatus(DeviceID: byte): TDeviceStatus;
begin
  broker_GetDeviceStatus(Broker, DeviceID, {%H-}Result);
end;

function TSnapMBBroker.GetDeviceStatus: TDeviceStatus;
begin
  Result:=GetDeviceStatus(0);
end;

destructor TSnapMBBroker.Destroy;
begin
  broker_Destroy(Broker);
  inherited;
end;

function TSnapMBBroker.AddDevice(Proto: TMBNetProto; DeviceID: byte;
  Address: string; Port: integer): integer;
begin
  Result := broker_AddControllerNetDevice(Broker, Ord(Proto), DeviceID, PAnsiChar(Address), Port);
end;

function TSnapMBBroker.AddDevice(Format: TMBSerialFormat; DeviceID: byte;
  PortName: string; BaudRate: integer; Parity: Char; DataBits, Stops: integer;
  Flow: TMBSerialFlow): integer;
begin
  Result := broker_AddControllerSerDevice(Broker, Ord(Format), DeviceID, PAnsiChar(PortName), BaudRate, AnsiChar(Parity), DataBits, Stops, ord(Flow));
end;

function TSnapMBBroker.Diagnostics(DeviceID : byte; SubFunction : word; pSendData : pword;
  pRecvData : pword; ItemsToSend: word; var ItemsReceived : word) : integer;
begin
  Result := broker_Diagnostics(Broker, DeviceID, SubFunction, pSendData, pRecvData, ItemsToSend, ItemsReceived);
end;

function TSnapMBBroker.Disconnect: integer;
begin
  Result := broker_Disconnect(Broker);
end;

function TSnapMBBroker.ExecuteMEIFunction(DeviceID: byte; MEI_Type: byte;
  pWRUsrData: Pointer; WRSize: word; pRDUsrData: Pointer; var RDSize: word): integer;
begin
  Result := broker_ExecuteMEIFunction(Broker, DeviceID, MEI_Type, pWRUsrData, WRSize, pRDUsrData, RDSize);
end;

function TSnapMBBroker.GetBufferRecv(Data: Pointer; var Size: integer): boolean;
begin
  Size := broker_GetIOBuffer(Broker, 0, ord(BkRcv), Data);
  Result := Size > 0;
end;

function TSnapMBBroker.GetBufferRecv(DeviceID: byte; Data: Pointer;
  var Size: integer): boolean;
begin
  Size := broker_GetIOBuffer(Broker, DeviceID, ord(BkRcv), Data);
  Result := Size > 0;
end;

function TSnapMBBroker.GetBufferSent(Data: Pointer; var Size: integer): boolean;
begin
  Size := broker_GetIOBuffer(Broker, 0, ord(BkSnd), Data);
  Result := Size > 0;
end;

function TSnapMBBroker.GetBufferSent(DeviceID: byte; Data: Pointer;
  var Size: integer): boolean;
begin
  Size := broker_GetIOBuffer(Broker, DeviceID, ord(BkSnd), Data);
  Result := Size > 0;
end;

function TSnapMBBroker.GetCommEventCounter(DeviceID: byte; var Status: word;
  var EventCount: word): integer;
begin
  Result := broker_GetCommEventCounter(Broker, DeviceID, Status, EventCount);
end;

function TSnapMBBroker.GetCommEventLog(DeviceID: byte; var Status: word;
  var EventCount: word; var MessageCount: word; var NumItems: word;
  Events: pbyte): integer;
begin
  Result := broker_GetCommEventLog(Broker, DeviceID, Status, EventCount, MessageCount, NumItems, Events);
end;

function TSnapMBBroker.MaskWriteRegister(DeviceID: byte; Address: word;
  AND_Mask, OR_Mask: word): integer;
begin
  Result := broker_MaskWriteRegister(Broker, DeviceID, Address, AND_Mask, OR_Mask);
end;

function TSnapMBBroker.ReadCoils(DeviceID: byte; Address: word; Amount: word;
  pUsrData: Pointer): integer;
begin
  Result := broker_ReadCoils(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.ReadDiscreteInputs(DeviceID: byte; Address: word;
  Amount: word; pUsrData: Pointer): integer;
begin
  Result := broker_ReadDiscreteInputs(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.ReadExceptionStatus(DeviceID: byte;
  var Data: byte): integer;
begin
  Result := broker_ReadExceptionStatus(Broker, DeviceId, Data);
end;

function TSnapMBBroker.ReadFIFOQueue(DeviceID: byte; Address: word;
  var FifoCount: word; FIFO: pword): integer;
begin
  Result := broker_ReadFIFOQueue(Broker, DeviceID, Address, FifoCount, FIFO);
end;

function TSnapMBBroker.ReadFileRecord(DeviceID: byte; RefType: byte;
  FileNumber, RecNumber, RegsAmount: word; RecData: Pointer): integer;
begin
  Result := broker_ReadFileRecord(Broker, DeviceID, RefType, FileNumber, RecNumber, RegsAmount, RecData);
end;

function TSnapMBBroker.ReadHoldingRegisters(DeviceID: byte; Address: word;
  Amount: word; pUsrData: Pointer): integer;
begin
  Result := broker_ReadHoldingRegisters(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.ReadInputRegisters(DeviceID: byte; Address: word;
  Amount: word; pUsrData: Pointer): integer;
begin
  Result := broker_ReadInputRegisters(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.ReadWriteMultipleRegisters(DeviceID: byte; RDAddress,
  RDAmount, WRAddress, WRAmount: word; pRDUsrData: Pointer; pWRUsrData: Pointer
  ): integer;
begin
  Result := broker_ReadWriteMultipleRegisters(Broker, DeviceID, RDAddress, RDAmount, WRAddress, WRAmount, pRDUsrData, pWRUsrData);
end;

function TSnapMBBroker.ReportServerID(DeviceID: byte; pUsrData: Pointer;
  var DataSize: integer): integer;
begin
  Result := broker_ReportServerID(Broker, DeviceID, pUsrData, DataSize);
end;

function TSnapMBBroker.SetLocalParam(LocalID: byte; ParamIndex,
  Value: integer): integer;
begin
  Result := broker_SetLocalParam(Broker, LocalID, ParamIndex, Value);
end;

function TSnapMBBroker.SetLocalParam(ParamIndex, Value: integer): integer;
begin
  Result := broker_SetLocalParam(Broker, 0, ParamIndex, Value);
end;

function TSnapMBBroker.SetRemoteDeviceParam(DeviceID: byte; ParamIndex,
  Value: integer): integer;
begin
  Result := broker_SetRemoteDeviceParam(Broker, DeviceID, ParamIndex, Value);
end;

function TSnapMBBroker.WriteFileRecord(DeviceID: byte; RefType: byte;
  FileNumber, RecNumber, RegsAmount: word; RecData: Pointer): integer;
begin
  Result := broker_WriteFileRecord(Broker, DeviceID, RefType, FileNumber, RecNumber, RegsAmount, RecData);
end;

function TSnapMBBroker.WriteMultipleCoils(DeviceID: byte; Address: word;
  Amount: word; pUsrData: Pointer): integer;
begin
  Result := broker_WriteMultipleCoils(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.WriteMultipleRegisters(DeviceID: byte; Address: word;
  Amount: word; pUsrData: Pointer): integer;
begin
  Result := broker_WriteMultipleRegisters(Broker, DeviceID, Address, Amount, pUsrData);
end;

function TSnapMBBroker.WriteSingleCoil(DeviceID: byte; Address: word;
  Value: word): integer;
begin
  Result := broker_WriteSingleCoil(Broker, DeviceID, Address, Value);
end;

function TSnapMBBroker.WriteSingleRegister(DeviceID: byte; Address: word;
  Value: word): integer;
begin
  Result := broker_WriteSingleRegister(Broker, DeviceID, Address, Value);
end;

{ TSnapMBDevice }

constructor TSnapMBDevice.Create(Proto: TMBNetProto; DeviceID: byte;
  Address: Ansistring; const Port : integer = def_Modbus_Port);
begin
  device_CreateEthernet(Device, Ord(Proto), DeviceID, PAnsiChar(Address), Port);
end;

constructor TSnapMBDevice.Create(Format: TMBSerialFormat; DeviceID: byte;
  PortName: Ansistring; BaudRate: integer; Parity: AnsiChar; DataBits, Stops : integer;
  Flow: TMBSerialFlow);
begin
  device_CreateSerial(Device, Ord(Format), DeviceID, PAnsiChar(PortName), BaudRate, AnsiChar(Parity), DataBits, Stops, ord(Flow));
end;

procedure TSnapMBDevice.ChangeTo(Proto: TMBNetProto; DeviceID: byte;
  Address: Ansistring; const Port: integer);
begin
  if Device.MBObject<>0 then
    Device_Destroy(Device);
  device_CreateEthernet(Device, Ord(Proto), DeviceID, PAnsiChar(Address), Port);
end;

procedure TSnapMBDevice.ChangeTo(Format: TMBSerialFormat; DeviceID: byte;
  PortName: Ansistring; BaudRate: integer; Parity: AnsiChar; DataBits,
  Stops: integer; Flow: TMBSerialFlow);
begin
  if Device.MBObject<>0 then
    Device_Destroy(Device);
  device_CreateSerial(Device, Ord(Format), DeviceID, PAnsiChar(PortName), BaudRate, AnsiChar(Parity), DataBits, Stops, ord(Flow));
end;

function TSnapMBDevice.AddPeer(Address: string): integer;
begin
  Result := device_AddPeer(Device, PAnsiChar(Address));
end;

function TSnapMBDevice.Bind(DeviceID: byte; Address: Ansistring;
  const Port: integer): integer;
begin
  Result := device_BindEthernet(Device, DeviceID, PAnsiChar(Address), Port);
end;

function TSnapMBDevice.Bind(DeviceID: byte; PortName: AnsiString;
  BaudRate: integer; Parity: AnsiChar; DataBits, Stops, Flow: integer): integer;
begin
  Result := device_BindSerial(Device, DeviceID, PAnsiChar(PortName), BaudRate, Parity, DataBits, Stops, Flow);
end;

destructor TSnapMBDevice.Destroy;
begin
  device_Destroy(Device);
  inherited;
end;

function TSnapMBDevice.PickEvent(var Event : TSrvEvent): boolean;
begin
  Result := device_PickEvent(Device, Event) <> 0;
end;

function TSnapMBDevice.PickEventAsText(var Text : String) : boolean;
Var
  AnsiText : packed array [0..511] of AnsiChar;
begin
  Result := device_PickEventAsText(Device, @AnsiText, 511) <> 0;
  if Result then
    Text := AnsiText;
end;

function TSnapMBDevice.GetDeviceInfo(var Info: TDeviceInfo): integer;
begin
  Result := device_GetDeviceInfo(Device, Info);
end;

function TSnapMBDevice.RegisterArea(AreaID: TMBArea; Data: Pointer;
  Amount: integer): integer;
begin
  Result := device_RegisterArea(Device, Ord(AreaID), Data, Amount);
end;

function TSnapMBDevice.CopyArea(AreaID: integer; Address: word; Amount: Word;
  Data: Pointer; CopyMode: integer): integer;
begin
  Result := device_CopyArea(Device, AreaID, Address, Amount, Data, CopyMode);
end;

function TSnapMBDevice.LockArea(AreaID: TMBArea): integer;
begin
  Result := device_LockArea(Device, Ord(AreaID));
end;

function TSnapMBDevice.UnlockArea(AreaID: TMBArea): integer;
begin
  Result := device_UnlockArea(Device, Ord(AreaID));
end;

function TSnapMBDevice.RegisterCallback(CallbackID: TCallbackID; cbRequest,
  UsrPtr: Pointer): integer;
begin
  Result := device_RegisterCallback(Device, ord(CallbackID), cbRequest, UsrPtr);
end;

function TSnapMBDevice.SetUserFunction(FunctionID: byte;
  Value: boolean): integer;
begin
  Result := device_SetUserFunction(Device, FunctionID, integer(Value));
end;

function TSnapMBDevice.SetParam(ParamIndex, Value: integer): integer;
begin
  Result := device_SetParam(Device, ParamIndex, Value);
end;

function TSnapMBDevice.GetSerialInterframe(var InterframeDelay: integer;
  var MaxInterframeDetected: integer): integer;
begin
  Result := device_GetSerialInterframe(Device, InterframeDelay, MaxInterframeDetected);
end;

function TSnapMBDevice.Start: integer;
begin
  Result := device_Start(Device);
end;

function TSnapMBDevice.Stop: integer;
begin
  Result := device_Stop(Device);
end;

function ErrorText(Error : integer) : string;
Var
  Text : packed array[0..TextLen-1] of AnsiChar;
begin
  Result:=string(_ErrorText(Error, @Text, TextLen));
end;

function EventText(var Event : TSrvEvent) : string;
Var
  Text : packed array[0..TextLen-1] of AnsiChar;
begin
  Result:=string(_EventText(Event, @Text, TextLen));
end;

end.



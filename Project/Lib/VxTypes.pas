unit VxTypes;

{$MODE Delphi}

interface

uses
  Classes, SysUtils;

Type
  TCommRegisterRead      = function(index : integer; var Value : Word) : integer; stdcall;
  TCommRegisterWrite     = procedure(index : integer; Value : Word); stdcall;
  TCommRegisterFastWrite = function(index : integer; Value : Word) : integer; stdcall;
  TCommReadRegisterAdd   = function(Address : Word) : integer; stdcall;
  TCommWriteRegisterAdd  = function(Address : Word; Fast : integer; InitValue : word) : integer; stdcall;
  TCommRegisterStatus    = function(Kind : integer; Index : integer) : integer; stdcall;

  THooksRecord = packed record
    CommRegisterRead      : TCommRegisterRead;
    CommRegisterWrite     : TCommRegisterWrite;
    CommRegisterFastWrite : TCommRegisterFastWrite;
    CommReadRegisterAdd   : TCommReadRegisterAdd;
    CommWriteRegisterAdd  : TCommWriteRegisterAdd;
    CommRegisterStatus    : TCommRegisterStatus;
  end;

  PHooksRecord = ^THooksRecord;

implementation

end.


{
    This file is part of the Free Component library.
    Copyright (c) 2005 by Michael Van Canneyt, member of
    the Free Pascal development team

    Unix implementation of one-way IPC between 2 processes

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$ifdef ipcunit}
unit pipesipc;

interface

{$IFDEF FPC_DOTTEDUNITS}
uses System.SysUtils, System.Classes, System.Simpleipc, UnixApi.Base, UnixApi.Unix;
{$ELSE FPC_DOTTEDUNITS}
uses sysutils, classes, simpleipc, baseunix, unix;
{$ENDIF FPC_DOTTEDUNITS}

{$else}

{$IFDEF FPC_DOTTEDUNITS}
uses UnixApi.Base, UnixApi.Unix;
{$ELSE FPC_DOTTEDUNITS}
uses baseunix, unix;
{$ENDIF FPC_DOTTEDUNITS}
{$endif}


ResourceString
  SErrFailedToCreatePipe = 'Failed to create named pipe: %s';
  SErrFailedToRemovePipe = 'Failed to remove named pipe: %s';

{ ---------------------------------------------------------------------
    TPipeClientComm
  ---------------------------------------------------------------------}

Type
  TPipeClientComm = Class(TIPCClientComm)
  Private
    FFileName: String;
    FStream: TFileStream;
  Public
    Constructor Create(aOwner : TSimpleIPCClient); override;
    Procedure Connect; override;
    Procedure Disconnect; override;
    Procedure SendMessage(AMsgType : TMessageType; AStream : TStream); override;
    Function  ServerRunning : Boolean; override;
    Property FileName : String Read FFileName;
    Property Stream : TFileStream Read FStream;
  end;

{$ifdef ipcunit}
implementation
{$endif}

constructor TPipeClientComm.Create(aOwner: TSimpleIPCClient);
begin
  inherited Create(aOwner);
  FFileName:=Owner.ServerID;
  If (Owner.ServerInstance<>'') then
    FFileName:=FFileName+'-'+Owner.ServerInstance;
  if FFileName[1]<>'/' then
    FFileName:=GetTempDir(aOwner.SystemGlobal)+FFileName;
end;


procedure TPipeClientComm.Connect;
begin
  If Not ServerRunning then
    DoError(SErrServerNotActive,[Owner.ServerID]);
  // Lock per complete message, rather than holding a shared open-time lock.
  FStream:=TFileStream.Create(FFileName,fmOpenWrite or fmShareNoLocking);
end;

procedure TPipeClientComm.Disconnect;
begin
  FreeAndNil(FStream);
end;

procedure TPipeClientComm.SendMessage(AMsgType : TMessagetype; AStream: TStream);
var
  lHeader: TMsgHeader;
  lFrame: TMemoryStream;
begin
  lFrame:=TMemoryStream.Create;
  try
    lHeader.Version:=MsgVersion;
    lHeader.MsgType:=AMsgType;
    lHeader.MsgLen:=AStream.Size;
    lFrame.WriteBuffer(lHeader,SizeOf(lHeader));
    lFrame.CopyFrom(AStream,0);
    // Each client opens the same FIFO separately. Hold its advisory lock for
    // the whole frame, including payloads larger than PIPE_BUF.
    if fpFlock(FStream.Handle,LOCK_EX)<>0 then
      RaiseLastOSError;
    try
      FStream.CopyFrom(lFrame,0);
    finally
      if fpFlock(FStream.Handle,LOCK_UN)<>0 then
        RaiseLastOSError;
    end;
  finally
    lFrame.Free;
  end;
end;

function TPipeClientComm.ServerRunning: Boolean;
var
  fd: cint;
begin
  Result:=FileExists(FFileName);
  // it's possible to have a stale file that is not open for reading which will
  // cause fpOpen to hang/block later when .Active is set to true while it
  // waits for the pipe to be opened on the other end
  if Result then
  begin
    // O_WRONLY | O_NONBLOCK causes fpOpen to return -1 if the file is not open for reading
    // so in fact the 'server' is not running
    fd := FpOpen(FFileName, O_WRONLY or O_NONBLOCK);
    if fd = -1 then
    begin
      Result := False;
      // delete the named pipe since it's orphaned
      FpUnlink(FFileName);
    end
    else
      FpClose(fd);
  end;
end;


{ ---------------------------------------------------------------------
    TPipeServerComm
  ---------------------------------------------------------------------}

Type

  { TPipeServerComm }

  TPipeServerComm = Class(TIPCServerComm)
  Private
    FFileName: String;
    FStream: TFileStream;
  Public
    Constructor Create(AOWner : TSimpleIPCServer); override;
    Procedure StartServer; override;
    Procedure StopServer; override;
    Function  PeekMessage(TimeOut : Integer) : Boolean; override;
    Procedure ReadMessage ; override;
    Function GetInstanceID : String;override;
    Property FileName : String Read FFileName;
    Property Stream : TFileStream Read FStream;
  end;


constructor TPipeServerComm.Create(AOWner: TSimpleIPCServer);
begin
  inherited Create(AOWner);
  FFileName:=Owner.ServerID;
  If not Owner.Global then
    FFileName:=FFileName+'-'+IntToStr(fpGetPID);
  if FFileName[1]<>'/' then
    FFileName:=GetTempDir(Owner.SystemGlobal)+FFileName;
end;


procedure TPipeServerComm.StartServer;

const
  PrivateRights = S_IRUSR or S_IWUSR;
  GlobalRights  = PrivateRights or S_IRGRP or S_IWGRP or S_IROTH or S_IWOTH;
  Rights : Array [Boolean] of Integer = (PrivateRights,GlobalRights);

begin
  If not FileExists(FFileName) then
    If (fpmkFifo(FFileName,438)<>0) then
      DoError(SErrFailedToCreatePipe,[FFileName]);
  if not Owner.Global then
    fpChmod(FFileName,&600);
  FStream:=TFileStream.Create(FFileName,fmOpenReadWrite or fmShareNoLocking,Rights[Owner.Global]);
end;

procedure TPipeServerComm.StopServer;
begin
  FreeAndNil(FStream);
  if Not DeleteFile(FFileName) then
    DoError(SErrFailedtoRemovePipe,[FFileName]);
end;

function TPipeServerComm.PeekMessage(TimeOut: Integer): Boolean;
Var
  FDS : TFDSet;
begin
  fpfd_zero(FDS);
  fpfd_set(FStream.Handle,FDS);
  Result := fpSelect(FStream.Handle+1,@FDS,Nil,Nil,TimeOut)>0;
end;

procedure TPipeServerComm.ReadMessage;
Var
  Hdr : TMsgHeader;
begin
  FStream.ReadBuffer(Hdr,SizeOf(Hdr));
  PushMessage(Hdr,FStream);
end;


function TPipeServerComm.GetInstanceID: String;
begin
  Result:=IntToStr(fpGetPID);
end;


{ ---------------------------------------------------------------------
    Set TSimpleIPCClient / TSimpleIPCServer defaults.
  ---------------------------------------------------------------------}

{$ifndef ipcunit}
function TSimpleIPCServer.CommClass: TIPCServerCommClass;

begin
  if (DefaultIPCServerClass<>Nil) then
    Result:=DefaultIPCServerClass
  else
    Result:=TPipeServerComm;
end;

function TSimpleIPCClient.CommClass: TIPCClientCommClass;
begin
  if (DefaultIPCClientClass<>Nil) then
    Result:=DefaultIPCClientClass
  else
    Result:=TPipeClientComm;
end;

{$else ipcunit}

end.
{$endif}

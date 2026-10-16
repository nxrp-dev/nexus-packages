// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLProcessProbe;

{$mode objfpc}{$H+}

interface

uses obNXTestContext;

procedure RunFCLProcessProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
procedure RunFCLProcessChild;
{$IFDEF MSWINDOWS}procedure RunFCLProcessService;{$ENDIF}

implementation

uses
  Classes, SysUtils, Process, Pipes, SimpleIPC, SyncIPC,
  {$IFDEF UNIX}BaseUnix, Unix,{$ENDIF}
  {$IFDEF MSWINDOWS}Windows, obFCLProcessWindowsProbe,{$ENDIF}
  obNXTestResult;

type
  TIntegerInput = class(TMemoryStream)
  public
    function Read(var ABuffer; ACount: LongInt): LongInt; override;
  end;

  THandleProvider = class
  private
    FFileName: string;
  public
    constructor Create(const AFileName: string);
    procedure Acquire(ASender: TObject; var AHandle: THandle;
      var ACloseOnExecute: Boolean);
  end;

  TCountedMessage = class(TIPCServerMsg)
  private
    FCounter: PInteger;
  public
    constructor Create(ACounter: PInteger);
    destructor Destroy; override;
  end;

  TQueueServer = class(TSimpleIPCServer)
  private
    FQueued: Integer;
    procedure Queued(ASender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Enqueue(AMessage: TIPCServerMsg);
    property QueuedCount: Integer read FQueued;
  end;

  TBarrierStream = class(TMemoryStream)
  private
    FDirectory: string;
    FId: Integer;
    FEntered: Boolean;
  public
    constructor Create(const ADirectory: string; AId: Integer);
    function Read(var ABuffer; ACount: LongInt): LongInt; override;
  end;

procedure SaveText(const AFileName, AText: string);
var
  lText: TStringList;
begin
  lText := TStringList.Create;
  try
    lText.Text := AText;
    lText.SaveToFile(AFileName);
  finally
    lText.Free;
  end;
end;

function ReadText(AStream: TStream): string;
var
  lBytes: UTF8String;
begin
  AStream.Position := 0;
  SetLength(lBytes, AStream.Size);
  if Length(lBytes) > 0 then
    AStream.ReadBuffer(lBytes[1], Length(lBytes));
  Result := UTF8Decode(lBytes);
end;

function Child(const AMode: string): TProcess;
begin
  Result := TProcess.Create(nil);
  Result.Executable := ParamStr(0);
  Result.Parameters.Add('--child');
  Result.Parameters.Add(AMode);
end;

procedure StopChild(AProcess: TProcess);
begin
  if AProcess.Running then
  begin
    AProcess.Terminate(1);
    AProcess.WaitOnExit;
  end;
end;

function TIntegerInput.Read(var ABuffer; ACount: LongInt): LongInt;
begin
  if (Position > 0) and (ACount > SizeOf(Integer)) then
    raise ENXTestFailure.CreateFmt('Decoder requested %d bytes for an Integer.', [ACount]);
  Result := inherited Read(ABuffer, ACount);
end;

constructor THandleProvider.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
end;

procedure THandleProvider.Acquire(ASender: TObject; var AHandle: THandle;
  var ACloseOnExecute: Boolean);
begin
  AHandle := FileOpen(FFileName, fmOpenRead);
  if AHandle = THandle(-1) then
    raise Exception.Create('Could not open callback input.');
  ACloseOnExecute := True;
end;

constructor TCountedMessage.Create(ACounter: PInteger);
begin
  inherited Create;
  FCounter := ACounter;
end;

destructor TCountedMessage.Destroy;
begin
  Inc(FCounter^);
  inherited Destroy;
end;

constructor TQueueServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OnMessageQueued:=@Queued;
end;

procedure TQueueServer.Queued(ASender: TObject);
begin
  Inc(FQueued);
end;

procedure TQueueServer.Enqueue(AMessage: TIPCServerMsg);
begin
  PushMessage(AMessage);
end;

constructor TBarrierStream.Create(const ADirectory: string; AId: Integer);
var
  lData: AnsiString;
begin
  inherited Create;
  FDirectory := IncludeTrailingPathDelimiter(ADirectory);
  FId := AId;
  lData := StringOfChar(AnsiChar(Ord('a') + AId), 131072);
  WriteBuffer(lData[1], Length(lData));
  Position := 0;
end;

function TBarrierStream.Read(var ABuffer; ACount: LongInt): LongInt;
var
  lStart: QWord;
begin
  if not FEntered then
  begin
    FEntered := True;
    SaveText(FDirectory + IntToStr(FId) + '.ready', 'ready');
    lStart := GetTickCount64;
    while not FileExists(FDirectory + IntToStr(1 - FId) + '.ready') do
    begin
      if GetTickCount64 - lStart > 3000 then
        raise Exception.Create('The other FIFO writer did not reach the barrier.');
      Sleep(1);
    end;
  end;
  Result := inherited Read(ABuffer, ACount);
end;

procedure Probe01(AContext: TNXTestContext);
var
  lProcess: TProcess;
  lRejected: Boolean;
begin
  {$IFDEF UNIX}
  lProcess := TProcess.Create(nil);
  try
    AContext.AssertFalse(lProcess.Terminate(0), 'No child exists to terminate.');
    AContext.AssertEquals(-1, lProcess.Suspend, 'No child exists to suspend.');
    AContext.AssertEquals(-1, lProcess.Resume, 'No child exists to resume.');
    lProcess.Executable:=ParamStr(0)+'.missing';
    lRejected:=False;
    try
      lProcess.Execute;
    except
      on E: EProcess do lRejected:=True;
    end;
    AContext.AssertTrue(lRejected,'Startup of a missing executable must fail.');
    AContext.AssertFalse(lProcess.Terminate(0),'Signaling after failed startup.');
    AContext.AssertEquals(-1,lProcess.Suspend);
    AContext.AssertEquals(-1,lProcess.Resume);
    lProcess.Executable:=ParamStr(0);
    lProcess.Parameters.Add('--child');
    lProcess.Parameters.Add('sleep');
    lProcess.Parameters.Add('0');
    lProcess.Execute;
    AContext.AssertTrue(lProcess.WaitOnExit(1000));
    AContext.AssertFalse(lProcess.Terminate(0),'Signaling after child exit.');
    AContext.AssertEquals(-1,lProcess.Suspend);
    AContext.AssertEquals(-1,lProcess.Resume);
  finally
    lProcess.Free;
  end;
  {$ELSE}
  AContext.Skip('Unix process-group signaling case.');
  {$ENDIF}
end;

procedure Probe02(AContext: TNXTestContext);
var
  lStream: TIntegerInput;
  lWidth: Byte;
  lValue, lIndex: Integer;
  lRejected: Boolean;
begin
  lStream := TIntegerInput.Create;
  try
    lWidth := SizeOf(Integer) + 1;
    lStream.WriteBuffer(lWidth, 1);
    lValue := 0;
    for lIndex := 1 to lWidth do
      lStream.WriteBuffer(lValue, 1);
    lStream.Position := 0;
    lRejected := False;
    try
      ReadInt(lStream, lWidth);
    except
      on E: EReadError do lRejected := True;
    end;
    AContext.AssertTrue(lRejected, 'Oversized integer width must be rejected before reading it.');
    lStream.Clear;
    lRejected := False;
    try
      WriteInt(lStream, 42, SizeOf(Integer) + 1);
    except
      on E: EWriteError do lRejected := True;
    end;
    AContext.AssertTrue(lRejected, 'Oversized integer writes must be rejected.');
    for lIndex := 1 to SizeOf(Integer) do
      if lIndex in [1, 2, 4] then
      begin
        lStream.Clear;
        WriteInt(lStream, 42, lIndex);
        lStream.Position := 0;
        AContext.AssertEquals(42, ReadInt(lStream, lWidth), 'Smaller-width integer decoding.');
        AContext.AssertEquals(lIndex, lWidth);
      end;
    lStream.Clear;
    lWidth := 4;
    lStream.WriteBuffer(lWidth, 1);
    lStream.Position := 0;
    lRejected := False;
    try
      ReadInt(lStream, lWidth);
    except
      on E: EReadError do lRejected := True;
    end;
    AContext.AssertTrue(lRejected, 'Truncated integer payload must be rejected.');
    lStream.Clear;
    lWidth:=0;
    lStream.WriteBuffer(lWidth,1);
    lStream.Position:=0;
    lRejected:=False;
    try
      ReadInt(lStream,lWidth);
    except
      on E: EReadError do lRejected:=True;
    end;
    AContext.AssertTrue(lRejected,'A zero width on the wire is invalid.');
    lStream.Clear;
    WriteInt(lStream,-42,0);
    lStream.Position:=0;
    AContext.AssertEquals(-42,ReadInt(lStream,lWidth),'Full-width negative integer.');
  finally
    lStream.Free;
  end;
end;

procedure Probe03(AContext: TNXTestContext);
var
  lOwner, lPeerOwner: TComponent;
  lProcess, lPeer: TProcess;
  lRejected: Boolean;
begin
  lOwner := TComponent.Create(nil);
  lPeerOwner:=TComponent.Create(nil);
  try
    lProcess := TProcess.Create(lOwner);
    lPeer := TProcess.Create(lPeerOwner);
    lProcess.OutputDescriptor.Process := lPeer;
    AContext.AssertTrue(lProcess.Owner = lOwner, 'Pipeline assignment changed the process Owner.');
    AContext.AssertEquals(1,lOwner.ComponentCount);
    AContext.AssertTrue(lPeer.Owner=lPeerOwner,'Pipeline assignment changed the peer Owner.');
    AContext.AssertEquals(1,lPeerOwner.ComponentCount);
    lProcess.OutputDescriptor.Process := nil;
    AContext.AssertTrue(lProcess.OutputDescriptor.Process = nil, 'Pipeline disconnection.');
    lRejected := False;
    try
      lProcess.OutputDescriptor.Process := lProcess;
    except
      on E: EProcess do lRejected := True;
    end;
    AContext.AssertTrue(lRejected, 'A process cannot be its own pipeline peer.');
    lProcess.OutputDescriptor.Process := lPeer;
    lProcess.ErrorDescriptor.Process:=lPeer;
    lProcess.OutputDescriptor.Process:=nil;
    lPeer.Free;
    AContext.AssertTrue(lProcess.OutputDescriptor.Process = nil, 'Destroyed peer was retained.');
    AContext.AssertTrue(lProcess.ErrorDescriptor.Process = nil,
      'Removing one of two references lost the peer destruction notification.');
    AContext.AssertTrue(lProcess.ErrorDescriptor.IOType <> iotProcess,
      'Destroyed peer left an active process descriptor.');
  finally
    lPeerOwner.Free;
    lOwner.Free;
  end;
end;

procedure Probe04(AContext: TNXTestContext);
var
  lProcess: TProcess;
  lByte: Byte;
  lExited: Boolean;
begin
  lProcess := Child('eof');
  try
    lProcess.Options := [poUsePipes];
    lProcess.Execute;
    lByte := 42;
    lProcess.Input.WriteBuffer(lByte, 1);
    lProcess.CloseInput;
    lProcess.CloseInput;
    lExited := lProcess.WaitOnExit(1000);
    AContext.AssertTrue(lExited, 'Child did not receive EOF after CloseInput.');
    AContext.AssertTrue(lProcess.Input=nil,'A closed pipe stream was recreated.');
    AContext.AssertEquals(0, lProcess.ExitCode);
  finally
    StopChild(lProcess);
    lProcess.Free;
  end;
end;

procedure Probe05(AContext: TNXTestContext);
var
  lProcess: TProcess;
  lStream: TMemoryStream;
begin
  lProcess := Child('streams');
  lStream := TMemoryStream.Create;
  try
    lProcess.Options := [poUsePipes];
    lProcess.Execute;
    AContext.AssertTrue(lProcess.WaitOnExit(1000), 'Output child did not exit.');
    AContext.AssertTrue(lProcess.ReadInputStream(lProcess.Stderr, lStream), 'No stderr data.');
    AContext.AssertEquals('stderr', ReadText(lStream), 'The stream-copy overload read stdout.');
    lStream.Clear;
    AContext.AssertTrue(lProcess.ReadInputStream(lProcess.Output,lStream));
    AContext.AssertEquals('stdout',ReadText(lStream),'Reading stderr consumed stdout.');
  finally
    StopChild(lProcess);
    lStream.Free;
    lProcess.Free;
  end;
end;

procedure Probe06(const ADirectory: string; AContext: TNXTestContext);
var
  lServer: TSimpleIPCServer;
  lWriters: array[0..1] of TProcess;
  lIndex, lType: Integer;
  lText, lExpected: string;
begin
  {$IFDEF UNIX}
  lServer := TSimpleIPCServer.Create(nil);
  lWriters[0] := nil;
  lWriters[1] := nil;
  try
    lServer.ServerID := 'nexus-fclp-' + ExtractFileName(ADirectory) + '-frames';
    lServer.Global := True;
    lServer.StartServer(False);
    for lIndex := 0 to 1 do
    begin
      lWriters[lIndex] := Child('fifo-writer');
      lWriters[lIndex].Parameters.Add(lServer.ServerID);
      lWriters[lIndex].Parameters.Add(ADirectory);
      lWriters[lIndex].Parameters.Add(IntToStr(lIndex));
      lWriters[lIndex].Execute;
    end;
    for lIndex := 0 to 1 do
    begin
      AContext.AssertTrue(lServer.PeekMessage(3000, True), 'Missing concurrent FIFO message.');
      lType := lServer.MsgType;
      AContext.AssertTrue(lType in [100, 101], 'Corrupted FIFO message type.');
      lText := ReadText(lServer.MsgData);
      lExpected := StringOfChar(Char(Ord('a') + lType - 100), 131072);
      AContext.AssertTrue(lText = lExpected,
        'Concurrent FIFO header/payload interleaving corrupted the message.');
    end;
    for lIndex := 0 to 1 do
      AContext.AssertTrue(lWriters[lIndex].WaitOnExit(1000), 'FIFO writer did not finish.');
  finally
    for lIndex := 0 to 1 do
      if lWriters[lIndex] <> nil then
      begin
        StopChild(lWriters[lIndex]);
        lWriters[lIndex].Free;
      end;
    lServer.Free;
  end;
  {$ELSE}
  AContext.Skip('Unix FIFO framing case.');
  {$ENDIF}
end;

procedure Probe10(const ADirectory: string; AContext: TNXTestContext);
var
  lProvider: THandleProvider;
  lProcess: TProcess;
begin
  SaveText(IncludeTrailingPathDelimiter(ADirectory) + 'input.txt', 'callback');
  lProvider := THandleProvider.Create(IncludeTrailingPathDelimiter(ADirectory) + 'input.txt');
  lProcess := Child('eof');
  try
    lProcess.InputDescriptor.IOType := iotHandle;
    lProcess.InputDescriptor.OnGetHandle := @lProvider.Acquire;
    lProcess.Execute;
    AContext.AssertTrue(lProcess.WaitOnExit(1000), 'Callback input child did not finish.');
    AContext.AssertEquals(0, lProcess.ExitCode);
  finally
    StopChild(lProcess);
    lProcess.Free;
    lProvider.Free;
  end;
end;

procedure Probe11(const ADirectory: string; AContext: TNXTestContext);
var
  lServer: TSimpleIPCServer;
  lStart: QWord;
begin
  lServer := TSimpleIPCServer.Create(nil);
  try
    lServer.ServerID := 'nexus-fclp-' + ExtractFileName(ADirectory) + '-idle';
    lServer.Global := True;
    lServer.ThreadTimeout := -1;
    lServer.StartServer(True);
    // Let the receiver enter its blocking wait before requesting shutdown.
    Sleep(150);
    lStart := GetTickCount64;
    lServer.StopServer;
    AContext.AssertTrue(GetTickCount64 - lStart < 1000,
      'Stopping an idle infinite-wait receiver exceeded one second.');
  finally
    lServer.Free;
  end;
end;

procedure Probe12(AContext: TNXTestContext);
var
  lQueue: TIPCServerMsgQueue;
  lRejected: TCountedMessage;
  lDestroyed: Integer;
  lServer: TQueueServer;
begin
  lDestroyed := 0;
  lQueue := TIPCServerMsgQueue.Create;
  lRejected := nil;
  try
    lQueue.MaxCount := 1;
    lQueue.MaxAction := ipcmoaDiscardNew;
    lQueue.Push(TCountedMessage.Create(@lDestroyed));
    lRejected := TCountedMessage.Create(@lDestroyed);
    lQueue.Push(lRejected);
    AContext.AssertEquals(1, lDestroyed, 'The discarded message was not destroyed.');
    AContext.AssertEquals(1, lQueue.Count);
  finally
    if (lDestroyed = 0) and (lRejected <> nil) then
      lRejected.Free;
    lQueue.Free;
  end;
  lServer:=TQueueServer.Create(nil);
  try
    lServer.MaxQueue:=1;
    lServer.MaxAction:=ipcmoaDiscardNew;
    lServer.Enqueue(TCountedMessage.Create(@lDestroyed));
    lServer.Enqueue(TCountedMessage.Create(@lDestroyed));
    AContext.AssertEquals(1,lServer.QueuedCount,
      'Discarded messages must not emit a queued notification.');
    AContext.AssertEquals(3,lDestroyed,'Server did not dispose of the rejected message.');
  finally
    lServer.Free;
  end;
  AContext.AssertEquals(4,lDestroyed,'Server did not dispose of the accepted message.');
end;

procedure Probe13(const ADirectory: string; AContext: TNXTestContext);
var
  lServer: TSimpleIPCServer;
  lClient: TSyncIPCClient;
  lIndex, lDummy, lSize: Integer;
  lBefore, lAfter: PtrUInt;

  procedure TimeoutRequest;
  begin
    lSize := 0;
    AContext.AssertEquals(mtUnknown,
      lClient.SendSyncMessage(0, 123, mtData_Null, lDummy, 0, lDummy, lSize));
    AContext.AssertTrue(lServer.PeekMessage(0, True), 'Silent server did not receive the request.');
  end;

begin
  lServer := TSimpleIPCServer.Create(nil);
  lClient := TSyncIPCClient.Create(nil);
  try
    lServer.ServerID := 'nexus-fclp-' + ExtractFileName(ADirectory) + '-silent';
    lServer.Global := True;
    lServer.StartServer(False);
    lClient.ServerID := lServer.ServerID;
    lDummy := 0;
    for lIndex := 1 to 16 do TimeoutRequest;
    lBefore := GetFPCHeapStatus.CurrHeapUsed;
    for lIndex := 1 to 128 do TimeoutRequest;
    lAfter := GetFPCHeapStatus.CurrHeapUsed;
    AContext.AssertTrue(lAfter <= lBefore + 256,
      Format('Timeouts retained heap bytes: before=%d after=%d.', [lBefore, lAfter]));
  finally
    lClient.Free;
    lServer.Free;
  end;
end;

procedure Probe14(AContext: TNXTestContext);
{$IFDEF UNIX}
var
  lProcess: TProcess;
  lTime: TimeVal;
  lStart, lElapsed: QWord;
begin
  lProcess := Child('sleep');
  try
    lProcess.Parameters.Add('3000');
    lProcess.Execute;
    repeat
      fpGetTimeOfDay(@lTime, nil);
      if (lTime.tv_usec >= 850000) and (lTime.tv_usec < 900000) then Break;
      Sleep(1);
    until False;
    lStart := GetTickCount64;
    AContext.AssertFalse(lProcess.WaitOnExit(300), 'Sleeping child exited before the timeout.');
    lElapsed := GetTickCount64 - lStart;
    AContext.AssertTrue(lElapsed >= 275,
      Format('A 300 ms wait expired after %d ms across a second boundary.', [lElapsed]));
  finally
    StopChild(lProcess);
    lProcess.Free;
  end;
end;
{$ELSE}
begin
  AContext.Skip('Unix deadline normalization case.');
end;
{$ENDIF}

procedure RunFCLProcessProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
begin
  case AId of
    1: Probe01(AContext);
    2: Probe02(AContext);
    3: Probe03(AContext);
    4: Probe04(AContext);
    5: Probe05(AContext);
    6: Probe06(ADirectory, AContext);
    7, 8, 9:
      {$IFDEF MSWINDOWS}RunWindowsProbe(AId, ADirectory, AContext);{$ELSE}
      AContext.Skip('Windows runtime required.');{$ENDIF}
    10: Probe10(ADirectory, AContext);
    11: Probe11(ADirectory, AContext);
    12: Probe12(AContext);
    13: Probe13(ADirectory, AContext);
    14: Probe14(AContext);
  else
    AContext.Fail('Unknown probe.');
  end;
end;

procedure RunFCLProcessChild;
var
  lBuffer: array[0..1023] of Byte;
  lData: AnsiString;
  lClient: TSimpleIPCClient;
  lStream: TBarrierStream;
  lIndex: Integer;
begin
  if ParamStr(2) = 'eof' then
  begin
    while FileRead(StdInputHandle, lBuffer, SizeOf(lBuffer)) > 0 do ;
  end
  else if ParamStr(2) = 'streams' then
  begin
    lData := 'stdout';
    FileWrite(StdOutputHandle, lData[1], Length(lData));
    lData := 'stderr';
    FileWrite(StdErrorHandle, lData[1], Length(lData));
  end
  else if ParamStr(2) = 'sleep' then
    Sleep(StrToInt(ParamStr(3)))
  else if ParamStr(2) = 'fifo-writer' then
  begin
    lIndex := StrToInt(ParamStr(5));
    lClient := TSimpleIPCClient.Create(nil);
    lStream := TBarrierStream.Create(ParamStr(4), lIndex);
    try
      lClient.ServerID := ParamStr(3);
      lClient.Connect;
      lClient.SendMessage(100 + lIndex, lStream);
    finally
      lStream.Free;
      lClient.Free;
    end;
  end
  {$IFDEF MSWINDOWS}
  else if ParamStr(2) = 'arguments' then
    SaveWindowsArguments(ParamStr(3))
  {$ENDIF}
  else
    raise Exception.Create('Unknown fixture child mode.');
end;

{$IFDEF MSWINDOWS}
procedure RunFCLProcessService;
begin
  RunWindowsServiceFixture;
end;
{$ENDIF}

end.

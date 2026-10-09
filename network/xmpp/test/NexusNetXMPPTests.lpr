(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusNetXMPPTests;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  {$IFDEF UNIX}
  cthreads,
  cwstring,
  {$ENDIF}
  Classes, SysUtils, Contnrs, DOM, blcksock, obNXSynapseOpenSSL, synsock,
  tpNXXMPPTypes, tpNXXMPPMessageTypes, tpNXXMPPFileTypes,
  obNXXMPPError,
  obNXXMPPJID,
  obNXXMPPStreamFramer,
  obNXXMPPStanza,
  obNXXMPPMessage,
  obNXXMPPModule,
  obNXXMPPForwarding,
  obNXXMPPDispatcher,
  obNXXMPPRequestManager,
  obNXXMPPEndpointResolver,
  obNXOpenSSLCrypto,
  obNXXMPPSASL,
  obNXXMPPQueue,
  obNXXMPPConfig,
  obNXXMPPCommand,
  obNXXMPPTransport,
  obNXXMPPClient,
  obNXXMPPNegotiation,
  obNXXMPPStreamManagement,
  obNXXMPPDisco,
  obNXXMPPFileSharing,
  obNXXMPPPing,
  obNXXMPPMessageFeatures,
  obNXXMPPMUC,
  obNXXMPPCarbons,
  obNXXMPPMAM,
  obNXXMPPRoster,
  utNXXMPPDateTime, utNXXMPPDOM, utNXXMPPIDs;

type
  TDispatchRecorder = class
  public
    CompletionCount: Integer;
    HandlerCount: Integer;
    LastError: UTF8String;
    procedure Complete(AStanza: TNXXMPPStanza; const AError: UTF8String);
    procedure Handle(AStanza: TNXXMPPStanza);
    function IsIQ(AStanza: TNXXMPPStanza): Boolean;
  end;

  TModuleRecorder = class
  public
    ChangedCount: Integer;
    LastJID: UTF8String;
    LastSubscription: UTF8String;
    XML: UTF8String;
    procedure Changed(ASender: TObject;
      const AJID, ASubscription: UTF8String);
    procedure Send(const AXML: UTF8String; AReplayable: Boolean);
  end;

  TClientRecorder = class
  public
    CallbackThreadID: TThreadID;
    ErrorCount: Integer;
    StateCount: Integer;
    procedure Error(ASender: TObject; AStage: TNXXMPPErrorStage;
      const ACondition, AMessage: UTF8String);
    procedure State(ASender: TObject; AState: TNXXMPPConnectionState);
  end;

  TPhase2Recorder = class
  public
    CallbackThreadID: TThreadID;
    CarbonCount: Integer;
    ChatStateCount: Integer;
    CapabilityCache: TNXXMPPCapabilityCache;
    CapabilityStored: Boolean;
    CompleteCount: Integer;
    DiscoCount: Integer;
    DiagnosticCount: Integer;
    IQHandler: TNXXMPPIQCompletionHandler;
    IQPayload: UTF8String;
    LastBody: UTF8String;
    LastContext: TNXXMPPMessageDeliveryContext;
    LastDelayPresent: Boolean;
    LastError: UTF8String;
    LastHash: UTF8String;
    LastAffiliation: TNXXMPPMUCAffiliation;
    LastAvailable: Boolean;
    LastRole: TNXXMPPMUCRole;
    LastRoom: TNXXMPPRoom;
    LastSelf: Boolean;
    LastQueryID: UTF8String;
    MAMResultCount: Integer;
    MessageCount: Integer;
    OccupantCount: Integer;
    ReceiptCount: Integer;
    ReceiptExpiredCount: Integer;
    RejectIQ: Boolean;
    LastReceiptOutcome: TNXXMPPReceiptOutcome;
    RoomStateCount: Integer;
    XML: UTF8String;
    UploadService: TNXXMPPHTTPUploadService;
    UploadSlot: TNXXMPPHTTPUploadSlot;
    procedure Carbon(ASender: TObject; ASent: Boolean;
      const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage);
    procedure CarbonDiagnostic(ASender: TObject;
      const ACondition, ADetail: UTF8String);
    procedure MUCChatState(ASender: TObject; ARoom: TNXXMPPRoom;
      const AOccupantJID: UTF8String; AState: TNXXMPPChatState);
    procedure DiscoInfo(ASender: TObject; AInfo: TNXXMPPDiscoInfo);
    procedure MAMComplete(ASender: TObject; const AQueryID, AError,
      AFirst, ALast: UTF8String; ACount: Integer;
      AComplete, AStable: Boolean);
    procedure MAMDiagnostic(ASender: TObject; const ACondition,
      AQueryID, ADetail: UTF8String);
    procedure MAMResult(ASender: TObject; const AQueryID,
      AResultID, AArchiveJID: UTF8String; const ADelay: TNXXMPPDelay;
      AMessage: TNXXMPPMessage);
    procedure MessageReceived(ASender: TObject; AMessage: TNXXMPPMessage);
    function ModuleSubmit(AModule: TObject;
      AOperation: TNXXMPPModuleOperation): Boolean;
    procedure Occupant(ASender: TObject; ARoom: TNXXMPPRoom;
      const AOccupantJID, ANick, ARealJID, AOccupantID: UTF8String;
      ARole: TNXXMPPMUCRole; AAffiliation: TNXXMPPMUCAffiliation;
      AAvailable, ASelf: Boolean);
    function SubmitIQ(AType: TNXXMPPIQType; const AToJID, AExpectedFrom,
      APayload: UTF8String; AHandler: TNXXMPPIQCompletionHandler;
      ATimeoutMS: Cardinal): Boolean;
    procedure RoomMessage(ASender: TObject; ARoom: TNXXMPPRoom;
      AMessage: TNXXMPPMessage);
    procedure RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
    procedure Receipt(ASender: TObject; const AFromJID,
      AStanzaID: UTF8String; AOutcome: TNXXMPPReceiptOutcome);
    procedure Send(const AXML: UTF8String; AReplayable: Boolean);
    procedure UploadServiceReady(ASender: TObject;
      const AService: TNXXMPPHTTPUploadService;
      const AError: UTF8String);
    procedure UploadSlotReady(ASender: TObject;
      const ASlot: TNXXMPPHTTPUploadSlot; const AError: UTF8String);
  end;

  TTLSLoopbackServer = class(TThread)
  private
    FCertificateFile: string;
    FListener: TTCPBlockSocket;
    FPort: Word;
    FPrivateKeyFile: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACertificateFile, APrivateKeyFile: string);
    destructor Destroy; override;
    property Port: Word read FPort;
  end;

  TBlockingLoopbackServer = class(TThread)
  private
    FListener: TTCPBlockSocket;
    FPort: Word;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    property Port: Word read FPort;
  end;

  TTransportReader = class(TThread)
  private
    FTransport: TNXXMPPTransport;
  protected
    procedure Execute; override;
  public
    constructor Create(ATransport: TNXXMPPTransport);
  end;

constructor TBlockingLoopbackServer.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FListener := TTCPBlockSocket.Create;
  FListener.Bind('127.0.0.1', '0');
  FListener.Listen;
  if FListener.LastError <> 0 then
    raise Exception.Create('Could not create the blocking loopback server.');
  FPort := FListener.GetLocalSinPort;
end;

destructor TBlockingLoopbackServer.Destroy;
begin
  FListener.CloseSocket;
  if not Finished then
    WaitFor;
  FListener.Free;
  inherited Destroy;
end;

procedure TBlockingLoopbackServer.Execute;
var
  lClient: TTCPBlockSocket;
begin
  lClient := TTCPBlockSocket.Create;
  try
    lClient.Socket := FListener.Accept;
    if lClient.Socket <> INVALID_SOCKET then
      lClient.RecvBufferStr(1, 5000);
  finally
    lClient.Free;
  end;
end;

constructor TTransportReader.Create(ATransport: TNXXMPPTransport);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTransport := ATransport;
end;

procedure TTransportReader.Execute;
begin
  try
    FTransport.Receive(10000);
  except
    on ENXXMPPError do ;
  end;
end;

constructor TTLSLoopbackServer.Create(const ACertificateFile,
  APrivateKeyFile: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCertificateFile := ACertificateFile;
  FPrivateKeyFile := APrivateKeyFile;
  FListener := TTCPBlockSocket.Create;
  FListener.Bind('127.0.0.1', '0');
  if FListener.LastError <> 0 then
    raise Exception.Create('Could not bind the TLS loopback listener.');
  FListener.Listen;
  if FListener.LastError <> 0 then
    raise Exception.Create('Could not listen on the TLS loopback socket.');
  FPort := FListener.GetLocalSinPort;
end;

destructor TTLSLoopbackServer.Destroy;
begin
  FListener.CloseSocket;
  if not Finished then
    WaitFor;
  FListener.Free;
  inherited Destroy;
end;

procedure TTLSLoopbackServer.Execute;
var
  lClient: TTCPBlockSocket;
begin
  lClient := TTCPBlockSocket.Create;
  try
    lClient.Socket := FListener.Accept;
    if lClient.Socket = INVALID_SOCKET then
      Exit;
    lClient.ConnectionTimeout := 2000;
    lClient.SSL.CertificateFile := FCertificateFile;
    lClient.SSL.PrivateKeyFile := FPrivateKeyFile;
    lClient.SSL.SSLType := LT_TLSv1_2;
    lClient.SSLAcceptConnection;
  finally
    lClient.Free;
  end;
end;

procedure TClientRecorder.Error(ASender: TObject; AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: UTF8String);
begin
  CallbackThreadID := GetCurrentThreadID;
  Inc(ErrorCount);
end;

procedure TClientRecorder.State(ASender: TObject;
  AState: TNXXMPPConnectionState);
begin
  CallbackThreadID := GetCurrentThreadID;
  Inc(StateCount);
end;

procedure TModuleRecorder.Send(const AXML: UTF8String;
  AReplayable: Boolean);
begin
  XML := AXML;
end;

procedure TModuleRecorder.Changed(ASender: TObject;
  const AJID, ASubscription: UTF8String);
begin
  Inc(ChangedCount);
  LastJID := AJID;
  LastSubscription := ASubscription;
end;

procedure TPhase2Recorder.Send(const AXML: UTF8String;
  AReplayable: Boolean);
begin
  XML := AXML;
end;

procedure TPhase2Recorder.UploadServiceReady(ASender: TObject;
  const AService: TNXXMPPHTTPUploadService; const AError: UTF8String);
begin
  UploadService := AService;
  LastError := AError;
  Inc(CompleteCount);
end;

procedure TPhase2Recorder.UploadSlotReady(ASender: TObject;
  const ASlot: TNXXMPPHTTPUploadSlot; const AError: UTF8String);
begin
  UploadSlot := ASlot;
  LastError := AError;
  Inc(CompleteCount);
end;

function TPhase2Recorder.ModuleSubmit(AModule: TObject;
  AOperation: TNXXMPPModuleOperation): Boolean;
begin
  Result := Assigned(AModule) and Assigned(AOperation);
  if not Result then
    Exit;
  try
    TNXXMPPModule(AModule).ProcessCommand(AOperation);
  finally
    AOperation.Free;
  end;
end;

function TPhase2Recorder.SubmitIQ(AType: TNXXMPPIQType;
  const AToJID, AExpectedFrom, APayload: UTF8String;
  AHandler: TNXXMPPIQCompletionHandler; ATimeoutMS: Cardinal): Boolean;
begin
  IQPayload := APayload;
  IQHandler := AHandler;
  Result := not RejectIQ;
end;

procedure TPhase2Recorder.MessageReceived(ASender: TObject;
  AMessage: TNXXMPPMessage);
begin
  Inc(MessageCount);
  LastBody := AMessage.Body;
  LastContext := AMessage.Context;
end;

procedure TPhase2Recorder.Carbon(ASender: TObject; ASent: Boolean;
  const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage);
begin
  Inc(CarbonCount);
  LastBody := AMessage.Body;
  LastContext := AMessage.Context;
  LastDelayPresent := ADelay.Present;
end;

procedure TPhase2Recorder.CarbonDiagnostic(ASender: TObject;
  const ACondition, ADetail: UTF8String);
begin
  Inc(DiagnosticCount);
  LastError := ACondition;
end;

procedure TPhase2Recorder.MUCChatState(ASender: TObject; ARoom: TNXXMPPRoom;
  const AOccupantJID: UTF8String; AState: TNXXMPPChatState);
begin
  Inc(ChatStateCount);
end;

procedure TPhase2Recorder.DiscoInfo(ASender: TObject;
  AInfo: TNXXMPPDiscoInfo);
begin
  Inc(DiscoCount);
  LastError := AInfo.Error;
  LastHash := TNXXMPPDiscoModule.CapabilityHash(AInfo);
  if Assigned(CapabilityCache) then
    CapabilityStored := CapabilityCache.StoreVerified(
      'service.example.com', 'client-node', LastHash, AInfo);
  if AInfo.Features.Count > 0 then
    LastBody := UTF8String(AInfo.Features[0]);
end;

procedure TPhase2Recorder.MAMResult(ASender: TObject;
  const AQueryID, AResultID, AArchiveJID: UTF8String;
  const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage);
begin
  Inc(MAMResultCount);
  LastQueryID := AQueryID;
  LastBody := AMessage.Body;
  LastContext := AMessage.Context;
  LastDelayPresent := ADelay.Present;
end;

procedure TPhase2Recorder.MAMComplete(ASender: TObject;
  const AQueryID, AError, AFirst, ALast: UTF8String; ACount: Integer;
  AComplete, AStable: Boolean);
begin
  Inc(CompleteCount);
  LastQueryID := AQueryID;
  LastError := AError;
end;

procedure TPhase2Recorder.MAMDiagnostic(ASender: TObject;
  const ACondition, AQueryID, ADetail: UTF8String);
begin
  Inc(DiagnosticCount);
  LastError := ACondition;
  LastQueryID := AQueryID;
end;

procedure TPhase2Recorder.Occupant(ASender: TObject; ARoom: TNXXMPPRoom;
  const AOccupantJID, ANick, ARealJID, AOccupantID: UTF8String;
  ARole: TNXXMPPMUCRole; AAffiliation: TNXXMPPMUCAffiliation;
  AAvailable, ASelf: Boolean);
begin
  Inc(OccupantCount);
  LastAffiliation := AAffiliation;
  LastAvailable := AAvailable;
  LastRole := ARole;
  LastRoom := ARoom;
  LastSelf := ASelf;
end;

procedure TPhase2Recorder.RoomMessage(ASender: TObject;
  ARoom: TNXXMPPRoom; AMessage: TNXXMPPMessage);
begin
  Inc(MessageCount);
  LastBody := AMessage.Body;
  LastContext := AMessage.Context;
end;

procedure TPhase2Recorder.RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
begin
  Inc(RoomStateCount);
  LastRoom := ARoom;
end;

procedure TPhase2Recorder.Receipt(ASender: TObject; const AFromJID,
  AStanzaID: UTF8String; AOutcome: TNXXMPPReceiptOutcome);
begin
  CallbackThreadID := GetCurrentThreadID;
  Inc(ReceiptCount);
  LastQueryID := AStanzaID;
  LastReceiptOutcome := AOutcome;
  if AOutcome = xroExpired then
    Inc(ReceiptExpiredCount);
end;

procedure TDispatchRecorder.Complete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  Inc(CompletionCount);
  LastError := AError;
end;

procedure TDispatchRecorder.Handle(AStanza: TNXXMPPStanza);
begin
  Inc(HandlerCount);
end;

function TDispatchRecorder.IsIQ(AStanza: TNXXMPPStanza): Boolean;
begin
  Result := Assigned(AStanza) and (AStanza.Kind = xskIQ);
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertEquals(const AExpected, AActual: UTF8String;
  const AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('%s Expected "%s", received "%s".',
      [AMessage, AExpected, AActual]);
end;

function HexValue(const AValue: RawByteString): string;
const
  cHex = '0123456789abcdef';
var
  lIndex: Integer;
begin
  SetLength(Result, Length(AValue) * 2);
  for lIndex := 1 to Length(AValue) do
  begin
    Result[(lIndex * 2) - 1] := cHex[(Ord(AValue[lIndex]) shr 4) + 1];
    Result[lIndex * 2] := cHex[(Ord(AValue[lIndex]) and $0F) + 1];
  end;
end;

procedure AssertRaises(const ACondition, AMessage: string;
  AProcedure: TProcedure);
begin
  try
    AProcedure;
  except
    on E: Exception do
    begin
      if (ACondition <> '') and (Pos(ACondition, E.Message) = 0) then
        raise Exception.CreateFmt('%s Wrong failure: %s', [AMessage, E.Message]);
      Exit;
    end;
  end;
  raise Exception.Create(AMessage + ' Expected an exception.');
end;

procedure AssertJIDRejected(const AValue, ACondition: UTF8String);
var
  lJID: TNXXMPPJID;
begin
  try
    lJID := TNXXMPPJID.Create(AValue);
    lJID.Free;
  except
    on E: ENXXMPPError do
    begin
      AssertTrue(E.Condition = ACondition,
        'A rejected JID should report the expected condition.');
      Exit;
    end;
  end;
  raise Exception.Create('The invalid JID should have been rejected.');
end;

procedure TestJID;
var
  lJID: TNXXMPPJID;
begin
  lJID := TNXXMPPJID.Create('KEVIN@NEXUS.REMOTE/Desk One');
  try
    AssertEquals('kevin@nexus.remote/Desk One', lJID.ToString,
      'JID should lowercase ASCII identity parts and retain the resource.');
    AssertEquals('kevin@nexus.remote', lJID.Bare,
      'Bare JID should omit the resourcepart.');
  finally
    lJID.Free;
  end;
  AssertJIDRejected(UTF8String('k') +
    UTF8Encode(UnicodeString(#$00E9)) + 'vin@example.com',
    'invalid-localpart');
  AssertJIDRejected(UTF8String('kevin@b') +
    UTF8Encode(UnicodeString(#$00FC)) + 'cher.example',
    'invalid-domainpart');
  AssertJIDRejected(UTF8String('kevin@example.com/D') +
    UTF8Encode(UnicodeString(#$00E9)) + 'sk', 'invalid-resourcepart');
  AssertJIDRejected('ke vin@example.com', 'invalid-localpart');
  AssertJIDRejected('@example.com', 'invalid-localpart');
  AssertJIDRejected('kevin@bad_domain.example', 'invalid-domainpart');
  AssertJIDRejected('kevin@example.com/', 'invalid-resourcepart');
end;

procedure TestStreamFramerAndStanza;
var
  lFrames: TStringList;
  lFramer: TNXXMPPStreamFramer;
  lInput: RawByteString;
  lStanza: TNXXMPPStanza;
  lSplit: Integer;
begin
  lFramer := TNXXMPPStreamFramer.Create;
  lFrames := TStringList.Create;
  try
    lInput := '<?xml version="1.0" encoding="UTF-8"?>' +
      '<stream:stream xmlns=''jabber:client'' ' +
      'xmlns:stream=''http://etherx.jabber.org/streams''>' +
      '<iq type=''get'' id=''one''><query xmlns=''urn:test''/></iq>' +
      '<message id=''two''><body>Hello</body></message>' +
      '</stream:stream>';
    lFramer.Feed(Copy(lInput, 1, 17), lFrames);
    AssertTrue(lFrames.Count = 0,
      'A partial stream opening must not emit a frame.');
    lFramer.Feed(Copy(lInput, 18, 31), lFrames);
    lFramer.Feed(Copy(lInput, 49, MaxInt), lFrames);
    AssertTrue(lFrames.Count = 4,
      'The framer should emit opening, two stanzas, and closing.');
    lStanza := TNXXMPPStanza.Create(UTF8String(lFrames[1]),
      lFramer.StreamNamespaceAttributes);
    try
      AssertTrue(lStanza.Kind = xskIQ, 'The IQ stanza kind should be retained.');
      AssertTrue(lStanza.IQType = xitGet, 'The IQ type should be retained.');
      AssertEquals('jabber:client', lStanza.NamespaceURI,
        'The inherited stream namespace should apply to the stanza.');
      AssertEquals('urn:test', lStanza.ChildNamespaceURI,
        'The child QName namespace should be retained.');
      AssertEquals('query', lStanza.ChildLocalName,
        'The child QName local name should be retained.');
    finally
      lStanza.Free;
    end;
  finally
    lFrames.Free;
    lFramer.Free;
  end;
  for lSplit := 1 to Length(lInput) - 1 do
  begin
    lFramer := TNXXMPPStreamFramer.Create;
    lFrames := TStringList.Create;
    try
      lFramer.Feed(Copy(lInput, 1, lSplit), lFrames);
      lFramer.Feed(Copy(lInput, lSplit + 1, MaxInt), lFrames);
      AssertTrue(lFrames.Count = 4,
        'Every byte boundary should preserve all stream frames.');
    finally
      lFrames.Free;
      lFramer.Free;
    end;
  end;
end;

procedure TestPhase2MessageModels;
var
  lForwarded: TNXXMPPForwarded;
  lForwardedElement: TDOMElement;
  lID: UTF8String;
  lMessage: TNXXMPPMessage;
  lResultElement: TDOMElement;
  lStanza: TNXXMPPStanza;
  lTimestamp: TDateTime;
  lGeneratedID: UTF8String;
begin
  lGeneratedID := NXXMPPCreateID;
  AssertTrue((Length(lGeneratedID) = 36) and
    (Pos(#0, string(lGeneratedID)) = 0),
    'Generated protocol IDs must be printable UUID text.');
  AssertTrue(NXXMPPTryParseTimestamp('2026-09-02T12:00:00Z', lTimestamp) and
    (NXXMPPFormatTimestamp(lTimestamp) <> ''),
    'XEP timestamps should parse and serialize as UTC ISO-8601 values.');
  AssertTrue((NXXMPPChatStateFromName('active') = xcsActive) and
    (NXXMPPChatStateFromName('composing') = xcsComposing) and
    (NXXMPPChatStateFromName('paused') = xcsPaused) and
    (NXXMPPChatStateFromName('inactive') = xcsInactive) and
    (NXXMPPChatStateFromName('gone') = xcsGone),
    'All five XEP-0085 chat states should have typed identities.');
  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client'' from=''peer@example.com/phone'' ' +
    'id=''wire-1'' type=''chat''><body>Hello</body>' +
    '<origin-id xmlns=''urn:xmpp:sid:0'' id=''origin-1''/>' +
    '<stanza-id xmlns=''urn:xmpp:sid:0'' by=''example.com'' id=''stable-1''/>' +
    '<reply xmlns=''urn:xmpp:reply:0'' to=''other@example.com/desk'' ' +
    'id=''prior-1''/><request xmlns=''urn:xmpp:receipts''/>' +
    '<composing xmlns=''http://jabber.org/protocol/chatstates''/>' +
    '</message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(lMessage.Valid, 'The combined Phase 2 message should parse.');
      AssertEquals('Hello', lMessage.Body,
        'Message body parsing must not concatenate extension text.');
      AssertEquals('origin-1', lMessage.OriginID,
        'The origin ID should remain independent.');
      AssertTrue(lMessage.StanzaIDFor('example.com', lID) and
        (lID = 'stable-1'), 'A stanza ID should retain its assigning JID.');
      AssertTrue(lMessage.Reply.Present and
        (lMessage.Reply.ID = 'prior-1'), 'Reply metadata should be typed.');
      AssertTrue((lMessage.ReceiptKind = xrkRequest) and
        (lMessage.ChatState = xcsComposing),
        'Receipt and chat-state metadata should compose.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><body>short</body>' +
    '<reply xmlns=''urn:xmpp:reply:0'' id=''prior''/>' +
    '<fallback xmlns=''urn:xmpp:fallback:0'' for=''urn:xmpp:reply:0''>' +
    '<body start=''0'' end=''50''/></fallback></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(not lMessage.Valid,
        'A fallback range beyond the Unicode body must be rejected.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><body>' +
    UTF8Encode(UnicodeString(#$1F642)) + '&gt; quoted' + #10 + 'answer</body>' +
    '<reply xmlns=''urn:xmpp:reply:0'' id=''prior''/>' +
    '<fallback xmlns=''urn:xmpp:fallback:0'' for=''urn:xmpp:reply:0''>' +
    '<body start=''0'' end=''10''/></fallback></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(lMessage.Valid and (lMessage.DisplayBody = 'answer'),
        'Fallback ranges must use Unicode character offsets, not UTF-8 bytes.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><body>ordinary URL text</body>' +
    '<fallback xmlns=''urn:xmpp:fallback:0'' for=''urn:xmpp:sfs:0''>' +
    '<body/></fallback></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(lMessage.Valid and
        (lMessage.DisplayBody = 'ordinary URL text'),
        'An SFS fallback without an SFS payload must not hide message text.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''>' +
    '<file-sharing xmlns=''urn:xmpp:sfs:0''><file ' +
    'xmlns=''urn:xmpp:file:metadata:0''><name/><name/></file>' +
    '<sources/><sources/></file-sharing></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(not lMessage.Valid,
        'Duplicate empty metadata and sources containers must be rejected.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
    '<body>https://files.example.test/report.txt</body>' +
    '<file-sharing xmlns=''urn:xmpp:sfs:0'' id=''share-1'' ' +
    'disposition=''attachment''><file xmlns=''urn:xmpp:file:metadata:0''>' +
    '<media-type>text/plain</media-type><name>report.txt</name>' +
    '<size>12</size><desc>Report</desc>' +
    '<hash xmlns=''urn:xmpp:hashes:2'' algo=''sha-256''>YWJj</hash>' +
    '</file><sources><url-data ' +
    'xmlns=''http://jabber.org/protocol/url-data'' ' +
    'target=''https://files.example.test/report.txt''/></sources>' +
    '</file-sharing><x xmlns=''jabber:x:oob''>' +
    '<url>https://files.example.test/report.txt</url></x>' +
    '<fallback xmlns=''urn:xmpp:fallback:0'' for=''urn:xmpp:sfs:0''>' +
    '<body/></fallback></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(lMessage.Valid and (Length(lMessage.Attachments) = 1),
        'A self-contained SFS message should retain one typed attachment.');
      AssertTrue((lMessage.DisplayBody = '') and
        (lMessage.Attachments[0].Name = 'report.txt') and
        lMessage.Attachments[0].HasSize and
        (lMessage.Attachments[0].DeclaredSize = 12) and
        (Length(lMessage.Attachments[0].Sources) = 1) and
        (Length(lMessage.Attachments[0].Hashes) = 1),
        'Typed file metadata and whole-body fallback must be retained.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><x xmlns=''jabber:x:oob''>' +
    '<url>https://files.example.test/legacy.txt</url></x></message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(lMessage.Valid and (Length(lMessage.Attachments) = 0),
        'An OOB-only message must not authorize an attachment download.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''>' +
    '<file-sharing xmlns=''urn:xmpp:sfs:0''><file ' +
    'xmlns=''urn:xmpp:file:metadata:0''><name>a.txt</name></file>' +
    '<sources><url-data xmlns=''http://jabber.org/protocol/url-data'' ' +
    'target=''https://files.example.test/a.txt''/></sources></file-sharing>' +
    '<file-sharing xmlns=''urn:xmpp:sfs:0'' id=''b''><file ' +
    'xmlns=''urn:xmpp:file:metadata:0''><name>b.txt</name></file>' +
    '<sources><url-data xmlns=''http://jabber.org/protocol/url-data'' ' +
    'target=''https://files.example.test/b.txt''/></sources></file-sharing>' +
    '</message>', '');
  try
    lMessage := TNXXMPPMessage.Create(lStanza);
    try
      AssertTrue(not lMessage.Valid,
        'Every attachment in a multi-file message must have an id.');
    finally
      lMessage.Free;
    end;
  finally
    lStanza.Free;
  end;

  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><result xmlns=''urn:xmpp:mam:2''>' +
    '<forwarded xmlns=''urn:xmpp:forward:0''>' +
    '<delay xmlns=''urn:xmpp:delay'' stamp=''2026-09-02T12:00:00Z''/>' +
    '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
    '<body>Archived</body></message></forwarded></result></message>', '');
  try
    lResultElement := NXXMPPFindChild(lStanza.Root, 'urn:xmpp:mam:2',
      'result');
    lForwardedElement := NXXMPPFindChild(lResultElement,
      'urn:xmpp:forward:0', 'forwarded');
    lForwarded := TNXXMPPForwarding.Decode(lForwardedElement, xmdcMAM);
    try
      AssertTrue(lForwarded.Valid and Assigned(lForwarded.Message),
        'A valid MAM forward should produce one retained typed message.');
      AssertEquals('Archived', lForwarded.Message.Body,
        'Forwarded content should retain its own body.');
      AssertTrue((lForwarded.Message.Context = xmdcMAM) and
        lForwarded.Delay.Present,
        'Forwarding should retain delivery context and delay metadata.');
    finally
      lForwarded.Free;
    end;
  finally
    lStanza.Free;
  end;
  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><result xmlns=''urn:xmpp:mam:2''>' +
    '<forwarded xmlns=''urn:xmpp:forward:0''>' +
    '<message xmlns=''jabber:client''><body>one</body></message>' +
    '<message xmlns=''jabber:client''><body>two</body></message>' +
    '</forwarded></result></message>', '');
  try
    lResultElement := NXXMPPFindChild(lStanza.Root, 'urn:xmpp:mam:2',
      'result');
    lForwardedElement := NXXMPPFindChild(lResultElement,
      'urn:xmpp:forward:0', 'forwarded');
    lForwarded := TNXXMPPForwarding.Decode(lForwardedElement, xmdcMAM);
    try
      AssertTrue(not lForwarded.Valid,
        'A forwarding envelope with multiple stanzas must be rejected.');
    finally
      lForwarded.Free;
    end;
  finally
    lStanza.Free;
  end;
  lStanza := TNXXMPPStanza.Create(
    '<message xmlns=''jabber:client''><result xmlns=''urn:xmpp:mam:2''>' +
    '<forwarded xmlns=''urn:xmpp:forward:0''>' +
    '<message xmlns=''jabber:client''><forwarded xmlns=' +
    '''urn:xmpp:forward:0''><message xmlns=''jabber:client''/>' +
    '</forwarded></message></forwarded></result></message>', '');
  try
    lResultElement := NXXMPPFindChild(lStanza.Root, 'urn:xmpp:mam:2',
      'result');
    lForwardedElement := NXXMPPFindChild(lResultElement,
      'urn:xmpp:forward:0', 'forwarded');
    lForwarded := TNXXMPPForwarding.Decode(lForwardedElement, xmdcMAM);
    try
      AssertTrue(not lForwarded.Valid,
        'Nested forwarding should be rejected at the configured depth.');
    finally
      lForwarded.Free;
    end;
  finally
    lStanza.Free;
  end;
end;

procedure TestDispatcherAndRequests;
var
  lCapacity: TNXXMPPIQCapacity;
  lCompletion: TNXXMPPIQCompletionEvent;
  lDispatcher: TNXXMPPDispatcher;
  lEvents: TObjectList;
  lID: UTF8String;
  lManager: TNXXMPPRequestManager;
  lRecorder: TDispatchRecorder;
  lStanza: TNXXMPPStanza;
begin
  lRecorder := TDispatchRecorder.Create;
  lDispatcher := TNXXMPPDispatcher.Create;
  lManager := TNXXMPPRequestManager.Create(2);
  lEvents := TObjectList.Create(True);
  lCapacity := TNXXMPPIQCapacity.Create(1);
  try
    AssertTrue(lCapacity.TryReserve,
      'The public IQ capacity should reserve available capacity.');
    AssertTrue(not lCapacity.TryReserve,
      'The public IQ capacity should reject synchronous overflow.');
    lCapacity.Release;
    AssertTrue(lCapacity.TryReserve,
      'Released IQ capacity should become synchronously available.');
    lCapacity.Release;
    lDispatcher.RegisterIQResponder(xitGet, 'urn:test', 'query',
      @lRecorder.Handle);
    try
      lDispatcher.RegisterIQResponder(xitGet, 'urn:test', 'query',
        @lRecorder.Handle);
      raise Exception.Create('A duplicate IQ responder should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'duplicate-iq-responder',
          'Duplicate ownership should report its exact condition.');
    end;
    lDispatcher.RegisterObserver(@lRecorder.IsIQ, @lRecorder.Handle);
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''get'' id=''one''>' +
      '<query xmlns=''urn:test''/></iq>', '');
    try
      AssertTrue(lDispatcher.DispatchStanza(lStanza),
        'The exact IQ responder should handle its registered QName.');
      AssertTrue(lRecorder.HandlerCount = 2,
        'The exclusive responder and matching observer should both run.');
    finally
      lStanza.Free;
    end;

    lID := lManager.BeginRequest('server.example', 1000, @lRecorder.Complete);
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' from=''server.example'' id=''' +
      lID + '''/>', '');
    lCompletion := lManager.Complete(lStanza);
    AssertTrue(Assigned(lCompletion),
      'A matching IQ result should produce a queued completion event.');
    AssertTrue(lManager.Count = 0,
      'A completed IQ request should leave the pending set.');
    lCompletion.Invoke;
    lCompletion.Free;
    AssertTrue(lRecorder.CompletionCount = 1,
      'IQ completion should invoke only when the caller pumps the event.');

    lManager.BeginRequest('', 0, @lRecorder.Complete);
    lManager.CollectTimeouts(GetTickCount64, lEvents);
    AssertTrue(lEvents.Count = 1,
      'An expired IQ request should become a queued timeout event.');
    TNXXMPPIQCompletionEvent(lEvents[0]).Invoke;
    AssertTrue(lRecorder.LastError <> '',
      'A timeout completion should carry an error.');
  finally
    lCapacity.Free;
    lEvents.Free;
    lManager.Free;
    lDispatcher.Free;
    lRecorder.Free;
  end;
end;

procedure TestEndpointOrderingAndCrypto;
var
  lCombined: TNXXMPPEndpointArray;
  lEndpoints: TNXXMPPEndpointArray;
  lRecords: TStringList;
begin
  lRecords := TStringList.Create;
  try
    lRecords.Add('20,0,5222,late.example');
    lRecords.Add('10,1,5222,first.example');
    lRecords.Add('10,5,5222,weighted.example');
    lEndpoints := TNXXMPPEndpointResolver.OrderSRVRecords(lRecords,
      xtsStartTLS, 1234);
    AssertTrue(Length(lEndpoints) = 3,
      'All valid SRV endpoints should be retained.');
    AssertTrue((lEndpoints[0].Priority = 10) and
      (lEndpoints[1].Priority = 10) and (lEndpoints[2].Priority = 20),
      'SRV priority groups should be ordered before weight selection.');
  finally
    lRecords.Free;
  end;
  SetLength(lCombined, 2);
  lCombined[0].Host := 'direct.example';
  lCombined[0].Priority := 20;
  lCombined[0].Weight := 1;
  lCombined[0].Security := xtsDirectTLS;
  lCombined[1].Host := 'starttls.example';
  lCombined[1].Priority := 10;
  lCombined[1].Weight := 1;
  lCombined[1].Security := xtsStartTLS;
  lCombined := TNXXMPPEndpointResolver.OrderEndpoints(lCombined, 1);
  AssertTrue((lCombined[0].Host = 'starttls.example') and
    (lCombined[0].Security = xtsStartTLS),
    'Direct TLS and STARTTLS endpoints should share one priority order.');
  TNXOpenSSLCrypto.RequireAvailable;
  AssertEquals('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    HexValue(TNXOpenSSLCrypto.SHA256('abc')),
    'OpenSSL should provide SHA-256.');
  AssertTrue(Length(TNXOpenSSLCrypto.RandomBytes(32)) = 32,
    'OpenSSL should provide secure random bytes.');
end;

procedure TestTLSVerification;
var
  lCAFile: string;
  lFixturePath: string;
  lServer: TTLSLoopbackServer;
  lTransport: TNXXMPPTransport;
begin
  lFixturePath := IncludeTrailingPathDelimiter(GetCurrentDir) +
    'packages' + DirectorySeparator + 'nexus-packages' + DirectorySeparator +
    'network' + DirectorySeparator + 'xmpp' + DirectorySeparator + 'test' +
    DirectorySeparator + 'fixtures' + DirectorySeparator + 'xmpp' +
    DirectorySeparator;
  lCAFile := lFixturePath + 'ca.crt';
  AssertTrue(FileExists(lCAFile) and
    FileExists(lFixturePath + 'server.crt') and
    FileExists(lFixturePath + 'server.key'),
    'The synthetic TLS fixtures should be available.');

  lServer := TTLSLoopbackServer.Create(lFixturePath + 'server.crt',
    lFixturePath + 'server.key');
  lTransport := TNXXMPPTransport.Create;
  try
    lServer.Start;
    lTransport.Connect('127.0.0.1', lServer.Port, 2000);
    lTransport.Secure('localhost', lCAFile);
    AssertTrue(lTransport.Socket.SSL.SSLEnabled,
      'A trusted loopback certificate with the right identity should pass.');
  finally
    lTransport.Free;
    lServer.Free;
  end;

  lServer := TTLSLoopbackServer.Create(lFixturePath + 'server.crt',
    lFixturePath + 'server.key');
  lTransport := TNXXMPPTransport.Create;
  try
    lServer.Start;
    lTransport.Connect('127.0.0.1', lServer.Port, 2000);
    try
      lTransport.Secure('wrong.example', lCAFile);
      raise Exception.Create('A wrong TLS service identity should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'tls-failed',
          'A wrong TLS identity should fail in the TLS owner.');
    end;
  finally
    lTransport.Free;
    lServer.Free;
  end;

  lServer := TTLSLoopbackServer.Create(lFixturePath + 'server.crt',
    lFixturePath + 'server.key');
  lTransport := TNXXMPPTransport.Create;
  try
    lServer.Start;
    lTransport.Connect('127.0.0.1', lServer.Port, 2000);
    try
      lTransport.Secure('localhost', lFixturePath + 'untrusted-ca.crt');
      raise Exception.Create('An untrusted TLS issuer should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'tls-failed',
          'An untrusted TLS issuer should fail in the TLS owner.');
    end;
  finally
    lTransport.Free;
    lServer.Free;
  end;
end;

procedure TestBlockedReadInterruption;
var
  lElapsed: QWord;
  lReader: TTransportReader;
  lServer: TBlockingLoopbackServer;
  lStarted: QWord;
  lTransport: TNXXMPPTransport;
begin
  lServer := TBlockingLoopbackServer.Create;
  lTransport := TNXXMPPTransport.Create;
  lReader := nil;
  try
    lServer.Start;
    lTransport.Connect('127.0.0.1', lServer.Port, 2000);
    lReader := TTransportReader.Create(lTransport);
    lReader.Start;
    Sleep(100);
    lStarted := GetTickCount64;
    lTransport.Interrupt;
    lReader.WaitFor;
    lElapsed := GetTickCount64 - lStarted;
    AssertTrue(lElapsed < 2000,
      'The independent shutdown path should wake a blocked socket read.');
  finally
    lReader.Free;
    lTransport.Free;
    lServer.Free;
  end;
end;

procedure TestSCRAMSHA256;
var
  lRejected: Boolean;
  lSCRAM: TNXXMPPSCRAMSHA256;
begin
  lSCRAM := TNXXMPPSCRAMSHA256.Create;
  try
    AssertEquals('n,,n=user,r=rOprNGfwEbeRWgbNEkqO',
      lSCRAM.Start('user', 'rOprNGfwEbeRWgbNEkqO'),
      'SCRAM should produce the RFC 7677 client-first message.');
    AssertEquals(
      'c=biws,r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,' +
      'p=dHzbZapWIk4jUhN+Ute9ytag9zjfMHgsqmmiz7AndVQ=',
      lSCRAM.Continue(
        'r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,' +
        's=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096', 'pencil'),
      'SCRAM should reproduce the RFC 7677 client proof.');
    lSCRAM.VerifyServerFinal(
      'v=6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4=');
    AssertEquals('n,,n=user,r=clientnonce',
      lSCRAM.Start('USER', 'clientnonce'),
      'SCRAM should apply ASCII case mapping to the username.');
    lRejected := False;
    try
      lSCRAM.Start(UTF8String('us') +
        UTF8Encode(UnicodeString(#$00E9)) + 'r', 'clientnonce');
    except
      on E: ENXXMPPError do
        lRejected := E.Condition = 'invalid-scram-username';
    end;
    AssertTrue(lRejected, 'SCRAM should reject a non-ASCII username.');
    lSCRAM.Start('user', 'clientnonce');
    lRejected := False;
    try
      lSCRAM.Continue(
        'r=clientnonceserver,s=QSXCR+Q6sek8bf92,i=4096',
        UTF8String('p') + UTF8Encode(UnicodeString(#$00E9)) + 'ncil');
    except
      on E: ENXXMPPError do
        lRejected := E.Condition = 'invalid-scram-password';
    end;
    AssertTrue(lRejected, 'SCRAM should reject a non-ASCII password.');
    lSCRAM.Start('user', 'clientnonce');
    try
      lSCRAM.Continue('r=wrongnonce,s=QSXCR+Q6sek8bf92,i=4096',
        'pencil');
      raise Exception.Create('A mismatched SCRAM nonce should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'invalid-scram-nonce',
          'A mismatched SCRAM nonce should have an exact condition.');
    end;
    lSCRAM.Start('user', 'clientnonce');
    try
      lSCRAM.Continue(
        'r=clientnonceserver,s=QSXCR+Q6sek8bf92,i=1', 'pencil');
      raise Exception.Create('A weak SCRAM iteration count should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'scram-iteration-policy',
          'Weak SCRAM iteration counts should be rejected by policy.');
    end;
    lSCRAM.Start('user', 'rOprNGfwEbeRWgbNEkqO');
    lSCRAM.Continue(
      'r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,' +
      's=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096', 'pencil');
    try
      lSCRAM.VerifyServerFinal('v=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
        'AAAAAAAAAAA=');
      raise Exception.Create('A mismatched SCRAM signature should fail.');
    except
      on E: ENXXMPPError do
        AssertTrue(E.Condition = 'scram-signature-mismatch',
          'A mismatched SCRAM signature should be rejected.');
    end;
  finally
    lSCRAM.Free;
  end;
end;

procedure TestBoundedQueue;
var
  lFirst: TObject;
  lQueue: TNXXMPPObjectQueue;
  lRejected: TObject;
begin
  lQueue := TNXXMPPObjectQueue.Create(1);
  try
    lFirst := TObject.Create;
    AssertTrue(lQueue.Enqueue(lFirst),
      'The queue should accept an item below capacity.');
    lRejected := TObject.Create;
    AssertTrue(not lQueue.Enqueue(lRejected),
      'The queue should reject an item at capacity.');
    lRejected.Free;
    AssertTrue(lQueue.Dequeue = lFirst,
      'The queue should transfer the enqueued object in order.');
    lFirst.Free;
  finally
    lQueue.Free;
  end;
end;

procedure TestNegotiationAndStates;
begin
  AssertTrue(TNXXMPPNegotiation.OffersStartTLS(
    '<starttls xmlns=''urn:ietf:params:xml:ns:xmpp-tls''/>'),
    'STARTTLS should be detected from stream features.');
  AssertTrue(TNXXMPPNegotiation.SelectAuthentication(
    '<mechanism>SCRAM-SHA-256</mechanism>', False, True) =
    xamSCRAMSHA256, 'SCRAM-SHA-256 should be preferred.');
  AssertTrue(TNXXMPPNegotiation.SelectAuthentication(
    '<mechanism>PLAIN</mechanism>', False, True) = xamNone,
    'PLAIN should require explicit policy permission.');
  AssertTrue(NXXMPPStateTransitionAllowed(xcsDisconnected, xcsResolving),
    'Resolution should be a legal initial transition.');
  AssertTrue(NXXMPPStateTransitionAllowed(xcsOnline, xcsClosing),
    'Online sessions should close explicitly.');
  AssertTrue(not NXXMPPStateTransitionAllowed(xcsOnline, xcsAuthenticating),
    'Online sessions must not jump back to authentication.');
end;

procedure TestStreamManagement;
var
  lCounter: Cardinal;
  lErrorRaised: Boolean;
  lResponse: TNXXMPPStanza;
  lSM: TNXXMPPStreamManagement;
  lUnrecoverable: TStringList;
begin
  lSM := TNXXMPPStreamManagement.Create(2);
  try
    lSM.Enable('resume-token', True, True, 30);
    lSM.IncomingHandled;
    lSM.PrepareOutgoing(True);
    lSM.OutgoingSent('<message id=''one''/>', True);
    lSM.OutgoingSent('<iq id=''unsafe''/>', False);
    lSM.PrepareOutgoing(True);
    lSM.OutgoingSent('<presence/>', True);
    AssertTrue(lSM.ReplayCount = 2,
      'Replayable unacknowledged stanzas should be retained.');
    lResponse := TNXXMPPStanza.Create(
      '<resumed xmlns=''urn:xmpp:sm:3'' h=''2'' previd=''resume-token''/>',
      '');
    try
      AssertTrue(lSM.ProcessResumeResponse(lResponse),
        'An accepted resumption response should continue the managed stream.');
    finally
      lResponse.Free;
    end;
    AssertTrue(lSM.ReplayCount = 1,
      'An acknowledgement should release the acknowledged prefix.');
    AssertEquals('<presence/>', lSM.ReplayXML(0),
      'Only the eligible unacknowledged suffix should be replayed.');
    AssertEquals('<a xmlns=''urn:xmpp:sm:3'' h=''1''/>',
      lSM.AcknowledgementXML,
      'The acknowledgement should report handled inbound stanzas.');
    lSM.MarkDisconnected(GetTickCount64);
    AssertTrue(Pos('previd=''resume-token''',
      string(lSM.ResumeRequestXML)) > 0,
      'A resumable stream should build a resume request with its token.');
    lResponse := TNXXMPPStanza.Create(
      '<failed xmlns=''urn:xmpp:sm:3''/>', '');
    try
      AssertTrue(not lSM.ProcessResumeResponse(lResponse),
        'A failed resumption response should reject the prior stream.');
    finally
      lResponse.Free;
    end;
    AssertTrue(lSM.ReplayCount = 1,
      'A failed response must retain replay state until it is surfaced.');
    lUnrecoverable := lSM.ResumeRejected;
    try
      AssertTrue((lUnrecoverable.Count = 1) and
        (lUnrecoverable[0] = '<presence/>'),
        'Rejected resumption should return every unrecoverable stanza.');
    finally
      lUnrecoverable.Free;
    end;

    lSM.Enable('window', True, True, 30);
    lSM.MarkDisconnected(1000);
    AssertTrue(lSM.CanResume(31000),
      'The advertised resumption interval should include its boundary.');
    AssertTrue(not lSM.CanResume(31001),
      'The advertised resumption interval should reject expired sessions.');

    lSM.Enable('not-authorized', False, False, 0);
    lSM.MarkDisconnected(1000);
    AssertTrue(not lSM.CanResume(1001),
      'An identifier must not permit resumption without server authorization.');

    lSM.Enable('unbounded', True, False, 0);
    lSM.MarkDisconnected(1000);
    AssertTrue(lSM.CanResume(QWord(High(Cardinal)) * 1000),
      'The absence of max should not invent a server resumption deadline.');

    lSM.Enable('capacity', True, False, 0);
    lSM.PrepareOutgoing(True);
    lSM.OutgoingSent('<message id=''full''/>', True);
    lSM.PrepareOutgoing(True);
    lSM.OutgoingCancelled(True);
    lSM.PrepareOutgoing(True);
    lSM.OutgoingSent('<message id=''second''/>', True);
    lErrorRaised := False;
    try
      lSM.PrepareOutgoing(True);
    except
      on E: ENXXMPPError do
        lErrorRaised := E.Condition = 'replay-queue-full';
    end;
    AssertTrue(lErrorRaised and (lSM.HandledOutgoing = 2),
      'Replay capacity must fail before a stanza is counted as transmitted.');

    lSM.Reset;
    lSM.Enable('expected', True, False, 0);
    lSM.MarkDisconnected(GetTickCount64);
    lResponse := TNXXMPPStanza.Create(
      '<resumed xmlns=''urn:xmpp:sm:3'' h=''0'' previd=''wrong''/>', '');
    try
      lErrorRaised := False;
      try
        lSM.ProcessResumeResponse(lResponse);
      except
        on E: ENXXMPPError do
          lErrorRaised := E.Condition = 'invalid-sm-previd';
      end;
      AssertTrue(lErrorRaised,
        'A resumed response must identify the requested prior stream.');
    finally
      lResponse.Free;
    end;

    lCounter := High(Cardinal);
    NXXMPPIncrementSMCounter(lCounter);
    AssertTrue((lCounter = 0) and
      (NXXMPPSMCounterDelta(High(Cardinal), 0) = 1),
      'Stream-management counters should wrap modulo two to the power of 32.');
  finally
    lSM.Free;
  end;
end;

procedure TestDiscoModule;
var
  lDisco: TNXXMPPDiscoModule;
  lDispatcher: TNXXMPPDispatcher;
  lRecorder: TModuleRecorder;
  lStanza: TNXXMPPStanza;
begin
  lDisco := TNXXMPPDiscoModule.Create('client', 'pc', 'NexusXMPP');
  lDispatcher := TNXXMPPDispatcher.Create;
  lRecorder := TModuleRecorder.Create;
  try
    lDisco.AddFeature('urn:xmpp:ping');
    lDisco.Sender := @lRecorder.Send;
    lDisco.RegisterHandlers(lDispatcher);
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''get'' id=''d1'' from=''peer''>' +
      '<query xmlns=''http://jabber.org/protocol/disco#info''/></iq>', '');
    try
      AssertTrue(lDispatcher.DispatchStanza(lStanza),
        'Disco info should own its exact IQ key.');
      AssertTrue(Pos('urn:xmpp:ping', string(lRecorder.XML)) > 0,
        'Disco info should advertise configured features.');
    finally
      lStanza.Free;
    end;
  finally
    lRecorder.Free;
    lDispatcher.Free;
    lDisco.Free;
  end;
end;

procedure TestRosterModule;
var
  lDispatcher: TNXXMPPDispatcher;
  lRecorder: TModuleRecorder;
  lRoster: TNXXMPPRosterModule;
  lStanza: TNXXMPPStanza;
begin
  lDispatcher := TNXXMPPDispatcher.Create;
  lRecorder := TModuleRecorder.Create;
  lRoster := TNXXMPPRosterModule.Create;
  try
    lRoster.Sender := @lRecorder.Send;
    lRoster.OnChanged := @lRecorder.Changed;
    lRoster.RegisterHandlers(lDispatcher);
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''set'' id=''r1''>' +
      '<query xmlns=''jabber:iq:roster''><item jid=''peer@example.com'' ' +
      'name=''Peer'' subscription=''both''/></query></iq>', '');
    try
      AssertTrue(lDispatcher.DispatchStanza(lStanza),
        'Roster pushes should own their exact IQ key.');
      AssertEquals('Peer', lRoster.Item('peer@example.com'),
        'A roster push should update the in-memory roster.');
      AssertTrue(Pos('type=''result''', string(lRecorder.XML)) > 0,
        'A roster push should receive the required acknowledgement.');
      lRoster.PumpStanza(lStanza);
      AssertTrue((lRecorder.ChangedCount = 1) and
        (lRecorder.LastJID = 'peer@example.com') and
        (lRecorder.LastSubscription = 'both'),
        'A pumped roster push should publish its subscription state.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''initial''>' +
      '<query xmlns=''jabber:iq:roster''><item jid=''two@example.com'' ' +
      'name=''Two'' subscription=''from''/></query></iq>', '');
    try
      lRoster.CompleteRequest(lStanza, '');
      AssertEquals('Two', lRoster.Item('two@example.com'),
        'Initial roster retrieval should populate roster items.');
      AssertEquals('from', lRoster.ItemSubscription('two@example.com'),
        'Roster retrieval should retain subscription state.');
    finally
      lStanza.Free;
    end;
  finally
    lRoster.Free;
    lRecorder.Free;
    lDispatcher.Free;
  end;
end;

procedure TestPhase2Config;
var
  lClone: TNXXMPPClientConfig;
  lConfig: TNXXMPPClientConfig;
  lRejected: Boolean;
begin
  lConfig := TNXXMPPClientConfig.Create;
  try
    lConfig.JID := 'test@example.com';
    lConfig.Password := 'password';
    lConfig.CAFile := ParamStr(0);
    lConfig.CapabilityCacheCapacity := 7;
    lConfig.MAMConcurrentCapacity := 3;
    lConfig.MAMMaximumBytes := 12345;
    lConfig.MAMMaximumPageSize := 17;
    lConfig.MAMMaximumResults := 29;
    lConfig.MUCHistoryCapacity := 11;
    lConfig.MUCOccupantCapacity := 13;
    lConfig.MUCRoomCapacity := 5;
    lConfig.ReceiptCapacity := 19;
    lConfig.ReplyFallbackMaximumCharacters := 23;
    lConfig.ForwardingMaximumDepth := 4;
    lConfig.Validate;
    lClone := lConfig.Clone;
    try
      AssertTrue((lClone.CapabilityCacheCapacity = 7) and
        (lClone.MAMConcurrentCapacity = 3) and
        (lClone.MAMMaximumBytes = 12345) and
        (lClone.MAMMaximumPageSize = 17) and
        (lClone.MAMMaximumResults = 29) and
        (lClone.MUCHistoryCapacity = 11) and
        (lClone.MUCOccupantCapacity = 13) and
        (lClone.MUCRoomCapacity = 5) and (lClone.ReceiptCapacity = 19) and
        (lClone.ReplyFallbackMaximumCharacters = 23) and
        (lClone.ForwardingMaximumDepth = 4),
        'Phase 2 limits should survive configuration cloning.');
    finally
      lClone.Free;
    end;
    lConfig.Resource := UTF8String('D') +
      UTF8Encode(UnicodeString(#$00E9)) + 'sk';
    lRejected := False;
    try
      lConfig.Validate;
    except
      on E: ENXXMPPError do
        lRejected := E.Condition = 'invalid-resource';
    end;
    AssertTrue(lRejected,
      'Configuration should reject a non-ASCII XMPP resource.');
    lConfig.Resource := 'Desk';
    lConfig.Password := UTF8String('p') +
      UTF8Encode(UnicodeString(#$00E9)) + 'ncil';
    lRejected := False;
    try
      lConfig.Validate;
    except
      on E: ENXXMPPError do
        lRejected := E.Condition = 'invalid-password';
    end;
    AssertTrue(lRejected,
      'Configuration should reject a non-ASCII XMPP password.');
    lConfig.Password := 'password';
    lConfig.ReceiptCapacity := 0;
    lRejected := False;
    try
      lConfig.Validate;
    except
      on ENXXMPPError do
        lRejected := True;
    end;
    AssertTrue(lRejected, 'Invalid Phase 2 limits should fail validation.');
  finally
    lConfig.Free;
  end;
end;

procedure TestPhase2Modules;
var
  lCarbons: TNXXMPPCarbonsModule;
  lBeforeCount: Integer;
  lBeforeComplete: Integer;
  lDisco: TNXXMPPDiscoModule;
  lDispatcher: TNXXMPPDispatcher;
  lIdentity: TNXXMPPOutgoingMessageIdentity;
  lIQHandler: TNXXMPPIQCompletionHandler;
  lMAM: TNXXMPPMAMModule;
  lMAMFilter: TNXXMPPMAMFilter;
  lMAMOperation: INXXMPPMAMOperation;
  lMAMOperation2: INXXMPPMAMOperation;
  lMAMPage: TNXXMPPMAMPage;
  lPhase2Config: TNXXMPPClientConfig;
  lMessage: TNXXMPPMessageModule;
  lCreateMUC: TNXXMPPMUCModule;
  lMUC: TNXXMPPMUCModule;
  lHistory: TNXXMPPMUCHistoryRequest;
  lOccupant: TNXXMPPOccupant;
  lReplyMessage: TNXXMPPMessage;
  lPing: TNXXMPPPingModule;
  lQueryID: UTF8String;
  lRecorder: TPhase2Recorder;
  lStanza: TNXXMPPStanza;
begin
  lRecorder := TPhase2Recorder.Create;
  lDispatcher := TNXXMPPDispatcher.Create;
  lMessage := TNXXMPPMessageModule.Create;
  lCreateMUC := TNXXMPPMUCModule.Create;
  lMUC := TNXXMPPMUCModule.Create;
  lCarbons := TNXXMPPCarbonsModule.Create('test@example.com');
  lMAM := TNXXMPPMAMModule.Create;
  lDisco := TNXXMPPDiscoModule.Create('client', 'pc', 'NexusXMPP');
  lPing := TNXXMPPPingModule.Create;
  try
    AssertTrue(not lMessage.SendChatMessage('peer@example.com', 'queued',
      False, lIdentity) and (lIdentity.StanzaID = ''),
      'A disconnected module must reject and clear an outgoing identity.');
    lMessage.Sender := @lRecorder.Send;
    lMessage.Submitter := @lRecorder.ModuleSubmit;
    lMessage.OnMessage := @lRecorder.MessageReceived;
    lMessage.OnReceipt := @lRecorder.Receipt;
    AssertTrue(lMessage.SendChatMessage('peer@example.com', 'hello', True,
      lIdentity), 'A typed chat message should enter the module command seam.');
    AssertTrue((lIdentity.StanzaID <> '') and (lIdentity.OriginID <> '') and
      (Pos(string(lIdentity.StanzaID), string(lRecorder.XML)) > 0) and
      (Pos('urn:xmpp:receipts', string(lRecorder.XML)) > 0),
      'A typed message should return and serialize distinct identifiers.');
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''attacker@example.com''>' +
      '<received xmlns=''urn:xmpp:receipts'' id=''' +
      lIdentity.StanzaID + '''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastReceiptOutcome = xroMalformed,
        'A receipt from the wrong peer must not consume a known correlation.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
      '<received xmlns=''urn:xmpp:receipts'' id=''' +
      lIdentity.StanzaID + '''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      lMessage.PumpStanza(lStanza);
      AssertTrue((lRecorder.ReceiptCount = 3) and
        (lRecorder.LastQueryID = lIdentity.StanzaID) and
        (lRecorder.LastReceiptOutcome = xroDuplicate),
        'A repeated known receipt should report the duplicate outcome.');
    finally
      lStanza.Free;
    end;

    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
      '<received xmlns=''urn:xmpp:receipts'' id=''unknown''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastReceiptOutcome = xroUnknown,
        'An unmatched delivery receipt should be surfaced as unknown.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
      '<received xmlns=''urn:xmpp:receipts''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastReceiptOutcome = xroMalformed,
        'A receipt without an id should be surfaced as malformed.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lMessage.SendReplyWithFallback('peer@example.com', 'answer',
      UTF8String(#$E2#$86#$92' quoted'#10), 'peer@example.com', 'source-id',
      False, lIdentity), 'A bounded reply fallback should be sent.');
    AssertTrue((Pos('end=''9''', string(lRecorder.XML)) > 0) and
      (Pos('urn:xmpp:fallback:0', string(lRecorder.XML)) > 0),
      'Reply fallback ranges should be serialized in Unicode characters.');
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''chat'' id=''wire-reply-id'' ' +
      'from=''peer@example.com/r''><body>source</body>' +
      '<origin-id xmlns=''urn:xmpp:sid:0'' id=''origin-not-used''/>' +
      '</message>', '');
    try
      lReplyMessage := TNXXMPPMessage.Create(lStanza);
      try
        AssertTrue(lMessage.SendReplyToMessage('peer@example.com', 'answer',
          lReplyMessage, False, lIdentity) and
          (Pos('id=''wire-reply-id''', string(lRecorder.XML)) > 0) and
          (Pos('id=''origin-not-used''', string(lRecorder.XML)) = 0),
          'A direct typed reply should use the received ordinary stanza id.');
      finally
        lReplyMessage.Free;
      end;
    finally
      lStanza.Free;
    end;
    lPhase2Config := TNXXMPPClientConfig.Create;
    try
      lPhase2Config.ReceiptCapacity := 1;
      lPhase2Config.ReceiptTimeoutMS := 1;
      lPhase2Config.ReplyFallbackMaximumCharacters := 2;
      lMessage.Configure(lPhase2Config);
      AssertTrue(not lMessage.SendReplyWithFallback('peer@example.com',
        'answer', 'long', 'peer@example.com', 'source-id', False, lIdentity),
        'An oversized reply fallback should fail before transmission.');
      AssertTrue(lMessage.SendChatMessage('peer@example.com', 'one', True,
        lIdentity), 'The bounded receipt table should accept its first item.');
      AssertTrue(not lMessage.SendChatMessage('peer@example.com', 'two', True,
        lIdentity),
        'Receipt capacity exhaustion should fail before transmission.');
      Sleep(25);
      lStanza := TNXXMPPStanza.Create(
        '<message xmlns=''jabber:client'' from=''peer@example.com''>' +
        '<received xmlns=''urn:xmpp:receipts'' id=''still-unknown''/>' +
        '</message>', '');
      try
        lMessage.PumpStanza(lStanza);
      finally
        lStanza.Free;
      end;
      AssertTrue((lRecorder.ReceiptExpiredCount = 1) and
        lMessage.SendChatMessage('peer@example.com', 'three', True,
          lIdentity),
        'Receipt expiry should be explicit and release bounded capacity.');
      lMessage.PumpLifecycle(xmlNewSession);
      AssertTrue(lRecorder.LastReceiptOutcome = xroFailed,
        'A fresh session should explicitly fail pending receipt correlation.');
    finally
      lPhase2Config.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''peer@example.com/r'' ' +
      'type=''chat'' id=''m1''><active xmlns=' +
      '''http://jabber.org/protocol/chatstates''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(lRecorder.MessageCount = 0,
        'A bodyless chat state must not become a durable message callback.');
    finally
      lStanza.Free;
    end;
    lMessage.AutomaticReceipts := True;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''peer@example.com/r'' ' +
      'type=''chat'' id=''incoming-receipt''><body>content</body>' +
      '<request xmlns=''urn:xmpp:receipts''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(Pos('<received xmlns=''urn:xmpp:receipts'' ' +
        'id=''incoming-receipt''/>', string(lRecorder.XML)) > 0,
        'Explicitly enabled automatic receipts should answer eligible chat.');
    finally
      lStanza.Free;
    end;
    lRecorder.XML := 'unchanged';
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''room@example.com/nick'' ' +
      'type=''groupchat'' id=''group-receipt''><body>content</body>' +
      '<request xmlns=''urn:xmpp:receipts''/></message>', '');
    try
      lMessage.PumpStanza(lStanza);
      AssertTrue(lRecorder.XML = 'unchanged',
        'Automatic receipts must not answer groupchat requests.');
    finally
      lStanza.Free;
    end;
    lMessage.AutomaticReceipts := False;
    lPing.Sender := @lRecorder.Send;
    lPing.RegisterHandlers(lDispatcher);
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''get'' id=''p1'' from=''peer''>' +
      '<ping xmlns=''urn:xmpp:ping''/></iq>', '');
    try
      AssertTrue(lDispatcher.DispatchStanza(lStanza) and
        (Pos('type=''result''', string(lRecorder.XML)) > 0),
        'The ping module should answer an incoming ping.');
    finally
      lStanza.Free;
    end;

    lDisco.IQSubmitter := @lRecorder.SubmitIQ;
    lDisco.OnInfo := @lRecorder.DiscoInfo;
    lRecorder.CapabilityCache := lDisco.Capabilities;
    AssertTrue(lDisco.QueryInfo('service.example.com', ''),
      'Outgoing disco info should use the shared IQ seam.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''d2'' ' +
      'from=''service.example.com''><query xmlns=' +
      '''http://jabber.org/protocol/disco#info''><identity category=''server'' ' +
      'type=''im''/><feature var=''urn:xmpp:ping''/></query></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.DiscoCount = 1) and
        (lRecorder.LastBody = 'urn:xmpp:ping') and
        (lRecorder.LastHash <> '') and lRecorder.CapabilityStored and
        lDisco.Capabilities.Supports('service.example.com', 'client-node',
          'urn:xmpp:ping'),
        'Outgoing disco results should be parsed into typed data.');
    finally
      lStanza.Free;
    end;
    lRecorder.CapabilityCache := nil;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' from=''peer@example.com/r''>' +
      '<c xmlns=''http://jabber.org/protocol/caps'' hash=''sha-1'' ' +
      'node=''client-node'' ver=''' + lRecorder.LastHash + '''/></presence>', '');
    try
      lDisco.PumpStanza(lStanza);
      AssertTrue(Pos('node=''client-node#' + string(lRecorder.LastHash) + '''',
        string(lRecorder.IQPayload)) > 0,
        'A supported capability advertisement should request its exact node.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''caps1'' ' +
      'from=''peer@example.com/r''><query xmlns=' +
      '''http://jabber.org/protocol/disco#info'' node=''client-node#' +
      lRecorder.LastHash + '''><identity category=''server'' type=''im''/>' +
      '<feature var=''urn:xmpp:ping''/></query></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue(lDisco.Capabilities.Supports('peer@example.com/r',
        'client-node#' + lRecorder.LastHash, 'urn:xmpp:ping'),
        'A matching capability response should enter the verified cache.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' from=''legacy@example.com/r''>' +
      '<c xmlns=''http://jabber.org/protocol/caps'' hash=''sha-256'' ' +
      'node=''legacy-node'' ver=''unsupported''/></presence>', '');
    try
      lDisco.PumpStanza(lStanza);
      AssertTrue(Pos(' node=', string(lRecorder.IQPayload)) = 0,
        'An unsupported caps hash should fall back to direct disco.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' from=''bad@example.com/r''>' +
      '<c xmlns=''http://jabber.org/protocol/caps'' hash=''sha-1'' ' +
      'node=''bad-node'' ver=''' + lRecorder.LastHash + '''/></presence>', '');
    try
      lDisco.PumpStanza(lStanza);
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''caps-bad'' ' +
      'from=''bad@example.com/r''><query xmlns=' +
      '''http://jabber.org/protocol/disco#info'' node=''wrong-node''>' +
      '<identity category=''server'' type=''im''/>' +
      '<feature var=''urn:xmpp:ping''/></query></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue(not lDisco.Capabilities.Contains('bad@example.com/r',
        'bad-node#' + lRecorder.LastHash),
        'A capability response for the wrong node must not be cached.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lDisco.QueryInfo('caps-vector.example.com', ''),
      'The capability verification vector should submit a disco query.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''caps-vector'' ' +
      'from=''caps-vector.example.com''><query xmlns=' +
      '''http://jabber.org/protocol/disco#info''>' +
      '<identity category=''client'' type=''pc'' name=''Exodus 0.9.1''/>' +
      '<feature var=''http://jabber.org/protocol/caps''/>' +
      '<feature var=''http://jabber.org/protocol/disco#info''/>' +
      '<feature var=''http://jabber.org/protocol/disco#items''/>' +
      '<feature var=''http://jabber.org/protocol/muc''/>' +
      '</query></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertEquals('QgayPKawpkPSDYmwT/WM94uAlu0=', lRecorder.LastHash,
        'XEP-0115 capability hashing should match the published vector.');
    finally
      lStanza.Free;
    end;

    lCarbons.IQSubmitter := @lRecorder.SubmitIQ;
    lCarbons.OnCarbon := @lRecorder.Carbon;
    lCarbons.OnDiagnostic := @lRecorder.CarbonDiagnostic;
    AssertTrue(not lCarbons.Enable,
      'Carbon activation should require verified support by default.');
    lCarbons.SetServerSupport(True);
    AssertTrue(lCarbons.Enable, 'Carbon activation should submit an IQ.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''c1''/>', '');
    try
      lRecorder.IQHandler(lStanza, '');
    finally
      lStanza.Free;
    end;
    AssertTrue(lCarbons.State = xcsCarbonsEnabled,
      'A successful activation IQ should enable carbons.');
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''test@example.com''>' +
      '<sent xmlns=''urn:xmpp:carbons:2''><forwarded xmlns=' +
      '''urn:xmpp:forward:0''><delay xmlns=''urn:xmpp:delay'' ' +
      'stamp=''2026-09-02T12:00:00Z''/><message xmlns=''jabber:client'' ' +
      'from=''test@example.com/resource'' to=''peer@example.com''>' +
      '<body>copy</body></message></forwarded>' +
      '</sent></message>', '');
    try
      lCarbons.PumpStanza(lStanza);
      AssertTrue((lRecorder.CarbonCount = 1) and
        (lRecorder.LastContext = xmdcCarbonSent) and
        lRecorder.LastDelayPresent,
        'A trusted carbon should preserve its synthetic delivery context.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''attacker.example''>' +
      '<sent xmlns=''urn:xmpp:carbons:2''><forwarded xmlns=' +
      '''urn:xmpp:forward:0''><message xmlns=''jabber:client''>' +
      '<body>spoofed</body></message></forwarded></sent></message>', '');
    try
      lCarbons.PumpStanza(lStanza);
      AssertTrue((lRecorder.CarbonCount = 1) and
        (lRecorder.DiagnosticCount = 1) and
        (lRecorder.LastError = 'carbon-authority'),
        'A carbon wrapper from another bare JID must be rejected.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''test@example.com''>' +
      '<received xmlns=''urn:xmpp:carbons:2''><forwarded xmlns=' +
      '''urn:xmpp:forward:0''><message xmlns=''jabber:client'' ' +
      'to=''someone-else@example.com''><body>wrong</body></message>' +
      '</forwarded></received></message>', '');
    try
      lCarbons.PumpStanza(lStanza);
      AssertTrue((lRecorder.CarbonCount = 1) and
        (lRecorder.LastError = 'carbon-direction-authority'),
        'A Carbon whose forwarded addressing contradicts its direction ' +
        'must be rejected.');
    finally
      lStanza.Free;
    end;
    lCarbons.Lifecycle(xmlTemporaryLoss);
    AssertTrue(lCarbons.State = xcsCarbonsUnknown,
      'Temporary loss should make carbon activation uncertain.');
    lCarbons.Lifecycle(xmlStreamResumed);
    AssertTrue(lCarbons.State = xcsCarbonsEnabled,
      'Accepted stream resumption should retain carbon activation.');
    lCarbons.Lifecycle(xmlNewSession);
    AssertTrue((lCarbons.State = xcsCarbonsEnabling) and
      (Pos('urn:xmpp:carbons:2', string(lRecorder.IQPayload)) > 0),
      'A new session should re-enable requested carbons.');

    lMAM.IQSubmitter := @lRecorder.SubmitIQ;
    lMAM.OnResult := @lRecorder.MAMResult;
    lMAM.OnComplete := @lRecorder.MAMComplete;
    lMAM.OnDiagnostic := @lRecorder.MAMDiagnostic;
    FillChar(lMAMFilter, SizeOf(lMAMFilter), 0);
    FillChar(lMAMPage, SizeOf(lMAMPage), 0);
    lMAMFilter.WithJID := 'peer@example.com';
    lMAMFilter.StartTimestamp := '2026-09-01T00:00:00Z';
    lMAMFilter.EndTimestamp := '2026-09-02T00:00:00Z';
    lMAMFilter.BeforeID := 'before-id';
    lMAMFilter.AfterID := 'after-id';
    SetLength(lMAMFilter.IDs, 2);
    lMAMFilter.IDs[0] := 'one';
    lMAMFilter.IDs[1] := 'two';
    lMAMFilter.IncludeGroupchatSpecified := True;
    lMAMFilter.IncludeGroupchat := True;
    lMAMPage.Direction := xmpLastPage;
    lMAMPage.Maximum := 10;
    AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
      10, 4096, lMAMOperation),
      'A bounded MAM query should submit its final IQ.');
    lQueryID := lMAMOperation.QueryID;
    AssertTrue((Pos('var=''with''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''start''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''end''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''before-id''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''after-id''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''ids''', string(lRecorder.IQPayload)) > 0) and
      (Pos('var=''include-groupchat''', string(lRecorder.IQPayload)) > 0) and
      (Pos('<before/>', string(lRecorder.IQPayload)) > 0),
      'MAM should serialize typed filters and last-page RSM requests.');
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''archive.example.com''>' +
      '<result xmlns=''urn:xmpp:mam:2'' queryid=''' + lQueryID +
      ''' id=''r1''><forwarded xmlns=''urn:xmpp:forward:0''>' +
      '<delay xmlns=''urn:xmpp:delay'' stamp=''2026-09-02T12:00:00Z''/>' +
      '<message xmlns=''jabber:client'' from=''peer''><body>archived</body>' +
      '</message></forwarded></result></message>', '');
    try
      lMAM.PumpStanza(lStanza);
      lMAM.PumpStanza(lStanza);
      AssertTrue((lRecorder.MAMResultCount = 1) and
        lRecorder.LastDelayPresent and
        (lRecorder.LastError = 'mam-duplicate-result'),
        'A MAM operation should reject a duplicate archive result ID.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''mam-final'' ' +
      'from=''archive.example.com''><fin xmlns=''urn:xmpp:mam:2'' ' +
      'queryid=''' + lQueryID + ''' complete=''true'' stable=''true''>' +
      '<set xmlns=''http://jabber.org/protocol/rsm''><first index=''4''>r1' +
      '</first><last>r9</last><count>20</count></set></fin></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.CompleteCount = 1) and
        (lRecorder.LastQueryID = lQueryID) and
        (lMAMOperation.State = xmsCompleted) and lMAMOperation.Complete and
        lMAMOperation.Stable and (lMAMOperation.First = 'r1') and
        (lMAMOperation.FirstIndex = 4) and
        (lMAMOperation.Last = 'r9') and
        (lMAMOperation.ArchiveCount = 20),
        'The final IQ should complete the exact MAM query.');
    finally
      lStanza.Free;
    end;

    lMAMPage.Direction := xmpBackward;
    lMAMPage.Anchor := 'previous';
    AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
      10, 4096, lMAMOperation) and
      (Pos('<before>previous</before>', string(lRecorder.IQPayload)) > 0) and
      (lMAMOperation.ArchiveJID = 'archive.example.com') and
      (lMAMOperation.MaximumResults = 10) and
      (lMAMOperation.MaximumBytes = 4096) and lMAMOperation.Cancel,
      'A MAM operation should retain its target, limits, and backward page.');
    lMAMFilter.StartTimestamp := 'not-a-timestamp';
    AssertTrue(not lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
      10, 4096, lMAMOperation),
      'An invalid MAM timestamp should fail before IQ submission.');
    lMAMFilter.StartTimestamp := '2026-09-01T00:00:00Z';

    lPhase2Config := TNXXMPPClientConfig.Create;
    try
      lPhase2Config.MAMConcurrentCapacity := 1;
      lMAM.Configure(lPhase2Config);
      lMAMPage.Direction := xmpForward;
      lMAMPage.Anchor := 'next';
      AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
        10, 4096, lMAMOperation), 'A forward MAM page should start.');
      AssertTrue((Pos('<after>next</after>', string(lRecorder.IQPayload)) > 0)
        and lMAMOperation.Cancel and
        (lMAMOperation.State = xmsCancelled),
        'Cancellation should terminate the owned operation locally.');
      lQueryID := lMAMOperation.QueryID;
      lBeforeCount := lRecorder.MAMResultCount;
      lStanza := TNXXMPPStanza.Create(
        '<message xmlns=''jabber:client'' from=''archive.example.com''>' +
        '<result xmlns=''urn:xmpp:mam:2'' queryid=''' + lQueryID +
        ''' id=''late''><forwarded xmlns=''urn:xmpp:forward:0''>' +
        '<message xmlns=''jabber:client''><body>late</body></message>' +
        '</forwarded></result></message>', '');
      try
        lMAM.PumpStanza(lStanza);
        AssertTrue(lRecorder.MAMResultCount = lBeforeCount,
          'Results arriving after local MAM cancellation must be ignored.');
        AssertTrue(lRecorder.LastError = 'mam-late-result',
          'Late MAM results should produce an explicit diagnostic.');
      finally
        lStanza.Free;
      end;
      AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
        10, 4096, lMAMOperation2),
        'Cancellation should release concurrent-operation capacity.');
      lMAMOperation2.Cancel;
    finally
      lPhase2Config.Free;
    end;

    lMAMPage.Direction := xmpForward;
    lMAMPage.Anchor := '';
    AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
      1, 4096, lMAMOperation),
      'A one-result MAM operation should start within configured bounds.');
    lQueryID := lMAMOperation.QueryID;
    lIQHandler := lRecorder.IQHandler;
    lBeforeCount := lRecorder.MAMResultCount;
    lBeforeComplete := lRecorder.CompleteCount;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''archive.example.com''>' +
      '<result xmlns=''urn:xmpp:mam:2'' queryid=''' + lQueryID +
      ''' id=''limit-1''><forwarded xmlns=''urn:xmpp:forward:0''>' +
      '<message xmlns=''jabber:client''><body>one</body></message>' +
      '</forwarded></result></message>', '');
    try
      lMAM.PumpStanza(lStanza);
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' from=''archive.example.com''>' +
      '<result xmlns=''urn:xmpp:mam:2'' queryid=''' + lQueryID +
      ''' id=''limit-2''><forwarded xmlns=''urn:xmpp:forward:0''>' +
      '<message xmlns=''jabber:client''><body>two</body></message>' +
      '</forwarded></result></message>', '');
    try
      lMAM.PumpStanza(lStanza);
      AssertTrue((lRecorder.MAMResultCount = lBeforeCount + 1) and
        (lRecorder.CompleteCount = lBeforeComplete + 1) and
        (lMAMOperation.State = xmsLimitExceeded) and
        (lMAMOperation.Error = 'mam-limit-exceeded'),
        'MAM result overflow should become one explicit terminal outcome.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''limit-final'' ' +
      'from=''archive.example.com''><fin xmlns=''urn:xmpp:mam:2'' ' +
      'queryid=''' + lQueryID + '''/></iq>', '');
    try
      lIQHandler(lStanza, '');
      AssertTrue((lRecorder.CompleteCount = lBeforeComplete + 1) and
        (lMAMOperation.State = xmsLimitExceeded),
        'The final IQ must not duplicate a limit-exceeded completion.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lMAM.Query('archive.example.com', lMAMFilter, lMAMPage,
      2, 4096, lMAMOperation),
      'A MAM operation should start for timeout completion coverage.');
    lBeforeComplete := lRecorder.CompleteCount;
    lRecorder.IQHandler(nil, 'request-timeout');
    AssertTrue((lRecorder.CompleteCount = lBeforeComplete + 1) and
      (lMAMOperation.State = xmsFailed) and
      (lMAMOperation.Error = 'request-timeout'),
      'A MAM IQ timeout should produce exactly one failed completion.');

    lCreateMUC.Sender := @lRecorder.Send;
    lCreateMUC.Submitter := @lRecorder.ModuleSubmit;
    lCreateMUC.IQSubmitter := @lRecorder.SubmitIQ;
    lCreateMUC.OnRoomState := @lRecorder.RoomState;
    AssertTrue(lCreateMUC.CreateInstantRoom(
      'created@conference.example.com', 'creator', True) and
      (Pos('maxstanzas=''0''', string(lRecorder.XML)) > 0),
      'Instant room creation should enter through the normal MUC command API.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''created@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''owner'' ' +
      'role=''moderator''/><status code=''110''/><status code=''201''/>' +
      '</x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsConfiguring) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrConfiguring) and
        (Pos('http://jabber.org/protocol/muc#owner',
        string(lRecorder.IQPayload)) > 0) and
        (Pos('jabber:x:data'' type=''submit''',
        string(lRecorder.IQPayload)) > 0),
        'Status 201 should submit the standard instant-room owner form.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''configure-room'' ' +
      'from=''created@conference.example.com''/>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.LastRoom.State = xrsJoined) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrRoomConfigured),
        'A successful owner-form submission should complete room creation.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lCreateMUC.CreateInstantRoom(
      'created@conference.example.com', 'creator', True),
      'A room-creation retry should be accepted for server resolution.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''created@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''owner'' ' +
      'role=''moderator''/><status code=''110''/><status code=''201''/>' +
      '</x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''error'' id=''configure-error'' ' +
      'from=''created@conference.example.com''><error type=''auth''>' +
      '<forbidden xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''/>' +
      '<text xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''>denied</text>' +
      '</error></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.LastRoom.State = xrsFailed) and
        (lRecorder.LastRoom.LastTransitionReason =
        xmtrConfigurationFailed) and
        (lRecorder.LastRoom.LastError.ErrorType = 'auth') and
        (lRecorder.LastRoom.LastError.Condition = 'forbidden') and
        (lRecorder.LastRoom.LastError.Text = 'denied'),
        'An owner-form error should retain structured configuration failure.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lCreateMUC.CreateInstantRoom(
      'created@conference.example.com', 'creator', True),
      'A subsequent creation attempt should be accepted for server resolution.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''created@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''owner'' ' +
      'role=''moderator''/><status code=''110''/></x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsFailed) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrRoomAlreadyExists) and
        (lRecorder.LastRoom.LastError.Condition = 'room-already-exists') and
        (Pos('type=''unavailable''', string(lRecorder.XML)) > 0),
        'CreateInstantRoom should reject an existing room without configuring it.');
    finally
      lStanza.Free;
    end;

    AssertTrue(lCreateMUC.JoinOrCreateInstantRoom(
      'created@conference.example.com', 'creator', True),
      'Join-or-create should accept an existing room.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''created@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''member'' ' +
      'role=''participant''/><status code=''110''/></x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsJoined) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrJoined),
        'Join-or-create should join an existing room without configuring it.');
    finally
      lStanza.Free;
    end;

    AssertTrue(lCreateMUC.JoinOrCreateInstantRoom(
      'temporary@conference.example.com', 'creator', True),
      'Join-or-create should accept a missing room.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''temporary@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''owner'' ' +
      'role=''moderator''/><status code=''110''/><status code=''201''/>' +
      '</x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsConfiguring) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrConfiguring),
        'Join-or-create should configure a newly created temporary room.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''configure-temporary'' ' +
      'from=''temporary@conference.example.com''/>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.LastRoom.State = xrsJoined) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrRoomConfigured),
        'Join-or-create should enter the newly configured temporary room.');
    finally
      lStanza.Free;
    end;

    lRecorder.RejectIQ := True;
    AssertTrue(lCreateMUC.CreateInstantRoom(
      'created@conference.example.com', 'creator', True),
      'Room entry should still queue before configuration capacity is known.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''created@conference.example.com/creator''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''owner'' ' +
      'role=''moderator''/><status code=''110''/><status code=''201''/>' +
      '</x></presence>', '');
    try
      lCreateMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsFailed) and
        (lRecorder.LastRoom.LastTransitionReason =
        xmtrConfigurationFailed) and
        (lRecorder.LastRoom.LastError.Condition =
        'room-configuration-capacity') and
        (Pos('type=''unavailable''', string(lRecorder.XML)) > 0),
        'Configuration-capacity failure should be explicit and leave the room.');
    finally
      lStanza.Free;
    end;
    lRecorder.RejectIQ := False;

    lRecorder.OccupantCount := 0;
    lRecorder.RoomStateCount := 0;
    lMUC.Sender := @lRecorder.Send;
    lMUC.Submitter := @lRecorder.ModuleSubmit;
    lMUC.IQSubmitter := @lRecorder.SubmitIQ;
    lMUC.OnOccupant := @lRecorder.Occupant;
    lMUC.OnChatState := @lRecorder.MUCChatState;
    lMUC.OnRoomMessage := @lRecorder.RoomMessage;
    lMUC.OnRoomState := @lRecorder.RoomState;
    lPhase2Config := TNXXMPPClientConfig.Create;
    try
      lPhase2Config.MUCHistoryCapacity := 1;
      lPhase2Config.MUCOccupantCapacity := 2;
      lPhase2Config.MUCRoomCapacity := 1;
      lMUC.Configure(lPhase2Config);
    finally
      lPhase2Config.Free;
    end;
    lHistory.MaxChars := 2048;
    lHistory.MaxStanzas := 1;
    lHistory.Seconds := 60;
    lHistory.SinceTimestamp := '2026-09-02T00:00:00Z';
    AssertTrue(lMUC.JoinWithHistory('room@conference.example.com', 'tester',
      '', lHistory, True), 'MUC join should use a typed module command.');
    AssertTrue((Pos('maxchars=''2048''', string(lRecorder.XML)) > 0) and
      (Pos('maxstanzas=''1''', string(lRecorder.XML)) > 0) and
      (Pos('seconds=''60''', string(lRecorder.XML)) > 0) and
      (Pos('since=''2026-09-02T00:00:00Z''', string(lRecorder.XML)) > 0),
      'A MUC join should serialize each bounded history control.');
    AssertTrue(not lMUC.Join('second@conference.example.com', 'tester', '',
      True), 'MUC room capacity should fail before a join is queued.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''room@conference.example.com/tester''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''member'' ' +
      'role=''participant''/><status code=''110''/></x></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.OccupantCount = 1) and
        (lRecorder.RoomStateCount = 1) and lRecorder.LastSelf and
        lRecorder.LastAvailable and (lRecorder.LastRole = xmrParticipant) and
        (lRecorder.LastAffiliation = xmaMember) and
        (lRecorder.LastRoom.State = xrsJoined) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrJoined) and
        (Length(lRecorder.LastRoom.StatusCodes) = 1) and
        (lRecorder.LastRoom.StatusCodes[0] = 110),
        'Reflected MUC self-presence should establish joined state.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''room@conference.example.com/oldnick''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''member'' ' +
      'role=''participant''/></x><occupant-id xmlns=' +
      '''urn:xmpp:occupant-id:0'' id=''occupant-1''/><status>ready</status>' +
      '</presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      lOccupant := lRecorder.LastRoom.Occupant('oldnick');
      AssertTrue(Assigned(lOccupant) and
        (lOccupant.OccupantID = 'occupant-1') and lOccupant.Available and
        not lOccupant.Self and (lOccupant.Status = 'ready'),
        'MUC presence should retain a stable occupant identifier.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' type=''unavailable'' ' +
      'from=''room@conference.example.com/oldnick''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''member'' ' +
      'role=''participant'' nick=''newnick''/><status code=''303''/>' +
      '</x></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.OccupantCount = 2) and
        (lRecorder.LastRoom.Occupant('newnick') = lOccupant) and
        (lOccupant.OccupantID = 'occupant-1'),
        'A 303 nickname change should preserve occupant identity.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''room@conference.example.com/overflow''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''none'' ' +
      'role=''visitor''/></x></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastRoom.OccupantCount = 2,
        'MUC occupant overflow should be rejected without eviction.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' type=''unavailable'' ' +
      'from=''room@conference.example.com/newnick''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''none'' ' +
      'role=''none''/><status code=''307''/></x></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastRoom.OccupantCount = 1,
        'A kicked occupant should be removed from bounded room state.');
    finally
      lStanza.Free;
    end;
    lMUC.Lifecycle(xmlTemporaryLoss);
    AssertTrue(lRecorder.LastRoom.State = xrsStale,
      'Temporary loss should mark joined MUC state stale.');
    lMUC.Lifecycle(xmlStreamResumed);
    AssertTrue(Pos('urn:xmpp:ping', string(lRecorder.IQPayload)) > 0,
      'Accepted stream resumption should verify MUC occupancy by self-ping.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' id=''self-ping'' ' +
      'from=''room@conference.example.com/tester''/>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue(lRecorder.LastRoom.State = xrsJoined,
        'A successful self-ping should restore joined state.');
    finally
      lStanza.Free;
    end;
    lMUC.Lifecycle(xmlTemporaryLoss);
    lMUC.Lifecycle(xmlNewSession);
    AssertTrue((lRecorder.LastRoom.State = xrsRejoining) and
      (Pos('room@conference.example.com/tester', string(lRecorder.XML)) > 0),
      'A fresh session should rejoin an auto-rejoin room.');
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' ' +
      'from=''room@conference.example.com/tester''><x xmlns=' +
      '''http://jabber.org/protocol/muc#user''><item affiliation=''member'' ' +
      'role=''participant''/><status code=''110''/></x></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
    finally
      lStanza.Free;
    end;
    lBeforeCount := lRecorder.MessageCount;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''groupchat'' ' +
      'from=''room@conference.example.com/peer''>' +
      '<composing xmlns=''http://jabber.org/protocol/chatstates''/>' +
      '</message>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.ChatStateCount = 1) and
        (lRecorder.MessageCount = lBeforeCount),
        'A bodyless room chat state should be transient, not a room message.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''groupchat'' ' +
      'from=''room@conference.example.com/peer''><subject>new subject</subject>' +
      '</message>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue(lRecorder.LastRoom.Subject = 'new subject',
        'A room subject message should update typed room state.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''groupchat'' ' +
      'from=''room@conference.example.com/peer'' id=''local-id''>' +
      '<body>reply target</body><origin-id xmlns=''urn:xmpp:sid:0'' ' +
      'id=''origin-id''/></message>', '');
    try
      lReplyMessage := TNXXMPPMessage.Create(lStanza);
      try
        AssertTrue(not lMUC.SendGroupReply('room@conference.example.com',
          'no', lReplyMessage, lIdentity),
          'A groupchat reply must reject non-authoritative local identifiers.');
      finally
        lReplyMessage.Free;
      end;
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''groupchat'' ' +
      'from=''room@conference.example.com/peer''><body>reply target</body>' +
      '<stanza-id xmlns=''urn:xmpp:sid:0'' ' +
      'by=''room@conference.example.com'' id=''room-id''/></message>', '');
    try
      lReplyMessage := TNXXMPPMessage.Create(lStanza);
      try
        AssertTrue(lMUC.SendGroupReply('room@conference.example.com', 'yes',
          lReplyMessage, lIdentity) and
          (Pos('id=''room-id''', string(lRecorder.XML)) > 0),
          'A groupchat reply should use the room-issued stanza identifier.');
      finally
        lReplyMessage.Free;
      end;
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<message xmlns=''jabber:client'' type=''groupchat'' ' +
      'from=''room@conference.example.com/peer''><body>history</body>' +
      '<composing xmlns=''http://jabber.org/protocol/chatstates''/>' +
      '<delay xmlns=''urn:xmpp:delay'' stamp=''2026-09-02T00:00:00Z''/>' +
      '</message>', '');
    try
      lBeforeCount := lRecorder.MessageCount;
      lMUC.PumpStanza(lStanza);
      lMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastContext = xmdcMUCHistory) and
        (lRecorder.MessageCount = lBeforeCount + 1) and
        (lRecorder.LastRoom.HistoryCount = 1) and
        (lRecorder.ChatStateCount = 1),
        'Delayed room entry traffic should be classified as MUC history.');
    finally
      lStanza.Free;
    end;
    AssertTrue(lMUC.Leave('room@conference.example.com'),
      'MUC leave should queue unavailable presence.');
    AssertTrue((lRecorder.LastRoom.State = xrsLeaving) and
      (Pos('urn:xmpp:ping', string(lRecorder.IQPayload)) > 0),
      'MUC leave should verify absence with a typed self-ping fallback.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''error'' id=''leave-ping'' ' +
      'from=''room@conference.example.com/tester''><error type=''cancel''>' +
      '<not-acceptable xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''/>' +
      '</error></iq>', '');
    try
      lRecorder.IQHandler(lStanza, '');
      AssertTrue((lRecorder.LastRoom.State = xrsLeft) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrLeft),
        'A negative leave self-ping should confirm absent room state.');
    finally
      lStanza.Free;
    end;
    lStanza := TNXXMPPStanza.Create(
      '<presence xmlns=''jabber:client'' type=''error'' ' +
      'from=''room@conference.example.com/tester''><error type=''cancel''>' +
      '<not-allowed xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''/>' +
      '<text xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''>denied</text>' +
      '</error></presence>', '');
    try
      lMUC.PumpStanza(lStanza);
      AssertTrue((lRecorder.LastRoom.State = xrsFailed) and
        (lRecorder.LastRoom.LastTransitionReason = xmtrServiceError) and
        lRecorder.LastRoom.LastError.Present and
        (lRecorder.LastRoom.LastError.ErrorType = 'cancel') and
        (lRecorder.LastRoom.LastError.Condition = 'not-allowed') and
        (lRecorder.LastRoom.LastError.Text = 'denied'),
        'A room presence error should retain structured failure details.');
    finally
      lStanza.Free;
    end;
  finally
    lPing.Free;
    lDisco.Free;
    lMAM.Free;
    lCarbons.Free;
    lCreateMUC.Free;
    lMUC.Free;
    lMessage.Free;
    lDispatcher.Free;
    lRecorder.Free;
  end;
end;

procedure TestFileSharingModule;
var
  lConfig: TNXXMPPClientConfig;
  lModule: TNXXMPPFileSharingModule;
  lRecorder: TPhase2Recorder;
  lShare: TNXXMPPFileShare;
  lStanza: TNXXMPPStanza;
begin
  lConfig := TNXXMPPClientConfig.Create;
  lModule := TNXXMPPFileSharingModule.Create;
  lRecorder := TPhase2Recorder.Create;
  try
    lConfig.JID := 'bot@example.com';
    lModule.Configure(lConfig);
    lModule.Submitter := @lRecorder.ModuleSubmit;
    lModule.IQSubmitter := @lRecorder.SubmitIQ;
    lModule.Sender := @lRecorder.Send;
    AssertTrue(lModule.DiscoverUploadService(12,
      @lRecorder.UploadServiceReady),
      'Upload discovery should enter the module command path.');
    AssertTrue(Pos('disco#items', string(lRecorder.IQPayload)) > 0,
      'Upload discovery should begin with domain disco items.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' from=''example.com''>' +
      '<query xmlns=''http://jabber.org/protocol/disco#items''>' +
      '<item jid=''upload.example.com''/></query></iq>', '');
    try lRecorder.IQHandler(lStanza, ''); finally lStanza.Free; end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' from=''example.com''>' +
      '<query xmlns=''http://jabber.org/protocol/disco#info''/></iq>', '');
    try lRecorder.IQHandler(lStanza, ''); finally lStanza.Free; end;
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' from=''upload.example.com''>' +
      '<query xmlns=''http://jabber.org/protocol/disco#info''>' +
      '<feature var=''urn:xmpp:http:upload:0''/>' +
      '<x xmlns=''jabber:x:data'' type=''result''>' +
      '<field var=''FORM_TYPE'' type=''hidden''><value>' +
      'urn:xmpp:http:upload:0</value></field>' +
      '<field var=''max-file-size''><value>1024</value></field>' +
      '</x></query></iq>', '');
    try lRecorder.IQHandler(lStanza, ''); finally lStanza.Free; end;
    AssertTrue((lRecorder.LastError = '') and
      (lRecorder.UploadService.JID = 'upload.example.com') and
      lRecorder.UploadService.HasMaximumSize and
      (lRecorder.UploadService.MaximumSize = 1024),
      'Typed disco forms should select the compatible upload service.');

    AssertTrue(lModule.RequestUploadSlot('upload.example.com', 'test.txt',
      'text/plain', 12, @lRecorder.UploadSlotReady),
      'A typed upload slot request should be accepted.');
    AssertTrue((Pos('filename=''test.txt''', string(lRecorder.IQPayload)) > 0)
      and (Pos('purpose', string(lRecorder.IQPayload)) = 0),
      'Slot request should contain metadata and omit optional purpose.');
    lStanza := TNXXMPPStanza.Create(
      '<iq xmlns=''jabber:client'' type=''result'' ' +
      'from=''upload.example.com''><slot xmlns=''urn:xmpp:http:upload:0''>' +
      '<put url=''https://upload.example.com/put''>' +
      '<header name=''Authorization''>Bearer&#10; token</header>' +
      '<header name=''X-Ignored''>value</header></put>' +
      '<get url=''https://upload.example.com/get''/></slot></iq>', '');
    try lRecorder.IQHandler(lStanza, ''); finally lStanza.Free; end;
    AssertTrue((lRecorder.LastError = '') and
      (Length(lRecorder.UploadSlot.Headers) = 1) and
      (lRecorder.UploadSlot.Headers[0].Value = 'Bearer token'),
      'Slot parsing should strip newlines, retain allowed headers, and ignore unknown headers.');

    lShare := Default(TNXXMPPFileShare);
    lShare.ID := 'share-1';
    lShare.Name := 'test.txt';
    lShare.MediaType := 'text/plain';
    lShare.HasSize := True;
    lShare.DeclaredSize := 12;
    SetLength(lShare.Hashes, 1);
    lShare.Hashes[0].Algorithm := 'sha-256';
    lShare.Hashes[0].Value := 'digest';
    SetLength(lShare.Sources, 1);
    lShare.Sources[0].URL := 'https://upload.example.com/get';
    AssertTrue(lModule.SendFileShare('room@conference.example.com',
      'groupchat', 'sender@example.com/device', 'reply-1', lShare),
      'A typed file share should be queued.');
    AssertTrue((Pos('urn:xmpp:sfs:0', string(lRecorder.XML)) > 0) and
      (Pos('jabber:x:oob', string(lRecorder.XML)) > 0) and
      (Pos('urn:xmpp:fallback:0', string(lRecorder.XML)) > 0) and
      (Pos('urn:xmpp:sid:0', string(lRecorder.XML)) > 0) and
      (Pos('urn:xmpp:reply:0', string(lRecorder.XML)) > 0) and
      (Pos('reply-1', string(lRecorder.XML)) > 0),
      'Outbound shares should preserve origin and reply identity metadata.');
  finally
    lRecorder.Free;
    lModule.Free;
    lConfig.Free;
  end;
end;

procedure TestClientLifecycleAndCapacity;
var
  lClient: TNXXMPPClient;
  lCycle: Integer;
  lDeadline: QWord;
  lMainThreadID: TThreadID;
  lMessage: TNXXMPPMessageModule;
  lIdentity: TNXXMPPOutgoingMessageIdentity;
  lPhaseRecorder: TPhase2Recorder;
  lRecorder: TClientRecorder;
begin
  lClient := TNXXMPPClient.Create;
  lRecorder := TClientRecorder.Create;
  lPhaseRecorder := TPhase2Recorder.Create;
  try
    lClient.Config.JID := 'user@example.com';
    lClient.Config.Password := 'password';
    lClient.Config.CAFile := ParamStr(0);
    lClient.Config.EndpointHost := '127.0.0.1';
    lClient.Config.EndpointPort := 1;
    lClient.Config.ConnectionTimeoutMS := 100;
    lClient.Config.PendingIQCapacity := 1;
    lClient.Config.ReconnectAttempts := 0;
    lClient.OnError := @lRecorder.Error;
    lClient.OnState := @lRecorder.State;
    lMessage := TNXXMPPMessageModule.Create;
    lMessage.OnReceipt := @lPhaseRecorder.Receipt;
    lClient.AddModule(lMessage);
    lMainThreadID := GetCurrentThreadID;
    for lCycle := 1 to 2 do
    begin
      lClient.Connect;
      AssertTrue(lMessage.SendChatMessage('peer@example.com', 'pending', True,
        lIdentity),
        'A pending typed message should enter the connection command queue.');
      AssertTrue(lClient.SendIQ(xitGet, '', '', '<query xmlns=''urn:test''/>',
        nil), 'The first public IQ request should reserve capacity.');
      AssertTrue(not lClient.SendIQ(xitGet, '', '',
        '<query xmlns=''urn:test''/>', nil),
        'The second public IQ request should reject capacity synchronously.');
      lDeadline := GetTickCount64 + 5000;
      while (lClient.State <> xcsFailed) and
        (GetTickCount64 < lDeadline) do
        Sleep(10);
      AssertTrue(lClient.State = xcsFailed,
        'A refused loopback endpoint should produce a terminal failure.');
      lClient.Disconnect;
    end;
    AssertTrue((lRecorder.ErrorCount = 2) and (lRecorder.StateCount > 0),
      'Repeated failed connection cycles should deliver direct events.');
    AssertTrue((lRecorder.CallbackThreadID <> 0) and
      (lRecorder.CallbackThreadID <> lMainThreadID),
      'Client callbacks should execute on the connection thread.');
    AssertTrue((lPhaseRecorder.LastReceiptOutcome = xroFailed) and
      (lPhaseRecorder.CallbackThreadID <> 0) and
      (lPhaseRecorder.CallbackThreadID <> lMainThreadID),
      'Module lifecycle outcomes should execute on the connection thread.');
  finally
    lClient.Free;
    lPhaseRecorder.Free;
    lRecorder.Free;
  end;
end;

begin
  TestJID;
  TestStreamFramerAndStanza;
  TestPhase2MessageModels;
  TestDispatcherAndRequests;
  TestEndpointOrderingAndCrypto;
  TestTLSVerification;
  TestBlockedReadInterruption;
  TestSCRAMSHA256;
  TestBoundedQueue;
  TestNegotiationAndStates;
  TestStreamManagement;
  TestDiscoModule;
  TestPhase2Config;
  TestPhase2Modules;
  TestRosterModule;
  TestFileSharingModule;
  TestClientLifecycleAndCapacity;
  WriteLn('NexusNet XMPP tests passed.');
end.

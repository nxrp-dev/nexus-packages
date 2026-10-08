(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPConnection;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, SyncObjs, synacode,
  obNXXMPPCommand, obNXXMPPConfig, obNXXMPPDispatcher,
  obNXXMPPEndpointResolver, obNXXMPPError, obNXXMPPJID,
  obNXXMPPModule, obNXXMPPQueue, obNXXMPPRequestManager, obNXXMPPSASL,
  obNXXMPPStanza, obNXXMPPStreamFramer, obNXXMPPTransport,
  obNXXMPPNegotiation, obNXXMPPStreamManagement,
  tpNXXMPPTypes, utNXXMPPXML;

type
  TNXXMPPConnectionStateEvent = procedure(
    AState: TNXXMPPConnectionState) of object;
  TNXXMPPConnectionStanzaEvent = procedure(AStanza: TNXXMPPStanza) of object;
  TNXXMPPConnectionErrorEvent = procedure(AStage: TNXXMPPErrorStage;
    const ACondition, AMessage: UTF8String) of object;
  TNXXMPPConnectionCompletionEvent = procedure(
    ACompletion: TNXXMPPIQCompletionEvent) of object;
  TNXXMPPConnectionUnrecoverableStanzasEvent = procedure(
    const AReason: UTF8String; AStanzas: TStrings) of object;
  TNXXMPPConnectionModuleLifecycleEvent = procedure(
    ALifecycle: TNXXMPPModuleLifecycle) of object;

  TNXXMPPConnection = class(TThread)
  private
    FCommands: TNXXMPPObjectQueue;
    FConfig: TNXXMPPClientConfig;
    FCriticalSection: TCriticalSection;
    FDisconnectRequested: Boolean;
    FDispatcher: TNXXMPPDispatcher;
    FFrames: TStringList;
    FFramer: TNXXMPPStreamFramer;
    FJID: TNXXMPPJID;
    FIQCapacity: TNXXMPPIQCapacity;
    FModules: TObjectList;
    FOnCompletion: TNXXMPPConnectionCompletionEvent;
    FOnError: TNXXMPPConnectionErrorEvent;
    FOnModuleLifecycle: TNXXMPPConnectionModuleLifecycleEvent;
    FOnStanza: TNXXMPPConnectionStanzaEvent;
    FOnState: TNXXMPPConnectionStateEvent;
    FOnUnrecoverableStanzas: TNXXMPPConnectionUnrecoverableStanzasEvent;
    FRequests: TNXXMPPRequestManager;
    FState: TNXXMPPConnectionState;
    FStreamManagement: TNXXMPPStreamManagement;
    FTransport: TNXXMPPTransport;
    function ConnectEndpoint: TNXXMPPEndpoint;
    procedure CompleteEvents(AEvents: TObjectList);
    procedure DoOnCompletion(ACompletion: TNXXMPPIQCompletionEvent);
    procedure DoOnError(AStage: TNXXMPPErrorStage;
      const ACondition, AMessage: UTF8String);
    procedure DoOnModuleLifecycle(ALifecycle: TNXXMPPModuleLifecycle);
    procedure DoOnStanza(AStanza: TNXXMPPStanza);
    procedure DoOnState(AState: TNXXMPPConnectionState);
    procedure DoOnUnrecoverableStanzas(const AReason: UTF8String;
      AStanzas: TStrings);
    procedure HandleIncoming(AStanza: TNXXMPPStanza);
    function IsDisconnectRequested: Boolean;
    procedure RejectResumption(const AReason: UTF8String);
    function OpenSecuredStream(
      const AEndpoint: TNXXMPPEndpoint): TNXXMPPStanza;
    procedure OnlineLoop;
    procedure PerformAuthentication(AFeatures: TNXXMPPStanza);
    procedure PerformBinding(AFeatures: TNXXMPPStanza);
    procedure PerformNegotiation(const AEndpoint: TNXXMPPEndpoint);
    procedure ProcessCommands;
    procedure NotifyModules(ALifecycle: TNXXMPPModuleLifecycle);
    function ReadElement: TNXXMPPStanza;
    function ReadFrame: UTF8String;
    function RecoverConnection: Boolean;
    procedure ResetStream;
    procedure SendOpen;
    procedure SendStanza(const AXML: UTF8String; AReplayable: Boolean);
    procedure SendUnhandledIQError(AStanza: TNXXMPPStanza);
    procedure Transition(AState: TNXXMPPConnectionState);
    function TryResume(const AEndpoint: TNXXMPPEndpoint): Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AConfig: TNXXMPPClientConfig;
      ACommands: TNXXMPPObjectQueue; ADispatcher: TNXXMPPDispatcher;
      AIQCapacity: TNXXMPPIQCapacity; AModules: TObjectList);
    destructor Destroy; override;
    procedure RequestDisconnect;
    procedure SendModuleXML(const AXML: UTF8String; AReplayable: Boolean);
    function State: TNXXMPPConnectionState;
    property OnCompletion: TNXXMPPConnectionCompletionEvent
      read FOnCompletion write FOnCompletion;
    property OnError: TNXXMPPConnectionErrorEvent read FOnError write FOnError;
    property OnModuleLifecycle: TNXXMPPConnectionModuleLifecycleEvent
      read FOnModuleLifecycle write FOnModuleLifecycle;
    property OnStanza: TNXXMPPConnectionStanzaEvent
      read FOnStanza write FOnStanza;
    property OnState: TNXXMPPConnectionStateEvent read FOnState write FOnState;
    property OnUnrecoverableStanzas: TNXXMPPConnectionUnrecoverableStanzasEvent
      read FOnUnrecoverableStanzas write FOnUnrecoverableStanzas;
  end;

implementation

constructor TNXXMPPConnection.Create(AConfig: TNXXMPPClientConfig;
  ACommands: TNXXMPPObjectQueue; ADispatcher: TNXXMPPDispatcher;
  AIQCapacity: TNXXMPPIQCapacity; AModules: TObjectList);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FConfig := AConfig;
  FCommands := ACommands;
  FDispatcher := ADispatcher;
  FIQCapacity := AIQCapacity;
  FModules := AModules;
  FCriticalSection := TCriticalSection.Create;
  FFrames := TStringList.Create;
  FFramer := TNXXMPPStreamFramer.Create;
  FRequests := TNXXMPPRequestManager.Create(FConfig.PendingIQCapacity,
    FIQCapacity);
  FStreamManagement := TNXXMPPStreamManagement.Create(FConfig.CommandCapacity);
  FTransport := TNXXMPPTransport.Create;
  FState := xcsDisconnected;
end;

destructor TNXXMPPConnection.Destroy;
begin
  if not Finished then
  begin
    RequestDisconnect;
    WaitFor;
  end;
  FTransport.Free;
  FStreamManagement.Free;
  FRequests.Free;
  FFramer.Free;
  FFrames.Free;
  FJID.Free;
  FCriticalSection.Free;
  FConfig.Free;
  inherited Destroy;
end;

function TNXXMPPConnection.State: TNXXMPPConnectionState;
begin
  FCriticalSection.Acquire;
  try
    Result := FState;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPConnection.Transition(AState: TNXXMPPConnectionState);
var
  lPrevious: TNXXMPPConnectionState;
begin
  FCriticalSection.Acquire;
  try
    lPrevious := FState;
    if not NXXMPPStateTransitionAllowed(lPrevious, AState) then
      raise ENXXMPPError.Create(xesProtocol, 'illegal-state-transition',
        'Illegal XMPP state transition from ' +
        NXXMPPConnectionStateName(lPrevious) + ' to ' +
        NXXMPPConnectionStateName(AState) + '.');
    FState := AState;
  finally
    FCriticalSection.Release;
  end;
  DoOnState(AState);
end;

procedure TNXXMPPConnection.DoOnCompletion(
  ACompletion: TNXXMPPIQCompletionEvent);
begin
  if Assigned(FOnCompletion) then
    FOnCompletion(ACompletion);
end;

procedure TNXXMPPConnection.DoOnError(AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: UTF8String);
begin
  if Assigned(FOnError) then
    FOnError(AStage, ACondition, AMessage);
end;

procedure TNXXMPPConnection.DoOnModuleLifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
begin
  if Assigned(FOnModuleLifecycle) then
    FOnModuleLifecycle(ALifecycle);
end;

procedure TNXXMPPConnection.DoOnStanza(AStanza: TNXXMPPStanza);
begin
  if Assigned(FOnStanza) then
    FOnStanza(AStanza);
end;

procedure TNXXMPPConnection.DoOnState(AState: TNXXMPPConnectionState);
begin
  if Assigned(FOnState) then
    FOnState(AState);
end;

procedure TNXXMPPConnection.DoOnUnrecoverableStanzas(
  const AReason: UTF8String; AStanzas: TStrings);
begin
  if Assigned(FOnUnrecoverableStanzas) then
    FOnUnrecoverableStanzas(AReason, AStanzas);
end;

procedure TNXXMPPConnection.RequestDisconnect;
begin
  FCriticalSection.Acquire;
  try
    FDisconnectRequested := True;
  finally
    FCriticalSection.Release;
  end;
  FTransport.Interrupt;
end;

procedure TNXXMPPConnection.SendModuleXML(const AXML: UTF8String;
  AReplayable: Boolean);
begin
  if GetCurrentThreadID <> ThreadID then
    raise ENXXMPPError.Create(xesProtocol, 'wrong-module-thread',
      'XMPP modules may send only while handling the connection thread.');
  SendStanza(AXML, AReplayable);
end;

procedure TNXXMPPConnection.NotifyModules(
  ALifecycle: TNXXMPPModuleLifecycle);
var
  lIndex: Integer;
begin
  if not Assigned(FModules) then
    Exit;
  for lIndex := 0 to FModules.Count - 1 do
    TNXXMPPModule(FModules[lIndex]).Lifecycle(ALifecycle);
  DoOnModuleLifecycle(ALifecycle);
end;

procedure TNXXMPPConnection.SendStanza(const AXML: UTF8String;
  AReplayable: Boolean);
begin
  FStreamManagement.PrepareOutgoing(AReplayable);
  try
    FTransport.Send(RawByteString(AXML));
    FStreamManagement.OutgoingSent(AXML, AReplayable);
  except
    FStreamManagement.OutgoingCancelled(AReplayable);
    raise;
  end;
end;

procedure TNXXMPPConnection.RejectResumption(const AReason: UTF8String);
var
  lStanzas: TStringList;
begin
  lStanzas := FStreamManagement.ResumeRejected;
  if lStanzas.Count = 0 then
  begin
    lStanzas.Free;
    Exit;
  end;
  try
    DoOnUnrecoverableStanzas(AReason, lStanzas);
  finally
    lStanzas.Free;
  end;
end;

function TNXXMPPConnection.IsDisconnectRequested: Boolean;
begin
  FCriticalSection.Acquire;
  try
    Result := FDisconnectRequested;
  finally
    FCriticalSection.Release;
  end;
end;

function TNXXMPPConnection.ConnectEndpoint: TNXXMPPEndpoint;
var
  lEndpoints: TNXXMPPEndpointArray;
  lErrorMessage: string;
  lIndex: Integer;
  lResolver: TNXXMPPEndpointResolver;
begin
  Result.Host := '';
  if FConfig.EndpointHost <> '' then
  begin
    SetLength(lEndpoints, 1);
    lEndpoints[0].Host := FConfig.EndpointHost;
    lEndpoints[0].Port := FConfig.EndpointPort;
    if FConfig.DirectTLS then
      lEndpoints[0].Security := xtsDirectTLS
    else
      lEndpoints[0].Security := xtsStartTLS;
  end
  else
  begin
    Transition(xcsResolving);
    lResolver := TNXXMPPEndpointResolver.Create;
    try
      lEndpoints := lResolver.Resolve(FJID.DomainPart);
    finally
      lResolver.Free;
    end;
    if Length(lEndpoints) = 0 then
      raise ENXXMPPError.Create(xesResolution, 'service-unavailable',
        'The XMPP service explicitly reports that it is unavailable.');
  end;
  lErrorMessage := '';
  for lIndex := 0 to High(lEndpoints) do
  begin
    if IsDisconnectRequested then
      raise ENXXMPPError.Create(xesShutdown, 'connection-cancelled',
        'The XMPP connection was cancelled.');
    try
      Transition(xcsConnecting);
      FTransport.Connect(lEndpoints[lIndex].Host, lEndpoints[lIndex].Port,
        FConfig.ConnectionTimeoutMS);
      if lEndpoints[lIndex].Security = xtsDirectTLS then
      begin
        Transition(xcsSecuring);
        FTransport.Secure(FJID.DomainPart, FConfig.CAFile);
      end;
      Exit(lEndpoints[lIndex]);
    except
      on E: Exception do
      begin
        lErrorMessage := E.Message;
        FTransport.Close;
      end;
    end;
  end;
  raise ENXXMPPError.Create(xesConnection, 'all-endpoints-failed',
    'All XMPP endpoints failed. Last failure: ' + lErrorMessage, True);
end;

procedure TNXXMPPConnection.SendOpen;
begin
  FTransport.Send('<stream:stream to=''' +
    RawByteString(NXXMPPEscapeAttribute(FJID.DomainPart)) +
    ''' version=''1.0'' xml:lang=''en'' xmlns=''jabber:client'' ' +
    'xmlns:stream=''http://etherx.jabber.org/streams''>');
end;

procedure TNXXMPPConnection.ResetStream;
begin
  FFramer.Reset;
  FFrames.Clear;
end;

function TNXXMPPConnection.ReadFrame: UTF8String;
var
  lData: RawByteString;
  lDeadline: QWord;
begin
  lDeadline := GetTickCount64 + Cardinal(FConfig.ConnectionTimeoutMS);
  while FFrames.Count = 0 do
  begin
    if IsDisconnectRequested then
      raise ENXXMPPError.Create(xesShutdown, 'connection-cancelled',
        'The XMPP connection was cancelled.');
    lData := FTransport.Receive(250);
    if lData <> '' then
      FFramer.Feed(lData, FFrames);
    if GetTickCount64 >= lDeadline then
      raise ENXXMPPError.Create(xesStream, 'stream-timeout',
        'Timed out while waiting for the next XMPP stream element.', True);
  end;
  Result := UTF8String(FFrames[0]);
  FFrames.Delete(0);
end;

function TNXXMPPConnection.ReadElement: TNXXMPPStanza;
var
  lFrame: UTF8String;
begin
  repeat
    lFrame := ReadFrame;
    if Copy(lFrame, 1, 14) = '<stream:stream' then
      Continue;
    if Copy(lFrame, 1, 15) = '</stream:stream' then
      raise ENXXMPPError.Create(xesStream, 'stream-closed',
        'The server closed the XMPP stream.');
    Result := TNXXMPPStanza.Create(lFrame,
      FFramer.StreamNamespaceAttributes);
    Exit;
  until False;
end;

procedure TNXXMPPConnection.PerformAuthentication(AFeatures: TNXXMPPStanza);
var
  lAuthentication: TNXXMPPAuthenticationMechanism;
  lChallenge: TNXXMPPStanza;
  lClientMessage: RawByteString;
  lFinal: TNXXMPPStanza;
  lPlain: RawByteString;
  lSCRAM: TNXXMPPSCRAMSHA256;
begin
  Transition(xcsAuthenticating);
  lAuthentication := TNXXMPPNegotiation.SelectAuthentication(
    AFeatures.RawXML, FConfig.AllowPlain, True);
  if lAuthentication = xamSCRAMSHA256 then
  begin
    lSCRAM := TNXXMPPSCRAMSHA256.Create;
    try
      lClientMessage := lSCRAM.Start(FJID.LocalPart);
      FTransport.Send('<auth xmlns=''urn:ietf:params:xml:ns:xmpp-sasl'' ' +
        'mechanism=''SCRAM-SHA-256''>' + EncodeBase64(lClientMessage) +
        '</auth>');
      lChallenge := ReadElement;
      try
        if (lChallenge.LocalName <> 'challenge') or
          (lChallenge.NamespaceURI <> 'urn:ietf:params:xml:ns:xmpp-sasl') then
          raise ENXXMPPError.Create(xesAuthentication,
            'unexpected-sasl-response',
            'Expected a SCRAM challenge from the server.');
        lClientMessage := lSCRAM.Continue(
          DecodeBase64(AnsiString(lChallenge.TextContent)), FConfig.Password);
      finally
        lChallenge.Free;
      end;
      FTransport.Send('<response xmlns=''urn:ietf:params:xml:ns:xmpp-sasl''>' +
        EncodeBase64(lClientMessage) + '</response>');
      lFinal := ReadElement;
      try
        if (lFinal.LocalName <> 'success') or
          (lFinal.NamespaceURI <> 'urn:ietf:params:xml:ns:xmpp-sasl') then
          raise ENXXMPPError.Create(xesAuthentication,
            'authentication-failed', 'SCRAM authentication failed.');
        lSCRAM.VerifyServerFinal(
          DecodeBase64(AnsiString(lFinal.TextContent)));
      finally
        lFinal.Free;
      end;
    finally
      lSCRAM.Free;
    end;
  end
  else if lAuthentication = xamPlain then
  begin
    lPlain := #0 + RawByteString(FJID.LocalPart) + #0 +
      RawByteString(FConfig.Password);
    FTransport.Send('<auth xmlns=''urn:ietf:params:xml:ns:xmpp-sasl'' ' +
      'mechanism=''PLAIN''>' + EncodeBase64(lPlain) + '</auth>');
    lFinal := ReadElement;
    try
      if (lFinal.LocalName <> 'success') or
        (lFinal.NamespaceURI <> 'urn:ietf:params:xml:ns:xmpp-sasl') then
        raise ENXXMPPError.Create(xesAuthentication, 'authentication-failed',
          'PLAIN authentication failed.');
    finally
      lFinal.Free;
    end;
    FillChar(Pointer(lPlain)^, Length(lPlain), 0);
  end
  else
    raise ENXXMPPError.Create(xesAuthentication, 'no-supported-mechanism',
      'The server did not offer an allowed SASL mechanism.');
end;

procedure TNXXMPPConnection.PerformBinding(AFeatures: TNXXMPPStanza);
var
  lBindXML: RawByteString;
  lResult: TNXXMPPStanza;
begin
  if not TNXXMPPNegotiation.OffersBinding(AFeatures.RawXML) then
    raise ENXXMPPError.Create(xesBinding, 'binding-unavailable',
      'The server did not offer resource binding.');
  Transition(xcsBinding);
  lBindXML := '<iq type=''set'' id=''nx-bind''><bind ' +
    'xmlns=''urn:ietf:params:xml:ns:xmpp-bind''>';
  if FConfig.Resource <> '' then
    lBindXML := lBindXML + '<resource>' +
      RawByteString(NXXMPPEscapeText(FConfig.Resource)) + '</resource>';
  lBindXML := lBindXML + '</bind></iq>';
  FTransport.Send(lBindXML);
  repeat
    lResult := ReadElement;
    if (lResult.Kind = xskIQ) and (lResult.ID = 'nx-bind') then
      Break;
    lResult.Free;
  until False;
  try
    if lResult.IQType <> xitResult then
      raise ENXXMPPError.Create(xesBinding, 'binding-failed',
        'The server rejected resource binding.');
  finally
    lResult.Free;
  end;
end;

function TNXXMPPConnection.OpenSecuredStream(
  const AEndpoint: TNXXMPPEndpoint): TNXXMPPStanza;
var
  lProceed: TNXXMPPStanza;
begin
  Result := nil;
  ResetStream;
  SendOpen;
  Result := ReadElement;
  try
    if Result.LocalName <> 'features' then
      raise ENXXMPPError.Create(xesStream, 'missing-stream-features',
        'The server did not provide stream features.');
    if AEndpoint.Security = xtsStartTLS then
    begin
      if not TNXXMPPNegotiation.OffersStartTLS(Result.RawXML) then
        raise ENXXMPPError.Create(xesTLS, 'starttls-unavailable',
          'The server did not offer STARTTLS.');
      FTransport.Send('<starttls xmlns=' +
        '''urn:ietf:params:xml:ns:xmpp-tls''/>');
      lProceed := ReadElement;
      try
        if (lProceed.LocalName <> 'proceed') or
          (lProceed.NamespaceURI <> 'urn:ietf:params:xml:ns:xmpp-tls') then
          raise ENXXMPPError.Create(xesTLS, 'starttls-rejected',
            'The server rejected STARTTLS.');
      finally
        lProceed.Free;
      end;
      Transition(xcsSecuring);
      FTransport.Secure(FJID.DomainPart, FConfig.CAFile);
      FreeAndNil(Result);
      ResetStream;
      SendOpen;
      Result := ReadElement;
      if Result.LocalName <> 'features' then
        raise ENXXMPPError.Create(xesStream, 'missing-stream-features',
          'The secured stream did not provide features.');
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TNXXMPPConnection.PerformNegotiation(
  const AEndpoint: TNXXMPPEndpoint);
var
  lFeatures: TNXXMPPStanza;
  lMaximum: QWord;
  lMaximumText: UTF8String;
  lProceed: TNXXMPPStanza;
  lResumeAllowed: Boolean;
begin
  lFeatures := OpenSecuredStream(AEndpoint);
  try
    PerformAuthentication(lFeatures);
  finally
    lFeatures.Free;
  end;
  ResetStream;
  SendOpen;
  lFeatures := ReadElement;
  try
    if lFeatures.LocalName <> 'features' then
      raise ENXXMPPError.Create(xesStream, 'missing-stream-features',
        'The authenticated stream did not provide features.');
    PerformBinding(lFeatures);
    if TNXXMPPNegotiation.OffersStreamManagement(lFeatures.RawXML) then
    begin
      if FStreamManagement.ReplayCount > 0 then
        RejectResumption('A new stream replaced the prior managed stream.')
      else
        FStreamManagement.Reset;
      FTransport.Send('<enable xmlns=''urn:xmpp:sm:3'' resume=''true''/>');
      lProceed := ReadElement;
      try
        if (lProceed.LocalName = 'enabled') and
          (lProceed.NamespaceURI = 'urn:xmpp:sm:3') then
        begin
          lResumeAllowed := (lProceed.Attribute('resume') = 'true') or
            (lProceed.Attribute('resume') = '1');
          if lResumeAllowed and (lProceed.Attribute('id') = '') then
            raise ENXXMPPError.Create(xesProtocol, 'missing-sm-resume-id',
              'The resumable stream has no session identifier.');
          lMaximumText := lProceed.Attribute('max');
          lMaximum := 0;
          if (lMaximumText <> '') and
            (not TryStrToQWord(string(lMaximumText), lMaximum) or
            (lMaximum = 0) or (lMaximum > High(Cardinal))) then
            raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-maximum',
              'The stream-management resumption maximum is invalid.');
          FStreamManagement.Enable(lProceed.Attribute('id'), lResumeAllowed,
            lMaximumText <> '', Cardinal(lMaximum));
        end;
      finally
        lProceed.Free;
      end;
    end;
  finally
    lFeatures.Free;
  end;
end;

function TNXXMPPConnection.TryResume(
  const AEndpoint: TNXXMPPEndpoint): Boolean;
var
  lFeatures: TNXXMPPStanza;
  lIndex: Integer;
  lResponse: TNXXMPPStanza;
begin
  Result := False;
  if not FStreamManagement.CanResume(GetTickCount64) then
  begin
    RejectResumption(
      'The prior managed stream is no longer eligible for resumption.');
    Exit;
  end;
  lFeatures := OpenSecuredStream(AEndpoint);
  try
    if not TNXXMPPNegotiation.OffersStreamManagement(lFeatures.RawXML) then
    begin
      RejectResumption(
        'The replacement stream does not offer stream management.');
      Exit;
    end;
  finally
    lFeatures.Free;
  end;
  Transition(xcsResuming);
  FTransport.Send(RawByteString(FStreamManagement.ResumeRequestXML));
  lResponse := ReadElement;
  try
    try
      if not FStreamManagement.ProcessResumeResponse(lResponse) then
      begin
        RejectResumption('The server rejected stream resumption.');
        Exit;
      end;
    except
      on ENXXMPPError do
      begin
        RejectResumption(
          'The server returned an invalid stream resumption response.');
        raise;
      end;
    end;
    for lIndex := 0 to FStreamManagement.ReplayCount - 1 do
      FTransport.Send(RawByteString(FStreamManagement.ReplayXML(lIndex)));
    Result := True;
  finally
    lResponse.Free;
  end;
end;

function TNXXMPPConnection.RecoverConnection: Boolean;
var
  lAttempt: Integer;
  lEndpoint: TNXXMPPEndpoint;
  lResumed: Boolean;
  lWaited: Cardinal;
begin
  Result := False;
  for lAttempt := 1 to FConfig.ReconnectAttempts do
  begin
    lWaited := 0;
    while (lWaited < FConfig.ReconnectDelayMS) and
      not IsDisconnectRequested do
    begin
      Sleep(50);
      Inc(lWaited, 50);
    end;
    if IsDisconnectRequested then
      Exit;
    try
      FTransport.Close;
      lEndpoint := ConnectEndpoint;
      lResumed := TryResume(lEndpoint);
      if not lResumed then
      begin
        FTransport.Close;
        lEndpoint := ConnectEndpoint;
        PerformNegotiation(lEndpoint);
        NotifyModules(xmlNewSession);
      end;
      if lResumed then
        NotifyModules(xmlStreamResumed);
      Transition(xcsOnline);
      Exit(True);
    except
      on ENXXMPPError do
      begin
        FTransport.Close;
        if State <> xcsResuming then
          Transition(xcsResuming);
      end;
    end;
  end;
end;

procedure TNXXMPPConnection.SendUnhandledIQError(AStanza: TNXXMPPStanza);
var
  lTo: RawByteString;
begin
  lTo := '';
  if AStanza.FromJID <> '' then
    lTo := ' to=''' + RawByteString(NXXMPPEscapeAttribute(AStanza.FromJID)) +
      '''';
  SendStanza('<iq type=''error'' id=''' +
    RawByteString(NXXMPPEscapeAttribute(AStanza.ID)) + '''' + lTo +
    '>' + RawByteString(AStanza.ChildXML) +
    '<error type=''cancel''><service-unavailable ' +
    'xmlns=''urn:ietf:params:xml:ns:xmpp-stanzas''/></error></iq>', False);
end;

procedure TNXXMPPConnection.HandleIncoming(AStanza: TNXXMPPStanza);
var
  lCompletion: TNXXMPPIQCompletionEvent;
  lHandled: QWord;
begin
  if (AStanza.NamespaceURI = 'urn:xmpp:sm:3') and
    (AStanza.LocalName = 'r') then
  begin
    FTransport.Send(RawByteString(FStreamManagement.AcknowledgementXML));
    AStanza.Free;
    Exit;
  end;
  if (AStanza.NamespaceURI = 'urn:xmpp:sm:3') and
    (AStanza.LocalName = 'a') then
  begin
    if not TryStrToQWord(string(AStanza.Attribute('h')), lHandled) or
      (lHandled > High(Cardinal)) then
      raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-acknowledgement',
        'The stream-management acknowledgement counter is invalid.');
    FStreamManagement.Acknowledge(Cardinal(lHandled));
    AStanza.Free;
    Exit;
  end;
  lCompletion := FRequests.Complete(AStanza);
  if Assigned(lCompletion) then
  begin
    try
      DoOnCompletion(lCompletion);
      FStreamManagement.IncomingHandled;
    finally
      lCompletion.Free;
    end;
    Exit;
  end;
  if (AStanza.Kind = xskIQ) and (AStanza.IQType in [xitGet, xitSet]) and
    not FDispatcher.DispatchStanza(AStanza) then
    SendUnhandledIQError(AStanza)
  else if not ((AStanza.Kind = xskIQ) and
    (AStanza.IQType in [xitGet, xitSet])) then
    FDispatcher.DispatchStanza(AStanza);
  DoOnStanza(AStanza);
  AStanza.Free;
  FStreamManagement.IncomingHandled;
end;

procedure TNXXMPPConnection.ProcessCommands;
var
  lCommand: TNXXMPPCommand;
  lID: UTF8String;
  lXML: UTF8String;
begin
  repeat
    lCommand := TNXXMPPCommand(FCommands.Dequeue);
    if not Assigned(lCommand) then
      Exit;
    try
      case lCommand.Kind of
        xckRawXML:
          SendStanza(lCommand.XML,
            lCommand.ReplayPolicy = xrpStreamManaged);
        xckIQ:
          begin
            try
              lID := FRequests.BeginRequest(lCommand.ExpectedFrom,
                lCommand.TimeoutMS, lCommand.Handler);
            except
              FIQCapacity.Release;
              raise;
            end;
            lXML := '<iq type=''' +
              UTF8String(NXXMPPIQTypeName(lCommand.IQType)) + ''' id=''' +
              NXXMPPEscapeAttribute(lID) + '''';
            if lCommand.ToJID <> '' then
              lXML := lXML + ' to=''' +
                NXXMPPEscapeAttribute(lCommand.ToJID) + '''';
            lXML := lXML + '>' + lCommand.Payload + '</iq>';
            SendStanza(lXML, False);
          end;
        xckModule:
          begin
            if not Assigned(FModules) or
              (FModules.IndexOf(lCommand.Module) < 0) then
              raise ENXXMPPError.Create(xesProtocol,
                'unregistered-module-command',
                'A module command targeted an unregistered module.');
            TNXXMPPModule(lCommand.Module).ProcessCommand(
              lCommand.ModuleOperation);
          end;
        xckDisconnect:
          RequestDisconnect;
      end;
    finally
      lCommand.Free;
    end;
  until False;
end;

procedure TNXXMPPConnection.CompleteEvents(AEvents: TObjectList);
var
  lCompletion: TNXXMPPIQCompletionEvent;
begin
  while AEvents.Count > 0 do
  begin
    lCompletion := TNXXMPPIQCompletionEvent(AEvents.Extract(AEvents[0]));
    try
      DoOnCompletion(lCompletion);
    finally
      lCompletion.Free;
    end;
  end;
end;

procedure TNXXMPPConnection.OnlineLoop;
var
  lCompletions: TObjectList;
  lData: RawByteString;
  lFrame: UTF8String;
  lStanza: TNXXMPPStanza;
begin
  lCompletions := TObjectList.Create(True);
  try
    while not IsDisconnectRequested do
    begin
      ProcessCommands;
      lData := FTransport.Receive(100);
      if lData <> '' then
        FFramer.Feed(lData, FFrames);
      while FFrames.Count > 0 do
      begin
        lFrame := UTF8String(FFrames[0]);
        FFrames.Delete(0);
        if Copy(lFrame, 1, 15) = '</stream:stream' then
          raise ENXXMPPError.Create(xesStream, 'stream-closed',
            'The server closed the XMPP stream.', True);
        if Copy(lFrame, 1, 14) = '<stream:stream' then
          Continue;
        lStanza := TNXXMPPStanza.Create(lFrame,
          FFramer.StreamNamespaceAttributes);
        try
          HandleIncoming(lStanza);
          lStanza := nil;
        finally
          lStanza.Free;
        end;
      end;
      FRequests.CollectTimeouts(GetTickCount64, lCompletions);
      CompleteEvents(lCompletions);
    end;
  finally
    lCompletions.Free;
  end;
end;

procedure TNXXMPPConnection.Execute;
var
  lCompletions: TObjectList;
  lEndpoint: TNXXMPPEndpoint;
begin
  lCompletions := TObjectList.Create(True);
  try
    try
      FJID := TNXXMPPJID.Create(FConfig.JID);
      lEndpoint := ConnectEndpoint;
      PerformNegotiation(lEndpoint);
      NotifyModules(xmlNewSession);
      Transition(xcsOnline);
      while not IsDisconnectRequested do
      begin
        try
          OnlineLoop;
          Break;
        except
          on E: ENXXMPPError do
          begin
            if IsDisconnectRequested then
              Break;
            FStreamManagement.MarkDisconnected(GetTickCount64);
            NotifyModules(xmlTemporaryLoss);
            FRequests.CancelAll('The IQ request was interrupted by a ' +
              'connection loss.', lCompletions);
            CompleteEvents(lCompletions);
            Transition(xcsResuming);
            if not RecoverConnection and not IsDisconnectRequested then
              raise;
          end;
        end;
      end;
      Transition(xcsClosing);
      try
        FTransport.Send('</stream:stream>');
      except
        on Exception do ;
      end;
    except
      on E: ENXXMPPError do
      begin
        if IsDisconnectRequested then
        begin
          if State <> xcsClosing then
            Transition(xcsClosing);
          Exit;
        end;
        FCriticalSection.Acquire;
        try
          FState := xcsFailed;
        finally
          FCriticalSection.Release;
        end;
        DoOnState(xcsFailed);
        DoOnError(E.Stage, UTF8String(E.Condition), UTF8String(E.Message));
        NotifyModules(xmlPermanentLoss);
      end;
      on E: Exception do
      begin
        if IsDisconnectRequested then
        begin
          if State <> xcsClosing then
            Transition(xcsClosing);
          Exit;
        end;
        FCriticalSection.Acquire;
        try
          FState := xcsFailed;
        finally
          FCriticalSection.Release;
        end;
        DoOnState(xcsFailed);
        DoOnError(xesProtocol, 'unexpected-failure', UTF8String(E.Message));
        NotifyModules(xmlPermanentLoss);
      end;
    end;
  finally
    FRequests.CancelAll('The XMPP connection closed.', lCompletions);
    try
      CompleteEvents(lCompletions);
    except
      on Exception do ;
    end;
    FTransport.Close;
    NotifyModules(xmlFinalDisconnect);
    if State <> xcsFailed then
      try
        Transition(xcsDisconnected);
      except
        on Exception do ;
      end;
    lCompletions.Free;
  end;
end;

end.

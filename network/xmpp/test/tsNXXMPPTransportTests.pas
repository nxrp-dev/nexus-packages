// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsNXXMPPTransportTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterXMPPTransportTests(ARegistry: TNXTestRegistry; const AFixtureDirectory: string);
implementation
uses
  Classes, SysUtils, SyncObjs, blcksock, synsock, obNXXMPPTransport,
  obNXXMPPError, tpNXXMPPTypes, obNXTestContext, obNXTestSuite;

type
  // This peer's blocking TLS accept must progress independently of the
  // test client's blocking handshake. The caller thread owns the client.
  TXMPPTLSPeer = class(TThread)
  private
    FListener: TTCPBlockSocket;
    FReady: TEvent;
    FProtocols, FSelected: AnsiString;
    FError: string;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AListener: TTCPBlockSocket; const AProtocols: AnsiString);
    destructor Destroy; override;
    function WaitReady: Boolean;
    property Selected: AnsiString read FSelected;
    property Success: Boolean read FSuccess;
    property Error: string read FError;
  end;

var
  lFixtureDirectory: string;

constructor TXMPPTLSPeer.Create(AListener: TTCPBlockSocket;
  const AProtocols: AnsiString);
begin
  inherited Create(True);
  FListener := AListener;
  FProtocols := AProtocols;
  FReady := TEvent.Create(nil, True, False, '');
end;

destructor TXMPPTLSPeer.Destroy;
begin
  if not Finished then WaitFor;
  FReady.Free;
  inherited Destroy;
end;

procedure TXMPPTLSPeer.Execute;
var
  lSocket: TTCPBlockSocket;
begin
  lSocket := TTCPBlockSocket.Create;
  try
    try
      if not FListener.CanRead(2000) then raise Exception.Create('XMPP TLS client did not connect');
      lSocket.Socket := FListener.Accept;
      if lSocket.Socket = INVALID_SOCKET then raise Exception.Create('XMPP TLS accept failed');
      lSocket.ConnectionTimeout := 1000;
      lSocket.SSL.CertificateFile := lFixtureDirectory + 'server.crt';
      lSocket.SSL.PrivateKeyFile := lFixtureDirectory + 'server.key';
      lSocket.SSL.ALPNProtocols := FProtocols;
      FSuccess := lSocket.SSL.Accept;
      FSelected := lSocket.SSL.SelectedALPNProtocol;
      if not FSuccess then FError := lSocket.SSL.LastErrorDesc;
    except
      on lError: Exception do FError := lError.Message;
    end;
  finally
    lSocket.Free;
    FReady.SetEvent;
  end;
end;

function TXMPPTLSPeer.WaitReady: Boolean;
begin
  Result := FReady.WaitFor(3000) = wrSignaled;
end;

procedure CheckTransport(AContext: TNXTestContext; ATransport: TNXXMPPTransport;
  ASecurity: TNXXMPPTransportSecurity; const AServerProtocols, ASelected: AnsiString;
  AExpected: Boolean);
var
  lPeer: TXMPPTLSPeer;
  lListener: TTCPBlockSocket;
  lSucceeded: Boolean;
begin
  lListener := TTCPBlockSocket.Create;
  lPeer := nil;
  try
    lListener.Bind('127.0.0.1', '0');
    AContext.AssertEquals(0, lListener.LastError, 'Could not bind XMPP TLS listener');
    lListener.Listen;
    AContext.AssertEquals(0, lListener.LastError, 'Could not listen for XMPP TLS test');
    lPeer := TXMPPTLSPeer.Create(lListener, AServerProtocols);
    lPeer.Start;
    ATransport.Connect('127.0.0.1', lListener.GetLocalSinPort, 1000);
    lSucceeded := False;
    try
      ATransport.Secure('localhost', lFixtureDirectory + 'ca.crt', ASecurity);
      lSucceeded := True;
    except
      on lError: ENXXMPPError do
      begin
        if AExpected then raise;
        AContext.AssertEquals('tls-failed', lError.Condition);
      end;
    end;
    AContext.AssertTrue(lSucceeded = AExpected, 'Unexpected XMPP ALPN handshake outcome');
    AContext.AssertTrue(lPeer.WaitReady, 'XMPP TLS peer did not complete');
    AContext.AssertTrue(lPeer.Success = AExpected, lPeer.Error);
    if AExpected then
    begin
      AContext.AssertEquals(ASelected, lPeer.Selected, 'Server saw the wrong XMPP protocol offer');
      AContext.AssertEquals(ASelected, ATransport.Socket.SSL.SelectedALPNProtocol);
      if ASecurity = xtsDirectTLS then
        AContext.AssertEquals('xmpp-client', ATransport.Socket.SSL.ALPNProtocols)
      else
        AContext.AssertEquals('', ATransport.Socket.SSL.ALPNProtocols);
    end;
    ATransport.Close;
    AContext.AssertEquals('', ATransport.Socket.SSL.SelectedALPNProtocol, 'Closed XMPP retained ALPN state');
  finally
    ATransport.Close;
    lPeer.Free;
    lListener.Free;
  end;
end;

procedure TestDirectTLSALPN(AContext: TNXTestContext);
var
  lTransport: TNXXMPPTransport;
begin
  lTransport := TNXXMPPTransport.Create;
  try
    CheckTransport(AContext, lTransport, xtsDirectTLS, 'xmpp-client', 'xmpp-client', True);
  finally lTransport.Free; end;
end;

procedure TestDirectTLSWithoutALPN(AContext: TNXTestContext);
var
  lTransport: TNXXMPPTransport;
begin
  lTransport := TNXXMPPTransport.Create;
  try
    CheckTransport(AContext, lTransport, xtsDirectTLS, '', '', True);
  finally lTransport.Free; end;
end;

procedure TestDirectTLSMismatch(AContext: TNXTestContext);
var
  lTransport: TNXXMPPTransport;
begin
  lTransport := TNXXMPPTransport.Create;
  try
    CheckTransport(AContext, lTransport, xtsDirectTLS, 'http/1.1', '', False);
  finally lTransport.Free; end;
end;

procedure TestStartTLSWithoutOffer(AContext: TNXTestContext);
var
  lTransport: TNXXMPPTransport;
begin
  lTransport := TNXXMPPTransport.Create;
  try
    CheckTransport(AContext, lTransport, xtsStartTLS, 'xmpp-client', '', True);
  finally lTransport.Free; end;
end;

procedure TestDirectToStartTLS(AContext: TNXTestContext);
var
  lTransport: TNXXMPPTransport;
begin
  lTransport := TNXXMPPTransport.Create;
  try
    CheckTransport(AContext, lTransport, xtsDirectTLS, 'xmpp-client', 'xmpp-client', True);
    CheckTransport(AContext, lTransport, xtsStartTLS, 'xmpp-client', '', True);
  finally lTransport.Free; end;
end;

procedure RegisterXMPPTransportTests(ARegistry: TNXTestRegistry; const AFixtureDirectory: string);
var
  lSuite: TNXTestSuite;
begin
  lFixtureDirectory := IncludeTrailingPathDelimiter(ExpandFileName(AFixtureDirectory));
  lSuite := ARegistry.AddSuite('XMPPTransport');
  lSuite.AddTest('DirectTLSALPN', @TestDirectTLSALPN);
  lSuite.AddTest('DirectTLSWithoutALPN', @TestDirectTLSWithoutALPN);
  lSuite.AddTest('DirectTLSMismatch', @TestDirectTLSMismatch);
  lSuite.AddTest('StartTLSWithoutOffer', @TestStartTLSWithoutOffer);
  lSuite.AddTest('DirectToStartTLS', @TestDirectToStartTLS);
end;
end.

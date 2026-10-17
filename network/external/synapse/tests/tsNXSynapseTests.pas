// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsNXSynapseTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterSynapseTests(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, blcksock, synsock, Sockets, utNXSynapseResolver,
  obNXTestContext, obNXTestSuite;

procedure TestNumericPort(AContext: TNXTestContext);
var lSocket: TTCPBlockSocket;
begin
  lSocket := TTCPBlockSocket.Create;
  try
    AContext.AssertEquals(443, lSocket.ResolvePort('443'));
    AContext.AssertEquals(0, lSocket.ResolvePort('0'));
  finally lSocket.Free; end;
end;

procedure TestTCPService(AContext: TNXTestContext);
var lSocket: TTCPBlockSocket;
begin
  lSocket := TTCPBlockSocket.Create;
  try
    AContext.AssertEquals(80, lSocket.ResolvePort('http'), 'Named TCP port is not in host byte order');
    AContext.AssertEquals(0, lSocket.ResolvePort('nexus-no-such-service'));
  finally lSocket.Free; end;
end;

procedure TestUDPService(AContext: TNXTestContext);
var lSocket: TUDPBlockSocket;
begin
  lSocket := TUDPBlockSocket.Create;
  try
    AContext.AssertEquals(53, lSocket.ResolvePort('domain'), 'Named UDP port is not in host byte order');
  finally lSocket.Free; end;
end;

procedure TestHostsFile(AContext: TNXTestContext);
var lAddress: TInAddr;
begin
  AContext.AssertTrue(FindHostAddress('localhost', lAddress), 'IPv4 localhost missing from hosts file');
  AContext.AssertEquals('127.0.0.1', HostAddrToStr(lAddress));
end;

procedure CheckResolution(AContext: TNXTestContext; AFamily: TSocketFamily;
  const AName, AAddress: string);
var
  lSocket: TTCPBlockSocket;
  lAddresses: TStringList;
  lActual, lExpected: TIn6Addr;
begin
  lSocket := TTCPBlockSocket.Create;
  lAddresses := TStringList.Create;
  try
    lSocket.Family := AFamily;
    lSocket.ResolveNameToIP(AName, lAddresses);
    AContext.AssertEquals(1, lAddresses.Count);
    if AFamily = SF_IP6 then
    begin
      lActual := StrToNetAddr6(lAddresses[0]);
      lExpected := StrToNetAddr6(AAddress);
      AContext.AssertTrue(CompareMem(@lActual, @lExpected, SizeOf(lActual)),
        'Resolved IPv6 address differs');
    end
    else
      AContext.AssertEquals(AAddress, lAddresses[0]);
  finally
    lAddresses.Free;
    lSocket.Free;
  end;
end;

procedure TestIPv4Literal(AContext: TNXTestContext);
begin CheckResolution(AContext, SF_IP4, '127.0.0.2', '127.0.0.2'); end;
procedure TestIPv6Literal(AContext: TNXTestContext);
begin CheckResolution(AContext, SF_IP6, '::1', '::1'); end;
procedure TestLocalhostIPv4(AContext: TNXTestContext);
begin CheckResolution(AContext, SF_IP4, 'localhost', '127.0.0.1'); end;
procedure TestLocalhostIPv6(AContext: TNXTestContext);
begin CheckResolution(AContext, SF_IP6, 'localhost', '::1'); end;

procedure CheckTCP(AContext: TNXTestContext; AFamily: TSocketFamily; const AAddress: string);
var lListener, lClient, lPeer: TTCPBlockSocket;
begin
  lListener := TTCPBlockSocket.Create;
  lClient := TTCPBlockSocket.Create;
  lPeer := TTCPBlockSocket.Create;
  try
    lListener.Family := AFamily;
    lClient.Family := AFamily;
    lListener.Bind(AAddress, '0');
    AContext.AssertEquals(0, lListener.LastError, 'TCP listener bind failed');
    lListener.Listen;
    AContext.AssertEquals(0, lListener.LastError, 'TCP listen failed: ' + lListener.LastErrorDesc);
    lClient.ConnectionTimeout := 1000;
    lClient.Connect(AAddress, IntToStr(lListener.GetLocalSinPort));
    AContext.AssertEquals(0, lClient.LastError, 'TCP connect failed: ' + lClient.LastErrorDesc + ' port ' + IntToStr(lListener.GetLocalSinPort));
    AContext.AssertTrue(lListener.CanRead(1000), 'TCP accept timed out');
    lPeer.Socket := lListener.Accept;
    AContext.AssertTrue(lPeer.Socket <> INVALID_SOCKET);
    AContext.AssertEquals(lListener.GetLocalSinPort, lClient.GetRemoteSinPort);
    lClient.SendString('Nexus TCP');
    AContext.AssertEquals('Nexus TCP', lPeer.RecvPacket(1000));
    lPeer.SendString('reply');
    AContext.AssertEquals('reply', lClient.RecvPacket(1000));
  finally
    lPeer.Free;
    lClient.Free;
    lListener.Free;
  end;
end;

procedure CheckUDP(AContext: TNXTestContext; AFamily: TSocketFamily; const AAddress: string);
var lReceiver, lSender: TUDPBlockSocket;
begin
  lReceiver := TUDPBlockSocket.Create;
  lSender := TUDPBlockSocket.Create;
  try
    lReceiver.Family := AFamily;
    lSender.Family := AFamily;
    lReceiver.Bind(AAddress, '0');
    AContext.AssertEquals(0, lReceiver.LastError, 'UDP bind failed');
    lSender.Connect(AAddress, IntToStr(lReceiver.GetLocalSinPort));
    AContext.AssertEquals(0, lSender.LastError, 'UDP connect failed');
    lSender.SendString('Nexus UDP');
    AContext.AssertEquals('Nexus UDP', lReceiver.RecvPacket(1000));
  finally
    lSender.Free;
    lReceiver.Free;
  end;
end;
procedure TestTCP4(AContext: TNXTestContext);
begin CheckTCP(AContext, SF_IP4, '127.0.0.1'); end;
procedure TestTCP6(AContext: TNXTestContext);
begin CheckTCP(AContext, SF_IP6, '::1'); end;
procedure TestUDP4(AContext: TNXTestContext);
begin CheckUDP(AContext, SF_IP4, '127.0.0.1'); end;
procedure TestUDP6(AContext: TNXTestContext);
begin CheckUDP(AContext, SF_IP6, '::1'); end;

{$ifdef NX_RESOLVER_LIBC}
procedure TestLibCForward(AContext: TNXTestContext);
var
  lIPv4: array[0..3] of TInAddr;
  lIPv6: array[0..3] of TIn6Addr;
  lLoopback: TIn6Addr;
begin
  AContext.AssertTrue(utNXSynapseResolver.ResolveName('localhost', lIPv4) > 0);
  AContext.AssertEquals('127.0.0.1', NetAddrToStr(lIPv4[0]));
  AContext.AssertTrue(utNXSynapseResolver.ResolveName6('localhost', lIPv6) > 0);
  lLoopback := StrToNetAddr6('::1');
  AContext.AssertTrue(CompareMem(@lIPv6[0], @lLoopback, SizeOf(lLoopback)));
end;

procedure TestLibCReverse(AContext: TNXTestContext);
var lNames: array[0..0] of string;
begin
  AContext.AssertEquals(1, utNXSynapseResolver.ResolveAddress(StrToHostAddr('127.0.0.1'), lNames));
  AContext.AssertTrue(lNames[0] <> '');
  AContext.AssertTrue(Pos(#0, lNames[0]) = 0, 'Resolver returned a padded C buffer');
  AContext.AssertEquals(1, utNXSynapseResolver.ResolveAddress6(StrToNetAddr6('::1'), lNames));
  AContext.AssertTrue(lNames[0] <> '');
end;

procedure TestLibCEmptyOutput(AContext: TNXTestContext);
var
  lIPv4: array of TInAddr;
  lIPv6: array of TIn6Addr;
  lNames: array of string;
begin
  lIPv4 := nil;
  lIPv6 := nil;
  lNames := nil;
  AContext.AssertEquals(-1, utNXSynapseResolver.ResolveName('localhost', lIPv4));
  AContext.AssertEquals(-1, utNXSynapseResolver.ResolveName6('localhost', lIPv6));
  AContext.AssertEquals(-1, utNXSynapseResolver.ResolveAddress(StrToHostAddr('127.0.0.1'), lNames));
end;
{$endif}

procedure RegisterSynapseTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('Synapse');
  lSuite.AddTest('NumericPort', @TestNumericPort);
  lSuite.AddTest('TCPService', @TestTCPService);
  lSuite.AddTest('UDPService', @TestUDPService);
  lSuite.AddTest('HostsFile', @TestHostsFile);
  lSuite.AddTest('IPv4Literal', @TestIPv4Literal);
  lSuite.AddTest('IPv6Literal', @TestIPv6Literal);
  lSuite.AddTest('LocalhostIPv4', @TestLocalhostIPv4);
  lSuite.AddTest('LocalhostIPv6', @TestLocalhostIPv6);
  lSuite.AddTest('TCP4', @TestTCP4);
  lSuite.AddTest('TCP6', @TestTCP6);
  lSuite.AddTest('UDP4', @TestUDP4);
  lSuite.AddTest('UDP6', @TestUDP6);
  {$ifdef NX_RESOLVER_LIBC}
  lSuite.AddTest('LibCForward', @TestLibCForward);
  lSuite.AddTest('LibCReverse', @TestLibCReverse);
  lSuite.AddTest('LibCEmptyOutput', @TestLibCEmptyOutput);
  {$endif}
end;
end.

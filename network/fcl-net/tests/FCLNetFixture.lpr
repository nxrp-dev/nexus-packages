// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLNetFixture;
{$mode objfpc}{$H+}
uses Classes, SysUtils, BaseUnix, Sockets, resolve, sslbase, fpsockets, ssockets, netdb, Nullable;
type
  TTrackedComponent = class(TComponent)
  public
    destructor Destroy; override;
  end;
  TVersionCertificate = class(TX509Certificate)
  public
    function CreateCertificateAndKey: TCertAndKey; override;
  end;
var
  lDestroyed: Integer;

destructor TTrackedComponent.Destroy;
begin
  Inc(lDestroyed);
  inherited Destroy;
end;

function TVersionCertificate.CreateCertificateAndKey: TCertAndKey;
begin
  Result := Default(TCertAndKey);
end;

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure ResolverOwnership;
var
  lOwner: TComponent;
  lResolver: TResolver;
begin
  lOwner := TComponent.Create(nil);
  lResolver := TResolver.Create(lOwner);
  TTrackedComponent.Create(lResolver);
  lResolver.Free;
  // On a broken baseline, exit this child before destroying the dangling owner.
  Require(lOwner.ComponentCount = 0, 'Resolver remains in owner component list');
  Require(lDestroyed = 1, 'Resolver did not destroy its owned component');
  lOwner.Free;
end;

procedure UnixAddress(ADecode: Boolean);
var
  lAddress: TAddressUnion;
  lPath: string;
  lEndpoint: TEndPoint;
begin
  lPath := '/tmp/nexus-fcl-net.sock';
  if ADecode then
  begin
    lAddress := Default(TAddressUnion);
    lAddress.SocketType := stUnixSocket;
    lAddress.UnixAddr.sun_family := AF_UNIX;
    Move(lPath[1], lAddress.UnixAddr.sun_path, Length(lPath));
    fpsockets.ReadAddr(lAddress, False, lEndpoint.First, lEndpoint.Second);
    Require(lEndpoint.First.AddressType = atUnixSock, 'Unix endpoint has wrong type');
    Require(lEndpoint.First.Address = lPath, 'Unix endpoint has wrong path');
    Require(lEndpoint.Second = 0, 'Unix endpoint has a port');
  end
  else
  begin
    lAddress := fpsockets.CreateAddr(fpsockets.UnixAddr(lPath), 0, False);
    Require(lAddress.UnixAddr.sun_family = AF_UNIX, 'Unix address family was cleared');
  end;
end;

procedure SelectReady(ATimeout: Integer; ADescriptorZero: Boolean);
var
  lPair: TSockArray;
  lStream: TSocketStream;
  lRead, lWrite, lExcept: TSocketStreamArray;
  lOriginalInput: Integer;
begin
  Require(fpSocketPair(AF_UNIX, SOCK_STREAM, 0, @lPair[0]) = 0, 'socketpair failed');
  lOriginalInput := -1;
  if ADescriptorZero then
  begin
    lOriginalInput := fpDup(0);
    Require(lOriginalInput >= 0, 'Could not preserve stdin');
    Require(fpDup2(lPair[0], 0) = 0, 'Could not place socket at descriptor zero');
    fpClose(lPair[0]);
    lPair[0] := 0;
  end;
  lStream := TSocketStream.Create(lPair[0]);
  try
    lRead := nil;
    lWrite := [lStream];
    lExcept := nil;
    Require(TSocketStream.Select(lRead, lWrite, lExcept, ATimeout), 'Ready socket was not selected');
    Require(Length(lRead) = 0, 'Invented read readiness');
    Require((Length(lWrite) = 1) and (lWrite[0] = lStream), 'Lost write readiness');
    Require(Length(lExcept) = 0, 'Invented exception readiness');
  finally
    lStream.Free;
    fpClose(lPair[1]);
    if lOriginalInput >= 0 then
    begin
      fpDup2(lOriginalInput, 0);
      fpClose(lOriginalInput);
    end;
  end;
end;

procedure CertificateVersion;
var
  lCertificate: TVersionCertificate;
begin
  lCertificate := TVersionCertificate.Create;
  try
    Require(lCertificate.Version = 1, 'First default version is not one');
    Require(lCertificate.Version = 1, 'Repeated version read changed');
    lCertificate.Version := 3;
    Require(lCertificate.Version = 3, 'Explicit version was not preserved');
  finally
    lCertificate.Free;
  end;
end;

procedure DNSText(ATCP, AEmpty: Boolean);
var
  lUDP: TPayLoad;
  lTCP: TPayLoadTCP;
  lRecord: TRRNameData;
  lText: AnsiString;
  lResult: Boolean;
begin
  lUDP := Default(TPayLoad);
  lTCP := Default(TPayLoadTCP);
  lRecord := Default(TRRNameData);
  lRecord.RRMeta.Atype := DNSQRY_TXT;
  lRecord.RDataSt := 16;
  lRecord.RRMeta.RDLength := 1;
  if not AEmpty then
  begin
    lUDP[16] := 2;
    lUDP[17] := Ord('a');
    lUDP[18] := Ord('b');
    lTCP[16] := 2;
    lTCP[17] := Ord('a');
    lTCP[18] := Ord('b');
  end;
  if ATCP then lResult := DNSRRGetText(lRecord, lTCP, lText)
  else lResult := DNSRRGetText(lRecord, lUDP, lText);
  if AEmpty then
  begin
    Require(lResult, 'Valid empty TXT string rejected');
    Require(lText = '', 'Empty TXT decoded as nonempty');
  end
  else
    Require(not lResult, 'TXT string crossed its declared RDATA boundary');
end;

procedure DNSTextSegments(ATCP: Boolean);
var
  lUDP: TPayLoad;
  lTCP: TPayLoadTCP;
  lRecord: TRRNameData;
  lText: AnsiString;
  lResult: Boolean;
begin
  lUDP := Default(TPayLoad);
  lTCP := Default(TPayLoadTCP);
  lRecord := Default(TRRNameData);
  lRecord.RRMeta.Atype := DNSQRY_TXT;
  lRecord.RDataSt := 16;
  lRecord.RRMeta.RDLength := 8;
  // Empty strings may appear before, between and after nonempty strings.
  lUDP[17] := 2;
  lUDP[18] := Ord('a');
  lUDP[19] := Ord('b');
  lUDP[21] := 1;
  lUDP[22] := Ord('c');
  Move(lUDP, lTCP, SizeOf(lUDP));
  if ATCP then lResult := DNSRRGetText(lRecord, lTCP, lText)
  else lResult := DNSRRGetText(lRecord, lUDP, lText);
  Require(lResult, 'Valid segmented TXT record rejected');
  Require(lText = 'abc', 'Segmented TXT record decoded incorrectly');
end;

function BoundPort(const ASocket: TFPSocket): Word;
var
  lAddress: TInetSockAddr;
  lLength: TSockLen;
begin
  lLength := SizeOf(lAddress);
  Require(fpGetSockName(ASocket.FD, @lAddress, @lLength) = 0, 'Could not read bound port');
  Result := NToHs(lAddress.sin_port);
end;

procedure UDPLoopback;
var
  lServer, lClient: TFPSocket;
  lMessage: TReceiveFromStringMessage;
begin
  lServer := fpsockets.UDPSocket(stIPv4);
  lClient := fpsockets.UDPSocket(stIPv4);
  try
    fpsockets.Bind(lServer, IN4Address('127.0.0.1'), 0);
    Require(fpsockets.SendStrTo(lClient, IN4Address('127.0.0.1'), BoundPort(lServer), 'abc') = 3,
      'UDP send did not send its payload');
    Require(fpsockets.DataAvailable(lServer, 1000), 'UDP payload did not arrive');
    lMessage := fpsockets.ReceiveStrFrom(lServer, 16);
    Require(lMessage.Data = 'abc', 'UDP payload changed');
    Require(lMessage.FromAddr.Address = '127.0.0.1', 'UDP source address was corrupted');
  finally
    fpsockets.CloseSocket(lClient);
    fpsockets.CloseSocket(lServer);
  end;
end;

procedure TCPLoopback(ANonBlocking: Boolean);
var
  lServer, lClient: TFPSocket;
  lAccepted: TFPSocketConnection;
  lOptional: specialize TNullable<TFPSocketConnection>;
  lEndpoint: TEndPoint;
begin
  lServer := fpsockets.TCPSocket(stIPv4);
  lClient := fpsockets.TCPSocket(stIPv4);
  lAccepted.Socket.FD := -1;
  try
    fpsockets.Bind(lServer, IN4Address('127.0.0.1'), 0);
    fpsockets.Listen(lServer, 1);
    Require(fpsockets.Connect(lClient, IN4Address('127.0.0.1'), BoundPort(lServer)) = csConnected,
      'TCP client did not connect');
    if ANonBlocking then
    begin
      fpsockets.SetNonBlocking(lServer, True);
      lOptional := fpsockets.AcceptNonBlocking(lServer);
      Require(lOptional.HasValue, 'Queued TCP connection was not accepted');
      lAccepted := lOptional.Value;
    end
    else lAccepted := fpsockets.AcceptConnection(lServer);
    Require(lAccepted.ClientAddress.Address = '127.0.0.1', 'TCP peer address was corrupted');
    lEndpoint := fpsockets.LocalEndpoint(lAccepted.Socket);
    Require(lEndpoint.Second = BoundPort(lServer), 'Local TCP endpoint was corrupted');
    lEndpoint := fpsockets.RemoteEndpoint(lClient);
    Require(lEndpoint.Second = BoundPort(lServer), 'Remote TCP endpoint was corrupted');
  finally
    if not fpsockets.SocketInvalid(lAccepted.Socket.FD) then fpsockets.CloseSocket(lAccepted.Socket);
    fpsockets.CloseSocket(lClient);
    fpsockets.CloseSocket(lServer);
  end;
end;

procedure DualStackAddressSize;
var
  lAddress: TAddressUnion;
begin
  lAddress := Default(TAddressUnion);
  lAddress.SocketType := stIPDualStack;
  Require(lAddress.GetAddrSize = SizeOf(sockaddr_in6), 'Dual-stack address buffer uses IPv4 size');
end;

begin
  try
    case ParamStr(1) of
      'resolver-ownership': ResolverOwnership;
      'unix-address': UnixAddress(False);
      'unix-endpoint': UnixAddress(True);
      'select-write': SelectReady(0, False);
      'select-infinite': SelectReady(-1, False);
      'select-zero': SelectReady(0, True);
      'certificate-version': CertificateVersion;
      'txt-empty-udp': DNSText(False, True);
      'txt-empty-tcp': DNSText(True, True);
      'txt-boundary-udp': DNSText(False, False);
      'txt-boundary-tcp': DNSText(True, False);
      'txt-segments-udp': DNSTextSegments(False);
      'txt-segments-tcp': DNSTextSegments(True);
      'udp-loopback': UDPLoopback;
      'tcp-loopback': TCPLoopback(False);
      'tcp-nonblocking': TCPLoopback(True);
      'dual-stack-size': DualStackAddressSize;
    else
      raise Exception.Create('Unknown regression case');
    end;
    WriteLn('PASS');
  except
    on lError: Exception do
    begin
      WriteLn(lError.ClassName, ': ', lError.Message);
      Halt(1);
    end;
  end;
end.

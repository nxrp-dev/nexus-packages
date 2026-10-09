unit tsNXOpenSSLTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure ConfigureOpenSSLTests(const AFixtureDirectory, ARuntimeDirectory: string);
procedure RegisterNXOpenSSLTests(ARegistry: TNXTestRegistry);

implementation

uses Classes, SysUtils, ctypes, Dynlibs, openssl, fpopenssl, opensslsockets,
  sslbase, sockets, ssockets, obNXTestContext, obNXTestSuite;

type
  TTestBIOPair = function(var ABIO: PBIO; ASize: csize_t;
    var APeer: PBIO; APeerSize: csize_t): cint; cdecl;
  TTestSSLSetBIO = procedure(ASSL: PSSL; ARead, AWrite: PBIO); cdecl;
  TTestX509SignatureNID = function(ACertificate: PX509): cint; cdecl;
  TTestX509Version = function(ACertificate: PX509): clong; cdecl;
  TTestX509CheckHost = function(ACertificate: PX509; AHost: PAnsiChar;
    ALength: csize_t; AFlags: cuint; APeerName: PPAnsiChar): cint; cdecl;
  TTestX509CheckIP = function(ACertificate: PX509; AIP: PAnsiChar;
    AFlags: cuint): cint; cdecl;
  TTestHandler = class(TOpenSSLSocketHandler)
  public
    procedure Prepare;
  end;
  TTestServer = class(TInetServer)
  public
    function TakeSocket: Integer;
  end;

var
  lFixtureDirectory: string;
  lSSLHandle, lCryptoHandle: TLibHandle;
  lBIOPair: TTestBIOPair;
  lSSLSetBIO: TTestSSLSetBIO;
  lX509SignatureNID: TTestX509SignatureNID;
  lX509Version: TTestX509Version;
  lX509CheckHost: TTestX509CheckHost;
  lX509CheckIP: TTestX509CheckIP;

function Fixture(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(lFixtureDirectory) + AName;
end;

function ReadBytes(const AFileName: string): TBytes;
var
  lStream: TFileStream;
begin
  Result := nil;
  lStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    SetLength(Result, lStream.Size);
    if Length(Result) <> 0 then lStream.ReadBuffer(Result[0], Length(Result));
  finally
    lStream.Free;
  end;
end;

procedure RequireNative(AResult: Boolean; const AMessage: string);
begin
  if not AResult then raise Exception.Create(AMessage);
end;

procedure TTestHandler.Prepare;
begin
  RequireNative(InitContext(False), 'Could not prepare TLS handler');
end;

function TTestServer.TakeSocket: Integer;
begin
  Result := fpAccept(FPSocket.FD, nil, nil);
  RequireNative(Result >= 0, 'Could not accept test loopback connection');
end;

procedure ConfigureOpenSSLTests(const AFixtureDirectory, ARuntimeDirectory: string);
var
  lSSLName, lCryptoName: string;
begin
  lFixtureDirectory := ExpandFileName(AFixtureDirectory);
  {$IFDEF WINDOWS}
  lSSLName := 'libssl-3-x64.dll';
  lCryptoName := 'libcrypto-3-x64.dll';
  {$ELSE}
  lSSLName := 'libssl.so.3';
  lCryptoName := 'libcrypto.so.3';
  {$ENDIF}
  if ARuntimeDirectory <> '' then
  begin
    lSSLName := IncludeTrailingPathDelimiter(ARuntimeDirectory) + lSSLName;
    lCryptoName := IncludeTrailingPathDelimiter(ARuntimeDirectory) + lCryptoName;
  end;
  RequireNative(InitSSLInterface(lSSLName, lCryptoName), 'OpenSSL 3 runtime unavailable');
  lSSLHandle := LoadLibrary(lSSLName);
  lCryptoHandle := LoadLibrary(lCryptoName);
  Pointer(lBIOPair) := GetProcedureAddress(lCryptoHandle, 'BIO_new_bio_pair');
  Pointer(lSSLSetBIO) := GetProcedureAddress(lSSLHandle, 'SSL_set_bio');
  Pointer(lX509SignatureNID) := GetProcedureAddress(lCryptoHandle, 'X509_get_signature_nid');
  Pointer(lX509Version) := GetProcedureAddress(lCryptoHandle, 'X509_get_version');
  Pointer(lX509CheckHost) := GetProcedureAddress(lCryptoHandle, 'X509_check_host');
  Pointer(lX509CheckIP) := GetProcedureAddress(lCryptoHandle, 'X509_check_ip_asc');
  RequireNative(Assigned(lBIOPair) and Assigned(lSSLSetBIO) and
    Assigned(lX509SignatureNID) and Assigned(lX509Version) and
    Assigned(lX509CheckHost) and Assigned(lX509CheckIP), 'Required test APIs unavailable');
  WriteLn('Runtime: ', OpenSSLGetVersion(0));
end;

function ServerContext(const APrefix: string): TSSLContext;
var
  lData: TSSLData;
begin
  Result := TSSLContext.Create(stAny);
  lData := TSSLData.Create;
  try
    RequireNative(Result.UseCertificateChainFile(PAnsiChar(Fixture(APrefix + '-chain.pem'))) = 1,
      'Could not load server certificate chain');
    lData.FileName := Fixture(APrefix + '.key');
    RequireNative(Result.UsePrivateKey(lData) = 1, 'Could not load server EC key');
  finally
    lData.Free;
  end;
end;

function ClientContext(AVerify: Boolean): TSSLContext;
begin
  Result := TSSLContext.Create(stAny);
  if AVerify then
  begin
    Result.SetVerify(SSL_VERIFY_PEER, nil);
    RequireNative(Result.LoadVerifyLocations(Fixture('root.pem'), '') = 1,
      'Could not load test root');
  end;
end;

procedure AttachMemoryPair(AClient, AServer: TSSL);
var
  lClientBIO, lServerBIO: PBIO;
begin
  lClientBIO := nil;
  lServerBIO := nil;
  RequireNative(lBIOPair(lClientBIO, 0, lServerBIO, 0) = 1, 'Could not create BIO pair');
  lSSLSetBIO(AClient.SSL, lClientBIO, lClientBIO);
  lSSLSetBIO(AServer.SSL, lServerBIO, lServerBIO);
end;

function Handshake(AClient, AServer: TSSL): Boolean;
var
  lClientDone, lServerDone: Boolean;
  lIteration, lReturn, lError: Integer;
begin
  lClientDone := False;
  lServerDone := False;
  for lIteration := 1 to 1000 do
  begin
    if not lClientDone then
    begin
      ErrClearError;
      lReturn := AClient.Connect;
      lError := AClient.GetError(lReturn);
      lClientDone := lReturn = 1;
      if not lClientDone and not (lError in [SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE]) then Exit(False);
    end;
    if not lServerDone then
    begin
      ErrClearError;
      lReturn := AServer.Accept;
      lError := AServer.GetError(lReturn);
      lServerDone := lReturn = 1;
      if not lServerDone and not (lError in [SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE]) then Exit(False);
    end;
    if lClientDone and lServerDone then Exit(True);
  end;
  raise Exception.Create('Memory TLS handshake did not converge');
end;

procedure TestECKeysAndModernSymbols(AContext: TNXTestContext);
var
  lContext: TSSLContext;
  lData: TSSLData;
  lKey: PEVP_PKEY;
  lBytes: PByte;
begin
  lContext := ServerContext('first');
  lData := TSSLData.Create;
  try
    lData.Value := ReadBytes(Fixture('first.der'));
    AContext.AssertEquals(1, lContext.UsePrivateKey(lData), 'DER EC private key rejected');
    AContext.AssertEquals(1, SslCtxCheckPrivateKeyFile(lContext.CTX), 'Certificate/key mismatch');
    lBytes := @lData.Value[0];
    lKey := d2i_AutoPrivateKey(nil, @lBytes, Length(lData.Value));
    try
      AContext.AssertTrue(EVP_PKEY_size(lKey) > 0, 'OpenSSL 3 key size symbol did not resolve');
    finally
      EvpPkeyFree(lKey);
    end;
  finally
    lData.Free;
    lContext.Free;
  end;
end;

procedure TestPFXChain(AContext: TNXTestContext);
var
  lContext: TSSLContext;
  lChain: Pointer;
  lBytes: TBytes;
  lIteration: Integer;
begin
  lContext := TSSLContext.Create(stAny);
  try
    lBytes := ReadBytes(Fixture('first.pfx'));
    for lIteration := 1 to 25 do
      AContext.AssertEquals(1, lContext.LoadPFX(lBytes, 'nexus-test'), 'PFX import failed');
    lChain := nil;
    AContext.AssertEquals(1, SslCtxCtrl(lContext.CTX, 115, 0, @lChain), 'Could not retrieve configured chain');
    AContext.AssertEquals(1, OpenSSLStackNum(lChain), 'PFX intermediate was lost or duplicated');
    AContext.AssertTrue(lContext.LoadPFX(lBytes, 'wrong-password') <> 1, 'Wrong PFX password accepted');
  finally
    lContext.Free;
  end;
end;

procedure TestPFXVerifiedHandshake(AContext: TNXTestContext);
var
  lClientContext, lServerContext: TSSLContext;
  lClient, lServer: TSSL;
begin
  lClientContext := ClientContext(True);
  lServerContext := TSSLContext.Create(stAny);
  lClient := nil;
  lServer := nil;
  try
    AContext.AssertEquals(1, lServerContext.LoadPFX(ReadBytes(Fixture('first.pfx')), 'nexus-test'));
    lClient := TSSL.Create(lClientContext);
    lServer := TSSL.Create(lServerContext);
    AContext.AssertEquals(1, lClient.Set1Host('first.test'));
    AttachMemoryPair(lClient, lServer);
    AContext.AssertTrue(Handshake(lClient, lServer), 'Root-only client could not validate PFX chain');
    AContext.AssertEquals(0, lClient.VerifyResult);
  finally
    lServer.Free;
    lClient.Free;
    lServerContext.Free;
    lClientContext.Free;
  end;
end;

procedure CheckIdentity(AContext: TNXTestContext; const AHost: string; AExpected: Boolean);
var
  lClientContext, lServerContext: TSSLContext;
  lClient, lServer: TSSL;
begin
  lClientContext := ClientContext(True);
  lServerContext := ServerContext('first');
  lClient := TSSL.Create(lClientContext);
  lServer := TSSL.Create(lServerContext);
  try
    AContext.AssertEquals(1, lClient.Set1Host(AHost));
    AttachMemoryPair(lClient, lServer);
    if AExpected then AContext.AssertTrue(Handshake(lClient, lServer), 'Expected verified identity rejected')
    else
    begin
      AContext.AssertFalse(Handshake(lClient, lServer), 'Wrong identity accepted');
      AContext.AssertTrue(lClient.VerifyResult <> 0, 'Identity rejection was not a certificate verification failure');
    end;
  finally
    lServer.Free;
    lClient.Free;
    lServerContext.Free;
    lClientContext.Free;
  end;
end;

procedure TestHostnameVerification(AContext: TNXTestContext);
begin
  CheckIdentity(AContext, 'first.test', True);
  CheckIdentity(AContext, 'wrong.test', False);
  CheckIdentity(AContext, '127.0.0.1', True);
  CheckIdentity(AContext, '127.0.0.2', False);
end;

procedure TestSNIContexts(AContext: TNXTestContext);
const
  cHosts: array[0..2] of string = ('first.test', 'second.test', 'third.test');
var
  lContexts: array[0..2] of TSSLContext;
  lRoutes: TTlsExtCtx;
  lClientContext: TSSLContext;
  lClient, lServer: TSSL;
  lIndex: Integer;
begin
  for lIndex := 0 to 2 do lContexts[lIndex] := nil;
  try
    SetLength(lRoutes, 3);
    for lIndex := 0 to 2 do
    begin
      lContexts[lIndex] := ServerContext(Copy(cHosts[lIndex], 1, Pos('.', cHosts[lIndex]) - 1));
      lRoutes[lIndex].CTX := lContexts[lIndex];
      SetLength(lRoutes[lIndex].domains, 1);
      lRoutes[lIndex].domains[0] := cHosts[lIndex];
    end;
    lContexts[0].ActivateServerSNI(lRoutes);
    lRoutes[1].domains[0] := 'caller-mutated.test';
    lRoutes := nil; // Context must retain its own routing data.
    for lIndex := 0 to 2 do
    begin
      lClientContext := ClientContext(True);
      lClient := TSSL.Create(lClientContext);
      lServer := TSSL.Create(lContexts[0]);
      try
        AContext.AssertEquals(1, lClient.Set1Host(cHosts[lIndex]));
        AContext.AssertEquals(1, lClient.Ctrl(SSL_CTRL_SET_TLSEXT_HOSTNAME,
          TLSEXT_NAMETYPE_host_name, PAnsiChar(cHosts[lIndex])));
        AttachMemoryPair(lClient, lServer);
        AContext.AssertTrue(Handshake(lClient, lServer), 'SNI selected wrong certificate: ' + cHosts[lIndex]);
        AContext.AssertEquals(cHosts[lIndex], lClient.PeerName);
        AContext.AssertTrue(lClient.PeerNameHash <> 0, 'OpenSSL 3 subject-name hash did not resolve');
      finally
        lServer.Free;
        lClient.Free;
        lClientContext.Free;
      end;
    end;
  finally
    for lIndex := 2 downto 0 do lContexts[lIndex].Free;
  end;
end;

procedure TestALPN(AContext: TNXTestContext);
var
  lClientContext, lServerContext: TSSLContext;
  lClient, lServer: TSSL;
  lMessage, lReceived: AnsiString;
begin
  lClientContext := ClientContext(False);
  lServerContext := ServerContext('first');
  lClient := nil;
  lServer := nil;
  try
    AContext.AssertEquals(0, lClientContext.SetALPNProtocols('http/1.1,h2'));
    AContext.AssertEquals(0, lServerContext.SetALPNProtocols('h2,http/1.1'));
    AContext.AssertEquals(1, lServerContext.SetMinProtoVersion($0303));
    lClient := TSSL.Create(lClientContext);
    lServer := TSSL.Create(lServerContext);
    AttachMemoryPair(lClient, lServer);
    AContext.AssertTrue(Handshake(lClient, lServer));
    AContext.AssertEquals('h2', lClient.GetSelectedALPNProtocol);
    AContext.AssertEquals('h2', lServer.GetSelectedALPNProtocol);
    AContext.AssertTrue(H2TLSFloorMet(lClient.Version, lClient.CipherName));
    lMessage := 'encrypted local test';
    AContext.AssertEquals(Length(lMessage), lClient.Write(Pointer(lMessage), Length(lMessage)));
    SetLength(lReceived, Length(lMessage));
    AContext.AssertEquals(Length(lMessage), lServer.Read(Pointer(lReceived), Length(lReceived)));
    AContext.AssertEquals(lMessage, lReceived);
  finally
    lServer.Free;
    lClient.Free;
    lServerContext.Free;
    lClientContext.Free;
  end;
end;

procedure TestALPNNoOverlap(AContext: TNXTestContext);
var
  lClientContext, lServerContext: TSSLContext;
  lClient, lServer: TSSL;
begin
  lClientContext := ClientContext(False);
  lServerContext := ServerContext('first');
  lClientContext.SetALPNProtocols('unmatched');
  lServerContext.SetALPNProtocols('h2');
  lClient := TSSL.Create(lClientContext);
  lServer := TSSL.Create(lServerContext);
  try
    AttachMemoryPair(lClient, lServer);
    AContext.AssertFalse(Handshake(lClient, lServer), 'ALPN mismatch accepted');
  finally
    lServer.Free;
    lClient.Free;
    lServerContext.Free;
    lClientContext.Free;
  end;
end;

procedure TestCertificateGeneration(AContext: TNXTestContext);
var
  lGenerator: TOpenSSLX509Certificate;
  lData: TCertAndKey;
  lCertificate: PX509;
  lBIO: PBIO;
  lHostName: AnsiString;
  lIndex: Integer;
begin
  lGenerator := TOpenSSLX509Certificate.Create;
  try
    lGenerator.ValidFrom := EncodeDate(2050, 1, 1);
    lGenerator.ValidTo := EncodeDate(2051, 1, 1);
    for lIndex := 0 to 1 do
    begin
      if lIndex = 0 then lHostName := 'generated.test' else lHostName := '127.0.0.1';
      lGenerator.HostName := lHostName;
      lData := lGenerator.CreateCertificateAndKey;
      AContext.AssertTrue((Length(lData.Certificate) > 0) and (Length(lData.PrivateKey) > 0));
      lBIO := BioNew(BioSMem);
      try
        BioWrite(lBIO, lData.Certificate, Length(lData.Certificate));
        lCertificate := d2iX509Bio(lBIO, nil);
      finally
        BioFreeAll(lBIO);
      end;
      AContext.AssertTrue(lCertificate <> nil);
      try
        AContext.AssertEquals(2, lX509Version(lCertificate), 'Certificate is not X.509 v3');
        AContext.AssertEquals(668, lX509SignatureNID(lCertificate), 'Certificate is not RSA/SHA-256');
        if lIndex = 0 then
          AContext.AssertEquals(1, lX509CheckHost(lCertificate, PAnsiChar(lHostName), Length(lHostName), $20, nil), 'DNS SAN missing')
        else
          AContext.AssertEquals(1, lX509CheckIP(lCertificate, PAnsiChar(lHostName), 0), 'IP SAN missing');
      finally
        X509Free(lCertificate);
      end;
    end;
  finally
    lGenerator.Free;
  end;
end;

procedure TestConfigurationFailures(AContext: TNXTestContext);
var
  lHandler: TTestHandler;
  lRejected: Boolean;
begin
  lHandler := TTestHandler.Create;
  try
    lHandler.CertificateData.ALPNProtocols := ' , ';
    lRejected := False;
    try lHandler.Prepare; except on E: ESSL do lRejected := True; end;
    AContext.AssertTrue(lRejected, 'Invalid ALPN configuration accepted');
    lHandler.CertificateData.ALPNProtocols := '';
    lHandler.CertificateData.CipherList := 'not-a-cipher';
    lRejected := False;
    try lHandler.Prepare; except on E: ESSL do lRejected := True; end;
    AContext.AssertTrue(lRejected, 'Invalid cipher configuration accepted');
  finally
    lHandler.Free;
  end;
end;

procedure TestReceiveTimeout(AContext: TNXTestContext);
var
  lListener: TTestServer;
  lPeer: TInetSocket;
  lSocket: TSocketStream;
  lHandler: TTestHandler;
  lClientContext: TSSLContext;
  lClient: TSSL;
  lAddress: TInetSockAddr;
  lAddressLength: TSockLen;
  lStarted, lElapsed: QWord;
  lByte: Byte;
begin
  lListener := TTestServer.Create('127.0.0.1', 0, nil);
  lPeer := nil;
  lSocket := nil;
  lHandler := nil;
  lClientContext := nil;
  lClient := nil;
  try
    lListener.Listen;
    lAddressLength := SizeOf(lAddress);
    RequireNative(fpGetSockName(lListener.FPSocket.FD, @lAddress, @lAddressLength) = 0, 'Could not retrieve loopback port');
    lPeer := TInetSocket.Create('127.0.0.1', ntohs(lAddress.sin_port));
    lHandler := TTestHandler.Create;
    lSocket := TSocketStream.Create(lListener.TakeSocket, lHandler);
    lSocket.IOTimeout := 150;
    lHandler.CertificateData.Certificate.FileName := Fixture('first-chain.pem');
    lHandler.CertificateData.PrivateKey.FileName := Fixture('first.key');
    lHandler.Prepare;
    lClientContext := ClientContext(False);
    lClient := TSSL.Create(lClientContext);
    AttachMemoryPair(lClient, lHandler.SSL);
    AContext.AssertTrue(Handshake(lClient, lHandler.SSL));
    lStarted := GetTickCount64;
    AContext.AssertEquals(-1, lSocket.Read(lByte, 1), 'Timeout was reported as clean EOF');
    lElapsed := GetTickCount64 - lStarted;
    AContext.AssertTrue((lElapsed >= 100) and (lElapsed < 5000), 'TLS retry did not wait within its deadline');
    AContext.AssertFalse(lSocket.PeerClosed, 'Timeout incorrectly marked peer closed');
    AContext.AssertEquals(SSL_ERROR_WANT_READ, lHandler.SSLLastError);
  finally
    lClient.Free;
    lClientContext.Free;
    if lSocket <> nil then
    begin
      lSocket.Free; // Socket stream owns the handler.
      lHandler := nil;
    end;
    lHandler.Free;
    lPeer.Free;
    lListener.Free;
  end;
end;

procedure RegisterNXOpenSSLTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('OpenSSL');
  lSuite.AddTest('ECKeysAndModernSymbols', @TestECKeysAndModernSymbols);
  lSuite.AddTest('PFXChain', @TestPFXChain);
  lSuite.AddTest('PFXVerifiedHandshake', @TestPFXVerifiedHandshake);
  lSuite.AddTest('HostnameVerification', @TestHostnameVerification);
  lSuite.AddTest('SNIContexts', @TestSNIContexts);
  lSuite.AddTest('ALPN', @TestALPN);
  lSuite.AddTest('ALPNNoOverlap', @TestALPNNoOverlap);
  lSuite.AddTest('CertificateGeneration', @TestCertificateGeneration);
  lSuite.AddTest('ConfigurationFailures', @TestConfigurationFailures);
  lSuite.AddTest('ReceiveTimeout', @TestReceiveTimeout);
end;

finalization
  if lSSLHandle <> NilHandle then UnloadLibrary(lSSLHandle);
  if lCryptoHandle <> NilHandle then UnloadLibrary(lCryptoHandle);

end.

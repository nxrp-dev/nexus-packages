(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXSynapseOpenSSL;

{$mode objfpc}{$H+}

interface

uses SysUtils, blcksock, synsock, fpopenssl;

type
  TNXSynapseOpenSSL = class(TCustomSSL)
  private
    FContext: TSSLContext;
    FSession: TSSL;
    FReceiveTimeout: Integer;
    procedure ReleaseTLS;
    procedure ResetError;
    procedure Fail(AError: Integer; const ADescription: string);
    procedure RequireSuccess(AResult: Integer; const AOperation: string);
    procedure LoadKeys;
    procedure AddTrust(const AValue: AnsiString);
    function Prepare(AServer: Boolean): Boolean;
    function Handshake(AServer: Boolean): Boolean;
    function WaitRetry(AError: Integer; AStart: QWord; ATimeout: Integer): Boolean;
    procedure TLSFailure(AError: Integer);
    function Transfer(AWrite: Boolean; ABuffer: TMemory; ALength: Integer): Integer;
  protected
    function CreateSelfSignedCert(AHost: string): Boolean; override;
  public
    constructor Create(const ASocket: TTCPBlockSocket); override;
    destructor Destroy; override;
    procedure Assign(const AValue: TCustomSSL); override;
    function LibVersion: string; override;
    function LibName: string; override;
    function Connect: Boolean; override;
    function Accept: Boolean; override;
    function Shutdown: Boolean; override;
    function BiShutdown: Boolean; override;
    function SendBuffer(ABuffer: TMemory; ALength: Integer): Integer; override;
    function RecvBuffer(ABuffer: TMemory; ALength: Integer): Integer; override;
    function WaitingData: Integer; override;
    function GetSSLVersion: string; override;
    function GetPeerSubject: string; override;
    function GetPeerSerialNo: Integer; override;
    function GetPeerIssuer: string; override;
    function GetPeerName: string; override;
    function GetPeerNameHash: Cardinal; override;
    function GetPeerFingerprint: AnsiString; override;
    function GetCertInfo: string; override;
    function GetCipherName: string; override;
    function GetCipherBits: Integer; override;
    function GetCipherAlgBits: Integer; override;
    function GetVerifyCert: Integer; override;
    // Milliseconds for a TLS read, including retries after partial TLS records.
    // -1 follows Synapse's unbounded blocking receive; callers set their read deadline.
    property ReceiveTimeout: Integer read FReceiveTimeout write FReceiveTimeout;
  end;

implementation

uses Classes, ctypes, sslbase, openssl, sockets;

function PasswordCallback(ABuffer: PAnsiChar; ASize, AReadWrite: cint;
  AUserData: Pointer): cint; cdecl;
var
  lPassword: AnsiString;
begin
  Result := 0;
  if (ASize <= 0) or (ABuffer = nil) or (AUserData = nil) then Exit;
  lPassword := TNXSynapseOpenSSL(AUserData).KeyPassword;
  Result := Length(lPassword);
  if Result >= ASize then Result := ASize - 1;
  if Result > 0 then Move(lPassword[1], ABuffer^, Result);
  ABuffer[Result] := #0;
end;

constructor TNXSynapseOpenSSL.Create(const ASocket: TTCPBlockSocket);
begin
  inherited Create(ASocket);
  FCiphers := 'DEFAULT';
  FReceiveTimeout := -1;
end;

destructor TNXSynapseOpenSSL.Destroy;
begin
  ReleaseTLS;
  inherited Destroy;
end;

procedure TNXSynapseOpenSSL.Assign(const AValue: TCustomSSL);
begin
  inherited Assign(AValue);
  if AValue is TNXSynapseOpenSSL then
    FReceiveTimeout := TNXSynapseOpenSSL(AValue).ReceiveTimeout;
end;

procedure TNXSynapseOpenSSL.ReleaseTLS;
begin
  FreeAndNil(FSession);
  FreeAndNil(FContext);
  FSSLEnabled := False;
end;

procedure TNXSynapseOpenSSL.ResetError;
begin
  FLastError := 0;
  FLastErrorDesc := '';
  ErrClearError;
end;

procedure TNXSynapseOpenSSL.Fail(AError: Integer; const ADescription: string);
begin
  FLastError := AError;
  FLastErrorDesc := ADescription;
end;

procedure TNXSynapseOpenSSL.RequireSuccess(AResult: Integer; const AOperation: string);
begin
  if AResult <> 1 then raise ESSL.Create('OpenSSL failed to ' + AOperation);
end;

function TNXSynapseOpenSSL.CreateSelfSignedCert(AHost: string): Boolean;
var
  lGenerator: TOpenSSLX509Certificate;
  lPair: TCertAndKey;
begin
  lGenerator := TOpenSSLX509Certificate.Create;
  try
    lGenerator.HostName := AHost;
    lPair := lGenerator.CreateCertificateAndKey;
    SetString(FCertificate, PAnsiChar(Pointer(lPair.Certificate)), Length(lPair.Certificate));
    SetString(FPrivateKey, PAnsiChar(Pointer(lPair.PrivateKey)), Length(lPair.PrivateKey));
    Result := True;
  finally
    lGenerator.Free;
  end;
end;

procedure TNXSynapseOpenSSL.AddTrust(const AValue: AnsiString);
var
  lBIO: PBIO;
  lCertificate: PX509;
  lStore: Pointer;
  lCount: Integer;
begin
  if AValue = '' then Exit;
  if Length(AValue) > High(cint) then raise ESSL.Create('Trust data exceeds the native length limit');
  lStore := SSL_CTX_get_cert_store(FContext.CTX);
  if lStore = nil then raise ESSL.Create('Certificate trust store unavailable');
  lBIO := BIO_new_mem_buf(Pointer(AValue), Length(AValue));
  if lBIO = nil then raise ESSL.Create('Could not allocate trust certificate BIO');
  try
    lCount := 0;
    if Pos('-----BEGIN CERTIFICATE-----', AValue) > 0 then
    begin
      repeat
        lCertificate := PEMReadBioX509(lBIO, nil, nil, nil);
        if lCertificate = nil then Break;
        try
          RequireSuccess(X509_STORE_add_cert(lStore, lCertificate), 'add trust certificate');
          Inc(lCount);
        finally
          X509Free(lCertificate);
        end;
      until False;
    end
    else
    begin
      lCertificate := d2iX509Bio(lBIO, nil);
      if lCertificate <> nil then
      try
        RequireSuccess(X509_STORE_add_cert(lStore, lCertificate), 'add DER trust certificate');
        Inc(lCount);
      finally
        X509Free(lCertificate);
      end;
    end;
    if lCount = 0 then raise ESSL.Create('Trust data contains no readable certificates');
  finally
    BioFreeAll(lBIO);
  end;
  ErrClearError; // PEM end-of-input is expected after a successfully read bundle.
end;

procedure TNXSynapseOpenSSL.LoadKeys;
var
  lData: TSSLData;
  lConfiguredKey: Boolean;
begin
  lData := TSSLData.Create;
  try
    if (FCertificateFile <> '') or (FCertificate <> '') then
    begin
      lData.FileName := FCertificateFile;
      lData.Value := BytesOf(FCertificate);
      RequireSuccess(FContext.UseCertificate(lData), 'load certificate');
    end;
    lConfiguredKey := (FPrivateKeyFile <> '') or (FPrivateKey <> '') or
      (FPFXFile <> '') or (FPFX <> '');
    if (FPrivateKeyFile <> '') or (FPrivateKey <> '') then
    begin
      lData.FileName := FPrivateKeyFile;
      lData.Value := BytesOf(FPrivateKey);
      RequireSuccess(FContext.UsePrivateKey(lData), 'load private key');
    end;
    if (FPFXFile <> '') or (FPFX <> '') then
    begin
      lData.FileName := FPFXFile;
      lData.Value := BytesOf(FPFX);
      RequireSuccess(FContext.LoadPFX(lData, FKeyPassword), 'load PFX');
    end;
    if lConfiguredKey then
      RequireSuccess(SslCtxCheckPrivateKeyFile(FContext.CTX), 'match certificate and private key');
    if FCertCAFile <> '' then
      RequireSuccess(FContext.LoadVerifyLocations(FCertCAFile, ''), 'load CA bundle');
    if FTrustCertificateFile <> '' then
      RequireSuccess(FContext.LoadVerifyLocations(FTrustCertificateFile, ''), 'load trust certificate');
    AddTrust(FCertCA);
    AddTrust(FTrustCertificate);
    if FVerifyCert and (FCertCAFile = '') and (FTrustCertificateFile = '') and
      (FCertCA = '') and (FTrustCertificate = '') then
      RequireSuccess(SSL_CTX_set_default_verify_paths(FContext.CTX), 'load default trust paths');
  finally
    lData.Free;
  end;
end;

function TNXSynapseOpenSSL.Prepare(AServer: Boolean): Boolean;
var
  lVersion: Integer;
  lCiphers: AnsiString;
  lIdentity: string;
  lIPv4: in_addr;
  lIPv6: in6_addr;
begin
  ReleaseTLS;
  ResetError;
  Result := False;
  try
    if FSocket.Socket = INVALID_SOCKET then raise ESSL.Create('TLS socket is not connected');
    if not InitSSLInterface then raise ESSL.Create('Required OpenSSL 3 runtime unavailable');
    FContext := TSSLContext.Create(sslbase.stAny);
    lVersion := TLS1_2_VERSION;
    case FSSLType of
      LT_All: ;
      LT_TLSv1_2: lVersion := TLS1_2_VERSION;
      LT_TLSv1_3: lVersion := TLS1_3_VERSION;
      else raise ESSL.Create('The Nexus TLS adapter requires TLS 1.2 or later');
    end;
    RequireSuccess(FContext.SetMinProtoVersion(lVersion), 'set TLS minimum version');
    if FSSLType <> LT_All then
      RequireSuccess(SslCtxCtrl(FContext.CTX, SSL_CTRL_SET_MAX_PROTO_VERSION, lVersion, nil), 'set TLS maximum version');
    lCiphers := FCiphers;
    RequireSuccess(FContext.SetCipherList(lCiphers), 'set cipher list');
    if FVerifyCert then
    begin
      lVersion := SSL_VERIFY_PEER;
      if AServer then lVersion := lVersion or SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
      FContext.SetVerify(lVersion, nil);
    end
    else FContext.SetVerify(SSL_VERIFY_NONE, nil);
    FContext.SetDefaultPasswdCb(@PasswordCallback);
    FContext.SetDefaultPasswdCbUserdata(Self);
    if AServer and (FCertificateFile = '') and (FCertificate = '') and
      (FPFXFile = '') and (FPFX = '') then
      CreateSelfSignedCert('localhost');
    LoadKeys;
    FSession := TSSL.Create(FContext);
    RequireSuccess(FSession.SetFd(FSocket.Socket), 'attach TLS socket');
    if not AServer then
    begin
      lIdentity := FSNIHost;
      if lIdentity = '' then lIdentity := FSocket.GetRemoteSinIP;
      if Pos(#0, lIdentity) > 0 then raise ESSL.Create('TLS identity contains a null byte');
      if FVerifyCert then
        RequireSuccess(FSession.Set1Host(lIdentity), 'set verified DNS or IP identity');
      if (lIdentity <> '') and not TryStrToHostAddr(lIdentity, lIPv4) and
        not TryStrToHostAddr6(lIdentity, lIPv6) then
        RequireSuccess(SslCtrl(FSession.SSL, SSL_CTRL_SET_TLSEXT_HOSTNAME,
          TLSEXT_NAMETYPE_host_name, PAnsiChar(AnsiString(lIdentity))), 'set SNI');
    end;
    ErrClearError; // Successful PEM/DER fallback loaders may have queued errors.
    Result := True;
  except
    on lError: Exception do
    begin
      Fail(SSL_ERROR_SSL, lError.Message);
      ReleaseTLS;
    end;
  end;
end;

procedure TNXSynapseOpenSSL.TLSFailure(AError: Integer);
var
  lCode: culong;
  lDescription: AnsiString;
begin
  lCode := ErrGetError;
  lDescription := '';
  if lCode <> 0 then
  begin
    SetLength(lDescription, 256);
    ErrErrorString(lCode, lDescription, Length(lDescription));
    SetLength(lDescription, StrLen(PAnsiChar(lDescription)));
  end;
  if lDescription = '' then lDescription := 'TLS operation failed (SSL error ' + IntToStr(AError) + ')';
  Fail(AError, lDescription);
end;

function TNXSynapseOpenSSL.WaitRetry(AError: Integer; AStart: QWord;
  ATimeout: Integer): Boolean;
var
  lRemaining: Integer;
  lElapsed: QWord;
begin
  Result := False;
  if (AError <> SSL_ERROR_WANT_READ) and (AError <> SSL_ERROR_WANT_WRITE) then
  begin
    TLSFailure(AError);
    Exit;
  end;
  lRemaining := ATimeout;
  if ATimeout >= 0 then
  begin
    lElapsed := GetTickCount64 - AStart;
    if lElapsed >= QWord(ATimeout) then
    begin
      Fail(WSAETIMEDOUT, 'TLS operation timed out');
      Exit;
    end;
    lRemaining := ATimeout - Integer(lElapsed);
  end;
  if AError = SSL_ERROR_WANT_READ then Result := FSocket.CanRead(lRemaining)
  else Result := FSocket.CanWrite(lRemaining);
  if not Result then
    if FSocket.LastError <> 0 then Fail(FSocket.LastError, FSocket.LastErrorDesc)
    else Fail(WSAETIMEDOUT, 'TLS operation timed out');
end;

function TNXSynapseOpenSSL.Handshake(AServer: Boolean): Boolean;
var
  lStart: QWord;
  lTimeout, lResult, lError: Integer;
  lNonBlocking: Boolean;
begin
  Result := False;
  if not Prepare(AServer) then Exit;
  lTimeout := FSocket.ConnectionTimeout;
  if lTimeout <= 0 then lTimeout := -1;
  lStart := GetTickCount64;
  lNonBlocking := FSocket.NonBlockMode;
  try
    FSocket.NonBlockMode := True;
    repeat
      ErrClearError;
      if AServer then lResult := FSession.Accept else lResult := FSession.Connect;
      lError := FSession.GetError(lResult);
      if lResult = 1 then Break;
      if not WaitRetry(lError, lStart, lTimeout) then Exit;
    until False;
    if FVerifyCert then
    begin
      if FSession.VerifyResult <> X509_V_OK then
      begin
        Fail(SSL_ERROR_SSL, 'Peer certificate verification failed');
        Exit;
      end;
      if not DoVerifyCert then
      begin
        Fail(SSL_ERROR_SSL, 'Peer certificate verification callback rejected the peer');
        Exit;
      end;
    end;
    FSSLEnabled := True;
    Result := True;
  finally
    FSocket.NonBlockMode := lNonBlocking;
    if not Result then ReleaseTLS;
  end;
end;

function TNXSynapseOpenSSL.Connect: Boolean;
begin
  Result := Handshake(False);
end;

function TNXSynapseOpenSSL.Accept: Boolean;
begin
  Result := Handshake(True);
end;

function TNXSynapseOpenSSL.Shutdown: Boolean;
var
  lResult, lError: Integer;
  lStart: QWord;
  lNonBlocking: Boolean;
begin
  ResetError;
  if FSession = nil then Exit(True);
  Result := False;
  lStart := GetTickCount64;
  lNonBlocking := FSocket.NonBlockMode;
  try
    FSocket.NonBlockMode := True;
    repeat
      ErrClearError;
      lResult := FSession.Shutdown;
      lError := FSession.GetError(lResult);
      // 0 means close_notify sent; hard close does not wait for the peer.
      if lResult >= 0 then Exit(True);
      if not WaitRetry(lError, lStart, FSocket.NonblockSendTimeout) then Exit;
    until False;
  finally
    FSocket.NonBlockMode := lNonBlocking;
    ReleaseTLS;
  end;
end;

function TNXSynapseOpenSSL.BiShutdown: Boolean;
var
  lStart: QWord;
  lResult, lError, lTimeout: Integer;
  lNonBlocking: Boolean;
begin
  ResetError;
  if FSession = nil then Exit(True);
  Result := False;
  lTimeout := FSocket.ConnectionTimeout;
  if lTimeout <= 0 then lTimeout := FSocket.NonblockSendTimeout;
  lStart := GetTickCount64;
  lNonBlocking := FSocket.NonBlockMode;
  try
    FSocket.NonBlockMode := True;
    repeat
      ErrClearError;
      lResult := FSession.Shutdown;
      lError := FSession.GetError(lResult);
      if lResult = 1 then Exit(True);
      if lResult = 0 then lError := SSL_ERROR_WANT_READ;
      if not WaitRetry(lError, lStart, lTimeout) then Exit;
    until False;
  finally
    FSocket.NonBlockMode := lNonBlocking;
    ReleaseTLS;
  end;
end;

function TNXSynapseOpenSSL.Transfer(AWrite: Boolean; ABuffer: TMemory;
  ALength: Integer): Integer;
var
  lStart: QWord;
  lError, lTimeout: Integer;
  lNonBlocking: Boolean;
begin
  ResetError;
  if ALength = 0 then Exit(0);
  if (ALength < 0) or (ABuffer = nil) or (FSession = nil) or not FSSLEnabled then
  begin
    Fail(SSL_ERROR_SSL, 'TLS transfer requires an active session and valid buffer');
    Exit(-1);
  end;
  if AWrite then lTimeout := FSocket.NonblockSendTimeout else lTimeout := FReceiveTimeout;
  lStart := GetTickCount64;
  lNonBlocking := FSocket.NonBlockMode;
  try
    FSocket.NonBlockMode := True;
    repeat
      ErrClearError;
      if AWrite then Result := FSession.Write(ABuffer, ALength)
      else Result := FSession.Read(ABuffer, ALength);
      lError := FSession.GetError(Result);
      if Result > 0 then Exit;
      if lError = SSL_ERROR_ZERO_RETURN then
      begin
        if AWrite then
        begin
          Fail(lError, 'Peer closed the TLS connection');
          Exit(-1);
        end;
        Exit(0);
      end;
      if not WaitRetry(lError, lStart, lTimeout) then Exit(-1);
    until False;
  finally
    FSocket.NonBlockMode := lNonBlocking;
  end;
end;

function TNXSynapseOpenSSL.SendBuffer(ABuffer: TMemory; ALength: Integer): Integer;
begin
  Result := Transfer(True, ABuffer, ALength);
end;

function TNXSynapseOpenSSL.RecvBuffer(ABuffer: TMemory; ALength: Integer): Integer;
begin
  Result := Transfer(False, ABuffer, ALength);
end;

function TNXSynapseOpenSSL.LibVersion: string;
begin
  Result := OpenSSLGetVersion(0);
end;

function TNXSynapseOpenSSL.LibName: string;
begin
  Result := 'Nexus OpenSSL';
end;

function TNXSynapseOpenSSL.WaitingData: Integer;
begin
  if FSession = nil then Exit(0);
  Result := FSession.Pending;
end;

function TNXSynapseOpenSSL.GetSSLVersion: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.Version;
end;

function TNXSynapseOpenSSL.GetPeerSubject: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.PeerSubject;
end;

function TNXSynapseOpenSSL.GetPeerSerialNo: Integer;
begin
  if FSession = nil then Exit(0);
  Result := FSession.PeerSerialNo;
end;

function TNXSynapseOpenSSL.GetPeerIssuer: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.PeerIssuer;
end;

function TNXSynapseOpenSSL.GetPeerName: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.PeerName;
end;

function TNXSynapseOpenSSL.GetPeerNameHash: Cardinal;
begin
  if FSession = nil then Exit(0);
  Result := FSession.PeerNameHash;
end;

function TNXSynapseOpenSSL.GetPeerFingerprint: AnsiString;
begin
  if FSession = nil then Exit('');
  Result := FSession.PeerFingerprint('SHA1');
end;

function TNXSynapseOpenSSL.GetCertInfo: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.CertInfo;
end;

function TNXSynapseOpenSSL.GetCipherName: string;
begin
  if FSession = nil then Exit('');
  Result := FSession.CipherName;
end;

function TNXSynapseOpenSSL.GetCipherBits: Integer;
begin
  if FSession = nil then Exit(0);
  Result := FSession.CipherBits;
end;

function TNXSynapseOpenSSL.GetCipherAlgBits: Integer;
begin
  if FSession = nil then Exit(0);
  Result := FSession.CipherAlgBits;
end;

function TNXSynapseOpenSSL.GetVerifyCert: Integer;
begin
  if FSession = nil then Exit(-1);
  Result := FSession.VerifyResult;
end;

initialization
  SSLImplementation := TNXSynapseOpenSSL;

end.

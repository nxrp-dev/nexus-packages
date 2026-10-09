{
    This file is part of the Free Component Library (FCL)
    Copyright (c) 1999-2000 by the Free Pascal development team

    Small OOP wrapper around OpenSSL unit.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$IFNDEF FPC_DOTTEDUNITS}
unit fpopenssl;
{$ENDIF FPC_DOTTEDUNITS}

{$mode objfpc}{$H+}
{.$DEFINE DUMPCERT}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.Classes, System.SysUtils, System.Net.Sslbase, Api.Openssl, System.CTypes;
{$ELSE FPC_DOTTEDUNITS}
uses
  Classes, SysUtils, sslbase, openssl, ctypes;
{$ENDIF FPC_DOTTEDUNITS}

{$IFDEF DUMPCERT}
Const
  DumpCertFile = 'x509.txt';
{$ENDIF}

Type
  { TSSLContext }

  TSSLContext = Class;
  TRTlsExtCtx = record
    CTX: TSSLContext;
    domains: array of string; // SSL Certificate with one or more alternative names (SAN)
  end;
  TTlsExtCtx = array of TRTlsExtCtx;
  PTlsExtCtx = ^TTlsExtCtx;

  TSSLContext = Class(TObject)
  private
    FCTX: PSSL_CTX;
    FSNIContexts: TTlsExtCtx;
    FALPNWire : TBytes;   // ALPN preference list, [len][bytes]… wire form (RFC 7301); read by the unit-level ALPN select callback
    function UsePrivateKey(pkey: SslPtr): cInt;
    function UsePrivateKeyASN1(pk: cInt; d: String; len: cLong): cInt;
    function UsePrivateKeyASN1(pk: cInt; d: TBytes; len: cLong): cInt;
    function UsePrivateKeyFile(const Afile: String; Atype: cInt): cInt;
  Public
    Constructor Create(AContext : PSSL_CTX = Nil); overload;
    Constructor Create(AType : TSSLType); overload;
    Destructor Destroy; override;
    Function SetCipherList(Var ACipherList : AnsiString) : Integer;
    // Install an ALPN protocol list (comma-separated, e.g. 'h2,http/1.1'): builds the
    // [len][bytes]… wire buffer, sets the client offer and the server select callback.
    // Returns the underlying SslCtxSetAlpnProtos result (0 == success, inverted!); an
    // empty/whitespace-only list installs nothing and returns non-zero (failure).
    Function SetALPNProtocols(const aProtocols: AnsiString): Integer;
    procedure SetVerify(mode: Integer; arg2: TSSLCTXVerifyCallback);
    procedure SetDefaultPasswdCb(cb: PPasswdCb);
    procedure SetDefaultPasswdCbUserdata(u: SslPtr);
    Function UsePrivateKey(Data : TSSLData) : cint;
    // Use certificate.
    Function UseCertificate(Data : TSSLData) : cint;
    function UseCertificateASN1(len: cLong; d: String):cInt; overload; deprecated 'use TBytes overload';
    function UseCertificateASN1(len: cLong; buf: TBytes):cInt; overload;
    function UseCertificateFile(const Afile: String; Atype: cInt):cInt;
    function UseCertificateChainFile(const Afile: PAnsiChar):cInt;
    function UseCertificate(x: SslPtr):cInt;
    function LoadVerifyLocations(const CAfile: String; const CApath: String):cInt;
    function LoadPFX(Const S,APassword : AnsiString) : cint; deprecated 'use TBytes overload';
    function LoadPFX(Const Buf : TBytes;APassword : AnsiString) : cint;
    function LoadPFX(Data : TSSLData; Const APAssword : Ansistring) : cint;
    function SetOptions(AOptions: QWord): QWord;
    // Set the minimum negotiated TLS protocol version (e.g. TLS1_2_VERSION).
    // Returns the SslCTXCtrl result (1 == success). Used to enforce the RFC 9113
    // §9.2 floor (TLS >= 1.2) when h2 is offered (Story 4.5).
    Function SetMinProtoVersion(aVersion : cInt) : cLong;
    procedure SetTlsextServernameCallback(cb: PCallbackCb);
    procedure SetTlsextServernameArg(ATlsextcbp: SslPtr);
    procedure ActivateServerSNI(ATlsextcbp: TTlsExtCtx);
    procedure SetEcdhAuto(const onoff: boolean);
    Property CTX: PSSL_CTX Read FCTX;
  end;

  TSSL = Class(TObject)
  Public
    FSSL : PSSL;
  Public
    Constructor Create(ASSL : PSSL = Nil);
    Constructor Create(AContext : TSSLContext);
    destructor Destroy; override;
    function SetFd(fd: cInt):cInt;
    function Accept : cInt;
    function Connect : cInt;
    function Shutdown : cInt;
    function Read(buf: SslPtr; num: cInt):cInt;
    function Peek(buf: SslPtr; num: cInt):cInt;
    function Write(buf: SslPtr; num: cInt):cInt;
    Function PeerCertificate : PX509;
    function Ctrl(cmd: cInt; larg: clong; parg: Pointer): cInt;
    function Pending:cInt;
    Function GetError(AResult :cint) : cint;
    function GetCurrentCipher :SslPtr;
    function Version: String;
    function PeerName: string;
    function PeerNameHash: cardinal;
    function PeerSubject : String;
    Function PeerIssuer : String;
    Function PeerSerialNo : Integer;
    Function PeerFingerprint(const name: string = 'MD5') : String;
    Function CertInfo : String;
    function CipherName: string;
    function CipherBits: integer;
    function CipherAlgBits: integer;
    Function VerifyResult : Integer;
    function Set1Host(const hostname: string): Integer;
    // Negotiated ALPN protocol after a completed handshake; '' when nothing negotiated.
    function GetSelectedALPNProtocol: AnsiString;
    Property SSL: PSSL Read FSSL;
  end;


  TOpenSSLX509Certificate = Class (TX509Certificate)
  Protected
    function CreateKey: PEVP_PKEY; virtual;
    procedure SetNameData(x: PX509); virtual;
    procedure SetTimes(x: PX509); virtual;
  Public
    Function CreateCertificateAndKey : TCertAndKey; override;
  end;

  ESSL = Class(Exception);

Function BioToString(B : PBIO; FreeBIO : Boolean = False) : AnsiString;

implementation

{$IFDEF FPC_DOTTEDUNITS}
uses System.DateUtils, System.Net.Sockets;
{$ELSE FPC_DOTTEDUNITS}
uses dateutils, sockets;
{$ENDIF FPC_DOTTEDUNITS}

Resourcestring
  SErrCountNotGetContext = 'Failed to create SSL Context';
  SErrFailedToCreateSSL = 'Failed to create SSL';


Function BioToString(B: PBIO; FreeBIO: Boolean = False): AnsiString;
var
  lPending: csize_t;
  lLength, lRead: Integer;
begin
  Result := '';
  try
    lPending := BioCtrlPending(B);
    if lPending > csize_t(High(cint)) then
      raise ESSL.Create('BIO output exceeds the supported read length');
    lLength := lPending;
    if lLength = 0 then Exit;
    SetLength(Result, lLength);
    lRead := BioRead(B, Result, lLength);
    if lRead > 0 then SetLength(Result, lRead)
    else Result := '';
  finally
    if FreeBIO then BioFreeAll(B);
  end;
end;

Function BioToTBytes(B: PBIO; FreeBIO: Boolean = False): TBytes;
var
  lPending: csize_t;
  lLength, lRead: Integer;
begin
  Result := nil;
  try
    lPending := BioCtrlPending(B);
    if lPending > csize_t(High(cint)) then
      raise ESSL.Create('BIO output exceeds the supported read length');
    lLength := lPending;
    if lLength = 0 then Exit;
    SetLength(Result, lLength);
    lRead := BioRead(B, Result, lLength);
    if lRead > 0 then SetLength(Result, lRead)
    else Result := nil;
  finally
    if FreeBIO then BioFreeAll(B);
  end;
end;

function SelectSNIContextCallback(ASSL: PSSL; AAlert: PcInt;
  AUserData: Pointer): cint; cdecl;
var
  lContext: TSSLContext;
  lHostName: string;
  lIndex, lDomain: Integer;
begin
  Result := SSL_TLSEXT_ERR_NOACK;
  lContext := TSSLContext(AUserData);
  if lContext = nil then Exit;
  lHostName := LowerCase(SSLGetServername(ASSL, TLSEXT_NAMETYPE_host_name));
  if lHostName = '' then Exit;
  for lIndex := 0 to High(lContext.FSNIContexts) do
    for lDomain := 0 to High(lContext.FSNIContexts[lIndex].domains) do
      if SameText(lHostName, lContext.FSNIContexts[lIndex].domains[lDomain]) then
      begin
        if (lContext.FSNIContexts[lIndex].CTX = nil) or
          (SslSetSslCtx(ASSL, lContext.FSNIContexts[lIndex].CTX.CTX) = nil) then
          Exit(SSL_TLSEXT_ERR_ALERT_FATAL);
        Exit(SSL_TLSEXT_ERR_OK);
      end;
end;

{ TOpenSSLX509Certificate }


procedure RequireSSLSuccess(AResult: cint; const AOperation: string);
begin
  if AResult <> 1 then
    raise ESSL.Create('OpenSSL failed to ' + AOperation);
end;

procedure TOpenSSLX509Certificate.SetNameData(x: PX509);
var
  lName: PX509_NAME;
  lHostName, lCountry: AnsiString;
begin
  lName := X509GetSubjectName(x);
  if lName = nil then raise ESSL.Create('OpenSSL certificate subject is unavailable');
  lCountry := Country;
  if lCountry = '' then lCountry := 'BE';
  lHostName := HostName;
  if lHostName = '' then lHostName := 'localhost';
  RequireSSLSuccess(X509NameAddEntryByTxt(lName, 'C', $1001, lCountry, -1, -1, 0), 'set certificate country');
  RequireSSLSuccess(X509NameAddEntryByTxt(lName, 'CN', $1001, lHostName, -1, -1, 0), 'set certificate common name');
  if Organization <> '' then
    RequireSSLSuccess(X509NameAddEntryByTxt(lName, 'O', $1001, Organization, -1, -1, 0), 'set certificate organization');
  RequireSSLSuccess(X509SetIssuerName(x, lName), 'set certificate issuer');
end;

Procedure TOpenSSLX509Certificate.SetTimes(x: PX509);
var
  lTime: PASN1_TIME;
begin
  if ValidTo <= ValidFrom then raise ESSL.Create('Certificate validity interval is empty');
  lTime := ASN1TimeNew;
  if lTime = nil then raise ESSL.Create('Could not allocate certificate validity time');
  try
    RequireSSLSuccess(ASN1TimeSetString(lTime, FormatDateTime('YYYYMMDDHHNNSS"Z"', ValidFrom)), 'encode certificate start time');
    RequireSSLSuccess(X509SetNotBefore(x, lTime), 'set certificate start time');
    RequireSSLSuccess(ASN1TimeSetString(lTime, FormatDateTime('YYYYMMDDHHNNSS"Z"', ValidTo)), 'encode certificate end time');
    RequireSSLSuccess(X509SetNotAfter(x, lTime), 'set certificate end time');
  finally
    ASN1TimeFree(lTime);
  end;
end;

function TOpenSSLX509Certificate.CreateKey: PEVP_PKEY;
var
  lContext: PEVP_PKEY_CTX;
begin
  Result := nil;
  if KeySize < 2048 then raise ESSL.Create('RSA certificate keys must have at least 2048 bits');
  lContext := EVP_PKEY_CTX_new_from_name(nil, 'RSA', nil);
  if lContext = nil then raise ESSL.Create('Could not create RSA generation context');
  try
    RequireSSLSuccess(EVPPKeyKeygenInit(lContext), 'initialize RSA key generation');
    RequireSSLSuccess(EVPPKeySetRSAKeygenBits(lContext, KeySize), 'set RSA key size');
    RequireSSLSuccess(EVPPKeyGenerate(lContext, Result), 'generate RSA key');
  finally
    EVP_PKEY_CTX_free(lContext);
  end;
end;

function TOpenSSLX509Certificate.CreateCertificateAndKey: TCertAndKey;
var
  lKey: PEVP_PKEY;
  lCertificate: PX509;
  lBIO: PBIO;
  lExtension: Pointer;
  lHostName, lSAN: AnsiString;
  lIPv4: in_addr;
  lIPv6: in6_addr;
  lSerial: Integer;
begin
  Result.Certificate := nil;
  Result.PrivateKey := nil;
  lKey := nil;
  lCertificate := X509New;
  if lCertificate = nil then raise ESSL.Create('Could not allocate certificate');
  try
    RequireSSLSuccess(X509SetVersion(lCertificate, 2), 'set X.509 v3 certificate version');
    lSerial := Serial;
    if lSerial = 0 then
    begin
      RequireSSLSuccess(RAND_bytes(@lSerial, SizeOf(lSerial)), 'generate certificate serial');
      lSerial := lSerial and $7FFFFFFF;
      if lSerial = 0 then lSerial := 1;
    end;
    RequireSSLSuccess(Asn1IntegerSet(X509GetSerialNumber(lCertificate), lSerial), 'set certificate serial');
    SetTimes(lCertificate);
    lKey := CreateKey;
    RequireSSLSuccess(X509SetPubkey(lCertificate, lKey), 'set certificate public key');
    SetNameData(lCertificate);
    lHostName := HostName;
    if lHostName = '' then lHostName := 'localhost';
    if (Pos(',', lHostName) > 0) or (Pos(#0, lHostName) > 0) then
      raise ESSL.Create('Certificate host name must identify one host');
    if TryStrToHostAddr(lHostName, lIPv4) or TryStrToHostAddr6(lHostName, lIPv6) then
      lSAN := 'IP:' + lHostName
    else
      lSAN := 'DNS:' + lHostName;
    lExtension := X509V3ExtNConf(nil, nil, 'subjectAltName', lSAN);
    if lExtension = nil then raise ESSL.Create('Could not encode certificate alternative name');
    try
      RequireSSLSuccess(X509AddExt(lCertificate, lExtension, -1), 'add certificate alternative name');
    finally
      X509ExtensionFree(lExtension);
    end;
    if X509Sign(lCertificate, lKey, EvpGetDigestByName('SHA256')) <= 0 then
      raise ESSL.Create('Could not sign certificate with SHA-256');
    lBIO := BioNew(BioSMem);
    if lBIO = nil then raise ESSL.Create('Could not allocate certificate BIO');
    try
      RequireSSLSuccess(i2dX509Bio(lBIO, lCertificate), 'encode certificate');
      Result.Certificate := BioToTBytes(lBIO);
    finally
      BioFreeAll(lBIO);
    end;
    lBIO := BioNew(BioSMem);
    if lBIO = nil then raise ESSL.Create('Could not allocate private key BIO');
    try
      RequireSSLSuccess(i2dPrivateKeyBio(lBIO, lKey), 'encode private key');
      Result.PrivateKey := BioToTBytes(lBIO);
    finally
      BioFreeAll(lBIO);
    end;
  finally
    X509Free(lCertificate);
    EvpPkeyFree(lKey);
  end;
end;

{ TSSLContext }

Constructor TSSLContext.Create(AContext: PSSL_CTX);
begin
  FCTX:=AContext
end;

Constructor TSSLContext.Create(AType: TSSLType);

Var
  C : PSSL_CTX;

begin
  C := nil;
  Case AType of
    stAny:
      begin
        if Assigned(SslTLSMethod) then
          C := SslCtxNew(SslTLSMethod)
        else
          C := SslCtxNew(SslMethodV23);
      end;
    stSSLv2: C := SslCtxNew(SslMethodV2);
    stSSLv3: C := SslCtxNew(SslMethodV3);
    stTLSv1: C := SslCtxNew(SslMethodTLSV1);
    stTLSv1_1: C := SslCtxNew(SslMethodTLSV1_1);
    stTLSv1_2: C := SslCtxNew(SslMethodTLSV1_2);
  end;
  if (C=Nil) then
     Raise ESSL.Create(SErrCountNotGetContext);
  Create(C);
end;

Destructor TSSLContext.Destroy;
begin
  SslCtxFree(FCTX);
  inherited Destroy;
end;

Function TSSLContext.SetCipherList(Var ACipherList: AnsiString): Integer;

begin
  Result:=SSLCTxSetCipherList(FCTX,ACipherList);
end;

{ Server-side ALPN select callback (plain cdecl function — no implicit Self — typed
  exactly as openssl.pas's TAlpnSelectCb). Recovers the TSSLContext from arg (Self,
  passed at install time) and lets OpenSSL pick from the client offer (in_/inlen) using
  our server preference wire list (FALPNWire). Returns SSL_TLSEXT_ERR_OK to accept; on
  no-overlap returns SSL_TLSEXT_ERR_ALERT_FATAL (RFC 7301 §3.2 no_application_protocol —
  NOT NOACK, which is the wrong NPN-era "continue without ALPN" semantics for h2). }
function ALPNSelectCallback(ssl: PSSL; out_: PPByte; outlen: PByte;
                            in_: PByte; inlen: cuint; arg: Pointer): cint; cdecl;
var
  Ctx : TSSLContext;
  r   : cint;
begin
  Ctx := TSSLContext(arg);
  if (Ctx = nil) or (Length(Ctx.FALPNWire) = 0) then
    Exit(SSL_TLSEXT_ERR_ALERT_FATAL);
  r := SslSelectNextProto(out_, outlen,
                          @Ctx.FALPNWire[0], Length(Ctx.FALPNWire),  // server prefs
                          in_, inlen);                               // client offer
  if r = OPENSSL_NPN_NEGOTIATED then
    Result := SSL_TLSEXT_ERR_OK            // 0 — accept; OpenSSL copies out_ itself
  else
    Result := SSL_TLSEXT_ERR_ALERT_FATAL;  // 2 — RFC 7301 §3.2 no_application_protocol
end;

Function TSSLContext.SetALPNProtocols(const aProtocols: AnsiString): Integer;

  // Append one length-prefixed token ([len][bytes]) to FALPNWire after trimming;
  // empty tokens are skipped. Raises ESSL for a token that cannot be length-prefixed.
  procedure AppendToken(const aToken: AnsiString);
  var
    Tok : AnsiString;
    L : Integer;
  begin
    Tok:=Trim(aToken);
    if Tok='' then
      Exit;                              // skip empty tokens
    if Length(Tok)>255 then              // cannot length-prefix in a single byte
      Raise ESSL.CreateFmt('ALPN protocol name too long (%d bytes): %s',[Length(Tok),Tok]);
    L:=Length(FALPNWire);
    SetLength(FALPNWire,L+1+Length(Tok));
    FALPNWire[L]:=Byte(Length(Tok));     // [len]
    Move(Tok[1],FALPNWire[L+1],Length(Tok)); // [bytes]  (1-based string -> 0-based TBytes)
  end;

var
  I,Start : Integer;
begin
  SetLength(FALPNWire,0);
  // Manual comma split (no type-helper dependency): emit each [Start..I-1] slice.
  Start:=1;
  for I:=1 to Length(aProtocols) do
    if aProtocols[I]=',' then
      begin
      AppendToken(Copy(aProtocols,Start,I-Start));
      Start:=I+1;
      end;
  AppendToken(Copy(aProtocols,Start,Length(aProtocols)-Start+1)); // trailing token
  if Length(FALPNWire)=0 then
    begin
    // No valid tokens: install nothing, signal failure (non-zero) — never a false success.
    Result:=1;
    Exit;
    end;
  { NB: SSL_CTX_set_alpn_protos returns 0 on SUCCESS (inverted!) }
  Result:=SslCtxSetAlpnProtos(FCTX,@FALPNWire[0],Length(FALPNWire)); // client offer
  SslCtxSetAlpnSelectCb(FCTX,@ALPNSelectCallback,Self);             // server side
end;

procedure TSSLContext.SetVerify(mode: Integer; arg2: TSSLCTXVerifyCallback);
begin
  SslCtxSetVerify(FCtx,Mode,arg2);
end;

procedure TSSLContext.SetDefaultPasswdCb(cb: PPasswdCb);
begin
  SslCtxSetDefaultPasswdCb(Fctx,cb)
end;

procedure TSSLContext.SetDefaultPasswdCbUserdata(u: SslPtr);
begin
  SslCtxSetDefaultPasswdCbUserdata(FCTX,u);
end;

function TSSLContext.UsePrivateKey(pkey: SslPtr):cInt;
begin
  Result:=SslCtxUsePrivateKey(FCTX,pkey);
end;

function TSSLContext.UsePrivateKeyASN1(pk: cInt; d: String; len: cLong):cInt;
begin
  Result:=SslCtxUsePrivateKeyASN1(pk,FCtx,d,len);
end;

function TSSLContext.UsePrivateKeyASN1(pk: cInt; d: TBytes; len: cLong): cInt;
begin
  Result:=SslCtxUsePrivateKeyASN1(pk,FCtx,d,len);
end;

function TSSLContext.UsePrivateKeyFile(const Afile: String; Atype: cInt):cInt;
begin
  Result:=SslCtxUsePrivateKeyFile(FCTX,AFile,AType);
end;


Function TSSLContext.UsePrivateKey(Data: TSSLData): cint;
var
  lKey: PEVP_PKEY;
  lBytes: PByte;
begin
  Result := -1;
  if Length(Data.Value) <> 0 then
  begin
    lBytes := @Data.Value[0];
    lKey := d2i_AutoPrivateKey(nil, @lBytes, Length(Data.Value));
    if lKey = nil then Exit;
    try
      Result := UsePrivateKey(lKey);
    finally
      EvpPkeyFree(lKey);
    end;
  end
  else if Data.FileName <> '' then
  begin
    Result := UsePrivateKeyFile(Data.FileName, SSL_FILETYPE_PEM);
    if Result <> 1 then
      Result := UsePrivateKeyFile(Data.FileName, SSL_FILETYPE_ASN1);
  end;
end;

Function TSSLContext.UseCertificate(Data: TSSLData): cint;

Var
  l : integer;
  FN : String;

begin
  Result:=-1;
  L:=Length(Data.Value);
  if (L<>0) then
    Result:=UseCertificateASN1(length(Data.Value),Data.Value)
  else if (Data.FileName<>'') then
    begin
    FN:=Data.FileName;
    Result:=UseCertificateChainFile(PAnsiChar(FN));
    if Result<>1 then
       begin
       Result:=UseCertificateFile(FN,SSL_FILETYPE_PEM);
       if (Result<>1) then
         Result:=UseCertificateFile(FN,SSL_FILETYPE_ASN1);
       end;
    end
end;

function TSSLContext.UseCertificateASN1(len: cLong; d: String): cInt;
begin
  Result:=sslctxUseCertificateASN1(FCTX,len,d);
end;

function TSSLContext.UseCertificateASN1(len: cLong; buf: TBytes): cInt;
begin
  Result:=sslctxUseCertificateASN1(FCTX,len,Buf);
end;

function TSSLContext.UseCertificateFile(const Afile: String; Atype: cInt): cInt;
begin
  Result:=sslctxUseCertificateFile(FCTX,Afile,Atype);
end;

function TSSLContext.UseCertificateChainFile(const Afile: PAnsiChar): cInt;
begin
  Result:=sslctxUseCertificateChainFile(FCTX,Afile);
end;

function TSSLContext.UseCertificate(x: SslPtr): cInt;
begin
  Result:=SSLCTXusecertificate(FCTX,X);
end;

function TSSLContext.LoadVerifyLocations(const CAfile: String; const CApath: String): cInt;
begin
  Result:=SslCtxLoadVerifyLocations(FCTX,CAfile,CApath);
end;

function TSSLContext.LoadPFX(Const S, APassword: AnsiString): cint;

var
  Buf : TBytes;

begin
  SetLength(Buf,Length(S));
  Move(S[1],Buf[0],Length(S));
  Result:=LoadPFX(Buf,APAssword);
end;

function TSSLContext.LoadPFX(const Buf: TBytes; APassword: AnsiString): cint;
const
  cSSLControlChain = 88; // SSL_CTX_set1_chain: copies stack and retains certificate references.
var
  lBIO: PBIO;
  lPKCS12, lCertificate, lKey, lChain: SslPtr;
  lIndex: Integer;
begin
  Result := -1;
  if Length(Buf) = 0 then Exit;
  lCertificate := nil;
  lKey := nil;
  lChain := nil;
  lPKCS12 := nil;
  lBIO := BioNew(BioSMem);
  if lBIO = nil then Exit;
  try
    if BioWrite(lBIO, Buf, Length(Buf)) <> Length(Buf) then Exit;
    lPKCS12 := d2iPKCS12bio(lBIO, nil);
    if lPKCS12 = nil then Exit;
    if PKCS12parse(lPKCS12, APassword, lKey, lCertificate, lChain) <> 1 then Exit;
    Result := UseCertificate(lCertificate);
    if Result = 1 then Result := UsePrivateKey(lKey);
    if Result = 1 then
      Result := SslCtxCtrl(FCTX, cSSLControlChain, 1, lChain);
    if Result = 1 then Result := SslCtxCheckPrivateKeyFile(FCTX);
  finally
    if lChain <> nil then
    begin
      for lIndex := 0 to OpenSSLStackNum(lChain) - 1 do
        X509Free(OpenSSLStackValue(lChain, lIndex));
      OpenSSLStackFree(lChain);
    end;
    if lKey <> nil then EvpPkeyFree(lKey);
    if lCertificate <> nil then X509Free(lCertificate);
    if lPKCS12 <> nil then PKCS12Free(lPKCS12);
    BioFreeAll(lBIO);
  end;
end;

function TSSLContext.LoadPFX(Data: TSSLData; Const APAssword: Ansistring): cint;
var
  lBytes: TBytes;
  lStream: TFileStream;
begin
  if Length(Data.Value) <> 0 then
    lBytes := Data.Value
  else
  begin
    lStream := TFileStream.Create(Data.FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(lBytes, lStream.Size);
      if Length(lBytes) <> 0 then lStream.ReadBuffer(lBytes[0], Length(lBytes));
    finally
      lStream.Free;
    end;
  end;
  Result := LoadPFX(lBytes, APassword);
end;

function TSSLContext.SetOptions(AOptions: QWord): QWord;
begin
  Result := SSLCTXSetOptions(FCTX, AOptions);
end;

Const
  // OpenSSL SSL_CTX control id used by SetMinProtoVersion. Defined here (not in
  // openssl.pas) to avoid re-opening that done unit (Story 4.5). Standard/stable
  // across OpenSSL 1.1.x/3.x. (TLS1_2_VERSION = $0303 lives at the call site in
  // opensslsockets.pp, the unit that passes it.)
  SSL_CTRL_SET_MIN_PROTO_VERSION = 123;    // openssl/ssl.h

function TSSLContext.SetMinProtoVersion(aVersion: cInt): cLong;
begin
  // Mirrors SetOptions: SSL_CTX_set_min_proto_version() is a macro over SSL_CTX_ctrl.
  Result := SslCtxCtrl(FCTX, SSL_CTRL_SET_MIN_PROTO_VERSION, aVersion, nil);
end;

procedure TSSLContext.SetTlsextServernameCallback(cb: PCallbackCb);
begin
  SslCtxCallbackCtrl(FCTX, SSL_CTRL_SET_TLSEXT_SERVERNAME_CB, cb);
end;

procedure TSSLContext.SetTlsextServernameArg(ATlsextcbp: SslPtr);
begin
  SslCtxCtrl(FCTX, SSL_CTRL_SET_TLSEXT_SERVERNAME_ARG, 0, ATlsextcbp);
end;

procedure TSSLContext.ActivateServerSNI(ATlsextcbp: TTlsExtCtx);
var
  lIndex: Integer;
begin
  FSNIContexts := Copy(ATlsextcbp);
  for lIndex := 0 to High(FSNIContexts) do
    FSNIContexts[lIndex].domains := Copy(ATlsextcbp[lIndex].domains);
  SetTlsextServernameCallback(@SelectSNIContextCallback);
  SetTlsextServernameArg(Self);
end;

procedure TSSLContext.SetEcdhAuto(const onoff: boolean);
var larg: clong;
begin
  if onoff then
    larg := 1
  else
    larg := 0;
  SslCtxCtrl(FCTX, SSL_CTRL_SET_ECDH_AUTO, larg, nil);
end;

{ TSSL }

Constructor TSSL.Create(ASSL: PSSL);
begin
  FSSL:=ASSL;
end;

Constructor TSSL.Create(AContext: TSSLContext);
begin
  FSSL:=Nil;
  if Assigned(AContext) and Assigned(AContext.CTX) then
    FSSL:=sslNew(AContext.CTX);
  If (FSSL=Nil) then
    Raise ESSL.Create(SErrFailedToCreateSSL)
end;

destructor TSSL.Destroy;
begin
  sslfree(FSSL);
  inherited Destroy;
end;

function TSSL.Ctrl(cmd: cInt; larg: clong; parg: Pointer): cInt;

begin
  Result:=sslCtrl(fSSL,cmd,larg,parg);
end;

function TSSL.SetFd(fd: cInt): cInt;
begin
  Result:=sslSetFD(fSSL,fd);
end;

function TSSL.Accept: cInt;
begin
  Result:=sslAccept(fSSL);
end;

function TSSL.Connect: cInt;
begin
  Result:=sslConnect(fSSL);
end;

function TSSL.Shutdown: cInt;
begin
  try
    Result:=sslShutDown(fSSL);
  except
    // Sometimes, SSL gives an error when the connection is lost
  end;
end;

function TSSL.Read(buf: SslPtr; num: cInt): cInt;
begin
  Result:=sslRead(FSSL,buf,num);
end;

function TSSL.Peek(buf: SslPtr; num: cInt): cInt;
begin
  Result:=sslPeek(FSSL,buf,num);
end;

function TSSL.Write(buf: SslPtr; num: cInt): cInt;
begin
  Result:=sslWrite(FSSL,buf,num);
end;

Function TSSL.PeerCertificate: PX509;
begin
  Result:=sslGetPeercertificate(FSSL);
end;

function TSSL.Pending: cInt;
begin
  Result:=sslPending(FSSL);
end;

Function TSSL.GetError(AResult: cint): cint;
begin
  Result:=SslGetError(FSsl,AResult);
end;

function TSSL.GetCurrentCipher: SslPtr;
begin
  Result:=SSLGetCurrentCipher(FSSL);
end;

function TSSL.Version: String;
begin
  Result:=SSlGetVersion(FSsl);
end;

function TSSL.PeerName: string;
var
  s : ansistring;
  p : Integer;
begin
  Result:='';
  S:=PeerSubject;
  P:=Pos('/CN=', S);
  if (P>0) then
    begin
    Delete(S,1,P+3);
    P:=Pos('/',S);
    if (P>0) then
      Result:=Copy(S,1,P-1)
    else
      Result := S;
    end
end;

function TSSL.PeerNameHash: cardinal;
var
  C : PX509;
begin
  Result:=0;
  c:=PeerCertificate;
  if (C=Nil) then
    exit;
  try
    Result:=X509NameHash(X509GetSubjectName(C));
  finally
    X509Free(C);
  end;
end;

function TSSL.PeerSubject: String;
var
  c : PX509;
  s : ansistring;

begin
  Result:='';
  S:='';
  c:=PeerCertificate;
  if Assigned(c) then
    try
      setlength(s, 4096);
      Result:=X509NameOneline(X509GetSubjectName(c),s,Length(s));
    finally
      X509Free(c);
    end;
end;

Function TSSL.PeerIssuer: String;

var
  C: PX509;
  S: ansistring;

begin
  Result:='';
  C:=PeerCertificate;
  if (C=Nil) then
    Exit;
  try
    S:=StringOfChar(#0,4096);
    Result:=X509NameOneline(X509GetIssuerName(C),S,4096);
  finally
    X509Free(C);
  end;
end;

Function TSSL.PeerSerialNo: Integer;
var
  C : PX509;
  SN : PASN1_INTEGER;

begin
  Result:=-1;
  C:=PeerCertificate;
  if (C=Nil) then
    exit;
  try
    SN:=X509GetSerialNumber(C);
    Result:=Asn1IntegerGet(SN);
  finally
    X509Free(C);
  end;
end;

Function TSSL.PeerFingerprint(const name: string): String;
var
  C : PX509;
  L : integer;

begin
  Result:='';
  C:=PeerCertificate;
  if (C=Nil) then
    Exit;
  try
    Result:=StringOfChar(#0,EVP_MAX_MD_SIZE);
    L:=0;
    X509Digest(C,EvpGetDigestByName(name),Result,L);
    SetLength(Result,L);
  finally
    X509Free(C);
  end;
end;

Function TSSL.CertInfo: String;
var
  C : PX509;
  B : PBIO;

begin
  Result:='';
  C:=PeerCertificate;
  if (C=Nil)  then
    Exit;
  try
    B:=BioNew(BioSMem);
    try
      X509Print(B,C);
      Result:=BioToString(B);
    finally
      BioFreeAll(B);
    end;
  finally
    X509Free(C);
  end;
end;

function TSSL.CipherName: string;
begin
  Result:=SslCipherGetName(GetCurrentCipher);
end;

function TSSL.CipherBits: integer;

var
  x: integer;

begin
  x:=0;
  Result:=SSLCipherGetBits(GetCurrentCipher,x);
end;

function TSSL.CipherAlgBits: integer;

begin
  Result:=0;
  SSLCipherGetBits(GetCurrentCipher,Result);
end;

Function TSSL.VerifyResult: Integer;

begin
  Result:=SslGetVerifyResult(FSsl);
end;

function TSSL.Set1Host(const hostname: string): Integer;
var
  lIPv4: in_addr;
  lIPv6: in6_addr;
begin
  if hostname = '' then Exit(0);
  if TryStrToHostAddr(hostname, lIPv4) or TryStrToHostAddr6(hostname, lIPv6) then
    Result := X509VerifyParamSet1IP(SSLGet0Param(FSSL), hostname)
  else
    Result := SslSet1Host(FSSL, hostname);
end;

function TSSL.GetSelectedALPNProtocol: AnsiString;
var
  data : PByte;
  len  : cuint;
begin
  Result := '';
  data := nil;
  len  := 0;
  SslGet0AlpnSelected(FSSL, @data, @len);          // public wrapper nils/zeros when unavailable
  if (len > 0) and (data <> nil) then
    SetString(Result, PAnsiChar(data), len);       // copy; NEVER free data (OpenSSL-owned)
end;

end.


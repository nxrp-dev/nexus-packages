(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPOpenSSL;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Dynlibs, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPOpenSSL = class
  private
    class var FLibraryHandle: TLibHandle;
    class var FLoaded: Boolean;
    class procedure Load; static;
  public
    class procedure RequireAvailable; static;
    class function SHA1(const AValue: RawByteString): RawByteString; static;
    class function SHA256(const AValue: RawByteString): RawByteString; static;
    class function SHA256Stream(AStream: TStream): RawByteString; static;
    class function HMACSHA256(const AKey,
      AValue: RawByteString): RawByteString; static;
    class function PBKDF2SHA256(const APassword, ASalt: RawByteString;
      AIterations, ALength: Integer): RawByteString; static;
    class function RandomBytes(ACount: Integer): RawByteString; static;
    class function ConstantTimeEquals(const ALeft,
      ARight: RawByteString): Boolean; static;
  end;

implementation

type
  PEVPMD = Pointer;
  PEVPMDContext = Pointer;
  TEvPSHA1 = function: PEVPMD; cdecl;
  TEvPSHA256 = function: PEVPMD; cdecl;
  TEvPDigest = function(AData: Pointer; ACount: NativeUInt;
    ADigest: PByte; ADigestLength: PCardinal; AType: PEVPMD;
    AImplementation: Pointer): Integer; cdecl;
  TEvPMDContextNew = function: PEVPMDContext; cdecl;
  TEvPMDContextFree = procedure(AContext: PEVPMDContext); cdecl;
  TEvPDigestInit = function(AContext: PEVPMDContext; AType: PEVPMD;
    AImplementation: Pointer): Integer; cdecl;
  TEvPDigestUpdate = function(AContext: PEVPMDContext; AData: Pointer;
    ACount: NativeUInt): Integer; cdecl;
  TEvPDigestFinal = function(AContext: PEVPMDContext; ADigest: PByte;
    ADigestLength: PCardinal): Integer; cdecl;
  THMAC = function(AType: PEVPMD; AKey: Pointer; AKeyLength: Integer;
    AData: PByte; ADataLength: NativeUInt; ADigest: PByte;
    ADigestLength: PCardinal): PByte; cdecl;
  TPBKDF2 = function(APassword: PAnsiChar; APasswordLength: Integer;
    ASalt: PByte; ASaltLength, AIterations: Integer; AType: PEVPMD;
    AKeyLength: Integer; AKey: PByte): Integer; cdecl;
  TRandomBytes = function(ABuffer: PByte; ACount: Integer): Integer; cdecl;
  TMemoryCompare = function(ALeft, ARight: Pointer;
    ACount: NativeUInt): Integer; cdecl;

var
  lEVPSHA1: TEvPSHA1;
  lEVPSHA256: TEvPSHA256;
  lEVPDigest: TEvPDigest;
  lEVPMDContextNew: TEvPMDContextNew;
  lEVPMDContextFree: TEvPMDContextFree;
  lEVPDigestInit: TEvPDigestInit;
  lEVPDigestUpdate: TEvPDigestUpdate;
  lEVPDigestFinal: TEvPDigestFinal;
  lHMAC: THMAC;
  lPBKDF2: TPBKDF2;
  lRandomBytes: TRandomBytes;
  lMemoryCompare: TMemoryCompare;

procedure RequireSymbol(var ADestination; const AName: AnsiString);
var
  lAddress: Pointer;
begin
  lAddress := GetProcedureAddress(TNXXMPPOpenSSL.FLibraryHandle, AName);
  if not Assigned(lAddress) then
    raise ENXXMPPError.Create(xesConfiguration, 'openssl-symbol-missing',
      'Required OpenSSL 3 symbol is unavailable: ' + string(AName));
  Pointer(ADestination) := lAddress;
end;

class procedure TNXXMPPOpenSSL.Load;
begin
  if FLoaded then
    Exit;
  FLoaded := True;
  {$IFDEF WINDOWS}
  FLibraryHandle := LoadLibrary('libcrypto-3-x64.dll');
  {$ELSE}
  FLibraryHandle := LoadLibrary('libcrypto.so.3');
  {$ENDIF}
  if FLibraryHandle = NilHandle then
    raise ENXXMPPError.Create(xesConfiguration, 'openssl-unavailable',
      'The OpenSSL 3 cryptography runtime is unavailable.');
  RequireSymbol(lEVPSHA256, 'EVP_sha256');
  RequireSymbol(lEVPSHA1, 'EVP_sha1');
  RequireSymbol(lEVPDigest, 'EVP_Digest');
  RequireSymbol(lEVPMDContextNew, 'EVP_MD_CTX_new');
  RequireSymbol(lEVPMDContextFree, 'EVP_MD_CTX_free');
  RequireSymbol(lEVPDigestInit, 'EVP_DigestInit_ex');
  RequireSymbol(lEVPDigestUpdate, 'EVP_DigestUpdate');
  RequireSymbol(lEVPDigestFinal, 'EVP_DigestFinal_ex');
  RequireSymbol(lHMAC, 'HMAC');
  RequireSymbol(lPBKDF2, 'PKCS5_PBKDF2_HMAC');
  RequireSymbol(lRandomBytes, 'RAND_bytes');
  RequireSymbol(lMemoryCompare, 'CRYPTO_memcmp');
end;

class function TNXXMPPOpenSSL.SHA1(
  const AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  Load;
  SetLength(Result, 20);
  lLength := 0;
  if lEVPDigest(Pointer(AValue), Length(AValue), @Result[1], @lLength,
    lEVPSHA1(), nil) <> 1 then
    raise ENXXMPPError.Create(xesProtocol, 'sha1-failure',
      'OpenSSL failed to calculate the XEP-0115 verification digest.');
  SetLength(Result, lLength);
end;

class procedure TNXXMPPOpenSSL.RequireAvailable;
begin
  Load;
end;

class function TNXXMPPOpenSSL.SHA256(
  const AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  Load;
  SetLength(Result, 32);
  lLength := 0;
  if lEVPDigest(Pointer(AValue), Length(AValue), @Result[1], @lLength,
    lEVPSHA256(), nil) <> 1 then
    raise ENXXMPPError.Create(xesAuthentication, 'sha256-failure',
      'OpenSSL failed to calculate SHA-256.');
  SetLength(Result, lLength);
end;

class function TNXXMPPOpenSSL.SHA256Stream(
  AStream: TStream): RawByteString;
const
  cBufferSize = 65536;
var
  lBuffer: array[0..cBufferSize - 1] of Byte;
  lContext: PEVPMDContext;
  lCount: LongInt;
  lLength: Cardinal;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('A SHA-256 input stream is required.');
  Load;
  lContext := lEVPMDContextNew();
  if not Assigned(lContext) then
    raise ENXXMPPError.Create(xesProtocol, 'sha256-failure',
      'OpenSSL could not create a SHA-256 context.');
  try
    if lEVPDigestInit(lContext, lEVPSHA256(), nil) <> 1 then
      raise ENXXMPPError.Create(xesProtocol, 'sha256-failure',
        'OpenSSL could not initialize SHA-256.');
    repeat
      lCount := AStream.Read(lBuffer, SizeOf(lBuffer));
      if (lCount > 0) and
        (lEVPDigestUpdate(lContext, @lBuffer[0], lCount) <> 1) then
        raise ENXXMPPError.Create(xesProtocol, 'sha256-failure',
          'OpenSSL could not update SHA-256.');
    until lCount = 0;
    SetLength(Result, 32);
    lLength := 0;
    if lEVPDigestFinal(lContext, @Result[1], @lLength) <> 1 then
      raise ENXXMPPError.Create(xesProtocol, 'sha256-failure',
        'OpenSSL could not finish SHA-256.');
    SetLength(Result, lLength);
  finally
    lEVPMDContextFree(lContext);
  end;
end;

class function TNXXMPPOpenSSL.HMACSHA256(const AKey,
  AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  Load;
  SetLength(Result, 32);
  lLength := 0;
  if not Assigned(lHMAC(lEVPSHA256(), Pointer(AKey), Length(AKey),
    PByte(Pointer(AValue)), Length(AValue), @Result[1], @lLength)) then
    raise ENXXMPPError.Create(xesAuthentication, 'hmac-failure',
      'OpenSSL failed to calculate HMAC-SHA-256.');
  SetLength(Result, lLength);
end;

class function TNXXMPPOpenSSL.PBKDF2SHA256(const APassword,
  ASalt: RawByteString; AIterations, ALength: Integer): RawByteString;
begin
  Load;
  if (AIterations < 1) or (ALength < 1) then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-pbkdf2-parameters',
      'PBKDF2 requires positive iteration and output lengths.');
  SetLength(Result, ALength);
  if lPBKDF2(PAnsiChar(APassword), Length(APassword), PByte(Pointer(ASalt)),
    Length(ASalt), AIterations, lEVPSHA256(), ALength, @Result[1]) <> 1 then
    raise ENXXMPPError.Create(xesAuthentication, 'pbkdf2-failure',
      'OpenSSL failed to calculate PBKDF2-HMAC-SHA-256.');
end;

class function TNXXMPPOpenSSL.RandomBytes(ACount: Integer): RawByteString;
begin
  Load;
  if ACount < 1 then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-random-length',
      'A positive random-byte length is required.');
  SetLength(Result, ACount);
  if lRandomBytes(@Result[1], ACount) <> 1 then
    raise ENXXMPPError.Create(xesAuthentication, 'random-failure',
      'OpenSSL failed to obtain cryptographically secure random bytes.');
end;

class function TNXXMPPOpenSSL.ConstantTimeEquals(const ALeft,
  ARight: RawByteString): Boolean;
begin
  Load;
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  if Length(ALeft) = 0 then
    Exit(True);
  Result := lMemoryCompare(Pointer(ALeft), Pointer(ARight), Length(ALeft)) = 0;
end;

finalization
  if TNXXMPPOpenSSL.FLibraryHandle <> NilHandle then
    UnloadLibrary(TNXXMPPOpenSSL.FLibraryHandle);

end.

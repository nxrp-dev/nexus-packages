(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXOpenSSLCrypto;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TNXOpenSSLCrypto = class
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

uses openssl, fpopenssl, ctypes;

class function TNXOpenSSLCrypto.SHA1(
  const AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  RequireAvailable;
  SetLength(Result, 20);
  lLength := 0;
  if EVP_Digest(Pointer(AValue), Length(AValue), @Result[1], @lLength,
    EVP_sha1(), nil) <> 1 then
    raise ESSL.Create('OpenSSL failed to calculate SHA-1.');
  if lLength <> Cardinal(Length(Result)) then
    raise ESSL.Create('OpenSSL returned an unexpected digest length.');
end;

class procedure TNXOpenSSLCrypto.RequireAvailable;
begin
  if not InitSSLInterface then
    raise ESSL.Create('The required OpenSSL 3 runtime is unavailable.');
end;

class function TNXOpenSSLCrypto.SHA256(
  const AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  RequireAvailable;
  SetLength(Result, 32);
  lLength := 0;
  if EVP_Digest(Pointer(AValue), Length(AValue), @Result[1], @lLength,
    EVP_sha256(), nil) <> 1 then
    raise ESSL.Create('OpenSSL failed to calculate SHA-256.');
  if lLength <> Cardinal(Length(Result)) then
    raise ESSL.Create('OpenSSL returned an unexpected digest length.');
end;

class function TNXOpenSSLCrypto.SHA256Stream(
  AStream: TStream): RawByteString;
const
  cBufferSize = 65536;
var
  lBuffer: array[0..cBufferSize - 1] of Byte;
  lContext: PEVP_MD_CTX;
  lCount: LongInt;
  lLength: Cardinal;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('A SHA-256 input stream is required.');
  RequireAvailable;
  lContext := EVP_MD_CTX_new();
  if not Assigned(lContext) then
    raise ESSL.Create('OpenSSL could not create a SHA-256 context.');
  try
    if EVP_DigestInit_ex(lContext, EVP_sha256(), nil) <> 1 then
      raise ESSL.Create('OpenSSL could not initialize SHA-256.');
    repeat
      lCount := AStream.Read(lBuffer, SizeOf(lBuffer));
      if (lCount > 0) and
        (EVP_DigestUpdate(lContext, @lBuffer[0], lCount) <> 1) then
        raise ESSL.Create('OpenSSL could not update SHA-256.');
    until lCount = 0;
    SetLength(Result, 32);
    lLength := 0;
    if EVP_DigestFinal_ex(lContext, @Result[1], @lLength) <> 1 then
      raise ESSL.Create('OpenSSL could not finish SHA-256.');
    if lLength <> Cardinal(Length(Result)) then
      raise ESSL.Create('OpenSSL returned an unexpected digest length.');
  finally
    EVP_MD_CTX_free(lContext);
  end;
end;

class function TNXOpenSSLCrypto.HMACSHA256(const AKey,
  AValue: RawByteString): RawByteString;
var
  lLength: Cardinal;
begin
  RequireAvailable;
  if Length(AKey) > High(cint) then
    raise EArgumentException.Create('HMAC key exceeds the native length limit.');
  SetLength(Result, 32);
  lLength := 0;
  if not Assigned(HMAC(EVP_sha256(), Pointer(AKey), Length(AKey),
    PByte(Pointer(AValue)), Length(AValue), @Result[1], @lLength)) then
    raise ESSL.Create('OpenSSL failed to calculate HMAC-SHA-256.');
  if lLength <> Cardinal(Length(Result)) then
    raise ESSL.Create('OpenSSL returned an unexpected digest length.');
end;

class function TNXOpenSSLCrypto.PBKDF2SHA256(const APassword,
  ASalt: RawByteString; AIterations, ALength: Integer): RawByteString;
begin
  RequireAvailable;
  if (AIterations < 1) or (ALength < 1) then
    raise ESSL.Create('PBKDF2 requires positive iteration and output lengths.');
  if (Length(APassword) > High(cint)) or (Length(ASalt) > High(cint)) then
    raise EArgumentException.Create('PBKDF2 input exceeds the native length limit.');
  SetLength(Result, ALength);
  if PKCS5_PBKDF2_HMAC(PAnsiChar(APassword), Length(APassword), PByte(Pointer(ASalt)),
    Length(ASalt), AIterations, EVP_sha256(), ALength, @Result[1]) <> 1 then
    raise ESSL.Create('OpenSSL failed to calculate PBKDF2-HMAC-SHA-256.');
end;

class function TNXOpenSSLCrypto.RandomBytes(ACount: Integer): RawByteString;
begin
  RequireAvailable;
  if ACount < 1 then
    raise ESSL.Create('A positive random-byte length is required.');
  SetLength(Result, ACount);
  if RAND_bytes(@Result[1], ACount) <> 1 then
    raise ESSL.Create('OpenSSL failed to obtain cryptographically secure random bytes.');
end;

class function TNXOpenSSLCrypto.ConstantTimeEquals(const ALeft,
  ARight: RawByteString): Boolean;
begin
  RequireAvailable;
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  if Length(ALeft) = 0 then
    Exit(True);
  Result := CRYPTO_memcmp(Pointer(ALeft), Pointer(ARight), Length(ALeft)) = 0;
end;

end.

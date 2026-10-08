(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPSASL;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, synacode, obNXXMPPError, obNXXMPPOpenSSL,
  tpNXXMPPTypes, utNXXMPPASCII;

type
  TNXXMPPSCRAMSHA256 = class
  private
    FClientFirstBare: RawByteString;
    FExpectedServerSignature: RawByteString;
    FNonce: RawByteString;
    class function EscapeUsername(const AValue: UTF8String): RawByteString; static;
    class function FieldValue(const AMessage: RawByteString;
      AName: AnsiChar): RawByteString; static;
  public
    function Start(const AUsername: UTF8String;
      const ANonce: RawByteString = ''): RawByteString;
    function Continue(const AServerFirst: RawByteString;
      const APassword: UTF8String): RawByteString;
    procedure VerifyServerFinal(const AServerFinal: RawByteString);
  end;

implementation

class function TNXXMPPSCRAMSHA256.EscapeUsername(
  const AValue: UTF8String): RawByteString;
var
  lIndex: Integer;
begin
  Result := '';
  for lIndex := 1 to Length(AValue) do
    case AValue[lIndex] of
      '=': Result := Result + '=3D';
      ',': Result := Result + '=2C';
    else
      Result := Result + AValue[lIndex];
    end;
end;

class function TNXXMPPSCRAMSHA256.FieldValue(
  const AMessage: RawByteString; AName: AnsiChar): RawByteString;
var
  lField: RawByteString;
  lPosition: Integer;
  lStart: Integer;
begin
  Result := '';
  lStart := 1;
  while lStart <= Length(AMessage) do
  begin
    lPosition := Pos(',', Copy(AMessage, lStart, MaxInt));
    if lPosition = 0 then
      lField := Copy(AMessage, lStart, MaxInt)
    else
      lField := Copy(AMessage, lStart, lPosition - 1);
    if (Length(lField) >= 2) and (lField[1] = AName) and
      (lField[2] = '=') then
    begin
      if Result <> '' then
        raise ENXXMPPError.Create(xesAuthentication, 'duplicate-scram-field',
          'A SCRAM message contains a duplicate field.');
      Result := Copy(lField, 3, MaxInt);
    end;
    if lPosition = 0 then
      Break;
    Inc(lStart, lPosition);
  end;
end;

function TNXXMPPSCRAMSHA256.Start(const AUsername: UTF8String;
  const ANonce: RawByteString): RawByteString;
var
  lUsername: UTF8String;
begin
  if (AUsername = '') or not NXXMPPIsASCIIIdentifier(AUsername) then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-username',
      'The SCRAM username must contain printable ASCII characters without spaces.');
  lUsername := NXXMPPASCIIToLower(AUsername);
  if ANonce = '' then
    FNonce := EncodeBase64(TNXXMPPOpenSSL.RandomBytes(18))
  else
    FNonce := ANonce;
  if Pos(',', FNonce) > 0 then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-nonce',
      'A SCRAM nonce must not contain a comma.');
  FClientFirstBare := 'n=' + EscapeUsername(lUsername) + ',r=' + FNonce;
  FExpectedServerSignature := '';
  Result := 'n,,' + FClientFirstBare;
end;

function TNXXMPPSCRAMSHA256.Continue(
  const AServerFirst: RawByteString;
  const APassword: UTF8String): RawByteString;
const
  cMinimumIterations = 4096;
  cMaximumIterations = 1000000;
var
  lAuthMessage: RawByteString;
  lClientFinalWithoutProof: RawByteString;
  lClientKey: RawByteString;
  lClientProof: RawByteString;
  lClientSignature: RawByteString;
  lIndex: Integer;
  lIterations: Integer;
  lNonce: RawByteString;
  lPassword: UTF8String;
  lSalt: RawByteString;
  lSaltedPassword: RawByteString;
  lServerKey: RawByteString;
begin
  if FClientFirstBare = '' then
    raise ENXXMPPError.Create(xesAuthentication, 'scram-not-started',
      'SCRAM must be started before processing a server challenge.');
  lNonce := FieldValue(AServerFirst, 'r');
  lSalt := FieldValue(AServerFirst, 's');
  if not TryStrToInt(string(FieldValue(AServerFirst, 'i')), lIterations) then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-iterations',
      'The SCRAM server iteration count is invalid.');
  if (Copy(lNonce, 1, Length(FNonce)) <> FNonce) or
    (Length(lNonce) <= Length(FNonce)) then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-nonce',
      'The SCRAM server nonce does not extend the client nonce.');
  if (lIterations < cMinimumIterations) or
    (lIterations > cMaximumIterations) then
    raise ENXXMPPError.Create(xesAuthentication, 'scram-iteration-policy',
      'The SCRAM iteration count is outside the accepted policy.');
  try
    lSalt := DecodeBase64(lSalt);
  except
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-salt',
      'The SCRAM salt is not valid Base64.');
  end;
  if (APassword = '') or not NXXMPPIsASCIIText(APassword) then
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-password',
      'The SCRAM password must contain printable ASCII characters only.');
  lPassword := APassword;
  lSaltedPassword := TNXXMPPOpenSSL.PBKDF2SHA256(
    RawByteString(lPassword), lSalt, lIterations, 32);
  lClientKey := TNXXMPPOpenSSL.HMACSHA256(lSaltedPassword, 'Client Key');
  lClientFinalWithoutProof := 'c=biws,r=' + lNonce;
  lAuthMessage := FClientFirstBare + ',' + AServerFirst + ',' +
    lClientFinalWithoutProof;
  lClientSignature := TNXXMPPOpenSSL.HMACSHA256(
    TNXXMPPOpenSSL.SHA256(lClientKey), lAuthMessage);
  SetLength(lClientProof, Length(lClientKey));
  for lIndex := 1 to Length(lClientKey) do
    lClientProof[lIndex] := AnsiChar(Ord(lClientKey[lIndex]) xor
      Ord(lClientSignature[lIndex]));
  lServerKey := TNXXMPPOpenSSL.HMACSHA256(lSaltedPassword, 'Server Key');
  FExpectedServerSignature := TNXXMPPOpenSSL.HMACSHA256(lServerKey,
    lAuthMessage);
  FillChar(Pointer(lSaltedPassword)^, Length(lSaltedPassword), 0);
  FillChar(Pointer(lClientKey)^, Length(lClientKey), 0);
  FillChar(Pointer(lServerKey)^, Length(lServerKey), 0);
  Result := lClientFinalWithoutProof + ',p=' + EncodeBase64(lClientProof);
  FillChar(Pointer(lClientProof)^, Length(lClientProof), 0);
end;

procedure TNXXMPPSCRAMSHA256.VerifyServerFinal(
  const AServerFinal: RawByteString);
var
  lError: RawByteString;
  lSignature: RawByteString;
begin
  lError := FieldValue(AServerFinal, 'e');
  if lError <> '' then
    raise ENXXMPPError.Create(xesAuthentication, 'scram-server-error',
      'The SCRAM server rejected authentication.');
  lSignature := FieldValue(AServerFinal, 'v');
  if lSignature = '' then
    raise ENXXMPPError.Create(xesAuthentication, 'missing-scram-signature',
      'The SCRAM server-final message lacks a verifier.');
  try
    lSignature := DecodeBase64(lSignature);
  except
    raise ENXXMPPError.Create(xesAuthentication, 'invalid-scram-signature',
      'The SCRAM server verifier is not valid Base64.');
  end;
  if not TNXXMPPOpenSSL.ConstantTimeEquals(lSignature,
    FExpectedServerSignature) then
    raise ENXXMPPError.Create(xesAuthentication, 'scram-signature-mismatch',
      'The SCRAM server signature does not match.');
  FExpectedServerSignature := '';
end;

end.

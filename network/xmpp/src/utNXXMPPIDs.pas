(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXXMPPIDs;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils, obNXOpenSSLCrypto;

function NXXMPPCreateID: UTF8String;

implementation

function ByteHex(AValue: Byte): UTF8String;
const
  cHex: PAnsiChar = '0123456789abcdef';
begin
  Result := UTF8String(cHex[AValue shr 4] + cHex[AValue and $0F]);
end;

function NXXMPPCreateID: UTF8String;
var
  lBytes: RawByteString;
  lIndex: Integer;
begin
  lBytes := TNXOpenSSLCrypto.RandomBytes(16);
  Byte(lBytes[7]) := (Byte(lBytes[7]) and $0F) or $40;
  Byte(lBytes[9]) := (Byte(lBytes[9]) and $3F) or $80;
  Result := '';
  for lIndex := 1 to 16 do
  begin
    Result := Result + ByteHex(Byte(lBytes[lIndex]));
    if lIndex in [4, 6, 8, 10] then
      Result := Result + '-';
  end;
end;

end.

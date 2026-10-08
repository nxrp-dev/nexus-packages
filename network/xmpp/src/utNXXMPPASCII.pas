(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXXMPPASCII;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils;

function NXXMPPASCIIToLower(const AValue: UTF8String): UTF8String;
function NXXMPPIsASCIIIdentifier(const AValue: UTF8String): Boolean;
function NXXMPPIsASCIIText(const AValue: UTF8String): Boolean;

implementation

function NXXMPPASCIIToLower(const AValue: UTF8String): UTF8String;
var
  lIndex: Integer;
begin
  Result := AValue;
  for lIndex := 1 to Length(Result) do
    if Result[lIndex] in ['A'..'Z'] then
      Result[lIndex] := AnsiChar(Ord(Result[lIndex]) +
        (Ord('a') - Ord('A')));
end;

function NXXMPPIsASCIIIdentifier(const AValue: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  Result := False;
  if AValue = '' then
    Exit;
  for lIndex := 1 to Length(AValue) do
    if (Ord(AValue[lIndex]) < 33) or (Ord(AValue[lIndex]) > 126) then
      Exit;
  Result := True;
end;

function NXXMPPIsASCIIText(const AValue: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  Result := False;
  for lIndex := 1 to Length(AValue) do
    if (Ord(AValue[lIndex]) < 32) or (Ord(AValue[lIndex]) > 126) then
      Exit;
  Result := True;
end;

end.

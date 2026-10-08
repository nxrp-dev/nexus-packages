(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXXMPPXML;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils;

function NXXMPPEscapeText(const AValue: UTF8String): UTF8String;
function NXXMPPEscapeAttribute(const AValue: UTF8String): UTF8String;

implementation

function NXXMPPEscapeText(const AValue: UTF8String): UTF8String;
var
  lIndex: Integer;
begin
  Result := '';
  for lIndex := 1 to Length(AValue) do
    case AValue[lIndex] of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
    else
      Result := Result + AValue[lIndex];
    end;
end;

function NXXMPPEscapeAttribute(const AValue: UTF8String): UTF8String;
var
  lIndex: Integer;
begin
  Result := '';
  for lIndex := 1 to Length(AValue) do
    case AValue[lIndex] of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&apos;';
    else
      Result := Result + AValue[lIndex];
    end;
end;

end.

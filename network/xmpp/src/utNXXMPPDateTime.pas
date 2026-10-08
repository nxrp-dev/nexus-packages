(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXXMPPDateTime;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils, DateUtils;

function NXXMPPTryParseTimestamp(const AValue: UTF8String;
  out ADateTime: TDateTime): Boolean;
function NXXMPPFormatTimestamp(ADateTime: TDateTime): UTF8String;

implementation

function NXXMPPTryParseTimestamp(const AValue: UTF8String;
  out ADateTime: TDateTime): Boolean;
begin
  ADateTime := 0;
  Result := (AValue <> '') and TryISO8601ToDate(string(AValue),
    ADateTime, True);
end;

function NXXMPPFormatTimestamp(ADateTime: TDateTime): UTF8String;
begin
  Result := UTF8String(DateToISO8601(ADateTime, True));
end;

end.

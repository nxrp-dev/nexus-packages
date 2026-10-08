(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPNegotiation;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPAuthenticationMechanism = (xamNone, xamSCRAMSHA256, xamPlain);

  TNXXMPPNegotiation = class
  public
    class function OffersStartTLS(const AFeatures: UTF8String): Boolean; static;
    class function OffersBinding(const AFeatures: UTF8String): Boolean; static;
    class function OffersStreamManagement(
      const AFeatures: UTF8String): Boolean; static;
    class function SelectAuthentication(const AFeatures: UTF8String;
      AAllowPlain, ASecure: Boolean): TNXXMPPAuthenticationMechanism; static;
  end;

implementation

class function TNXXMPPNegotiation.OffersStartTLS(
  const AFeatures: UTF8String): Boolean;
begin
  Result := (Pos('urn:ietf:params:xml:ns:xmpp-tls', string(AFeatures)) > 0) and
    (Pos('starttls', string(AFeatures)) > 0);
end;

class function TNXXMPPNegotiation.OffersBinding(
  const AFeatures: UTF8String): Boolean;
begin
  Result := Pos('urn:ietf:params:xml:ns:xmpp-bind',
    string(AFeatures)) > 0;
end;

class function TNXXMPPNegotiation.OffersStreamManagement(
  const AFeatures: UTF8String): Boolean;
begin
  Result := Pos('urn:xmpp:sm:3', string(AFeatures)) > 0;
end;

class function TNXXMPPNegotiation.SelectAuthentication(
  const AFeatures: UTF8String; AAllowPlain,
  ASecure: Boolean): TNXXMPPAuthenticationMechanism;
begin
  if Pos('SCRAM-SHA-256', string(AFeatures)) > 0 then
    Exit(xamSCRAMSHA256);
  if AAllowPlain and ASecure and
    (Pos('>PLAIN<', string(AFeatures)) > 0) then
    Exit(xamPlain);
  Result := xamNone;
end;

end.

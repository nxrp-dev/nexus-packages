(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPJID;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPError, tpNXXMPPTypes, utNXXMPPASCII;

type
  TNXXMPPJID = class
  private
    FDomainPart: UTF8String;
    FLocalPart: UTF8String;
    FResourcePart: UTF8String;
    FHasLocalPart: Boolean;
    FHasResourcePart: Boolean;
    procedure Parse(const AValue: UTF8String);
  public
    constructor Create(const AValue: UTF8String);
    function Bare: UTF8String;
    function Equals(AOther: TNXXMPPJID): Boolean; reintroduce;
    function ToString: UTF8String; reintroduce;
    property DomainPart: UTF8String read FDomainPart;
    property HasLocalPart: Boolean read FHasLocalPart;
    property HasResourcePart: Boolean read FHasResourcePart;
    property LocalPart: UTF8String read FLocalPart;
    property ResourcePart: UTF8String read FResourcePart;
  end;

implementation

const
  cMaximumPartBytes = 1023;

procedure CheckPartLength(const AName: string; const AValue: UTF8String);
begin
  if Length(UTF8String(AValue)) > cMaximumPartBytes then
    raise ENXXMPPError.Create(xesConfiguration, 'jid-part-too-long',
      'The JID ' + AName + ' exceeds 1023 ASCII bytes.');
end;

function IsIPLiteral(const AValue: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  Result := (Length(AValue) >= 4) and (AValue[1] = '[') and
    (AValue[Length(AValue)] = ']');
  if not Result then
    Exit;
  for lIndex := 2 to Length(AValue) - 1 do
    if not (AValue[lIndex] in ['0'..'9', 'a'..'f', 'A'..'F', ':', '.']) then
      Exit(False);
end;

procedure ValidateDomainPart(const AValue: UTF8String);
var
  lIndex: Integer;
  lLabelLength: Integer;
begin
  if not NXXMPPIsASCIIIdentifier(AValue) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-domainpart',
      'The JID domainpart must contain printable ASCII characters only.');
  if IsIPLiteral(AValue) then
    Exit;
  lLabelLength := 0;
  for lIndex := 1 to Length(AValue) do
    if AValue[lIndex] = '.' then
    begin
      if (lLabelLength = 0) or (AValue[lIndex - 1] = '-') then
        raise ENXXMPPError.Create(xesConfiguration, 'invalid-domainpart',
          'The JID domainpart contains an invalid domain label.');
      lLabelLength := 0;
    end
    else
    begin
      if not (AValue[lIndex] in ['a'..'z', 'A'..'Z', '0'..'9', '-']) or
        ((lLabelLength = 0) and (AValue[lIndex] = '-')) then
        raise ENXXMPPError.Create(xesConfiguration, 'invalid-domainpart',
          'The JID domainpart contains an invalid domain label.');
      Inc(lLabelLength);
      if lLabelLength > 63 then
        raise ENXXMPPError.Create(xesConfiguration, 'invalid-domainpart',
          'A JID domain label exceeds 63 ASCII characters.');
    end;
  if (lLabelLength = 0) or (AValue[Length(AValue)] = '-') then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-domainpart',
      'The JID domainpart contains an invalid domain label.');
end;

procedure ValidateLocalPart(const AValue: UTF8String);
const
  cProhibited = ['"', '&', '''', '/', ':', '<', '>', '@'];
var
  lIndex: Integer;
begin
  if (AValue = '') or not NXXMPPIsASCIIIdentifier(AValue) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-localpart',
      'The JID localpart must contain printable ASCII characters without spaces.');
  for lIndex := 1 to Length(AValue) do
    if AValue[lIndex] in cProhibited then
      raise ENXXMPPError.Create(xesConfiguration, 'invalid-localpart',
        'The JID localpart contains an XMPP-prohibited character.');
end;

constructor TNXXMPPJID.Create(const AValue: UTF8String);
begin
  inherited Create;
  Parse(AValue);
end;

procedure TNXXMPPJID.Parse(const AValue: UTF8String);
var
  lAtPosition: Integer;
  lDomainSource: UTF8String;
  lPreResource: UTF8String;
  lSlashPosition: Integer;
begin
  if AValue = '' then
    raise ENXXMPPError.Create(xesConfiguration, 'empty-jid',
      'A JID must not be empty.');
  lSlashPosition := Pos('/', AValue);
  if lSlashPosition > 0 then
  begin
    FHasResourcePart := True;
    lPreResource := Copy(AValue, 1, lSlashPosition - 1);
    FResourcePart := Copy(AValue, lSlashPosition + 1, MaxInt);
    if (FResourcePart = '') or not NXXMPPIsASCIIText(FResourcePart) then
      raise ENXXMPPError.Create(xesConfiguration, 'invalid-resourcepart',
        'The JID resourcepart must contain printable ASCII characters only.');
    CheckPartLength('resourcepart', FResourcePart);
  end
  else
    lPreResource := AValue;

  lAtPosition := Pos('@', lPreResource);
  if lAtPosition > 0 then
  begin
    if Pos('@', Copy(lPreResource, lAtPosition + 1, MaxInt)) > 0 then
      raise ENXXMPPError.Create(xesConfiguration, 'invalid-jid',
        'A JID contains more than one localpart separator.');
    FHasLocalPart := True;
    FLocalPart := Copy(lPreResource, 1, lAtPosition - 1);
    lDomainSource := Copy(lPreResource, lAtPosition + 1, MaxInt);
    FLocalPart := NXXMPPASCIIToLower(FLocalPart);
    ValidateLocalPart(FLocalPart);
    CheckPartLength('localpart', FLocalPart);
  end
  else
    lDomainSource := lPreResource;

  if lDomainSource = '' then
    raise ENXXMPPError.Create(xesConfiguration, 'empty-domainpart',
      'A JID domainpart must not be empty.');
  ValidateDomainPart(lDomainSource);
  FDomainPart := NXXMPPASCIIToLower(lDomainSource);
  CheckPartLength('domainpart', FDomainPart);
end;

function TNXXMPPJID.Bare: UTF8String;
begin
  if FHasLocalPart then
    Result := FLocalPart + '@' + FDomainPart
  else
    Result := FDomainPart;
end;

function TNXXMPPJID.Equals(AOther: TNXXMPPJID): Boolean;
begin
  Result := Assigned(AOther) and (ToString = AOther.ToString);
end;

function TNXXMPPJID.ToString: UTF8String;
begin
  Result := Bare;
  if FHasResourcePart then
    Result := Result + '/' + FResourcePart;
end;

end.

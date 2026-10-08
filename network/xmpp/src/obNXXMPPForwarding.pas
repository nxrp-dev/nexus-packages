(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPForwarding;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, obNXXMPPMessage, obNXXMPPStanza,
  tpNXXMPPMessageTypes, utNXXMPPDateTime, utNXXMPPDOM;

type
  TNXXMPPForwarded = class
  private
    FDelay: TNXXMPPDelay;
    FMessage: TNXXMPPMessage;
    FValid: Boolean;
    FValidationError: UTF8String;
  public
    destructor Destroy; override;
    property Delay: TNXXMPPDelay read FDelay;
    property Message: TNXXMPPMessage read FMessage;
    property Valid: Boolean read FValid;
    property ValidationError: UTF8String read FValidationError;
  end;

  TNXXMPPForwarding = class
  public
    class function Decode(AForwardedElement: TDOMElement;
      AContext: TNXXMPPMessageDeliveryContext;
      AMaximumDepth: Integer = 1): TNXXMPPForwarded; static;
  end;

implementation

function NXXMPPForwardingDepth(ANode: TDOMNode;
  ACurrentDepth: Integer): Integer;
var
  lChild: TDOMElement;
  lChildDepth: Integer;
  lDepth: Integer;
begin
  Result := ACurrentDepth;
  lChild := NXXMPPFirstChildElement(ANode);
  while Assigned(lChild) do
  begin
    lDepth := ACurrentDepth;
    if NXXMPPElementMatches(lChild, 'urn:xmpp:forward:0', 'forwarded') then
      Inc(lDepth);
    lChildDepth := NXXMPPForwardingDepth(lChild, lDepth);
    if lChildDepth > Result then
      Result := lChildDepth;
    lChild := NXXMPPNextSiblingElement(lChild);
  end;
end;

destructor TNXXMPPForwarded.Destroy;
begin
  FMessage.Free;
  inherited Destroy;
end;

class function TNXXMPPForwarding.Decode(AForwardedElement: TDOMElement;
  AContext: TNXXMPPMessageDeliveryContext;
  AMaximumDepth: Integer): TNXXMPPForwarded;
var
  lChild: TDOMElement;
  lMessageCount: Integer;
  lStanza: TNXXMPPStanza;
begin
  Result := TNXXMPPForwarded.Create;
  Result.FValid := False;
  if not NXXMPPElementMatches(AForwardedElement, 'urn:xmpp:forward:0',
    'forwarded') then
  begin
    Result.FValidationError := 'The wrapper is not an XEP-0297 forward.';
    Exit;
  end;
  if (AMaximumDepth < 1) or
    (NXXMPPForwardingDepth(AForwardedElement, 1) > AMaximumDepth) then
  begin
    Result.FValidationError := 'The forwarding depth exceeds its limit.';
    Exit;
  end;
  lMessageCount := 0;
  lChild := NXXMPPFirstChildElement(AForwardedElement);
  while Assigned(lChild) do
  begin
    if NXXMPPElementMatches(lChild, 'urn:xmpp:delay', 'delay') then
    begin
      if Result.FDelay.Present then
      begin
        Result.FValidationError := 'A forwarded stanza has multiple delays.';
        Exit;
      end;
      Result.FDelay.Present := True;
      Result.FDelay.Stamp := UTF8Encode(lChild.GetAttribute('stamp'));
      Result.FDelay.Valid := NXXMPPTryParseTimestamp(Result.FDelay.Stamp,
        Result.FDelay.Timestamp);
      if not Result.FDelay.Valid then
      begin
        Result.FValidationError := 'A forwarded delay timestamp is invalid.';
        Exit;
      end;
      Result.FDelay.FromJID := UTF8Encode(lChild.GetAttribute('from'));
      Result.FDelay.Reason := NXXMPPDirectText(lChild);
    end
    else if NXXMPPElementMatches(lChild, 'jabber:client', 'message') then
    begin
      Inc(lMessageCount);
      if lMessageCount > 1 then
      begin
        Result.FValidationError :=
          'A forwarded wrapper contains more than one message.';
        Exit;
      end;
      lStanza := TNXXMPPStanza.Create(NXXMPPElementXML(lChild), '');
      try
        Result.FMessage := TNXXMPPMessage.Create(lStanza, AContext);
      finally
        lStanza.Free;
      end;
    end;
    lChild := NXXMPPNextSiblingElement(lChild);
  end;
  if lMessageCount <> 1 then
  begin
    Result.FValidationError :=
      'A forwarded wrapper must contain exactly one message.';
    Exit;
  end;
  Result.FValid := Result.FMessage.Valid;
  if not Result.FValid then
    Result.FValidationError := Result.FMessage.ValidationError;
end;

end.

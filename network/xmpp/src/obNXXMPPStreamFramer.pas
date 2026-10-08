(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPStreamFramer;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPStreamFramer = class
  private
    FBuffer: RawByteString;
    FMaximumNestingDepth: Integer;
    FMaximumStanzaBytes: Integer;
    FStreamNamespaceAttributes: UTF8String;
    FStreamOpen: Boolean;
    function ExtractNamespaceAttributes(
      const AOpening: RawByteString): UTF8String;
    function FindTagEnd(AStart: Integer): Integer;
    function FindElementEnd: Integer;
    procedure RemoveLeadingWhitespace;
    procedure RejectProhibitedMarkup(const AValue: RawByteString);
  public
    constructor Create;
    procedure Feed(const AData: RawByteString; AFrames: TStrings);
    procedure Reset;
    property MaximumNestingDepth: Integer read FMaximumNestingDepth
      write FMaximumNestingDepth;
    property MaximumStanzaBytes: Integer read FMaximumStanzaBytes
      write FMaximumStanzaBytes;
    property StreamNamespaceAttributes: UTF8String
      read FStreamNamespaceAttributes;
    property StreamOpen: Boolean read FStreamOpen;
  end;

implementation

function IsWhitespace(AValue: AnsiChar): Boolean;
begin
  Result := AValue in [#9, #10, #13, ' '];
end;

function StartsText(const AValue: RawByteString; APosition: Integer;
  const AText: RawByteString): Boolean;
begin
  Result := Copy(AValue, APosition, Length(AText)) = AText;
end;

constructor TNXXMPPStreamFramer.Create;
begin
  inherited Create;
  FMaximumNestingDepth := cNXXMPPDefaultMaxNestingDepth;
  FMaximumStanzaBytes := cNXXMPPDefaultMaxStanzaBytes;
end;

procedure TNXXMPPStreamFramer.Reset;
begin
  FBuffer := '';
  FStreamNamespaceAttributes := '';
  FStreamOpen := False;
end;

procedure TNXXMPPStreamFramer.RemoveLeadingWhitespace;
var
  lIndex: Integer;
begin
  lIndex := 1;
  while (lIndex <= Length(FBuffer)) and IsWhitespace(FBuffer[lIndex]) do
    Inc(lIndex);
  if lIndex > 1 then
    Delete(FBuffer, 1, lIndex - 1);
end;

procedure TNXXMPPStreamFramer.RejectProhibitedMarkup(
  const AValue: RawByteString);
var
  lUpper: string;
begin
  lUpper := UpperCase(string(AValue));
  if (Pos('<!DOCTYPE', lUpper) > 0) or (Pos('<!ENTITY', lUpper) > 0) then
    raise ENXXMPPError.Create(xesStream, 'prohibited-xml',
      'DTD and entity declarations are prohibited in an XMPP stream.');
  if Pos('<!--', lUpper) > 0 then
    raise ENXXMPPError.Create(xesStream, 'prohibited-xml',
      'XML comments are not accepted in the XMPP stream.');
  if Pos('<?', lUpper) > 0 then
    raise ENXXMPPError.Create(xesStream, 'prohibited-xml',
      'XML processing instructions are not accepted in the XMPP stream.');
end;

function TNXXMPPStreamFramer.FindTagEnd(AStart: Integer): Integer;
var
  lIndex: Integer;
  lQuote: AnsiChar;
begin
  lQuote := #0;
  for lIndex := AStart to Length(FBuffer) do
  begin
    if lQuote <> #0 then
    begin
      if FBuffer[lIndex] = lQuote then
        lQuote := #0;
    end
    else if FBuffer[lIndex] in ['''', '"'] then
      lQuote := FBuffer[lIndex]
    else if FBuffer[lIndex] = '>' then
      Exit(lIndex);
  end;
  Result := 0;
end;

function TNXXMPPStreamFramer.ExtractNamespaceAttributes(
  const AOpening: RawByteString): UTF8String;
var
  lAttributeEnd: Integer;
  lAttributeName: RawByteString;
  lAttributeStart: Integer;
  lIndex: Integer;
  lQuote: AnsiChar;
begin
  Result := '';
  lIndex := 2;
  while (lIndex <= Length(AOpening)) and
    not IsWhitespace(AOpening[lIndex]) and (AOpening[lIndex] <> '>') do
    Inc(lIndex);
  while lIndex <= Length(AOpening) do
  begin
    while (lIndex <= Length(AOpening)) and IsWhitespace(AOpening[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AOpening)) or (AOpening[lIndex] = '>') then
      Break;
    lAttributeStart := lIndex;
    while (lIndex <= Length(AOpening)) and
      not IsWhitespace(AOpening[lIndex]) and
      not (AOpening[lIndex] in ['=', '>']) do
      Inc(lIndex);
    lAttributeName := Copy(AOpening, lAttributeStart, lIndex - lAttributeStart);
    while (lIndex <= Length(AOpening)) and IsWhitespace(AOpening[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AOpening)) or (AOpening[lIndex] <> '=') then
      raise ENXXMPPError.Create(xesStream, 'malformed-stream-opening',
        'The XMPP stream opening contains a malformed attribute.');
    Inc(lIndex);
    while (lIndex <= Length(AOpening)) and IsWhitespace(AOpening[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AOpening)) or
      not (AOpening[lIndex] in ['''', '"']) then
      raise ENXXMPPError.Create(xesStream, 'malformed-stream-opening',
        'The XMPP stream opening contains an unquoted attribute.');
    lQuote := AOpening[lIndex];
    Inc(lIndex);
    while (lIndex <= Length(AOpening)) and (AOpening[lIndex] <> lQuote) do
      Inc(lIndex);
    if lIndex > Length(AOpening) then
      raise ENXXMPPError.Create(xesStream, 'malformed-stream-opening',
        'The XMPP stream opening contains an unterminated attribute.');
    lAttributeEnd := lIndex;
    Inc(lIndex);
    if (lAttributeName = 'xmlns') or
      (Copy(lAttributeName, 1, 6) = 'xmlns:') then
      Result := Result + ' ' + UTF8String(Copy(AOpening, lAttributeStart,
        lAttributeEnd - lAttributeStart + 1));
  end;
end;

function TNXXMPPStreamFramer.FindElementEnd: Integer;
var
  lDepth: Integer;
  lEnd: Integer;
  lIndex: Integer;
  lSelfClosing: Boolean;
  lTagIndex: Integer;
begin
  lDepth := 0;
  lIndex := 1;
  while lIndex <= Length(FBuffer) do
  begin
    if FBuffer[lIndex] <> '<' then
    begin
      Inc(lIndex);
      Continue;
    end;
    if StartsText(FBuffer, lIndex, '<![CDATA[') then
    begin
      lEnd := Pos(']]>', Copy(FBuffer, lIndex + 9, MaxInt));
      if lEnd = 0 then
        Exit(0);
      lIndex := lIndex + 8 + lEnd + 2;
      Continue;
    end;
    if StartsText(FBuffer, lIndex, '<!') or
      StartsText(FBuffer, lIndex, '<?') then
      raise ENXXMPPError.Create(xesStream, 'prohibited-xml',
        'Unsupported XML markup is prohibited in an XMPP stanza.');
    lEnd := FindTagEnd(lIndex);
    if lEnd = 0 then
      Exit(0);
    if StartsText(FBuffer, lIndex, '</') then
    begin
      Dec(lDepth);
      if lDepth < 0 then
        raise ENXXMPPError.Create(xesStream, 'malformed-xml',
          'The XMPP stream contains an unexpected closing tag.');
      if lDepth = 0 then
        Exit(lEnd);
    end
    else
    begin
      lTagIndex := lEnd - 1;
      while (lTagIndex > lIndex) and IsWhitespace(FBuffer[lTagIndex]) do
        Dec(lTagIndex);
      lSelfClosing := FBuffer[lTagIndex] = '/';
      if not lSelfClosing then
      begin
        Inc(lDepth);
        if lDepth > FMaximumNestingDepth then
          raise ENXXMPPError.Create(xesStream, 'stanza-too-deep',
            'The XMPP stanza exceeds the configured nesting limit.');
      end
      else if lDepth = 0 then
        Exit(lEnd);
    end;
    lIndex := lEnd + 1;
  end;
  Result := 0;
end;

procedure TNXXMPPStreamFramer.Feed(const AData: RawByteString;
  AFrames: TStrings);
var
  lEnd: Integer;
  lFrame: RawByteString;
begin
  if not Assigned(AFrames) then
    raise ENXXMPPError.Create(xesStream, 'missing-frame-target',
      'A frame target is required.');
  FBuffer := FBuffer + AData;
  if Length(FBuffer) > FMaximumStanzaBytes then
    raise ENXXMPPError.Create(xesStream, 'stanza-too-large',
      'The buffered XMPP input exceeds the configured stanza limit.');
  while FBuffer <> '' do
  begin
    RemoveLeadingWhitespace;
    if FBuffer = '' then
      Exit;
    if not FStreamOpen then
    begin
      if (Length(FBuffer) < Length('<?xml')) and
        (FBuffer = Copy('<?xml', 1, Length(FBuffer))) then
        Exit;
      if StartsText(FBuffer, 1, '<?xml') then
      begin
        lEnd := Pos('?>', FBuffer);
        if lEnd = 0 then
          Exit;
        Delete(FBuffer, 1, lEnd + 1);
        RemoveLeadingWhitespace;
        if FBuffer = '' then
          Exit;
      end;
      RejectProhibitedMarkup(FBuffer);
      if Copy(FBuffer, 1, 15) <> '<stream:stream ' then
        Exit;
      lEnd := FindTagEnd(1);
      if lEnd = 0 then
        Exit;
      lFrame := Copy(FBuffer, 1, lEnd);
      if Pos('http://etherx.jabber.org/streams', string(lFrame)) = 0 then
        raise ENXXMPPError.Create(xesStream, 'invalid-stream-namespace',
          'The stream opening does not declare the XMPP streams namespace.');
      FStreamNamespaceAttributes := ExtractNamespaceAttributes(lFrame);
      FStreamOpen := True;
      AFrames.Add(string(lFrame));
      Delete(FBuffer, 1, lEnd);
      Continue;
    end;
    RejectProhibitedMarkup(FBuffer);
    if StartsText(FBuffer, 1, '</stream:stream') then
    begin
      lEnd := FindTagEnd(1);
      if lEnd = 0 then
        Exit;
      lFrame := Copy(FBuffer, 1, lEnd);
      AFrames.Add(string(lFrame));
      Delete(FBuffer, 1, lEnd);
      FStreamOpen := False;
      Continue;
    end;
    if FBuffer[1] <> '<' then
      raise ENXXMPPError.Create(xesStream, 'malformed-stream',
        'Non-whitespace text appeared between XMPP stanzas.');
    lEnd := FindElementEnd;
    if lEnd = 0 then
      Exit;
    lFrame := Copy(FBuffer, 1, lEnd);
    RejectProhibitedMarkup(lFrame);
    AFrames.Add(string(lFrame));
    Delete(FBuffer, 1, lEnd);
  end;
end;

end.

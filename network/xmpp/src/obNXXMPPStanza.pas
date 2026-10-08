(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPStanza;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, XMLRead, XMLWrite, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPStanza = class
  private
    FChildLocalName: UTF8String;
    FChildNamespaceURI: UTF8String;
    FDocument: TXMLDocument;
    FFrom: UTF8String;
    FID: UTF8String;
    FIQType: TNXXMPPIQType;
    FKind: TNXXMPPStanzaKind;
    FLocalName: UTF8String;
    FNamespaceURI: UTF8String;
    FRawXML: UTF8String;
    FRoot: TDOMElement;
    FTo: UTF8String;
    FTypeValue: UTF8String;
    procedure CaptureQNames(const ANamespaceAttributes: UTF8String);
    function FindFirstElementChild(AParent: TDOMNode): TDOMElement;
    procedure Parse(const ANamespaceAttributes: UTF8String);
  public
    constructor Create(const ARawXML, ANamespaceAttributes: UTF8String);
    destructor Destroy; override;
    function Attribute(const AName: UTF8String): UTF8String;
    function ChildXML: UTF8String;
    function TextContent: UTF8String;
    property ChildLocalName: UTF8String read FChildLocalName;
    property ChildNamespaceURI: UTF8String read FChildNamespaceURI;
    property FromJID: UTF8String read FFrom;
    property ID: UTF8String read FID;
    property IQType: TNXXMPPIQType read FIQType;
    property Kind: TNXXMPPStanzaKind read FKind;
    property LocalName: UTF8String read FLocalName;
    property NamespaceURI: UTF8String read FNamespaceURI;
    property RawXML: UTF8String read FRawXML;
    property Root: TDOMElement read FRoot;
    property ToJID: UTF8String read FTo;
    property TypeValue: UTF8String read FTypeValue;
  end;

implementation

function IsXMLWhitespace(AValue: AnsiChar): Boolean;
begin
  Result := AValue in [#9, #10, #13, ' '];
end;

procedure ParseStartTag(const AXML: UTF8String; AStart: Integer;
  AMappings: TStringList; out ALocalName, ANamespaceURI: UTF8String;
  out ATagEnd: Integer);
var
  lAttributeName: UTF8String;
  lAttributeValue: UTF8String;
  lIndex: Integer;
  lName: UTF8String;
  lNameStart: Integer;
  lPrefix: UTF8String;
  lQuote: AnsiChar;
  lSeparator: Integer;
  lValueStart: Integer;
begin
  ALocalName := '';
  ANamespaceURI := '';
  ATagEnd := 0;
  if (AStart < 1) or (AStart > Length(AXML)) or (AXML[AStart] <> '<') then
    Exit;
  lIndex := AStart + 1;
  lNameStart := lIndex;
  while (lIndex <= Length(AXML)) and not IsXMLWhitespace(AXML[lIndex]) and
    not (AXML[lIndex] in ['/', '>']) do
    Inc(lIndex);
  lName := Copy(AXML, lNameStart, lIndex - lNameStart);
  while lIndex <= Length(AXML) do
  begin
    while (lIndex <= Length(AXML)) and IsXMLWhitespace(AXML[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AXML)) or (AXML[lIndex] = '>') then
      Break;
    if (AXML[lIndex] = '/') and (lIndex < Length(AXML)) and
      (AXML[lIndex + 1] = '>') then
    begin
      Inc(lIndex);
      Break;
    end;
    lNameStart := lIndex;
    while (lIndex <= Length(AXML)) and not IsXMLWhitespace(AXML[lIndex]) and
      not (AXML[lIndex] in ['=', '>']) do
      Inc(lIndex);
    lAttributeName := Copy(AXML, lNameStart, lIndex - lNameStart);
    while (lIndex <= Length(AXML)) and IsXMLWhitespace(AXML[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AXML)) or (AXML[lIndex] <> '=') then
      Exit;
    Inc(lIndex);
    while (lIndex <= Length(AXML)) and IsXMLWhitespace(AXML[lIndex]) do
      Inc(lIndex);
    if (lIndex > Length(AXML)) or not (AXML[lIndex] in ['''', '"']) then
      Exit;
    lQuote := AXML[lIndex];
    Inc(lIndex);
    lValueStart := lIndex;
    while (lIndex <= Length(AXML)) and (AXML[lIndex] <> lQuote) do
      Inc(lIndex);
    if lIndex > Length(AXML) then
      Exit;
    lAttributeValue := Copy(AXML, lValueStart, lIndex - lValueStart);
    Inc(lIndex);
    if lAttributeName = 'xmlns' then
      AMappings.Values['$default'] := string(lAttributeValue)
    else if Copy(lAttributeName, 1, 6) = 'xmlns:' then
      AMappings.Values[string(Copy(lAttributeName, 7, MaxInt))] :=
        string(lAttributeValue);
  end;
  if (lIndex <= Length(AXML)) and (AXML[lIndex] = '>') then
    ATagEnd := lIndex
  else
    Exit;
  lSeparator := Pos(':', lName);
  if lSeparator > 0 then
  begin
    lPrefix := Copy(lName, 1, lSeparator - 1);
    ALocalName := Copy(lName, lSeparator + 1, MaxInt);
    ANamespaceURI := UTF8String(AMappings.Values[string(lPrefix)]);
  end
  else
  begin
    ALocalName := lName;
    ANamespaceURI := UTF8String(AMappings.Values['$default']);
  end;
end;

constructor TNXXMPPStanza.Create(const ARawXML,
  ANamespaceAttributes: UTF8String);
begin
  inherited Create;
  FRawXML := ARawXML;
  Parse(ANamespaceAttributes);
end;

destructor TNXXMPPStanza.Destroy;
begin
  FDocument.Free;
  inherited Destroy;
end;

function TNXXMPPStanza.FindFirstElementChild(AParent: TDOMNode): TDOMElement;
var
  lNode: TDOMNode;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;
  lNode := AParent.FirstChild;
  while Assigned(lNode) do
  begin
    if lNode is TDOMElement then
      Exit(TDOMElement(lNode));
    lNode := lNode.NextSibling;
  end;
end;

procedure TNXXMPPStanza.Parse(const ANamespaceAttributes: UTF8String);
var
  lChild: TDOMElement;
  lMemory: TMemoryStream;
  lWrapper: UTF8String;
begin
  lWrapper := '<nxwrapper' + ANamespaceAttributes + '>' + FRawXML +
    '</nxwrapper>';
  lMemory := TMemoryStream.Create;
  try
    if Length(lWrapper) > 0 then
      lMemory.WriteBuffer(PAnsiChar(lWrapper)^, Length(lWrapper));
    lMemory.Position := 0;
    try
      ReadXMLFile(FDocument, lMemory);
    except
      on E: Exception do
        raise ENXXMPPError.Create(xesStream, 'malformed-stanza',
          string(UTF8String('The XMPP stanza is not well-formed XML: ') +
            UTF8String(E.Message)));
    end;
  finally
    lMemory.Free;
  end;
  CaptureQNames(ANamespaceAttributes);
  FRoot := FindFirstElementChild(FDocument.DocumentElement);
  if not Assigned(FRoot) then
    raise ENXXMPPError.Create(xesStream, 'empty-stanza',
      'The XMPP frame does not contain a stanza element.');
  if FLocalName = '' then
    FLocalName := UTF8String(FRoot.NodeName);
  FFrom := Attribute('from');
  FTo := Attribute('to');
  FID := Attribute('id');
  FTypeValue := Attribute('type');
  if FLocalName = 'message' then
    FKind := xskMessage
  else if FLocalName = 'presence' then
    FKind := xskPresence
  else if FLocalName = 'iq' then
    FKind := xskIQ
  else
    FKind := xskUnknown;
  FIQType := NXXMPPIQTypeFromString(string(FTypeValue));
  lChild := FindFirstElementChild(FRoot);
  if Assigned(lChild) then
  begin
    if FChildLocalName = '' then
      FChildLocalName := UTF8String(lChild.NodeName);
  end;
end;

procedure TNXXMPPStanza.CaptureQNames(
  const ANamespaceAttributes: UTF8String);
var
  lChildEnd: Integer;
  lChildStart: Integer;
  lIndex: Integer;
  lMappings: TStringList;
  lRootEnd: Integer;
  lUnusedLocalName: UTF8String;
  lUnusedNamespace: UTF8String;
  lWrapper: UTF8String;
begin
  lMappings := TStringList.Create;
  try
    lMappings.CaseSensitive := True;
    lMappings.NameValueSeparator := '=';
    lWrapper := '<nxwrapper' + ANamespaceAttributes + '/>';
    ParseStartTag(lWrapper, 1, lMappings, lUnusedLocalName,
      lUnusedNamespace, lRootEnd);
    ParseStartTag(FRawXML, 1, lMappings, FLocalName, FNamespaceURI, lRootEnd);
    if lRootEnd = 0 then
      Exit;
    lIndex := lRootEnd + 1;
    while lIndex <= Length(FRawXML) do
    begin
      while (lIndex <= Length(FRawXML)) and
        IsXMLWhitespace(FRawXML[lIndex]) do
        Inc(lIndex);
      if (lIndex > Length(FRawXML)) or
        (Copy(FRawXML, lIndex, 2) = '</') then
        Exit;
      if FRawXML[lIndex] = '<' then
      begin
        lChildStart := lIndex;
        ParseStartTag(FRawXML, lChildStart, lMappings, FChildLocalName,
          FChildNamespaceURI, lChildEnd);
        Exit;
      end;
      Inc(lIndex);
    end;
  finally
    lMappings.Free;
  end;
end;

{ The FPC 3.2.2 DOM builder retains the parsed tree but drops namespace
  metadata. CaptureQNames preserves the QName contract directly from the same
  validated bytes and namespace declarations. }

function TNXXMPPStanza.Attribute(const AName: UTF8String): UTF8String;
begin
  if Assigned(FRoot) then
    Result := UTF8Encode(FRoot.GetAttribute(UTF8Decode(AName)))
  else
    Result := '';
end;

function TNXXMPPStanza.TextContent: UTF8String;
begin
  if Assigned(FRoot) then
    Result := UTF8Encode(FRoot.TextContent)
  else
    Result := '';
end;

function TNXXMPPStanza.ChildXML: UTF8String;
var
  lChild: TDOMElement;
  lMemory: TMemoryStream;
begin
  Result := '';
  lChild := FindFirstElementChild(FRoot);
  if not Assigned(lChild) then
    Exit;
  lMemory := TMemoryStream.Create;
  try
    WriteXML(lChild, lMemory);
    SetLength(Result, lMemory.Size);
    if lMemory.Size > 0 then
    begin
      lMemory.Position := 0;
      lMemory.ReadBuffer(PAnsiChar(Result)^, lMemory.Size);
    end;
  finally
    lMemory.Free;
  end;
end;

end.

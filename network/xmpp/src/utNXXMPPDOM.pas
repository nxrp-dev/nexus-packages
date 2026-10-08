(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXXMPPDOM;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, XMLWrite;

function NXXMPPElementLocalName(AElement: TDOMElement): UTF8String;
function NXXMPPElementNamespaceURI(AElement: TDOMElement): UTF8String;
function NXXMPPElementMatches(AElement: TDOMElement;
  const ANamespaceURI, ALocalName: UTF8String): Boolean;
function NXXMPPFirstChildElement(AParent: TDOMNode): TDOMElement;
function NXXMPPNextSiblingElement(ANode: TDOMNode): TDOMElement;
function NXXMPPFindChild(AParent: TDOMNode; const ANamespaceURI,
  ALocalName: UTF8String): TDOMElement;
function NXXMPPDirectText(AElement: TDOMElement): UTF8String;
function NXXMPPElementXML(AElement: TDOMElement): UTF8String;

implementation

function NXXMPPElementLocalName(AElement: TDOMElement): UTF8String;
var
  lName: UTF8String;
  lSeparator: Integer;
begin
  Result := '';
  if not Assigned(AElement) then
    Exit;
  lName := UTF8Encode(AElement.NodeName);
  lSeparator := Pos(':', lName);
  if lSeparator > 0 then
    Result := Copy(lName, lSeparator + 1, MaxInt)
  else
    Result := lName;
end;

function NXXMPPElementNamespaceURI(AElement: TDOMElement): UTF8String;
var
  lElement: TDOMElement;
  lName: UTF8String;
  lPrefix: UTF8String;
  lSeparator: Integer;
begin
  Result := '';
  if not Assigned(AElement) then
    Exit;
  lName := UTF8Encode(AElement.NodeName);
  lSeparator := Pos(':', lName);
  if lSeparator > 0 then
    lPrefix := Copy(lName, 1, lSeparator - 1)
  else
    lPrefix := '';
  lElement := AElement;
  while Assigned(lElement) do
  begin
    if lPrefix = '' then
      Result := UTF8Encode(lElement.GetAttribute('xmlns'))
    else
      Result := UTF8Encode(lElement.GetAttribute(UTF8Decode(
        UTF8String('xmlns:') + lPrefix)));
    if Result <> '' then
      Exit;
    if lElement.ParentNode is TDOMElement then
      lElement := TDOMElement(lElement.ParentNode)
    else
      lElement := nil;
  end;
end;

function NXXMPPElementMatches(AElement: TDOMElement;
  const ANamespaceURI, ALocalName: UTF8String): Boolean;
begin
  Result := Assigned(AElement) and
    (NXXMPPElementLocalName(AElement) = ALocalName) and
    (NXXMPPElementNamespaceURI(AElement) = ANamespaceURI);
end;

function NXXMPPFirstChildElement(AParent: TDOMNode): TDOMElement;
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

function NXXMPPNextSiblingElement(ANode: TDOMNode): TDOMElement;
var
  lNode: TDOMNode;
begin
  Result := nil;
  if not Assigned(ANode) then
    Exit;
  lNode := ANode.NextSibling;
  while Assigned(lNode) do
  begin
    if lNode is TDOMElement then
      Exit(TDOMElement(lNode));
    lNode := lNode.NextSibling;
  end;
end;

function NXXMPPFindChild(AParent: TDOMNode; const ANamespaceURI,
  ALocalName: UTF8String): TDOMElement;
begin
  Result := NXXMPPFirstChildElement(AParent);
  while Assigned(Result) do
  begin
    if NXXMPPElementMatches(Result, ANamespaceURI, ALocalName) then
      Exit;
    Result := NXXMPPNextSiblingElement(Result);
  end;
end;

function NXXMPPDirectText(AElement: TDOMElement): UTF8String;
var
  lNode: TDOMNode;
begin
  Result := '';
  if not Assigned(AElement) then
    Exit;
  lNode := AElement.FirstChild;
  while Assigned(lNode) do
  begin
    if lNode.NodeType in [TEXT_NODE, CDATA_SECTION_NODE] then
      Result := Result + UTF8Encode(lNode.NodeValue);
    lNode := lNode.NextSibling;
  end;
end;

function NXXMPPElementXML(AElement: TDOMElement): UTF8String;
var
  lMemory: TMemoryStream;
begin
  Result := '';
  if not Assigned(AElement) then
    Exit;
  lMemory := TMemoryStream.Create;
  try
    WriteXML(AElement, lMemory);
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

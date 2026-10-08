(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPRoster;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, SyncObjs, obNXXMPPDispatcher, obNXXMPPModule,
  obNXXMPPRequestManager, obNXXMPPStanza, tpNXXMPPTypes, utNXXMPPXML;

type
  TNXXMPPRosterChangedEvent = procedure(ASender: TObject;
    const AJID, ASubscription: UTF8String) of object;

  TNXXMPPRosterModule = class(TNXXMPPModule)
  private
    FCriticalSection: TCriticalSection;
    FItems: TStringList;
    FOnChanged: TNXXMPPRosterChangedEvent;
    procedure ApplyQuery(AQuery: TDOMElement);
    procedure HandlePush(AStanza: TNXXMPPStanza);
    procedure UpdateItem(AItem: TDOMElement);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CompleteRequest(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    function Item(const AJID: UTF8String): UTF8String;
    function ItemSubscription(const AJID: UTF8String): UTF8String;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    class function RequestPayload: UTF8String; static;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    property OnChanged: TNXXMPPRosterChangedEvent read FOnChanged
      write FOnChanged;
  end;

implementation

constructor TNXXMPPRosterModule.Create;
begin
  inherited Create;
  FItems := TStringList.Create;
  FItems.CaseSensitive := True;
  FItems.NameValueSeparator := '=';
  FCriticalSection := TCriticalSection.Create;
end;

destructor TNXXMPPRosterModule.Destroy;
begin
  FCriticalSection.Free;
  FItems.Free;
  inherited Destroy;
end;

procedure TNXXMPPRosterModule.UpdateItem(AItem: TDOMElement);
var
  lIndex: Integer;
  lJID: UTF8String;
  lSubscription: UTF8String;
begin
  if not Assigned(AItem) then
    Exit;
  lJID := UTF8Encode(AItem.GetAttribute('jid'));
  if lJID = '' then
    Exit;
  lSubscription := UTF8Encode(AItem.GetAttribute('subscription'));
  FCriticalSection.Acquire;
  try
    lIndex := FItems.IndexOfName(string(lJID));
    if lSubscription = 'remove' then
    begin
      if lIndex >= 0 then
        FItems.Delete(lIndex);
    end
    else
      FItems.Values[string(lJID)] := string(UTF8Encode(
        AItem.GetAttribute('name')) + #9 + lSubscription);
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPRosterModule.ApplyQuery(AQuery: TDOMElement);
var
  lNode: TDOMNode;
begin
  if not Assigned(AQuery) then
    Exit;
  lNode := AQuery.FirstChild;
  while Assigned(lNode) do
  begin
    if (lNode is TDOMElement) and (lNode.NodeName = 'item') then
      UpdateItem(TDOMElement(lNode));
    lNode := lNode.NextSibling;
  end;
end;

procedure TNXXMPPRosterModule.CompleteRequest(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  if (AError <> '') or not Assigned(AStanza) or
    (AStanza.IQType <> xitResult) then
    Exit;
  ApplyQuery(TDOMElement(AStanza.Root.FindNode('query')));
end;

class function TNXXMPPRosterModule.RequestPayload: UTF8String;
begin
  Result := '<query xmlns=''jabber:iq:roster''/>';
end;

procedure TNXXMPPRosterModule.RegisterHandlers(
  ADispatcher: TNXXMPPDispatcher);
begin
  ADispatcher.RegisterIQResponder(xitSet, 'jabber:iq:roster', 'query',
    @HandlePush);
end;

procedure TNXXMPPRosterModule.HandlePush(AStanza: TNXXMPPStanza);
begin
  ApplyQuery(TDOMElement(AStanza.Root.FindNode('query')));
  Send('<iq type=''result'' id=''' + NXXMPPEscapeAttribute(AStanza.ID) +
    '''/>');
end;

function TNXXMPPRosterModule.Item(const AJID: UTF8String): UTF8String;
var
  lValue: UTF8String;
  lSeparator: Integer;
begin
  FCriticalSection.Acquire;
  try
    lValue := UTF8String(FItems.Values[string(AJID)]);
  finally
    FCriticalSection.Release;
  end;
  lSeparator := Pos(#9, lValue);
  if lSeparator > 0 then
    Result := Copy(lValue, 1, lSeparator - 1)
  else
    Result := lValue;
end;

function TNXXMPPRosterModule.ItemSubscription(
  const AJID: UTF8String): UTF8String;
var
  lValue: UTF8String;
  lSeparator: Integer;
begin
  FCriticalSection.Acquire;
  try
    lValue := UTF8String(FItems.Values[string(AJID)]);
  finally
    FCriticalSection.Release;
  end;
  lSeparator := Pos(#9, lValue);
  if lSeparator > 0 then
    Result := Copy(lValue, lSeparator + 1, MaxInt)
  else
    Result := '';
end;

procedure TNXXMPPRosterModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lItem: TDOMElement;
  lQuery: TDOMElement;
begin
  if not Assigned(FOnChanged) or not Assigned(AStanza) then
    Exit;
  if (AStanza.Kind = xskIQ) and (AStanza.IQType = xitSet) and
    (AStanza.ChildNamespaceURI = 'jabber:iq:roster') then
  begin
    lQuery := TDOMElement(AStanza.Root.FindNode('query'));
    if Assigned(lQuery) then
    begin
      lItem := TDOMElement(lQuery.FindNode('item'));
      if Assigned(lItem) then
        FOnChanged(Self, UTF8Encode(lItem.GetAttribute('jid')),
          UTF8Encode(lItem.GetAttribute('subscription')));
    end;
  end
  else if (AStanza.Kind = xskPresence) and
    ((AStanza.TypeValue = 'subscribe') or
    (AStanza.TypeValue = 'subscribed') or
    (AStanza.TypeValue = 'unsubscribe') or
    (AStanza.TypeValue = 'unsubscribed')) then
    FOnChanged(Self, AStanza.FromJID, AStanza.TypeValue);
end;

end.

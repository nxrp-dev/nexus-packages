(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPDispatcher;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, obNXXMPPError, obNXXMPPStanza,
  tpNXXMPPTypes;

type
  TNXXMPPStanzaHandler = procedure(AStanza: TNXXMPPStanza) of object;
  TNXXMPPStanzaPredicate = function(AStanza: TNXXMPPStanza): Boolean of object;

  TNXXMPPDispatcher = class
  private
    FObservers: TObjectList;
    FResponders: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    function DispatchStanza(AStanza: TNXXMPPStanza): Boolean;
    procedure RegisterIQResponder(AType: TNXXMPPIQType;
      const AChildNamespaceURI, AChildLocalName: UTF8String;
      AHandler: TNXXMPPStanzaHandler);
    procedure RegisterObserver(APredicate: TNXXMPPStanzaPredicate;
      AHandler: TNXXMPPStanzaHandler);
  end;

implementation

type
  TNXXMPPIQResponderRegistration = class
  public
    ChildLocalName: UTF8String;
    ChildNamespaceURI: UTF8String;
    Handler: TNXXMPPStanzaHandler;
    IQType: TNXXMPPIQType;
  end;

  TNXXMPPObserverRegistration = class
  public
    Handler: TNXXMPPStanzaHandler;
    Predicate: TNXXMPPStanzaPredicate;
  end;

constructor TNXXMPPDispatcher.Create;
begin
  inherited Create;
  FObservers := TObjectList.Create(True);
  FResponders := TObjectList.Create(True);
end;

destructor TNXXMPPDispatcher.Destroy;
begin
  FResponders.Free;
  FObservers.Free;
  inherited Destroy;
end;

procedure TNXXMPPDispatcher.RegisterIQResponder(AType: TNXXMPPIQType;
  const AChildNamespaceURI, AChildLocalName: UTF8String;
  AHandler: TNXXMPPStanzaHandler);
var
  lIndex: Integer;
  lRegistration: TNXXMPPIQResponderRegistration;
begin
  if not (AType in [xitGet, xitSet]) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-iq-responder',
      'An IQ responder must register for get or set.');
  if (AChildNamespaceURI = '') or (AChildLocalName = '') or
    not Assigned(AHandler) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-iq-responder',
      'An IQ responder requires a complete child QName and handler.');
  for lIndex := 0 to FResponders.Count - 1 do
  begin
    lRegistration := TNXXMPPIQResponderRegistration(FResponders[lIndex]);
    if (lRegistration.IQType = AType) and
      (lRegistration.ChildNamespaceURI = AChildNamespaceURI) and
      (lRegistration.ChildLocalName = AChildLocalName) then
      raise ENXXMPPError.Create(xesConfiguration, 'duplicate-iq-responder',
        'Only one IQ responder may own an exact type and child QName.');
  end;
  lRegistration := TNXXMPPIQResponderRegistration.Create;
  lRegistration.IQType := AType;
  lRegistration.ChildNamespaceURI := AChildNamespaceURI;
  lRegistration.ChildLocalName := AChildLocalName;
  lRegistration.Handler := AHandler;
  FResponders.Add(lRegistration);
end;

procedure TNXXMPPDispatcher.RegisterObserver(
  APredicate: TNXXMPPStanzaPredicate; AHandler: TNXXMPPStanzaHandler);
var
  lRegistration: TNXXMPPObserverRegistration;
begin
  if not Assigned(AHandler) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-observer',
      'A stanza observer requires a handler.');
  lRegistration := TNXXMPPObserverRegistration.Create;
  lRegistration.Predicate := APredicate;
  lRegistration.Handler := AHandler;
  FObservers.Add(lRegistration);
end;

function TNXXMPPDispatcher.DispatchStanza(AStanza: TNXXMPPStanza): Boolean;
var
  lIndex: Integer;
  lObserver: TNXXMPPObserverRegistration;
  lResponder: TNXXMPPIQResponderRegistration;
begin
  Result := False;
  if not Assigned(AStanza) then
    Exit;
  if (AStanza.Kind = xskIQ) and
    (AStanza.IQType in [xitGet, xitSet]) then
    for lIndex := 0 to FResponders.Count - 1 do
    begin
      lResponder := TNXXMPPIQResponderRegistration(FResponders[lIndex]);
      if (lResponder.IQType = AStanza.IQType) and
        (lResponder.ChildNamespaceURI = AStanza.ChildNamespaceURI) and
        (lResponder.ChildLocalName = AStanza.ChildLocalName) then
      begin
        lResponder.Handler(AStanza);
        Result := True;
        Break;
      end;
    end;
  for lIndex := 0 to FObservers.Count - 1 do
  begin
    lObserver := TNXXMPPObserverRegistration(FObservers[lIndex]);
    if not Assigned(lObserver.Predicate) or lObserver.Predicate(AStanza) then
      lObserver.Handler(AStanza);
  end;
end;

end.

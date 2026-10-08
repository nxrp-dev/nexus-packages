(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPRequestManager;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, SyncObjs, obNXXMPPError, obNXXMPPStanza,
  tpNXXMPPTypes;

type
  TNXXMPPIQCapacity = class
  private
    FCapacity: Integer;
    FCriticalSection: TCriticalSection;
    FReserved: Integer;
  public
    constructor Create(ACapacity: Integer);
    destructor Destroy; override;
    procedure Release;
    function TryReserve: Boolean;
    function Reserved: Integer;
  end;

  TNXXMPPIQCompletionHandler = procedure(AStanza: TNXXMPPStanza;
    const AError: UTF8String) of object;

  TNXXMPPIQCompletionEvent = class
  private
    FError: UTF8String;
    FHandler: TNXXMPPIQCompletionHandler;
    FStanza: TNXXMPPStanza;
  public
    constructor Create(AHandler: TNXXMPPIQCompletionHandler;
      AStanza: TNXXMPPStanza; const AError: UTF8String);
    destructor Destroy; override;
    procedure Invoke;
    property Error: UTF8String read FError;
    property Stanza: TNXXMPPStanza read FStanza;
  end;

  TNXXMPPRequestManager = class
  private
    FCapacity: Integer;
    FNextID: QWord;
    FPending: TObjectList;
    FReservation: TNXXMPPIQCapacity;
  public
    constructor Create(ACapacity: Integer = cNXXMPPDefaultPendingIQCapacity;
      AReservation: TNXXMPPIQCapacity = nil);
    destructor Destroy; override;
    function BeginRequest(const AExpectedFrom: UTF8String; ATimeoutMS: Cardinal;
      AHandler: TNXXMPPIQCompletionHandler): UTF8String;
    function Complete(AStanza: TNXXMPPStanza): TNXXMPPIQCompletionEvent;
    procedure CollectTimeouts(ANow: QWord; AEvents: TObjectList);
    procedure CancelAll(const AReason: UTF8String; AEvents: TObjectList);
    function Count: Integer;
    property Capacity: Integer read FCapacity;
  end;

implementation

constructor TNXXMPPIQCapacity.Create(ACapacity: Integer);
begin
  inherited Create;
  if ACapacity < 1 then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-iq-capacity',
      'The pending IQ capacity must be positive.');
  FCapacity := ACapacity;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TNXXMPPIQCapacity.Destroy;
begin
  FCriticalSection.Free;
  inherited Destroy;
end;

function TNXXMPPIQCapacity.TryReserve: Boolean;
begin
  FCriticalSection.Acquire;
  try
    Result := FReserved < FCapacity;
    if Result then
      Inc(FReserved);
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPIQCapacity.Release;
begin
  FCriticalSection.Acquire;
  try
    if FReserved > 0 then
      Dec(FReserved);
  finally
    FCriticalSection.Release;
  end;
end;

function TNXXMPPIQCapacity.Reserved: Integer;
begin
  FCriticalSection.Acquire;
  try
    Result := FReserved;
  finally
    FCriticalSection.Release;
  end;
end;

type
  TNXXMPPPendingIQ = class
  public
    Deadline: QWord;
    ExpectedFrom: UTF8String;
    Handler: TNXXMPPIQCompletionHandler;
    ID: UTF8String;
  end;

constructor TNXXMPPIQCompletionEvent.Create(
  AHandler: TNXXMPPIQCompletionHandler; AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  inherited Create;
  FHandler := AHandler;
  FStanza := AStanza;
  FError := AError;
end;

destructor TNXXMPPIQCompletionEvent.Destroy;
begin
  FStanza.Free;
  inherited Destroy;
end;

procedure TNXXMPPIQCompletionEvent.Invoke;
begin
  if Assigned(FHandler) then
    FHandler(FStanza, FError);
end;

constructor TNXXMPPRequestManager.Create(ACapacity: Integer;
  AReservation: TNXXMPPIQCapacity);
begin
  inherited Create;
  if ACapacity < 1 then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-iq-capacity',
      'The pending IQ capacity must be positive.');
  FCapacity := ACapacity;
  FReservation := AReservation;
  FPending := TObjectList.Create(True);
end;

destructor TNXXMPPRequestManager.Destroy;
begin
  FPending.Free;
  inherited Destroy;
end;

function TNXXMPPRequestManager.BeginRequest(const AExpectedFrom: UTF8String;
  ATimeoutMS: Cardinal; AHandler: TNXXMPPIQCompletionHandler): UTF8String;
var
  lPending: TNXXMPPPendingIQ;
begin
  if FPending.Count >= FCapacity then
    raise ENXXMPPError.Create(xesProtocol, 'pending-iq-full',
      'The pending IQ request limit has been reached.', True);
  Inc(FNextID);
  Result := UTF8String('nx-' + IntToStr(FNextID));
  lPending := TNXXMPPPendingIQ.Create;
  lPending.ID := Result;
  lPending.ExpectedFrom := AExpectedFrom;
  lPending.Deadline := GetTickCount64 + ATimeoutMS;
  lPending.Handler := AHandler;
  FPending.Add(lPending);
end;

function TNXXMPPRequestManager.Complete(
  AStanza: TNXXMPPStanza): TNXXMPPIQCompletionEvent;
var
  lIndex: Integer;
  lPending: TNXXMPPPendingIQ;
begin
  Result := nil;
  if not Assigned(AStanza) or (AStanza.Kind <> xskIQ) or
    not (AStanza.IQType in [xitResult, xitError]) then
    Exit;
  for lIndex := 0 to FPending.Count - 1 do
  begin
    lPending := TNXXMPPPendingIQ(FPending[lIndex]);
    if lPending.ID <> AStanza.ID then
      Continue;
    if (lPending.ExpectedFrom <> '') and
      (lPending.ExpectedFrom <> AStanza.FromJID) then
      Exit;
    FPending.Extract(lPending);
    if Assigned(FReservation) then
      FReservation.Release;
    Result := TNXXMPPIQCompletionEvent.Create(lPending.Handler, AStanza, '');
    lPending.Free;
    Exit;
  end;
end;

procedure TNXXMPPRequestManager.CollectTimeouts(ANow: QWord;
  AEvents: TObjectList);
var
  lIndex: Integer;
  lPending: TNXXMPPPendingIQ;
begin
  if not Assigned(AEvents) then
    Exit;
  lIndex := FPending.Count - 1;
  while lIndex >= 0 do
  begin
    lPending := TNXXMPPPendingIQ(FPending[lIndex]);
    if ANow >= lPending.Deadline then
    begin
      FPending.Extract(lPending);
      if Assigned(FReservation) then
        FReservation.Release;
      AEvents.Add(TNXXMPPIQCompletionEvent.Create(lPending.Handler, nil,
        'IQ request timed out.'));
      lPending.Free;
    end;
    Dec(lIndex);
  end;
end;

procedure TNXXMPPRequestManager.CancelAll(const AReason: UTF8String;
  AEvents: TObjectList);
var
  lPending: TNXXMPPPendingIQ;
begin
  while FPending.Count > 0 do
  begin
    lPending := TNXXMPPPendingIQ(FPending.Extract(FPending[0]));
    if Assigned(FReservation) then
      FReservation.Release;
    if Assigned(AEvents) then
      AEvents.Add(TNXXMPPIQCompletionEvent.Create(lPending.Handler, nil,
        AReason));
    lPending.Free;
  end;
end;

function TNXXMPPRequestManager.Count: Integer;
begin
  Result := FPending.Count;
end;

end.

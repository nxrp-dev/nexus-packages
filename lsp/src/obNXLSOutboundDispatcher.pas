(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSOutboundDispatcher;

{$mode objfpc}{$H+}

interface

uses
  Contnrs,
  fpjson,
  obNXJSONRPCMessages,
  obNXJSONValues,
  obNXLSTransport;

type
  TNXLSClientRequest = class
  private
    FID: Int64;
    FRequest: TNXJSONRPCOutboundCommand;
  public
    constructor Create(const AID: Int64; ARequest: TNXJSONRPCOutboundCommand);
    destructor Destroy; override;
    property ID: Int64 read FID;
    property Request: TNXJSONRPCOutboundCommand read FRequest;
  end;

  TNXLSOutboundDispatcher = class
  private
    FNextRequestID: Int64;
    FPendingRequests: TObjectList;
    FTransport: TNXLSTransport;

    function FindPendingRequestIndex(const AID: Int64): Integer;
    function NextRequestID: Int64;
    function PendingContainsID(const AID: Int64): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function SendRequest(ARequest: TNXJSONRPCOutboundCommand): Int64;
    procedure SendNotification(ANotification: TNXJSONRPCOutboundNotification);
    function ReceiveResponse(AMessage: TNXJSONRPCMessage): Boolean;
    procedure ClearPendingRequests;

    property Transport: TNXLSTransport read FTransport write FTransport;
  end;

implementation

uses
  SysUtils;

constructor TNXLSClientRequest.Create(const AID: Int64;
  ARequest: TNXJSONRPCOutboundCommand);
begin
  inherited Create;
  FID := AID;
  FRequest := ARequest;
end;

destructor TNXLSClientRequest.Destroy;
begin
  FreeAndNil(FRequest);
  inherited Destroy;
end;

constructor TNXLSOutboundDispatcher.Create;
begin
  inherited Create;
  FNextRequestID := 1;
  FPendingRequests := TObjectList.Create(True);
end;

destructor TNXLSOutboundDispatcher.Destroy;
begin
  FreeAndNil(FPendingRequests);
  inherited Destroy;
end;

function TNXLSOutboundDispatcher.FindPendingRequestIndex(const AID: Int64): Integer;
var
  lIdx: Integer;
begin
  for lIdx := 0 to FPendingRequests.Count - 1 do
    if TNXLSClientRequest(FPendingRequests[lIdx]).ID = AID then
      Exit(lIdx);

  Result := -1;
end;

function TNXLSOutboundDispatcher.PendingContainsID(const AID: Int64): Boolean;
begin
  Result := FindPendingRequestIndex(AID) >= 0;
end;

function TNXLSOutboundDispatcher.NextRequestID: Int64;
begin
  repeat
    Result := FNextRequestID;

    if FNextRequestID = High(Int64) then
      FNextRequestID := 1
    else
      Inc(FNextRequestID);
  until not PendingContainsID(Result);
end;

function TNXLSOutboundDispatcher.SendRequest(ARequest: TNXJSONRPCOutboundCommand): Int64;
var
  lID: TJSONData;
  lMessage: TJSONObject;
  lRequest: TNXJSONRPCOutboundCommand;
begin
  Result := 0;
  lRequest := ARequest;
  if ARequest = nil then
    raise Exception.Create('Client request is required.');

  try
    if FTransport = nil then
      Exit;

    Result := NextRequestID;
    ARequest.jsonrpc.Value := TNXJSONRPC.Version;
    ARequest.method.Value := ARequest.GetFactoryName;

    lID := TJSONIntegerNumber.Create(Result);
    try
      ARequest.id.FromJSONData(lID);
    finally
      lID.Free;
    end;

    lMessage := TJSONObject(ARequest.ToJSONData);
    try
      FTransport.WriteMessage(lMessage.AsJSON);
    finally
      lMessage.Free;
    end;

    FPendingRequests.Add(TNXLSClientRequest.Create(Result, lRequest));
    lRequest := nil;
  finally
    lRequest.Free;
  end;
end;

procedure TNXLSOutboundDispatcher.SendNotification(
  ANotification: TNXJSONRPCOutboundNotification);
var
  lMessage: TJSONObject;
  lNotification: TNXJSONRPCOutboundNotification;
begin
  lNotification := ANotification;
  if ANotification = nil then
    raise Exception.Create('Client notification is required.');

  try
    if FTransport = nil then
      Exit;

    ANotification.jsonrpc.Value := TNXJSONRPC.Version;
    ANotification.method.Value := ANotification.GetFactoryName;

    lMessage := TJSONObject(ANotification.ToJSONData);
    try
      FTransport.WriteMessage(lMessage.AsJSON);
    finally
      lMessage.Free;
    end;

    lNotification := nil;
  finally
    lNotification.Free;
  end;
end;

function TNXLSOutboundDispatcher.ReceiveResponse(AMessage: TNXJSONRPCMessage): Boolean;
var
  lPendingRequest: TNXLSClientRequest;
  lID: TJSONData;
  lIDValue: Int64;
  lIdx: Integer;
begin
  Result := False;
  if (AMessage = nil) or
    (not (AMessage.Kind in [rpcSuccessResponse, rpcErrorResponse])) then
    Exit;

  lID := AMessage.IDJSON;
  try
    if lID.JSONType <> jtNumber then
      Exit;

    lIDValue := lID.AsInteger;
  finally
    lID.Free;
  end;

  lIdx := FindPendingRequestIndex(lIDValue);
  if lIdx < 0 then
    Exit;

  lPendingRequest := TNXLSClientRequest(FPendingRequests[lIdx]);
  try
    lPendingRequest.Request.LoadOutboundResponse(TNXJSONRPCResponse(AMessage));
    if AMessage.Kind = rpcSuccessResponse then
      lPendingRequest.Request.ProcessOutboundResult
    else
      lPendingRequest.Request.ProcessOutboundError;
  finally
    FPendingRequests.Delete(lIdx);
  end;
  Result := True;
end;

procedure TNXLSOutboundDispatcher.ClearPendingRequests;
var
  lIdx: Integer;
begin
  for lIdx := 0 to FPendingRequests.Count - 1 do
    TNXLSClientRequest(FPendingRequests[lIdx]).Request.ProcessOutboundTimeout;

  FPendingRequests.Clear;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSDispatcher;

{$mode objfpc}{$H+}

interface

uses
  obNXJSONRPCMessages;

type
  TNXLSDispatcher = class
  public
    class function DispatchMessage(AMessage: TNXJSONRPCMessage; out AResponse: string): Boolean; static;
  end;

implementation

uses
  SysUtils,
  fpjson,
  obNXClassFactory,
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXLSLogger;

function CreateErrorResponse(const AID: TJSONData; const ACode: Integer; const AMessage: string): string;
var
  lResponse: TJSONObject;
begin
  lResponse := TNXJSONRPC.CreateErrorResponse(AID, ACode, AMessage);
  try
    Result := lResponse.AsJSON;
  finally
    lResponse.Free;
  end;
end;

class function TNXLSDispatcher.DispatchMessage(AMessage: TNXJSONRPCMessage; out AResponse: string): Boolean;
var
  lCommandMessage: TNXJSONRPCCommandMessage;
  lRequest: TNXJSONRPCRequest;
  lID: TJSONData;
  lMethod: string;
  lResult: TNXJSONRPCValue;
  lResponse: TJSONObject;
  lIsRequest: Boolean;
begin
  AResponse := '';
  Result := False;
  lRequest := nil;
  lID := nil;
  lResult := nil;
  lResponse := nil;
  lIsRequest := False;

  try
    try
      if AMessage = nil then
        Exit(False);

      lIsRequest := AMessage.MessageType = rpcmtRequest;
      if not (AMessage.MessageType in [rpcmtRequest, rpcmtNotification]) then
        Exit(False);

      lCommandMessage := TNXJSONRPCCommandMessage(AMessage);
      lMethod := lCommandMessage.method.Value;
      if not TNXClassFactory.Registered(lMethod) then
      begin
        if lIsRequest then
        begin
          lID := AMessage.IDJSON;
          AResponse := CreateErrorResponse(lID, TNXJSONRPC.MethodNotFound, 'Method not found: ' + lMethod);
          Exit(True);
        end;

        Exit(False);
      end;

      if lIsRequest then
        lID := AMessage.IDJSON;

      if not (AMessage is TNXJSONRPCRequest) then
        raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
          'JSON-RPC method is not an inbound request: ' + lMethod);

      lRequest := TNXJSONRPCRequest(AMessage);

      lResult := lRequest.Execute;
      lRequest.ValidateResult(lResult);

      if lIsRequest then
      begin
        FreeAndNil(lID);
        lID := lRequest.IDJSON;
        lResponse := TNXJSONRPC.CreateSuccessResponse(lID, lResult);
        try
          AResponse := lResponse.AsJSON;
          Exit(True);
        finally
          lResponse.Free;
        end;
      end;
    except
      on E: ENXJSONRPC do
      begin
        if lIsRequest then
        begin
          FreeAndNil(lID);
          if lRequest <> nil then
            lID := lRequest.IDJSON
          else
            lID := AMessage.IDJSON;
          AResponse := CreateErrorResponse(lID, E.Code, E.Message);
          Exit(True);
        end;

        TNXLSLogger.Error('Notification "' + lMethod + '" failed: ' + E.Message);
        Exit(False);
      end;
      on E: Exception do
      begin
        if lIsRequest then
        begin
          FreeAndNil(lID);
          if lRequest <> nil then
            lID := lRequest.IDJSON
          else
            lID := AMessage.IDJSON;
          AResponse := CreateErrorResponse(lID, TNXJSONRPC.InternalError, E.Message);
          Exit(True);
        end;

        TNXLSLogger.Error('Notification "' + lMethod + '" failed: ' + E.Message);
        Exit(False);
      end;
    end;
  finally
    lResult.Free;
    lID.Free;
  end;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestCommandProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson,
  obNXTestRegistry,
  obNXTestRunner;

type
  TNXTestCommandProcessor = class
  private
    FRegistry: TNXTestRegistry;
    FRunner: TNXTestRunner;
  public
    constructor Create(ARegistry: TNXTestRegistry);
    destructor Destroy; override;

    function ExecuteCommand(const ARequest: string): string;

    property Registry: TNXTestRegistry read FRegistry;
    property Runner: TNXTestRunner read FRunner;
  end;

implementation

uses
  jsonparser,
  obNXClassFactory,
  obNXJSONRPCMessages,
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXTestRPCValues;

function ExtractErrorID(const AMessage: string): TJSONData;
var
  lJSON: TJSONData;
  lID: TJSONData;
begin
  Result := nil;
  lJSON := nil;
  try
    try
      lJSON := GetJSON(AMessage);
      if not (lJSON is TJSONObject) then
        Exit;

      lID := TJSONObject(lJSON).Find('id');
      if lID = nil then
        Exit;

      if not (lID.JSONType in [jtNull, jtString, jtNumber]) then
        Exit;

      if (lID.JSONType = jtNumber) and (Pos('.', lID.AsJSON) > 0) then
        Exit;

      Result := lID.Clone;
    except
      FreeAndNil(Result);
    end;
  finally
    lJSON.Free;
  end;
end;

function CreateErrorResponse(const AID: TJSONData; const ACode: Integer; const AMessage: string; const ANXTestCode: Integer = 0): string;
var
  lData: TNXJSONRPCValue;
  lResponse: TJSONObject;
begin
  lData := nil;
  lResponse := nil;
  try
    if ANXTestCode <> 0 then
      lData := NXTestErrorData(ANXTestCode);

    lResponse := TNXJSONRPC.CreateErrorResponse(AID, ACode, AMessage, lData);
    Result := lResponse.AsJSON;
  finally
    lResponse.Free;
    lData.Free;
  end;
end;

constructor TNXTestCommandProcessor.Create(ARegistry: TNXTestRegistry);
begin
  inherited Create;
  FRegistry := ARegistry;
  FRunner := TNXTestRunner.Create(FRegistry);
end;

destructor TNXTestCommandProcessor.Destroy;
begin
  FreeAndNil(FRunner);
  inherited Destroy;
end;

function TNXTestCommandProcessor.ExecuteCommand(const ARequest: string): string;
var
  lMessage: TNXJSONRPCMessage;
  lCommandMessage: TNXJSONRPCCommandMessage;
  lRequest: TNXJSONRPCRequest;
  lID: TJSONData;
  lMethod: string;
  lRequestClass: TNXJSONRPCRequestClass;
  lResult: TNXJSONRPCValue;
  lResponse: TJSONObject;
  lIsRequest: Boolean;
begin
  Result := '';
  lMessage := nil;
  lRequest := nil;
  lID := nil;
  lResult := nil;
  lResponse := nil;
  lIsRequest := False;

  try
    try
      try
        lMessage := TNXJSONRPC.ParseMessage(ARequest);
      except
        on E: ENXJSONRPC do
        begin
          lID := ExtractErrorID(ARequest);
          Exit(CreateErrorResponse(lID, E.Code, E.Message, 0));
        end;
        on E: Exception do
          Exit(CreateErrorResponse(nil, TNXJSONRPC.ParseError, E.Message, 0));
      end;

      lIsRequest := lMessage.Kind = rpcRequest;
      if not (lMessage.Kind in [rpcRequest, rpcNotification]) then
      begin
        lID := lMessage.IDJSON;
        Exit(CreateErrorResponse(lID, TNXJSONRPC.InvalidRequest, 'Expected JSON-RPC request.', 0));
      end;

      lCommandMessage := TNXJSONRPCCommandMessage(lMessage);
      lMethod := lCommandMessage.method.Value;
      if not TNXClassFactory.Registered(lMethod) then
      begin
        if lIsRequest then
        begin
          lID := lMessage.IDJSON;
          Exit(CreateErrorResponse(lID, TNXJSONRPC.MethodNotFound, 'Method not found: ' + lMethod, 0));
        end;

        Exit('');
      end;

      lRequestClass := TNXJSONRPCRequestClass(TNXClassFactory.FindClass(lMethod));
      if lIsRequest then
        lID := lMessage.IDJSON;

      try
        FreeAndNil(lMessage);
        lRequest := TNXJSONRPCRequest(TNXJSONRPC.ParseMessage(ARequest, lRequestClass));
      except
        on E: ENXJSONRPC do
        begin
          if lIsRequest then
            Exit(CreateErrorResponse(lID, E.Code, E.Message, 0));
          Exit('');
        end;
        on E: Exception do
        begin
          if lIsRequest then
            Exit(CreateErrorResponse(lID, TNXJSONRPC.InvalidParams, E.Message, 0));
          Exit('');
        end;
      end;

      try
        lResult := lRequest.Execute;
      except
        on E: ENXTestRPC do
        begin
          if lIsRequest then
          begin
            FreeAndNil(lID);
            lID := lRequest.IDJSON;
            Exit(CreateErrorResponse(lID, E.Code, E.Message, E.NXTestCode));
          end;

          Exit('');
        end;
      end;

      if lIsRequest then
      begin
        FreeAndNil(lID);
        lID := lRequest.IDJSON;
        lResponse := TNXJSONRPC.CreateSuccessResponse(lID, lResult);
        Result := lResponse.AsJSON;
        Exit;
      end;
    except
      on E: Exception do
      begin
        if lIsRequest then
        begin
          FreeAndNil(lID);
          if Assigned(lRequest) then
            lID := lRequest.IDJSON;
          Exit(CreateErrorResponse(lID, TNXJSONRPC.InternalError, E.Message, 0));
        end;

        Exit('');
      end;
    end;
  finally
    lResponse.Free;
    lResult.Free;
    lID.Free;
    lRequest.Free;
    lMessage.Free;
  end;
end;

end.

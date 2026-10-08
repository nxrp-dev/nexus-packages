(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSServer;

{$mode objfpc}{$H+}

interface

uses
  obNXJSONRPCMessages,
  obNXLSTransport;

type
  TNXLSServerApplication = class
  public
    function ServerName: string; virtual; abstract;
    procedure AttachTransport(ATransport: TNXLSTransport); virtual; abstract;
    function ReceiveClientResponse(AMessage: TNXJSONRPCMessage): Boolean; virtual; abstract;
  end;

  TNXLSServer = class
  private
    FTransport: TNXLSTransport;
    FApplication: TNXLSServerApplication;
  public
    { After validating both arguments, takes ownership of them even if
      application attachment raises an exception. }
    constructor Create(ATransport: TNXLSTransport;
      AApplication: TNXLSServerApplication);
    destructor Destroy; override;
    procedure Execute;
    property Transport: TNXLSTransport read FTransport;
    property Application: TNXLSServerApplication read FApplication;
  end;

implementation

uses
  SysUtils,
  fpjson,
  jsonparser,
  obNXLSDispatcher,
  obNXLSLogger;

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

constructor TNXLSServer.Create(ATransport: TNXLSTransport;
  AApplication: TNXLSServerApplication);
begin
  inherited Create;
  if ATransport = nil then
    raise Exception.Create('Transport is required.');
  if AApplication = nil then
    raise Exception.Create('Language server application is required.');

  FTransport := ATransport;
  FApplication := AApplication;
  FApplication.AttachTransport(FTransport);
end;

destructor TNXLSServer.Destroy;
begin
  FApplication.Free;
  FTransport.Free;
  inherited Destroy;
end;

procedure TNXLSServer.Execute;
var
  lID: TJSONData;
  lMessage: string;
  lResponse: string;
  lRPCMessages: TNXJSONRPCMessages;
  lRPCMessage: TNXJSONRPCMessage;
  lBatchResponses: TJSONArray;
  lResponseJSON: TJSONData;
  lIdx: Integer;
begin
  FTransport.Open;
  try
    TNXLSLogger.Info(FApplication.ServerName + ' started using ' +
      FTransport.GetFactoryName + ' transport.');

    while FTransport.ReadMessage(lMessage) do
    begin
      lRPCMessages := nil;
      try
        try
          lRPCMessages := TNXJSONRPC.ParseMessages(lMessage);
        except
          on E: ENXJSONRPC do
          begin
            lID := ExtractErrorID(lMessage);
            try
              FTransport.WriteMessage(CreateErrorResponse(lID, E.Code, E.Message));
            finally
              lID.Free;
            end;
            Continue;
          end;
          on E: Exception do
          begin
            FTransport.WriteMessage(CreateErrorResponse(nil, TNXJSONRPC.ParseError, E.Message));
            Continue;
          end;
        end;

        lBatchResponses := nil;
        try
          if lRPCMessages.Count > 1 then
            lBatchResponses := TJSONArray.Create;

          for lIdx := 0 to lRPCMessages.Count - 1 do
          begin
            lRPCMessage := lRPCMessages.GetItem(lIdx);
            case lRPCMessage.MessageType of
              rpcmtRequest,
              rpcmtNotification:
                if TNXLSDispatcher.DispatchMessage(lRPCMessage, lResponse) and
                  (lResponse <> '') then
                begin
                  if lBatchResponses = nil then
                    FTransport.WriteMessage(lResponse)
                  else
                  begin
                    lResponseJSON := GetJSON(lResponse);
                    try
                      lBatchResponses.Add(lResponseJSON);
                      lResponseJSON := nil;
                    finally
                      lResponseJSON.Free;
                    end;
                  end;
                end;

              rpcmtSuccessResponse,
              rpcmtErrorResponse:
                FApplication.ReceiveClientResponse(lRPCMessage);
            end;
          end;

          if (lBatchResponses <> nil) and (lBatchResponses.Count > 0) then
            FTransport.WriteMessage(lBatchResponses.AsJSON);
        finally
          lBatchResponses.Free;
        end;
      finally
        lRPCMessages.Free;
      end;
    end;
  finally
    FTransport.Close;
  end;
end;

end.

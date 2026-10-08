(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXJSONRPCMessages;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Contnrs,
  fpjson,
  obNXJSONValues,
  obNXJSONRPCObjects;

type
  ENXJSONRPC = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(const ACode: Integer; const AMessage: string);
    property Code: Integer read FCode;
  end;

  TNXJSONRPCMessageKind = (
    rpcUnknown,
    rpcRequest,
    rpcNotification,
    rpcSuccessResponse,
    rpcErrorResponse,
    rpcBatch
  );

  TNXJSONRPCResultKind = (
    rkNoResult,
    rkNullResult,
    rkConcreteResult,
    rkNullableConcreteResult
  );

  TNXJSONRPCMessageType = (
    rpcmtInvalid,
    rpcmtRequest,
    rpcmtNotification,
    rpcmtSuccessResponse,
    rpcmtErrorResponse
  );

  TNXJSONRPCEnvelopePolicy = (
    jepStandard,
    jepHeaderless
  );

  TNXJSONRPCMessage = class;
  TNXJSONRPCMessageClass = class of TNXJSONRPCMessage;
  TNXJSONRPCCommandMessage = class;
  TNXJSONRPCNotification = class;
  TNXJSONRPCResponse = class;
  TNXJSONRPCError = class;
  TNXJSONRPCCommandResult = class;
  TNXJSONRPCRequest = class;
  TNXJSONRPCRequestClass = class of TNXJSONRPCRequest;
  TNXJSONRPCOutboundCommand = class;
  TNXJSONRPCOutboundCommandClass = class of TNXJSONRPCOutboundCommand;
  TNXJSONRPCOutboundNotification = class;
  TNXJSONRPCOutboundNotificationClass = class of TNXJSONRPCOutboundNotification;
  TNXJSONRPCMessages = class;

  TNXJSONRPCMessage = class(TNXJSONObject)
  private
    Fjsonrpc: TNXJSONString;
    Fid: TNXJSONRPCID;
    FMessageType: TNXJSONRPCMessageType;
    function GetMessageType: TNXJSONRPCMessageType;
    procedure SetID(AValue: TNXJSONRPCID);
  protected
    procedure UpdateMessageType; virtual;
  public
    function Kind: TNXJSONRPCMessageKind;

    function HasID: Boolean;
    function IDJSON: TJSONData;
    property MessageType: TNXJSONRPCMessageType read GetMessageType;

  published
    property jsonrpc: TNXJSONString read Fjsonrpc write Fjsonrpc;
    property id: TNXJSONRPCID read Fid write SetID;
  end;

  TNXJSONRPCCommandMessage = class(TNXJSONRPCMessage)
  private
    Fmethod: TNXJSONString;
    Fparams: TNXJSONRPCObjectParams;
    procedure SetMethod(AValue: TNXJSONString);
    procedure SetParams(AValue: TNXJSONRPCObjectParams);
  protected
    procedure UpdateMessageType; override;
  public
    function HasParams: Boolean;
    function ParamsObject: TNXJSONObject;
  published
    property method: TNXJSONString read Fmethod write SetMethod;
    property params: TNXJSONRPCObjectParams read Fparams write SetParams;
  end;

  TNXJSONRPCNotification = class(TNXJSONRPCCommandMessage)
  end;

  TNXJSONRPCResponse = class(TNXJSONRPCMessage)
  private
    Fresult: TNXJSONRPCValue;
    Ferror: TNXJSONRPCError;
    procedure SetError(AValue: TNXJSONRPCError);
    procedure SetResult(AValue: TNXJSONRPCValue);
  protected
    procedure UpdateMessageType; override;
  published
    property result: TNXJSONRPCValue read Fresult write SetResult;
    property error: TNXJSONRPCError read Ferror write SetError;
  end;

  TNXJSONRPCError = class(TNXJSONObject)
  private
    Fcode: TNXJSONInteger;
    Fmessage: TNXJSONString;
    Fdata: TNXJSONRPCUnknown;
  published
    property code: TNXJSONInteger read Fcode write Fcode;
    property message: TNXJSONString read Fmessage write Fmessage;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXJSONRPCCommandResult = class(TNXJSONObject)
  end;

  TNXJSONRPCRequest = class(TNXJSONRPCCommandMessage)
  private
    FResult: TNXJSONRPCValue;
    function GetResult: TNXJSONRPCValue;
    procedure SetResult(AValue: TNXJSONRPCValue);
  protected
    function PrepareResult: TNXJSONRPCValue; virtual;
  public
    destructor Destroy; override;
    class function GetResultKind: TNXJSONRPCResultKind; virtual;
    function Execute: TNXJSONRPCValue; virtual; abstract;
    procedure ValidateResult(AResult: TNXJSONRPCValue); virtual;
  published
    property result: TNXJSONRPCValue read GetResult write SetResult;
  end;

  TNXJSONRPCOutboundCommand = class(TNXJSONRPCCommandMessage)
  private
    FCommandResult: TNXJSONRPCCommandResult;
    FCommandError: TNXJSONRPCError;
    function GetResult: TNXJSONRPCCommandResult;
    procedure SetResult(AValue: TNXJSONRPCCommandResult);
  public
    destructor Destroy; override;
    class function GetResultKind: TNXJSONRPCResultKind; virtual;
    procedure LoadOutboundResponse(AResponse: TNXJSONRPCResponse); virtual;
    procedure ProcessOutboundResult; virtual;
    procedure ProcessOutboundError; virtual;
    procedure ProcessOutboundTimeout; virtual;
    procedure ValidateResult(AResult: TNXJSONRPCValue); virtual;
    property CommandError: TNXJSONRPCError read FCommandError;
  published
    property result: TNXJSONRPCCommandResult read GetResult write SetResult;
  end;

  TNXJSONRPCOutboundNotification = class(TNXJSONRPCCommandMessage)
  end;

  TNXJSONRPCMessages = class
  private
    FItems: TObjectList;
    function GetCount: Integer;
    function GetPrimary: TNXJSONRPCMessage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AMessage: TNXJSONRPCMessage);
    function GetItem(AIndex: Integer): TNXJSONRPCMessage;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TNXJSONRPCMessage read GetItem; default;
    property Primary: TNXJSONRPCMessage read GetPrimary;
  end;

  TNXJSONRPC = class
  public
    const Version = '2.0';
    const ParseError = -32700;
    const InvalidRequest = -32600;
    const MethodNotFound = -32601;
    const InvalidParams = -32602;
    const InternalError = -32603;

    class function ParseMessage(const AJSON: UTF8String): TNXJSONRPCMessage; overload; static;
    class function ParseMessage(const AJSON: UTF8String;
      APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessage; overload; static;
    class function ParseMessage(const AJSON: UTF8String;
      AMessageClass: TNXJSONRPCMessageClass): TNXJSONRPCMessage; overload; static;
    class function ParseMessage(const AJSON: UTF8String;
      AMessageClass: TNXJSONRPCMessageClass;
      APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessage; overload; static;
    class function ParseMessages(const AJSON: UTF8String): TNXJSONRPCMessages; overload; static;
    class function ParseMessages(const AJSON: UTF8String;
      APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessages; overload; static;
    class procedure ValidateMessage(AMessage: TNXJSONRPCMessage); overload; static;
    class procedure ValidateMessage(AMessage: TNXJSONRPCMessage;
      APolicy: TNXJSONRPCEnvelopePolicy); overload; static;
    class function CreateSuccessResponse(AID: TJSONData;
      AResult: TNXJSONRPCValue): TJSONObject; overload; static;
    class function CreateSuccessResponse(AID: TJSONData;
      AResult: TNXJSONRPCValue; APolicy: TNXJSONRPCEnvelopePolicy): TJSONObject;
      overload; static;
    class function CreateErrorResponse(AID: TJSONData; const ACode: Integer;
      const AMessage: UTF8String; AData: TNXJSONRPCValue = nil): TJSONObject;
      overload; static;
    class function CreateErrorResponse(AID: TJSONData; const ACode: Integer;
      const AMessage: UTF8String; AData: TNXJSONRPCValue;
      APolicy: TNXJSONRPCEnvelopePolicy): TJSONObject; overload; static;
  end;

implementation

uses
  jsonparser,
  obNXClassFactory;

function NXJSONRPCMessageClassForObject(AObject: TJSONObject;
  AMessageClass: TNXJSONRPCMessageClass): TNXJSONRPCMessageClass;
var
  lMethodJSON: TJSONData;
begin
  Result := AMessageClass;
  if Result = nil then
    Result := TNXJSONRPCMessage;

  if Result <> TNXJSONRPCMessage then
    Exit;

  if AObject.Find('method') <> nil then
  begin
    lMethodJSON := AObject.Find('method');
    if (lMethodJSON.JSONType = jtString) and
      (lMethodJSON.AsString <> '') and
      TNXClassFactory.Registered(lMethodJSON.AsString) then
      Result := TNXJSONRPCMessageClass(TNXClassFactory.FindClass(lMethodJSON.AsString))
    else if AObject.Find('id') = nil then
      Result := TNXJSONRPCNotification
    else
      Result := TNXJSONRPCCommandMessage;
  end
  else if (AObject.Find('result') <> nil) or (AObject.Find('error') <> nil) then
    Result := TNXJSONRPCResponse;
end;

function NXJSONRPCParseMessageData(AData: TJSONData;
  AMessageClass: TNXJSONRPCMessageClass;
  APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessage;
var
  lMessageClass: TNXJSONRPCMessageClass;
begin
  if not (AData is TJSONObject) then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
      'JSON-RPC message must be a JSON object.');

  lMessageClass := NXJSONRPCMessageClassForObject(TJSONObject(AData), AMessageClass);
  Result := lMessageClass.Create;
  try
    Result.FromJSONData(AData);
    TNXJSONRPC.ValidateMessage(Result, APolicy);
  except
    Result.Free;
    raise;
  end;
end;

constructor ENXJSONRPC.CreateCode(const ACode: Integer; const AMessage: string);
begin
  inherited Create(AMessage);
  FCode := ACode;
end;

constructor TNXJSONRPCMessages.Create;
begin
  inherited Create;
  FItems := TObjectList.Create(True);
end;

destructor TNXJSONRPCMessages.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TNXJSONRPCMessages.Add(AMessage: TNXJSONRPCMessage);
begin
  if AMessage = nil then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      'JSON-RPC message collection cannot add nil.');

  FItems.Add(AMessage);
end;

function TNXJSONRPCMessages.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TNXJSONRPCMessages.GetItem(AIndex: Integer): TNXJSONRPCMessage;
begin
  Result := TNXJSONRPCMessage(FItems[AIndex]);
end;

function TNXJSONRPCMessages.GetPrimary: TNXJSONRPCMessage;
begin
  if Count = 0 then
    Result := nil
  else
    Result := GetItem(0);
end;

function TNXJSONRPCMessage.GetMessageType: TNXJSONRPCMessageType;
begin
  UpdateMessageType;
  Result := FMessageType;
end;

function TNXJSONRPCMessage.Kind: TNXJSONRPCMessageKind;
begin
  case MessageType of
    rpcmtRequest:
      Result := rpcRequest;
    rpcmtNotification:
      Result := rpcNotification;
    rpcmtSuccessResponse:
      Result := rpcSuccessResponse;
    rpcmtErrorResponse:
      Result := rpcErrorResponse;
  else
    Result := rpcUnknown;
  end;
end;

procedure TNXJSONRPCMessage.SetID(AValue: TNXJSONRPCID);
begin
  Fid := AValue;
  UpdateMessageType;
end;

procedure TNXJSONRPCMessage.UpdateMessageType;
begin
  FMessageType := rpcmtInvalid;
end;

function TNXJSONRPCMessage.HasID: Boolean;
begin
  Result := (id <> nil) and id.Assigned;
end;

function TNXJSONRPCCommandMessage.HasParams: Boolean;
begin
  Result := (params <> nil) and params.Assigned;
end;

function TNXJSONRPCMessage.IDJSON: TJSONData;
begin
  if HasID then
    Result := id.ToJSONData
  else
    Result := TJSONNull.Create;
end;

function TNXJSONRPCCommandMessage.ParamsObject: TNXJSONObject;
begin
  if (params <> nil) and (params is TNXJSONObject) then
    Result := TNXJSONObject(params)
  else
    Result := nil;
end;

procedure TNXJSONRPCCommandMessage.SetMethod(AValue: TNXJSONString);
begin
  Fmethod := AValue;
  UpdateMessageType;
end;

procedure TNXJSONRPCCommandMessage.SetParams(AValue: TNXJSONRPCObjectParams);
begin
  Fparams := AValue;
end;

procedure TNXJSONRPCCommandMessage.UpdateMessageType;
begin
  if (method <> nil) and method.Assigned and (method.Value <> '') then
  begin
    if HasID then
      FMessageType := rpcmtRequest
    else
      FMessageType := rpcmtNotification;
  end
  else
    FMessageType := rpcmtInvalid;
end;

procedure TNXJSONRPCResponse.SetError(AValue: TNXJSONRPCError);
begin
  Ferror := AValue;
  UpdateMessageType;
end;

procedure TNXJSONRPCResponse.SetResult(AValue: TNXJSONRPCValue);
begin
  Fresult := AValue;
  UpdateMessageType;
end;

procedure TNXJSONRPCResponse.UpdateMessageType;
var
  lHasError: Boolean;
  lHasResult: Boolean;
begin
  lHasResult := (Self.result <> nil) and Self.result.Assigned;
  lHasError := (error <> nil) and error.Assigned;

  if lHasResult and (not lHasError) then
    FMessageType := rpcmtSuccessResponse
  else if lHasError and (not lHasResult) then
    FMessageType := rpcmtErrorResponse
  else
    FMessageType := rpcmtInvalid;
end;

class function TNXJSONRPCRequest.GetResultKind: TNXJSONRPCResultKind;
begin
  Result := rkConcreteResult;
end;

function TNXJSONRPCRequest.PrepareResult: TNXJSONRPCValue;
var
  lResultKind: TNXJSONRPCResultKind;
  lResult: TNXJSONRPCValue;
begin
  lResultKind := GetResultKind;
  if lResultKind = rkNoResult then
    Exit(nil);
  if lResultKind = rkNullResult then
    Exit(TNXJSONNull.Create);

  lResult := Self.result;
  if lResult = nil then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property is not assigned.');

  if lResult.ClassType = TNXJSONRPCValue then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property uses raw TNXJSONRPCValue. This should never happen.');

  Result := TNXJSONRPCValueClass(lResult.ClassType).Create;
  try
    ValidateResult(Result);
  except
    Result.Free;
    raise;
  end;
end;

destructor TNXJSONRPCRequest.Destroy;
begin
  FreeAndNil(FResult);
  inherited Destroy;
end;

function TNXJSONRPCRequest.GetResult: TNXJSONRPCValue;
begin
  Result := FResult;
end;

procedure TNXJSONRPCRequest.SetResult(AValue: TNXJSONRPCValue);
begin
  FResult := AValue;
end;

procedure TNXJSONRPCRequest.ValidateResult(AResult: TNXJSONRPCValue);
var
  lResultKind: TNXJSONRPCResultKind;
  lResult: TNXJSONRPCValue;
begin
  lResultKind := GetResultKind;

  if AResult = nil then
  begin
    if lResultKind = rkNoResult then
      Exit;

    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.Execute returned nil result.');
  end;

  if AResult.ClassType = TNXJSONRPCValue then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.Execute returned raw TNXJSONRPCValue result. This should never happen.');

  if AResult is TNXJSONNull then
  begin
    if lResultKind in [rkNullResult, rkNullableConcreteResult] then
      Exit;

    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.Execute returned null but null is not allowed for this result.');
  end;

  if not (lResultKind in [rkConcreteResult, rkNullableConcreteResult]) then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.Execute returned ' + AResult.ClassName +
      ' but this result kind does not allow a concrete result.');

  lResult := Self.result;
  if lResult = nil then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property is not assigned.');

  if lResult.ClassType = TNXJSONRPCValue then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property uses raw TNXJSONRPCValue. This should never happen.');

  if not AResult.InheritsFrom(lResult.ClassType) then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.Execute returned ' + AResult.ClassName +
      ' but expected ' + lResult.ClassName + '.');
end;

destructor TNXJSONRPCOutboundCommand.Destroy;
begin
  FreeAndNil(FCommandError);
  FreeAndNil(FCommandResult);
  inherited Destroy;
end;

function TNXJSONRPCOutboundCommand.GetResult: TNXJSONRPCCommandResult;
begin
  Result := FCommandResult;
end;

class function TNXJSONRPCOutboundCommand.GetResultKind: TNXJSONRPCResultKind;
begin
  Result := rkConcreteResult;
end;

procedure TNXJSONRPCOutboundCommand.SetResult(AValue: TNXJSONRPCCommandResult);
begin
  FCommandResult := AValue;
end;

procedure TNXJSONRPCOutboundCommand.ValidateResult(AResult: TNXJSONRPCValue);
var
  lResultKind: TNXJSONRPCResultKind;
  lResult: TNXJSONRPCCommandResult;
begin
  lResultKind := GetResultKind;

  if AResult = nil then
  begin
    if lResultKind = rkNoResult then
      Exit;

    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + ' received nil result.');
  end;

  if AResult.ClassType = TNXJSONRPCValue then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + ' received raw TNXJSONRPCValue result. This should never happen.');

  if AResult is TNXJSONNull then
  begin
    if lResultKind in [rkNullResult, rkNullableConcreteResult] then
      Exit;

    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + ' received null but null is not allowed for this result.');
  end;

  if not (lResultKind in [rkConcreteResult, rkNullableConcreteResult]) then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + ' received ' + AResult.ClassName +
      ' but this result kind does not allow a concrete result.');

  lResult := Self.result;
  if lResult = nil then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property is not assigned.');

  if lResult.ClassType = TNXJSONRPCCommandResult then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + '.result property uses raw TNXJSONRPCCommandResult. This should never happen.');

  if not AResult.InheritsFrom(lResult.ClassType) then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
      ClassName + ' received ' + AResult.ClassName +
      ' but expected ' + lResult.ClassName + '.');
end;

procedure TNXJSONRPCOutboundCommand.LoadOutboundResponse(AResponse: TNXJSONRPCResponse);
var
  lJSON: TJSONData;
  lNullResult: TNXJSONNull;
begin
  if AResponse = nil then
    raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
      'JSON-RPC response cannot be nil.');

  if AResponse.Kind = rpcSuccessResponse then
  begin
    if (AResponse.result = nil) or (not AResponse.result.Assigned) then
      raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
        'JSON-RPC success response is missing result.');

    if AResponse.result is TNXJSONNull then
    begin
      lNullResult := TNXJSONNull.Create;
      try
        ValidateResult(lNullResult);
      finally
        lNullResult.Free;
      end;
      Exit;
    end;

    if FCommandResult = nil then
      raise ENXJSONRPC.CreateCode(TNXJSONRPC.InternalError,
        ClassName + '.result property is not assigned.');

    lJSON := AResponse.result.ToJSONData;
    try
      FCommandResult.Clear;
      FCommandResult.FromJSONData(lJSON);
    finally
      lJSON.Free;
    end;

    ValidateResult(FCommandResult);
    Exit;
  end;

  if AResponse.Kind = rpcErrorResponse then
  begin
    if (AResponse.error = nil) or (not AResponse.error.Assigned) then
      raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
        'JSON-RPC error response is missing error.');

    FreeAndNil(FCommandError);
    lJSON := AResponse.error.ToJSONData;
    try
      FCommandError := TNXJSONRPCError.Create;
      FCommandError.FromJSONData(lJSON);
    finally
      lJSON.Free;
    end;
    Exit;
  end;

  raise ENXJSONRPC.CreateCode(TNXJSONRPC.InvalidRequest,
    'JSON-RPC message is not a response.');
end;

procedure TNXJSONRPCOutboundCommand.ProcessOutboundResult;
begin
end;

procedure TNXJSONRPCOutboundCommand.ProcessOutboundError;
begin
end;

procedure TNXJSONRPCOutboundCommand.ProcessOutboundTimeout;
begin
end;

class function TNXJSONRPC.ParseMessage(const AJSON: UTF8String): TNXJSONRPCMessage;
begin
  Result := ParseMessage(AJSON, TNXJSONRPCMessage, jepStandard);
end;

class function TNXJSONRPC.ParseMessage(const AJSON: UTF8String;
  APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessage;
begin
  Result := ParseMessage(AJSON, TNXJSONRPCMessage, APolicy);
end;

class function TNXJSONRPC.ParseMessage(const AJSON: UTF8String;
  AMessageClass: TNXJSONRPCMessageClass): TNXJSONRPCMessage;
begin
  Result := ParseMessage(AJSON, AMessageClass, jepStandard);
end;

class function TNXJSONRPC.ParseMessage(const AJSON: UTF8String;
  AMessageClass: TNXJSONRPCMessageClass;
  APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessage;
var
  lJSON: TJSONData;
begin
  lJSON := nil;
  try
    try
      lJSON := GetJSON(AJSON);
    except
      on E: Exception do
        raise ENXJSONRPC.CreateCode(ParseError, E.Message);
    end;

    Result := NXJSONRPCParseMessageData(lJSON, AMessageClass, APolicy);
  finally
    lJSON.Free;
  end;
end;

class function TNXJSONRPC.ParseMessages(const AJSON: UTF8String): TNXJSONRPCMessages;
begin
  Result := ParseMessages(AJSON, jepStandard);
end;

class function TNXJSONRPC.ParseMessages(const AJSON: UTF8String;
  APolicy: TNXJSONRPCEnvelopePolicy): TNXJSONRPCMessages;
var
  lJSON: TJSONData;
  lArray: TJSONArray;
  lIdx: Integer;
  lMessage: TNXJSONRPCMessage;
begin
  lJSON := nil;
  Result := TNXJSONRPCMessages.Create;
  try
    try
      try
        lJSON := GetJSON(AJSON);
      except
        on E: Exception do
          raise ENXJSONRPC.CreateCode(ParseError, E.Message);
      end;

      if lJSON is TJSONArray then
      begin
        lArray := TJSONArray(lJSON);
        if lArray.Count = 0 then
          raise ENXJSONRPC.CreateCode(InvalidRequest,
            'JSON-RPC batch must contain at least one message.');

        for lIdx := 0 to lArray.Count - 1 do
        begin
          lMessage := NXJSONRPCParseMessageData(lArray.Items[lIdx],
            TNXJSONRPCMessage, APolicy);
          try
            Result.Add(lMessage);
            lMessage := nil;
          finally
            lMessage.Free;
          end;
        end;
      end
      else
      begin
        lMessage := NXJSONRPCParseMessageData(lJSON, TNXJSONRPCMessage,
          APolicy);
        try
          Result.Add(lMessage);
          lMessage := nil;
        finally
          lMessage.Free;
        end;
      end;
    finally
      lJSON.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

class procedure TNXJSONRPC.ValidateMessage(AMessage: TNXJSONRPCMessage);
begin
  ValidateMessage(AMessage, jepStandard);
end;

class procedure TNXJSONRPC.ValidateMessage(AMessage: TNXJSONRPCMessage;
  APolicy: TNXJSONRPCEnvelopePolicy);
var
  lIDJSON: TJSONData;
  lParamsJSON: TJSONData;
  lErrorJSON: TJSONData;
  lErrorObject: TJSONObject;
  lKind: TNXJSONRPCMessageKind;
  lCommandMessage: TNXJSONRPCCommandMessage;
  lResponse: TNXJSONRPCResponse;
begin
  if AMessage = nil then
    raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC message cannot be nil.');

  if APolicy = jepStandard then
  begin
    if (AMessage.jsonrpc = nil) or (not AMessage.jsonrpc.Assigned) or
      (AMessage.jsonrpc.Value <> Version) then
      raise ENXJSONRPC.CreateCode(InvalidRequest,
        'JSON-RPC message must contain jsonrpc = "2.0".');
  end
  else if (AMessage.jsonrpc <> nil) and AMessage.jsonrpc.Assigned and
    (AMessage.jsonrpc.Value <> Version) then
    raise ENXJSONRPC.CreateCode(InvalidRequest,
      'JSON-RPC message jsonrpc must be "2.0" when present.');

  lKind := AMessage.Kind;
  if not (lKind in [rpcRequest, rpcNotification, rpcSuccessResponse, rpcErrorResponse]) then
    raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC message shape is invalid.');

  if lKind in [rpcRequest, rpcNotification] then
  begin
    if not (AMessage is TNXJSONRPCCommandMessage) then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC request must be a command message.');

    lCommandMessage := TNXJSONRPCCommandMessage(AMessage);
    if (lCommandMessage.method = nil) or (not lCommandMessage.method.Assigned) or (lCommandMessage.method.Value = '') then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC request must contain a non-empty method string.');

    if lCommandMessage.HasParams then
    begin
      lParamsJSON := lCommandMessage.params.ToJSONData;
      try
        if not (lParamsJSON.JSONType in [jtArray, jtObject]) then
          raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC params must be an object or array.');
      finally
        lParamsJSON.Free;
      end;
    end;
  end
  else
  begin
    if not (AMessage is TNXJSONRPCResponse) then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC response must be a response message.');

    lResponse := TNXJSONRPCResponse(AMessage);

    if not AMessage.HasID then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC response must contain id.');
  end;

  if lKind = rpcSuccessResponse then
  begin
    lResponse := TNXJSONRPCResponse(AMessage);
    if (lResponse.error <> nil) and lResponse.error.Assigned then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC response cannot contain both result and error.');
  end;

  if lKind = rpcErrorResponse then
  begin
    lResponse := TNXJSONRPCResponse(AMessage);
    if (lResponse.result <> nil) and lResponse.result.Assigned then
      raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC response cannot contain both result and error.');

    lErrorJSON := lResponse.error.ToJSONData;
    try
      if not (lErrorJSON is TJSONObject) then
        raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC error must be an object.');

      lErrorObject := TJSONObject(lErrorJSON);
      if (lErrorObject.Find('code') = nil) or
        (lErrorObject.Find('code').JSONType <> jtNumber) or
        (Pos('.', lErrorObject.Find('code').AsJSON) > 0) then
        raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC error code must be an integer.');

      if (lErrorObject.Find('message') = nil) or
        (lErrorObject.Find('message').JSONType <> jtString) then
        raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC error message must be a string.');
    finally
      lErrorJSON.Free;
    end;
  end;

  if AMessage.HasID then
  begin
    lIDJSON := AMessage.IDJSON;
    try
      if not (lIDJSON.JSONType in [jtNull, jtString, jtNumber]) then
        raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC id must be a string, number, or null.');

      if (lIDJSON.JSONType = jtNumber) and (Pos('.', lIDJSON.AsJSON) > 0) then
        raise ENXJSONRPC.CreateCode(InvalidRequest, 'JSON-RPC numeric id must not contain a fractional part.');
    finally
      lIDJSON.Free;
    end;
  end;
end;

class function TNXJSONRPC.CreateSuccessResponse(AID: TJSONData; AResult: TNXJSONRPCValue): TJSONObject;
begin
  Result := CreateSuccessResponse(AID, AResult, jepStandard);
end;

class function TNXJSONRPC.CreateSuccessResponse(AID: TJSONData;
  AResult: TNXJSONRPCValue; APolicy: TNXJSONRPCEnvelopePolicy): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    if APolicy = jepStandard then
      Result.Add('jsonrpc', Version);

    if AID = nil then
      Result.Add('id', TJSONNull.Create)
    else
      Result.Add('id', AID.Clone);

    if AResult = nil then
      Result.Add('result', TJSONNull.Create)
    else
      Result.Add('result', AResult.ToJSONData);
  except
    Result.Free;
    raise;
  end;
end;

class function TNXJSONRPC.CreateErrorResponse(AID: TJSONData;
  const ACode: Integer; const AMessage: UTF8String;
  AData: TNXJSONRPCValue): TJSONObject;
begin
  Result := CreateErrorResponse(AID, ACode, AMessage, AData, jepStandard);
end;

class function TNXJSONRPC.CreateErrorResponse(AID: TJSONData;
  const ACode: Integer; const AMessage: UTF8String; AData: TNXJSONRPCValue;
  APolicy: TNXJSONRPCEnvelopePolicy): TJSONObject;
var
  lError: TNXJSONRPCError;
begin
  Result := TJSONObject.Create;
  lError := nil;
  try
    if APolicy = jepStandard then
      Result.Add('jsonrpc', Version);

    if AID = nil then
      Result.Add('id', TJSONNull.Create)
    else
      Result.Add('id', AID.Clone);

    lError := TNXJSONRPCError.Create;
    lError.code.Value := ACode;
    lError.message.Value := AMessage;
    if AData <> nil then
      lError.data.Assign(AData);

    Result.Add('error', lError.ToJSONData);
    FreeAndNil(lError);
  except
    lError.Free;
    Result.Free;
    raise;
  end;
end;

end.

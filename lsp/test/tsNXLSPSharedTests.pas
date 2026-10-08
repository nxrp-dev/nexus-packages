(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXLSPSharedTests;

{$mode objfpc}{$H+}

interface

uses
  obNXTestRegistry;

procedure RegisterNXLSPSharedTests(ARegistry: TNXTestRegistry);

implementation

uses
  SysUtils,
  fpjson,
  jsonparser,
  obNXClassFactory,
  obNXJSONRPCMessages,
  obNXJSONRPCObjects,
  obNXJSONValues,
  obNXLSTransport,
  obNXLSServer,
  obNXLSDispatcher,
  obNXLSOutboundDispatcher,
  obNXTestContext,
  obNXTestSuite;

type
  TNXLSPTestTransport = class(TNXLSTransport)
  private
    FOpen: Boolean;
    FOutput: string;
    FRead: Boolean;
  protected
    function ReadLine(out ALine: string): Boolean; override;
    function ReadContent(const ALength: Integer; out AContent: string): Boolean; override;
    procedure WriteContent(const AContent: string); override;
  public
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
    function ReadMessage(out AMessage: string): Boolean; override;
    function LastPayload: string;
  end;

  TNXLSPTestApplication = class(TNXLSServerApplication)
  private
    FAttachedTransport: TNXLSTransport;
    FResponseReceived: Boolean;
  public
    function ServerName: string; override;
    procedure AttachTransport(ATransport: TNXLSTransport); override;
    function ReceiveClientResponse(AMessage: TNXJSONRPCMessage): Boolean; override;
    property AttachedTransport: TNXLSTransport read FAttachedTransport;
    property ResponseReceived: Boolean read FResponseReceived;
  end;

  TNXLSPFailingApplication = class(TNXLSServerApplication)
  public
    class var Destroyed: Boolean;
    destructor Destroy; override;
    function ServerName: string; override;
    procedure AttachTransport(ATransport: TNXLSTransport); override;
    function ReceiveClientResponse(AMessage: TNXJSONRPCMessage): Boolean; override;
  end;

  TNXLSPTrackedTransport = class(TNXLSPTestTransport)
  public
    class var Destroyed: Boolean;
    destructor Destroy; override;
  end;

  TNXLSPTestResult = class(TNXJSONRPCCommandResult)
  private
    Faccepted: TNXJSONBoolean;
  published
    property accepted: TNXJSONBoolean read Faccepted write Faccepted;
  end;

  TNXLSPTestOutboundRequest = class(TNXJSONRPCOutboundCommand)
  private
    function GetResult: TNXLSPTestResult;
    procedure SetResult(AValue: TNXLSPTestResult);
  public
    class var Processed: Boolean;
    class function GetFactoryName: string; override;
    procedure ProcessOutboundResult; override;
  published
    property result: TNXLSPTestResult read GetResult write SetResult;
  end;

  TNXLSPTestInboundRequest = class(TNXJSONRPCRequest)
  public
    class function GetFactoryName: string; override;
    class function GetResultKind: TNXJSONRPCResultKind; override;
    function Execute: TNXJSONRPCValue; override;
  end;

function TNXLSPTestTransport.ReadLine(out ALine: string): Boolean;
begin
  ALine := '';
  Result := False;
end;

function TNXLSPTestTransport.ReadContent(const ALength: Integer;
  out AContent: string): Boolean;
begin
  AContent := '';
  Result := False;
end;

procedure TNXLSPTestTransport.WriteContent(const AContent: string);
begin
  FOutput := FOutput + AContent;
end;

function TNXLSPTestTransport.LastPayload: string;
var
  lPos: Integer;
begin
  Result := '';
  lPos := Pos(#13#10#13#10, FOutput);
  if lPos > 0 then
    Result := Copy(FOutput, lPos + 4, MaxInt);
end;

procedure TNXLSPTestTransport.Open;
begin
  FOpen := True;
end;

procedure TNXLSPTestTransport.Close;
begin
  FOpen := False;
end;

function TNXLSPTestTransport.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TNXLSPTestTransport.ReadMessage(out AMessage: string): Boolean;
begin
  if FRead then
  begin
    AMessage := '';
    Exit(False);
  end;

  FRead := True;
  AMessage := '{"jsonrpc":"2.0","id":1,"result":null}';
  Result := True;
end;

function TNXLSPTestApplication.ServerName: string;
begin
  Result := 'Shared LSP Test';
end;

procedure TNXLSPTestApplication.AttachTransport(ATransport: TNXLSTransport);
begin
  FAttachedTransport := ATransport;
end;

function TNXLSPTestApplication.ReceiveClientResponse(
  AMessage: TNXJSONRPCMessage): Boolean;
begin
  FResponseReceived := AMessage <> nil;
  Result := FResponseReceived;
end;

destructor TNXLSPFailingApplication.Destroy;
begin
  Destroyed := True;
  inherited Destroy;
end;

function TNXLSPFailingApplication.ServerName: string;
begin
  Result := 'Failing LSP Test';
end;

procedure TNXLSPFailingApplication.AttachTransport(
  ATransport: TNXLSTransport);
begin
  raise Exception.Create('Attachment failure');
end;

function TNXLSPFailingApplication.ReceiveClientResponse(
  AMessage: TNXJSONRPCMessage): Boolean;
begin
  Result := False;
end;

destructor TNXLSPTrackedTransport.Destroy;
begin
  Destroyed := True;
  inherited Destroy;
end;

function TNXLSPTestOutboundRequest.GetResult: TNXLSPTestResult;
begin
  Result := TNXLSPTestResult(inherited result);
end;

procedure TNXLSPTestOutboundRequest.SetResult(AValue: TNXLSPTestResult);
begin
  inherited result := AValue;
end;

class function TNXLSPTestOutboundRequest.GetFactoryName: string;
begin
  Result := 'shared/testRequest';
end;

procedure TNXLSPTestOutboundRequest.ProcessOutboundResult;
begin
  Processed := result.accepted.Value;
end;

class function TNXLSPTestInboundRequest.GetFactoryName: string;
begin
  Result := 'shared/explicitRequest';
end;

class function TNXLSPTestInboundRequest.GetResultKind: TNXJSONRPCResultKind;
begin
  Result := rkNullResult;
end;

function TNXLSPTestInboundRequest.Execute: TNXJSONRPCValue;
begin
  Result := TNXJSONNull.Create;
end;

procedure TestDispatcherHasNoConcreteRegistryDependency(AContext: TNXTestContext);
var
  lMessage: TNXJSONRPCMessage;
  lResponse: string;
begin
  lMessage := TNXJSONRPC.ParseMessage(
    '{"jsonrpc":"2.0","id":1,"method":"shared/notRegistered"}');
  try
    AContext.AssertTrue(TNXLSDispatcher.DispatchMessage(lMessage, lResponse),
      'An unknown request should produce a response.');
    AContext.AssertTrue(Pos('Method not found', lResponse) > 0,
      'The shared dispatcher should resolve only explicitly registered requests.');
  finally
    lMessage.Free;
  end;
end;

procedure TestHostInjectsApplication(AContext: TNXTestContext);
var
  lApplication: TNXLSPTestApplication;
  lServer: TNXLSServer;
  lTransport: TNXLSPTestTransport;
begin
  lTransport := TNXLSPTestTransport.Create;
  lApplication := TNXLSPTestApplication.Create;
  lServer := TNXLSServer.Create(lTransport, lApplication);
  try
    AContext.AssertTrue(lApplication.AttachedTransport = lTransport,
      'The host should attach its transport to the injected application.');
    lServer.Execute;
    AContext.AssertTrue(lApplication.ResponseReceived,
      'The host should pass client responses to the injected application.');
  finally
    lServer.Free;
  end;
end;

procedure TestDispatcherUsesExplicitRegistration(AContext: TNXTestContext);
var
  lJSON: TJSONData;
  lMessage: TNXJSONRPCMessage;
  lResponse: string;
begin
  if not TNXClassFactory.Registered(
    TNXLSPTestInboundRequest.GetFactoryName) then
    TNXClassFactory.RegisterClass(TNXLSPTestInboundRequest);
  lMessage := TNXJSONRPC.ParseMessage(
    '{"jsonrpc":"2.0","id":2,"method":"shared/explicitRequest"}');
  lJSON := nil;
  try
    AContext.AssertTrue(TNXLSDispatcher.DispatchMessage(lMessage, lResponse),
      'An explicitly registered shared request should dispatch.');
    lJSON := GetJSON(lResponse);
    AContext.AssertTrue(TJSONObject(lJSON).Find('result').JSONType = jtNull,
      'The explicitly registered request should return its null result.');
  finally
    lJSON.Free;
    lMessage.Free;
  end;
end;

procedure TestOutboundDispatcherOwnsResponseFlow(AContext: TNXTestContext);
var
  lDispatcher: TNXLSOutboundDispatcher;
  lJSON: TJSONData;
  lRequest: TNXLSPTestOutboundRequest;
  lResponse: TNXJSONRPCMessage;
  lTransport: TNXLSPTestTransport;
begin
  lDispatcher := TNXLSOutboundDispatcher.Create;
  lTransport := TNXLSPTestTransport.Create;
  lRequest := TNXLSPTestOutboundRequest.Create;
  lResponse := nil;
  try
    lTransport.Open;
    lDispatcher.Transport := lTransport;
    TNXLSPTestOutboundRequest.Processed := False;
    AContext.AssertEquals(1, lDispatcher.SendRequest(lRequest),
      'The first shared outbound request should receive ID 1.');
    lRequest := nil;

    lJSON := GetJSON(lTransport.LastPayload);
    try
      AContext.AssertEquals('shared/testRequest',
        TJSONObject(lJSON).Strings['method'],
        'The outbound dispatcher should serialize the typed factory name.');
    finally
      lJSON.Free;
    end;

    lResponse := TNXJSONRPC.ParseMessage(
      '{"jsonrpc":"2.0","id":1,"result":{"accepted":true}}');
    AContext.AssertTrue(lDispatcher.ReceiveResponse(lResponse),
      'The dispatcher should consume the matching response.');
    AContext.AssertTrue(TNXLSPTestOutboundRequest.Processed,
      'The original request should process its typed response.');
  finally
    lResponse.Free;
    lRequest.Free;
    lTransport.Free;
    lDispatcher.Free;
  end;
end;

procedure TestHostOwnsArgumentsWhenAttachmentRaises(AContext: TNXTestContext);
var
  lRaised: Boolean;
begin
  TNXLSPFailingApplication.Destroyed := False;
  TNXLSPTrackedTransport.Destroyed := False;
  lRaised := False;
  try
    TNXLSServer.Create(TNXLSPTrackedTransport.Create,
      TNXLSPFailingApplication.Create);
  except
    on lException: Exception do
      lRaised := True;
  end;

  AContext.AssertTrue(lRaised,
    'The attachment failure should leave the constructor.');
  AContext.AssertTrue(TNXLSPFailingApplication.Destroyed,
    'The failed host constructor should free its accepted application.');
  AContext.AssertTrue(TNXLSPTrackedTransport.Destroyed,
    'The failed host constructor should free its accepted transport.');
end;

procedure RegisterNXLSPSharedTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NexusLSP.Shared');
  lSuite.AddTest('DispatcherHasNoConcreteRegistryDependency',
    @TestDispatcherHasNoConcreteRegistryDependency);
  lSuite.AddTest('HostInjectsApplication', @TestHostInjectsApplication);
  lSuite.AddTest('DispatcherUsesExplicitRegistration',
    @TestDispatcherUsesExplicitRegistration);
  lSuite.AddTest('OutboundDispatcherOwnsResponseFlow',
    @TestOutboundDispatcherOwnsResponseFlow);
  lSuite.AddTest('HostOwnsArgumentsWhenAttachmentRaises',
    @TestHostOwnsArgumentsWhenAttachmentRaises);
end;

end.

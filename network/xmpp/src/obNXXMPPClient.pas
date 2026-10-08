(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPClient;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs,
  obNXXMPPCommand, obNXXMPPConfig, obNXXMPPConnection,
  obNXXMPPDisco, obNXXMPPDispatcher, obNXXMPPError, obNXXMPPModule,
  obNXXMPPQueue, obNXXMPPRequestManager, obNXXMPPStanza,
  obNXXMPPRoster,
  tpNXXMPPMessageTypes, tpNXXMPPTypes, utNXXMPPIDs, utNXXMPPXML;

type
  TNXXMPPStateEvent = procedure(ASender: TObject;
    AState: TNXXMPPConnectionState) of object;
  TNXXMPPStanzaEvent = procedure(ASender: TObject;
    AStanza: TNXXMPPStanza) of object;
  TNXXMPPErrorEvent = procedure(ASender: TObject; AStage: TNXXMPPErrorStage;
    const ACondition, AMessage: UTF8String) of object;
  TNXXMPPUnrecoverableStanzasEvent = procedure(ASender: TObject;
    const AReason: UTF8String; AStanzas: TStrings) of object;

  TNXXMPPClient = class
  private
    FCommands: TNXXMPPObjectQueue;
    FConfig: TNXXMPPClientConfig;
    FConnection: TNXXMPPConnection;
    FDispatcher: TNXXMPPDispatcher;
    FIQCapacity: TNXXMPPIQCapacity;
    FModules: TObjectList;
    FModulesFrozen: Boolean;
    FOnError: TNXXMPPErrorEvent;
    FOnStanza: TNXXMPPStanzaEvent;
    FOnState: TNXXMPPStateEvent;
    FOnUnrecoverableStanzas: TNXXMPPUnrecoverableStanzasEvent;
    FState: TNXXMPPConnectionState;
    procedure DoOnCompletion(ACompletion: TNXXMPPIQCompletionEvent);
    procedure DoOnError(AStage: TNXXMPPErrorStage;
      const ACondition, AMessage: UTF8String);
    procedure DoOnModuleLifecycle(ALifecycle: TNXXMPPModuleLifecycle);
    procedure DoOnStanza(AStanza: TNXXMPPStanza);
    procedure DoOnState(AState: TNXXMPPConnectionState);
    procedure DoOnUnrecoverableStanzas(const AReason: UTF8String;
      AStanzas: TStrings);
    function EnqueueCommand(ACommand: TNXXMPPCommand): Boolean;
    function EnqueueModuleCommand(AModule: TObject;
      AOperation: TNXXMPPModuleOperation): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddModule(AModule: TNXXMPPModule);
    procedure Connect;
    procedure Disconnect;
    function SendIQ(AType: TNXXMPPIQType; const AToJID, AExpectedFrom,
      APayload: UTF8String; AHandler: TNXXMPPIQCompletionHandler;
      ATimeoutMS: Cardinal = cNXXMPPDefaultTimeoutMS): Boolean;
    function SendMessage(const AToJID, ABody: UTF8String;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    function RequestRoster(ARoster: TNXXMPPRosterModule;
      ATimeoutMS: Cardinal = cNXXMPPDefaultTimeoutMS): Boolean;
    function SendPresence(const AType: UTF8String = ''): Boolean;
    function SendRaw(const AXML: UTF8String): Boolean;
    function State: TNXXMPPConnectionState;
    property Config: TNXXMPPClientConfig read FConfig;
    property OnError: TNXXMPPErrorEvent read FOnError write FOnError;
    property OnStanza: TNXXMPPStanzaEvent read FOnStanza write FOnStanza;
    property OnState: TNXXMPPStateEvent read FOnState write FOnState;
    property OnUnrecoverableStanzas: TNXXMPPUnrecoverableStanzasEvent
      read FOnUnrecoverableStanzas write FOnUnrecoverableStanzas;
  end;

implementation

constructor TNXXMPPClient.Create;
begin
  inherited Create;
  FConfig := TNXXMPPClientConfig.Create;
  FModules := TObjectList.Create(True);
  FState := xcsDisconnected;
end;

destructor TNXXMPPClient.Destroy;
begin
  Disconnect;
  FIQCapacity.Free;
  FCommands.Free;
  FDispatcher.Free;
  FModules.Free;
  FConfig.Free;
  inherited Destroy;
end;

procedure TNXXMPPClient.AddModule(AModule: TNXXMPPModule);
begin
  if not Assigned(AModule) then
    raise ENXXMPPError.Create(xesConfiguration, 'missing-module',
      'An XMPP module is required.');
  if FModulesFrozen then
    raise ENXXMPPError.Create(xesConfiguration, 'modules-frozen',
      'XMPP modules cannot change while connected.');
  FModules.Add(AModule);
end;

procedure TNXXMPPClient.Connect;
var
  lFeatures: TStringList;
  lIndex: Integer;
  lFeatureIndex: Integer;
begin
  if Assigned(FConnection) then
    raise ENXXMPPError.Create(xesConfiguration, 'already-connected',
      'The XMPP client already has an active connection.');
  FConfig.Validate;
  FreeAndNil(FCommands);
  FreeAndNil(FDispatcher);
  FreeAndNil(FIQCapacity);
  FCommands := TNXXMPPObjectQueue.Create(FConfig.CommandCapacity);
  FDispatcher := TNXXMPPDispatcher.Create;
  FIQCapacity := TNXXMPPIQCapacity.Create(FConfig.PendingIQCapacity);
  lFeatures := TStringList.Create;
  try
    lFeatures.CaseSensitive := True;
    lFeatures.Sorted := True;
    lFeatures.Duplicates := dupIgnore;
    for lIndex := 0 to FModules.Count - 1 do
    begin
      TNXXMPPModule(FModules[lIndex]).Configure(FConfig);
      TNXXMPPModule(FModules[lIndex]).AddFeatures(lFeatures);
    end;
    for lIndex := 0 to FModules.Count - 1 do
    begin
      if FModules[lIndex] is TNXXMPPDiscoModule then
        for lFeatureIndex := 0 to lFeatures.Count - 1 do
          TNXXMPPDiscoModule(FModules[lIndex]).AddFeature(
            UTF8String(lFeatures[lFeatureIndex]));
      TNXXMPPModule(FModules[lIndex]).RegisterHandlers(FDispatcher);
    end;
  finally
    lFeatures.Free;
  end;
  FModulesFrozen := True;
  FConnection := TNXXMPPConnection.Create(FConfig.Clone, FCommands,
    FDispatcher, FIQCapacity, FModules);
  FConnection.OnCompletion := @DoOnCompletion;
  FConnection.OnError := @DoOnError;
  FConnection.OnModuleLifecycle := @DoOnModuleLifecycle;
  FConnection.OnStanza := @DoOnStanza;
  FConnection.OnState := @DoOnState;
  FConnection.OnUnrecoverableStanzas := @DoOnUnrecoverableStanzas;
  for lIndex := 0 to FModules.Count - 1 do
  begin
    TNXXMPPModule(FModules[lIndex]).Sender := @FConnection.SendModuleXML;
    TNXXMPPModule(FModules[lIndex]).Submitter := @EnqueueModuleCommand;
    TNXXMPPModule(FModules[lIndex]).IQSubmitter := @SendIQ;
  end;
  FConnection.Start;
end;

procedure TNXXMPPClient.Disconnect;
var
  lIndex: Integer;
begin
  if not Assigned(FConnection) then
    Exit;
  FConnection.RequestDisconnect;
  FConnection.WaitFor;
  FState := FConnection.State;
  FreeAndNil(FConnection);
  for lIndex := 0 to FModules.Count - 1 do
  begin
    TNXXMPPModule(FModules[lIndex]).Sender := nil;
    TNXXMPPModule(FModules[lIndex]).Submitter := nil;
    TNXXMPPModule(FModules[lIndex]).IQSubmitter := nil;
  end;
  if FState <> xcsFailed then
    FState := xcsDisconnected;
  FModulesFrozen := False;
end;

function TNXXMPPClient.EnqueueModuleCommand(AModule: TObject;
  AOperation: TNXXMPPModuleOperation): Boolean;
begin
  if not Assigned(AOperation) then
    Exit(False);
  if not FModulesFrozen or (FModules.IndexOf(AModule) < 0) then
  begin
    AOperation.Free;
    Exit(False);
  end;
  Result := EnqueueCommand(TNXXMPPCommand.CreateModule(AModule, AOperation));
end;

function TNXXMPPClient.EnqueueCommand(ACommand: TNXXMPPCommand): Boolean;
begin
  Result := Assigned(FConnection) and FCommands.Enqueue(ACommand);
  if not Result then
    ACommand.Free;
end;

function TNXXMPPClient.SendRaw(const AXML: UTF8String): Boolean;
begin
  if AXML = '' then
    Exit(False);
  Result := EnqueueCommand(TNXXMPPCommand.CreateRaw(AXML, xrpNever));
end;

function TNXXMPPClient.SendMessage(const AToJID, ABody: UTF8String;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
begin
  AIdentity.StanzaID := '';
  AIdentity.OriginID := '';
  if (AToJID = '') or (ABody = '') then
    Exit(False);
  AIdentity.StanzaID := NXXMPPCreateID;
  AIdentity.OriginID := NXXMPPCreateID;
  Result := EnqueueCommand(TNXXMPPCommand.CreateRaw('<message to=''' +
    NXXMPPEscapeAttribute(AToJID) +
    ''' type=''chat'' id=''' + NXXMPPEscapeAttribute(AIdentity.StanzaID) +
    '''><body>' + NXXMPPEscapeText(ABody) +
    '</body><origin-id xmlns=''urn:xmpp:sid:0'' id=''' +
    NXXMPPEscapeAttribute(AIdentity.OriginID) + '''/>' +
    '</message>', xrpStreamManaged));
  if not Result then
  begin
    AIdentity.StanzaID := '';
    AIdentity.OriginID := '';
  end;
end;

function TNXXMPPClient.RequestRoster(ARoster: TNXXMPPRosterModule;
  ATimeoutMS: Cardinal): Boolean;
begin
  if not Assigned(ARoster) or (FModules.IndexOf(ARoster) < 0) then
    Exit(False);
  Result := SendIQ(xitGet, '', '', TNXXMPPRosterModule.RequestPayload,
    @ARoster.CompleteRequest, ATimeoutMS);
end;

function TNXXMPPClient.SendPresence(const AType: UTF8String): Boolean;
begin
  if AType = '' then
    Result := EnqueueCommand(TNXXMPPCommand.CreateRaw('<presence/>',
      xrpStreamManaged))
  else
    Result := EnqueueCommand(TNXXMPPCommand.CreateRaw('<presence type=''' +
      NXXMPPEscapeAttribute(AType) + '''/>', xrpStreamManaged));
end;

function TNXXMPPClient.SendIQ(AType: TNXXMPPIQType; const AToJID,
  AExpectedFrom, APayload: UTF8String; AHandler: TNXXMPPIQCompletionHandler;
  ATimeoutMS: Cardinal): Boolean;
begin
  if not (AType in [xitGet, xitSet]) or (APayload = '') then
    Exit(False);
  if not Assigned(FIQCapacity) or not FIQCapacity.TryReserve then
    Exit(False);
  Result := EnqueueCommand(TNXXMPPCommand.CreateIQ(AType, AToJID,
    AExpectedFrom, APayload, ATimeoutMS, AHandler));
  if not Result then
    FIQCapacity.Release;
end;

procedure TNXXMPPClient.DoOnCompletion(
  ACompletion: TNXXMPPIQCompletionEvent);
begin
  if Assigned(ACompletion) then
    ACompletion.Invoke;
end;

procedure TNXXMPPClient.DoOnError(AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: UTF8String);
begin
  if Assigned(FOnError) then
    FOnError(Self, AStage, ACondition, AMessage);
end;

procedure TNXXMPPClient.DoOnModuleLifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
var
  lIndex: Integer;
begin
  for lIndex := 0 to FModules.Count - 1 do
    TNXXMPPModule(FModules[lIndex]).PumpLifecycle(ALifecycle);
end;

procedure TNXXMPPClient.DoOnStanza(AStanza: TNXXMPPStanza);
var
  lIndex: Integer;
begin
  for lIndex := 0 to FModules.Count - 1 do
    TNXXMPPModule(FModules[lIndex]).PumpStanza(AStanza);
  if Assigned(FOnStanza) then
    FOnStanza(Self, AStanza);
end;

procedure TNXXMPPClient.DoOnState(AState: TNXXMPPConnectionState);
begin
  FState := AState;
  if Assigned(FOnState) then
    FOnState(Self, AState);
end;

procedure TNXXMPPClient.DoOnUnrecoverableStanzas(
  const AReason: UTF8String; AStanzas: TStrings);
begin
  if Assigned(FOnUnrecoverableStanzas) then
    FOnUnrecoverableStanzas(Self, AReason, AStanzas);
end;

function TNXXMPPClient.State: TNXXMPPConnectionState;
begin
  if Assigned(FConnection) then
    Result := FConnection.State
  else
    Result := FState;
end;

end.

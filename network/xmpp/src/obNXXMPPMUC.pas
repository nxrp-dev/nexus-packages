(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPMUC;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, DOM, SyncObjs, obNXXMPPCommand, obNXXMPPConfig,
  obNXXMPPDispatcher, obNXXMPPMessage, obNXXMPPModule,
  obNXXMPPRequestManager, obNXXMPPStanza, tpNXXMPPMessageTypes,
  tpNXXMPPTypes, utNXXMPPDateTime, utNXXMPPDOM, utNXXMPPIDs, utNXXMPPXML;

type
  TNXXMPPRoomState = (xrsJoining, xrsCreating, xrsConfiguring, xrsJoined,
    xrsLeaving, xrsStale, xrsRejoining, xrsFailed, xrsLeft);

  TNXXMPPMUCRoomEntryMode = (xremJoin, xremCreateInstant,
    xremJoinOrCreateInstant);

  TNXXMPPOccupant = class
  private
    FAffiliation: TNXXMPPMUCAffiliation;
    FAvailable: Boolean;
    FJID: UTF8String;
    FNick: UTF8String;
    FOccupantID: UTF8String;
    FRealJID: UTF8String;
    FRole: TNXXMPPMUCRole;
    FSelf: Boolean;
    FStatus: UTF8String;
  public
    property Affiliation: TNXXMPPMUCAffiliation read FAffiliation;
    property Available: Boolean read FAvailable;
    property JID: UTF8String read FJID;
    property Nick: UTF8String read FNick;
    property OccupantID: UTF8String read FOccupantID;
    property RealJID: UTF8String read FRealJID;
    property Role: TNXXMPPMUCRole read FRole;
    property Self: Boolean read FSelf;
    property Status: UTF8String read FStatus;
  end;

  TNXXMPPRoom = class
  private
    FAutoRejoin: Boolean;
    FEntryMode: TNXXMPPMUCRoomEntryMode;
    FJID: UTF8String;
    FNick: UTF8String;
    FOccupants: TObjectList;
    FPassword: UTF8String;
    FState: TNXXMPPRoomState;
    FHistoryCount: Integer;
    FLastError: TNXXMPPMUCError;
    FLastTransitionReason: TNXXMPPMUCTransitionReason;
    FStatusCodes: TNXXMPPMUCStatusCodeArray;
    FSubject: UTF8String;
  public
    constructor Create;
    destructor Destroy; override;
    function Occupant(const ANick: UTF8String): TNXXMPPOccupant;
    function OccupantByID(const AOccupantID: UTF8String): TNXXMPPOccupant;
    function OccupantCount: Integer;
    property AutoRejoin: Boolean read FAutoRejoin write FAutoRejoin;
    property JID: UTF8String read FJID;
    property Nick: UTF8String read FNick;
    property Password: UTF8String read FPassword;
    property State: TNXXMPPRoomState read FState;
    property HistoryCount: Integer read FHistoryCount;
    property LastError: TNXXMPPMUCError read FLastError;
    property LastTransitionReason: TNXXMPPMUCTransitionReason
      read FLastTransitionReason;
    property StatusCodes: TNXXMPPMUCStatusCodeArray read FStatusCodes;
    property Subject: UTF8String read FSubject;
  end;

  TNXXMPPRoomStateEvent = procedure(ASender: TObject; ARoom: TNXXMPPRoom)
    of object;
  TNXXMPPRoomMessageEvent = procedure(ASender: TObject; ARoom: TNXXMPPRoom;
    AMessage: TNXXMPPMessage) of object;
  TNXXMPPMUCChatStateEvent = procedure(ASender: TObject; ARoom: TNXXMPPRoom;
    const AOccupantJID: UTF8String; AState: TNXXMPPChatState) of object;
  TNXXMPPOccupantEvent = procedure(ASender: TObject; ARoom: TNXXMPPRoom;
    const AOccupantJID, ANick, ARealJID, AOccupantID: UTF8String;
    ARole: TNXXMPPMUCRole; AAffiliation: TNXXMPPMUCAffiliation;
    AAvailable, ASelf: Boolean) of object;

  TNXXMPPMUCOperation = class(TNXXMPPModuleOperation)
  public
    XML: UTF8String;
  end;

  TNXXMPPMUCModule = class(TNXXMPPModule)
  private
    FCriticalSection: TCriticalSection;
    FOnOccupant: TNXXMPPOccupantEvent;
    FOnChatState: TNXXMPPMUCChatStateEvent;
    FOnRoomMessage: TNXXMPPRoomMessageEvent;
    FOnRoomState: TNXXMPPRoomStateEvent;
    FMaximumHistoryMessages: Integer;
    FMaximumOccupants: Integer;
    FMaximumRooms: Integer;
    FPendingConfigurations: TObjectList;
    FSelfPingTimeoutMS: Cardinal;
    FRooms: TObjectList;
    function BeginInstantRoomConfiguration(ARoom: TNXXMPPRoom): Boolean;
    procedure CompleteRoomConfiguration(ARequest: TObject;
      AStanza: TNXXMPPStanza; const AError: UTF8String);
    procedure CompleteLeaveConfirmation(ARequest: TObject;
      AStanza: TNXXMPPStanza; const AError: UTF8String);
    function QueueXML(const AXML: UTF8String): Boolean;
    function StartJoin(const ARoomJID, ANick, APassword: UTF8String;
      const AHistory: TNXXMPPMUCHistoryRequest; AAutoRejoin: Boolean;
      AEntryMode: TNXXMPPMUCRoomEntryMode): Boolean;
    procedure SetState(ARoom: TNXXMPPRoom; AState: TNXXMPPRoomState;
      AReason: TNXXMPPMUCTransitionReason = xmtrNone);
    procedure SelfPingComplete(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    function CreateInstantRoom(const ARoomJID, ANick: UTF8String;
      AAutoRejoin: Boolean = True): Boolean;
    function FindRoom(const AJID: UTF8String): TNXXMPPRoom;
    function JoinOrCreateInstantRoom(const ARoomJID, ANick: UTF8String;
      AAutoRejoin: Boolean = True): Boolean;
    function ChangeNick(const ARoomJID, ANick: UTF8String): Boolean;
    function Join(const ARoomJID, ANick, APassword: UTF8String;
      AAutoRejoin: Boolean = True): Boolean;
    function JoinWithHistory(const ARoomJID, ANick, APassword: UTF8String;
      const AHistory: TNXXMPPMUCHistoryRequest;
      AAutoRejoin: Boolean = True): Boolean;
    procedure Lifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    procedure PumpLifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    function Leave(const ARoomJID: UTF8String): Boolean;
    procedure ProcessCommand(AOperation: TNXXMPPModuleOperation); override;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    function SendGroupMessage(const ARoomJID, ABody: UTF8String): Boolean;
    function SendGroupReply(const ARoomJID, ABody: UTF8String;
      AMessage: TNXXMPPMessage;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    function SendPrivateMessage(const AOccupantJID, ABody: UTF8String): Boolean;
    function SetSubject(const ARoomJID, ASubject: UTF8String): Boolean;
    property OnOccupant: TNXXMPPOccupantEvent read FOnOccupant
      write FOnOccupant;
    property OnChatState: TNXXMPPMUCChatStateEvent read FOnChatState
      write FOnChatState;
    property OnRoomMessage: TNXXMPPRoomMessageEvent read FOnRoomMessage
      write FOnRoomMessage;
    property OnRoomState: TNXXMPPRoomStateEvent read FOnRoomState
      write FOnRoomState;
    property MaximumHistoryMessages: Integer read FMaximumHistoryMessages
      write FMaximumHistoryMessages;
  end;

implementation

type
  TNXXMPPRoomConfigurationRequest = class
  private
    FModule: TNXXMPPMUCModule;
    FRoom: TNXXMPPRoom;
  public
    constructor Create(AModule: TNXXMPPMUCModule; ARoom: TNXXMPPRoom);
    procedure Complete(AStanza: TNXXMPPStanza; const AError: UTF8String);
  end;

  TNXXMPPRoomLeaveConfirmation = class
  private
    FModule: TNXXMPPMUCModule;
    FRoom: TNXXMPPRoom;
  public
    constructor Create(AModule: TNXXMPPMUCModule; ARoom: TNXXMPPRoom);
    procedure Complete(AStanza: TNXXMPPStanza; const AError: UTF8String);
  end;

constructor TNXXMPPRoomConfigurationRequest.Create(
  AModule: TNXXMPPMUCModule; ARoom: TNXXMPPRoom);
begin
  inherited Create;
  FModule := AModule;
  FRoom := ARoom;
end;

procedure TNXXMPPRoomConfigurationRequest.Complete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  FModule.CompleteRoomConfiguration(Self, AStanza, AError);
end;

constructor TNXXMPPRoomLeaveConfirmation.Create(
  AModule: TNXXMPPMUCModule; ARoom: TNXXMPPRoom);
begin
  inherited Create;
  FModule := AModule;
  FRoom := ARoom;
end;

procedure TNXXMPPRoomLeaveConfirmation.Complete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  FModule.CompleteLeaveConfirmation(Self, AStanza, AError);
end;

constructor TNXXMPPRoom.Create;
begin
  inherited Create;
  FOccupants := TObjectList.Create(True);
end;

destructor TNXXMPPRoom.Destroy;
begin
  FOccupants.Free;
  inherited Destroy;
end;

function TNXXMPPRoom.Occupant(const ANick: UTF8String): TNXXMPPOccupant;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to FOccupants.Count - 1 do
    if TNXXMPPOccupant(FOccupants[lIndex]).Nick = ANick then
      Exit(TNXXMPPOccupant(FOccupants[lIndex]));
end;

function TNXXMPPRoom.OccupantCount: Integer;
begin
  Result := FOccupants.Count;
end;

function TNXXMPPRoom.OccupantByID(
  const AOccupantID: UTF8String): TNXXMPPOccupant;
var
  lIndex: Integer;
begin
  Result := nil;
  if AOccupantID = '' then
    Exit;
  for lIndex := 0 to FOccupants.Count - 1 do
    if TNXXMPPOccupant(FOccupants[lIndex]).OccupantID = AOccupantID then
      Exit(TNXXMPPOccupant(FOccupants[lIndex]));
end;

procedure TNXXMPPMUCModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add('http://jabber.org/protocol/muc');
  AFeatures.Add('urn:xmpp:occupant-id:0');
end;

constructor TNXXMPPMUCModule.Create;
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  FRooms := TObjectList.Create(True);
  FPendingConfigurations := TObjectList.Create(True);
  FMaximumHistoryMessages := 100;
  FMaximumOccupants := 512;
  FMaximumRooms := 32;
  FSelfPingTimeoutMS := 10000;
end;

procedure TNXXMPPMUCModule.Configure(AConfig: TNXXMPPClientConfig);
begin
  FMaximumHistoryMessages := AConfig.MUCHistoryCapacity;
  FMaximumOccupants := AConfig.MUCOccupantCapacity;
  FMaximumRooms := AConfig.MUCRoomCapacity;
  FSelfPingTimeoutMS := AConfig.MUCSelfPingTimeoutMS;
end;

destructor TNXXMPPMUCModule.Destroy;
begin
  FPendingConfigurations.Free;
  FRooms.Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TNXXMPPMUCModule.RegisterHandlers(ADispatcher: TNXXMPPDispatcher);
begin
end;

function TNXXMPPMUCModule.FindRoom(const AJID: UTF8String): TNXXMPPRoom;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to FRooms.Count - 1 do
    if TNXXMPPRoom(FRooms[lIndex]).JID = AJID then
      Exit(TNXXMPPRoom(FRooms[lIndex]));
end;

procedure TNXXMPPMUCModule.SetState(ARoom: TNXXMPPRoom;
  AState: TNXXMPPRoomState; AReason: TNXXMPPMUCTransitionReason);
begin
  if Assigned(ARoom) then
  begin
    ARoom.FState := AState;
    ARoom.FLastTransitionReason := AReason;
  end;
end;

function TNXXMPPMUCModule.QueueXML(const AXML: UTF8String): Boolean;
var
  lOperation: TNXXMPPMUCOperation;
begin
  lOperation := TNXXMPPMUCOperation.Create;
  lOperation.XML := AXML;
  Result := Submit(lOperation);
end;

function TNXXMPPMUCModule.BeginInstantRoomConfiguration(
  ARoom: TNXXMPPRoom): Boolean;
var
  lRequest: TNXXMPPRoomConfigurationRequest;
begin
  Result := False;
  if not Assigned(ARoom) then
    Exit;
  lRequest := TNXXMPPRoomConfigurationRequest.Create(Self, ARoom);
  FPendingConfigurations.Add(lRequest);
  Result := SubmitIQ(xitSet, ARoom.JID, ARoom.JID,
    '<query xmlns=''http://jabber.org/protocol/muc#owner''>' +
    '<x xmlns=''jabber:x:data'' type=''submit''/></query>',
    @lRequest.Complete);
  if not Result then
  begin
    FPendingConfigurations.Extract(lRequest);
    lRequest.Free;
  end;
end;

procedure TNXXMPPMUCModule.CompleteRoomConfiguration(ARequest: TObject;
  AStanza: TNXXMPPStanza; const AError: UTF8String);
var
  lError: TDOMElement;
  lErrorChild: TDOMElement;
  lRequest: TNXXMPPRoomConfigurationRequest;
  lRoom: TNXXMPPRoom;
begin
  if not (ARequest is TNXXMPPRoomConfigurationRequest) or
    (FPendingConfigurations.IndexOf(ARequest) < 0) then
    Exit;
  lRequest := TNXXMPPRoomConfigurationRequest(ARequest);
  lRoom := lRequest.FRoom;
  lRoom.FEntryMode := xremJoin;
  if (AError = '') and Assigned(AStanza) and
    (AStanza.IQType = xitResult) then
    SetState(lRoom, xrsJoined, xmtrRoomConfigured)
  else
  begin
    lRoom.FLastError.Present := True;
    lRoom.FLastError.ErrorType := '';
    lRoom.FLastError.Condition := 'room-configuration-failed';
    lRoom.FLastError.Text := AError;
    if Assigned(AStanza) and (AStanza.IQType = xitError) then
    begin
      lError := NXXMPPFindChild(AStanza.Root, 'jabber:client', 'error');
      if Assigned(lError) then
      begin
        lRoom.FLastError.ErrorType := UTF8Encode(lError.GetAttribute('type'));
        lErrorChild := NXXMPPFirstChildElement(lError);
        while Assigned(lErrorChild) do
        begin
          if NXXMPPElementNamespaceURI(lErrorChild) =
            'urn:ietf:params:xml:ns:xmpp-stanzas' then
            if NXXMPPElementLocalName(lErrorChild) = 'text' then
              lRoom.FLastError.Text := NXXMPPDirectText(lErrorChild)
            else if lRoom.FLastError.Condition =
              'room-configuration-failed' then
              lRoom.FLastError.Condition := NXXMPPElementLocalName(lErrorChild);
          lErrorChild := NXXMPPNextSiblingElement(lErrorChild);
        end;
      end;
    end;
    SetState(lRoom, xrsFailed, xmtrConfigurationFailed);
    QueueXML('<presence to=''' + NXXMPPEscapeAttribute(
      lRoom.JID + '/' + lRoom.Nick) + ''' type=''unavailable''/>');
  end;
  if Assigned(FOnRoomState) then
    FOnRoomState(Self, lRoom);
  FPendingConfigurations.Extract(lRequest);
  lRequest.Free;
end;

function TNXXMPPMUCModule.Join(const ARoomJID, ANick,
  APassword: UTF8String; AAutoRejoin: Boolean): Boolean;
var
  lHistory: TNXXMPPMUCHistoryRequest;
begin
  lHistory.MaxChars := -1;
  lHistory.MaxStanzas := -1;
  lHistory.Seconds := -1;
  lHistory.SinceTimestamp := '';
  Result := JoinWithHistory(ARoomJID, ANick, APassword, lHistory,
    AAutoRejoin);
end;

function TNXXMPPMUCModule.CreateInstantRoom(const ARoomJID,
  ANick: UTF8String; AAutoRejoin: Boolean): Boolean;
var
  lHistory: TNXXMPPMUCHistoryRequest;
begin
  lHistory.MaxChars := -1;
  lHistory.MaxStanzas := 0;
  lHistory.Seconds := -1;
  lHistory.SinceTimestamp := '';
  Result := StartJoin(ARoomJID, ANick, '', lHistory, AAutoRejoin,
    xremCreateInstant);
end;

function TNXXMPPMUCModule.JoinOrCreateInstantRoom(const ARoomJID,
  ANick: UTF8String; AAutoRejoin: Boolean): Boolean;
var
  lHistory: TNXXMPPMUCHistoryRequest;
begin
  lHistory.MaxChars := -1;
  lHistory.MaxStanzas := 0;
  lHistory.Seconds := -1;
  lHistory.SinceTimestamp := '';
  Result := StartJoin(ARoomJID, ANick, '', lHistory, AAutoRejoin,
    xremJoinOrCreateInstant);
end;

function TNXXMPPMUCModule.JoinWithHistory(const ARoomJID, ANick,
  APassword: UTF8String; const AHistory: TNXXMPPMUCHistoryRequest;
  AAutoRejoin: Boolean): Boolean;
begin
  Result := StartJoin(ARoomJID, ANick, APassword, AHistory, AAutoRejoin,
    xremJoin);
end;

function TNXXMPPMUCModule.StartJoin(const ARoomJID, ANick,
  APassword: UTF8String; const AHistory: TNXXMPPMUCHistoryRequest;
  AAutoRejoin: Boolean; AEntryMode: TNXXMPPMUCRoomEntryMode): Boolean;
var
  lRoom: TNXXMPPRoom;
  lXML: UTF8String;
  lTimestamp: TDateTime;
begin
  if (ARoomJID = '') or (ANick = '') then
    Exit(False);
  if (AHistory.MaxChars < -1) or (AHistory.MaxStanzas < -1) or
    (AHistory.MaxStanzas > FMaximumHistoryMessages) or
    (AHistory.Seconds < -1) or ((AHistory.SinceTimestamp <> '') and
    not NXXMPPTryParseTimestamp(AHistory.SinceTimestamp, lTimestamp)) then
    Exit(False);
  FCriticalSection.Acquire;
  try
    lRoom := FindRoom(ARoomJID);
    if not Assigned(lRoom) then
    begin
      if FRooms.Count >= FMaximumRooms then
        Exit(False);
      lRoom := TNXXMPPRoom.Create;
      lRoom.FJID := ARoomJID;
      FRooms.Add(lRoom);
    end;
    lRoom.FNick := ANick;
    lRoom.FPassword := APassword;
    lRoom.FAutoRejoin := AAutoRejoin;
    lRoom.FEntryMode := AEntryMode;
    if AEntryMode <> xremJoin then
      SetState(lRoom, xrsCreating, xmtrCreateRequested)
    else
      SetState(lRoom, xrsJoining, xmtrJoinRequested);
  finally
    FCriticalSection.Release;
  end;
  lXML := '<presence to=''' + NXXMPPEscapeAttribute(ARoomJID + '/' + ANick) +
    '''><x xmlns=''http://jabber.org/protocol/muc''>';
  if APassword <> '' then
    lXML := lXML + '<password>' + NXXMPPEscapeText(APassword) + '</password>';
  if (AHistory.MaxChars >= 0) or (AHistory.MaxStanzas >= 0) or
    (AHistory.Seconds >= 0) or (AHistory.SinceTimestamp <> '') then
  begin
    lXML := lXML + '<history';
    if AHistory.MaxChars >= 0 then
      lXML := lXML + ' maxchars=''' + UTF8String(IntToStr(
        AHistory.MaxChars)) + '''';
    if AHistory.MaxStanzas >= 0 then
      lXML := lXML + ' maxstanzas=''' + UTF8String(IntToStr(
        AHistory.MaxStanzas)) + '''';
    if AHistory.Seconds >= 0 then
      lXML := lXML + ' seconds=''' + UTF8String(IntToStr(
        AHistory.Seconds)) + '''';
    if AHistory.SinceTimestamp <> '' then
      lXML := lXML + ' since=''' +
        NXXMPPEscapeAttribute(AHistory.SinceTimestamp) + '''';
    lXML := lXML + '/>';
  end;
  Result := QueueXML(lXML + '</x></presence>');
  if not Result then
  begin
    lRoom.FEntryMode := xremJoin;
    SetState(lRoom, xrsFailed, xmtrServiceError);
  end;
end;

function TNXXMPPMUCModule.SendGroupReply(const ARoomJID,
  ABody: UTF8String; AMessage: TNXXMPPMessage;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
var
  lReferencedID: UTF8String;
  lRoom: TNXXMPPRoom;
  lXML: UTF8String;
begin
  AIdentity.StanzaID := '';
  AIdentity.OriginID := '';
  lRoom := FindRoom(ARoomJID);
  if not Assigned(lRoom) or (lRoom.State <> xrsJoined) or
    not Assigned(AMessage) or (ABody = '') or
    not AMessage.StanzaIDFor(ARoomJID, lReferencedID) then
    Exit(False);
  AIdentity.StanzaID := NXXMPPCreateID;
  AIdentity.OriginID := NXXMPPCreateID;
  lXML := '<message to=''' + NXXMPPEscapeAttribute(ARoomJID) +
    ''' type=''groupchat'' id=''' + NXXMPPEscapeAttribute(
    AIdentity.StanzaID) + '''><body>' + NXXMPPEscapeText(ABody) +
    '</body><origin-id xmlns=''urn:xmpp:sid:0'' id=''' +
    NXXMPPEscapeAttribute(AIdentity.OriginID) + '''/><reply xmlns=' +
    '''urn:xmpp:reply:0'' id=''' + NXXMPPEscapeAttribute(lReferencedID) +
    '''/></message>';
  Result := QueueXML(lXML);
  if not Result then
  begin
    AIdentity.StanzaID := '';
    AIdentity.OriginID := '';
  end;
end;

function TNXXMPPMUCModule.Leave(const ARoomJID: UTF8String): Boolean;
var
  lConfirmation: TNXXMPPRoomLeaveConfirmation;
  lRoom: TNXXMPPRoom;
begin
  lRoom := FindRoom(ARoomJID);
  if not Assigned(lRoom) then
    Exit(False);
  SetState(lRoom, xrsLeaving, xmtrLeaveRequested);
  Result := QueueXML('<presence to=''' +
    NXXMPPEscapeAttribute(lRoom.JID + '/' + lRoom.Nick) +
    ''' type=''unavailable''/>');
  if not Result then
    Exit;
  lConfirmation := TNXXMPPRoomLeaveConfirmation.Create(Self, lRoom);
  if not SubmitIQ(xitGet, lRoom.JID + '/' + lRoom.Nick,
    lRoom.JID + '/' + lRoom.Nick, '<ping xmlns=''urn:xmpp:ping''/>',
    @lConfirmation.Complete, FSelfPingTimeoutMS) then
    lConfirmation.Free;
end;

procedure TNXXMPPMUCModule.CompleteLeaveConfirmation(ARequest: TObject;
  AStanza: TNXXMPPStanza; const AError: UTF8String);
var
  lAbsent: Boolean;
  lError: TDOMElement;
  lRequest: TNXXMPPRoomLeaveConfirmation;
begin
  lRequest := TNXXMPPRoomLeaveConfirmation(ARequest);
  try
    if lRequest.FRoom.State <> xrsLeaving then
      Exit;
    if Assigned(AStanza) then
      lError := NXXMPPFindChild(AStanza.Root, 'jabber:client', 'error')
    else
      lError := nil;
    lAbsent := Assigned(AStanza) and (AStanza.IQType = xitError) and
      Assigned(lError) and
      (Assigned(NXXMPPFindChild(lError,
        'urn:ietf:params:xml:ns:xmpp-stanzas', 'not-acceptable')) or
      Assigned(NXXMPPFindChild(lError,
        'urn:ietf:params:xml:ns:xmpp-stanzas', 'not-allowed')) or
      Assigned(NXXMPPFindChild(lError,
        'urn:ietf:params:xml:ns:xmpp-stanzas', 'bad-request')));
    if not lAbsent then
      Exit;
    SetState(lRequest.FRoom, xrsLeft, xmtrLeft);
    if Assigned(FOnRoomState) then
      FOnRoomState(Self, lRequest.FRoom);
  finally
    lRequest.Free;
  end;
end;

function TNXXMPPMUCModule.ChangeNick(const ARoomJID,
  ANick: UTF8String): Boolean;
var
  lRoom: TNXXMPPRoom;
begin
  lRoom := FindRoom(ARoomJID);
  Result := Assigned(lRoom) and (ANick <> '') and QueueXML('<presence to=''' +
    NXXMPPEscapeAttribute(ARoomJID + '/' + ANick) + '''/>');
end;

function TNXXMPPMUCModule.SendGroupMessage(const ARoomJID,
  ABody: UTF8String): Boolean;
var
  lRoom: TNXXMPPRoom;
begin
  lRoom := FindRoom(ARoomJID);
  Result := Assigned(lRoom) and (lRoom.State = xrsJoined) and
    (ABody <> '') and
    QueueXML('<message to=''' + NXXMPPEscapeAttribute(ARoomJID) +
    ''' type=''groupchat'' id=''' + NXXMPPCreateID + '''><body>' +
    NXXMPPEscapeText(ABody) + '</body><origin-id xmlns=''urn:xmpp:sid:0'' ' +
    'id=''' + NXXMPPCreateID + '''/></message>');
end;

function TNXXMPPMUCModule.SendPrivateMessage(const AOccupantJID,
  ABody: UTF8String): Boolean;
begin
  Result := (AOccupantJID <> '') and (ABody <> '') and
    QueueXML('<message to=''' + NXXMPPEscapeAttribute(AOccupantJID) +
    ''' type=''chat'' id=''' + NXXMPPCreateID + '''><body>' +
    NXXMPPEscapeText(ABody) + '</body></message>');
end;

function TNXXMPPMUCModule.SetSubject(const ARoomJID,
  ASubject: UTF8String): Boolean;
var
  lRoom: TNXXMPPRoom;
begin
  lRoom := FindRoom(ARoomJID);
  Result := Assigned(lRoom) and (lRoom.State = xrsJoined) and
    QueueXML('<message to=''' +
    NXXMPPEscapeAttribute(ARoomJID) + ''' type=''groupchat''><subject>' +
    NXXMPPEscapeText(ASubject) + '</subject></message>');
end;

procedure TNXXMPPMUCModule.ProcessCommand(AOperation: TNXXMPPModuleOperation);
begin
  if not (AOperation is TNXXMPPMUCOperation) then
    inherited ProcessCommand(AOperation);
  Send(TNXXMPPMUCOperation(AOperation).XML, xrpStreamManaged);
end;

procedure TNXXMPPMUCModule.Lifecycle(ALifecycle: TNXXMPPModuleLifecycle);
var
  lIndex: Integer;
  lRoom: TNXXMPPRoom;
  lXML: UTF8String;
begin
  FCriticalSection.Acquire;
  try
    for lIndex := 0 to FRooms.Count - 1 do
    begin
      lRoom := TNXXMPPRoom(FRooms[lIndex]);
      case ALifecycle of
        xmlTemporaryLoss: if lRoom.State = xrsJoined then
          SetState(lRoom, xrsStale, xmtrTemporaryLoss);
        xmlStreamResumed: if lRoom.State = xrsStale then
          SubmitIQ(xitGet, lRoom.JID + '/' + lRoom.Nick,
            lRoom.JID + '/' + lRoom.Nick,
            '<ping xmlns=''urn:xmpp:ping''/>', @SelfPingComplete,
            FSelfPingTimeoutMS);
        xmlNewSession: if lRoom.AutoRejoin and
          (lRoom.State in [xrsStale, xrsJoined]) then
          begin
            SetState(lRoom, xrsRejoining, xmtrFreshSessionRejoin);
            lXML := '<presence to=''' + NXXMPPEscapeAttribute(
              lRoom.JID + '/' + lRoom.Nick) +
              '''><x xmlns=''http://jabber.org/protocol/muc''>';
            if lRoom.Password <> '' then
              lXML := lXML + '<password>' +
                NXXMPPEscapeText(lRoom.Password) + '</password>';
            Send(lXML + '</x></presence>', xrpStreamManaged);
          end;
        xmlPermanentLoss, xmlFinalDisconnect:
          if not (lRoom.State in [xrsLeft, xrsFailed]) then
            SetState(lRoom, xrsFailed, xmtrPermanentLoss);
      end;
    end;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPMUCModule.SelfPingComplete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lRoomJID: UTF8String;
  lSeparator: Integer;
  lRoom: TNXXMPPRoom;
  lIndex: Integer;
begin
  if not Assigned(AStanza) then
  begin
    for lIndex := 0 to FRooms.Count - 1 do
    begin
      lRoom := TNXXMPPRoom(FRooms[lIndex]);
      if lRoom.State = xrsStale then
        if lRoom.AutoRejoin then
          Join(lRoom.JID, lRoom.Nick, lRoom.Password, True)
        else
          SetState(lRoom, xrsFailed, xmtrSelfPingFailed);
    end;
    Exit;
  end;
  lSeparator := Pos('/', AStanza.FromJID);
  if lSeparator > 0 then
    lRoomJID := Copy(AStanza.FromJID, 1, lSeparator - 1)
  else
    lRoomJID := AStanza.FromJID;
  lRoom := FindRoom(lRoomJID);
  if not Assigned(lRoom) then
    Exit;
  if (AError = '') and (AStanza.IQType = xitResult) then
    SetState(lRoom, xrsJoined, xmtrResumedVerified)
  else if lRoom.AutoRejoin then
    Join(lRoom.JID, lRoom.Nick, lRoom.Password, True)
  else
    SetState(lRoom, xrsFailed, xmtrSelfPingFailed);
  if Assigned(FOnRoomState) then
    FOnRoomState(Self, lRoom);
end;

procedure TNXXMPPMUCModule.PumpLifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
var
  lIndex: Integer;
begin
  if Assigned(FOnRoomState) then
    for lIndex := 0 to FRooms.Count - 1 do
      FOnRoomState(Self, TNXXMPPRoom(FRooms[lIndex]));
end;

procedure TNXXMPPMUCModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lAffiliation: TNXXMPPMUCAffiliation;
  lContext: TNXXMPPMessageDeliveryContext;
  lCreated: Boolean;
  lFrom: UTF8String;
  lItem: TDOMElement;
  lMessage: TNXXMPPMessage;
  lMUC: TDOMElement;
  lNick: UTF8String;
  lNewNick: UTF8String;
  lNickChanged: Boolean;
  lOccupantID: UTF8String;
  lOccupant: TNXXMPPOccupant;
  lRealJID: UTF8String;
  lPresenceStatus: TDOMElement;
  lStatusText: UTF8String;
  lRole: TNXXMPPMUCRole;
  lRoom: TNXXMPPRoom;
  lRoomJID: UTF8String;
  lSelf: Boolean;
  lRemoved: Boolean;
  lRemovalReason: TNXXMPPMUCTransitionReason;
  lSeparator: Integer;
  lStatus: TDOMElement;
  lStatusCode: Integer;
  lError: TDOMElement;
  lErrorChild: TDOMElement;
begin
  if not Assigned(AStanza) then
    Exit;
  lFrom := AStanza.FromJID;
  lSeparator := Pos('/', lFrom);
  if lSeparator > 0 then
    lRoomJID := Copy(lFrom, 1, lSeparator - 1)
  else
    lRoomJID := lFrom;
  lRoom := FindRoom(lRoomJID);
  if not Assigned(lRoom) then
    Exit;
  if AStanza.Kind = xskPresence then
  begin
    SetLength(lRoom.FStatusCodes, 0);
    lRoom.FLastError.Present := False;
    lRoom.FLastError.ErrorType := '';
    lRoom.FLastError.Condition := '';
    lRoom.FLastError.Text := '';
    if AStanza.TypeValue = 'error' then
    begin
      lRoom.FLastError.Present := True;
      lError := NXXMPPFindChild(AStanza.Root, 'jabber:client', 'error');
      if Assigned(lError) then
      begin
        lRoom.FLastError.ErrorType := UTF8Encode(lError.GetAttribute('type'));
        lErrorChild := NXXMPPFirstChildElement(lError);
        while Assigned(lErrorChild) do
        begin
          if NXXMPPElementNamespaceURI(lErrorChild) =
            'urn:ietf:params:xml:ns:xmpp-stanzas' then
            if NXXMPPElementLocalName(lErrorChild) = 'text' then
              lRoom.FLastError.Text := NXXMPPDirectText(lErrorChild)
            else if lRoom.FLastError.Condition = '' then
              lRoom.FLastError.Condition :=
                NXXMPPElementLocalName(lErrorChild);
          lErrorChild := NXXMPPNextSiblingElement(lErrorChild);
        end;
      end;
      SetState(lRoom, xrsFailed, xmtrServiceError);
      if Assigned(FOnRoomState) then
        FOnRoomState(Self, lRoom);
      Exit;
    end;
    lRole := xmrNone;
    lAffiliation := xmaNone;
    lRealJID := '';
    lNewNick := '';
    lMUC := NXXMPPFindChild(AStanza.Root,
      'http://jabber.org/protocol/muc#user', 'x');
    if not Assigned(lMUC) then
      Exit;
    lSelf := False;
    lCreated := False;
    lRemoved := False;
    lRemovalReason := xmtrNone;
    lNickChanged := False;
    lStatus := NXXMPPFindChild(lMUC,
      'http://jabber.org/protocol/muc#user', 'status');
    while Assigned(lStatus) do
    begin
      if TryStrToInt(string(UTF8Encode(lStatus.GetAttribute('code'))),
        lStatusCode) and (lStatusCode >= 0) then
      begin
        SetLength(lRoom.FStatusCodes, Length(lRoom.FStatusCodes) + 1);
        lRoom.FStatusCodes[High(lRoom.FStatusCodes)] := lStatusCode;
      end;
      if UTF8Encode(lStatus.GetAttribute('code')) = '110' then
        lSelf := True
      else if UTF8Encode(lStatus.GetAttribute('code')) = '201' then
        lCreated := True
      else if UTF8Encode(lStatus.GetAttribute('code')) = '301' then
      begin
        lRemoved := True;
        lRemovalReason := xmtrBanned;
      end
      else if UTF8Encode(lStatus.GetAttribute('code')) = '307' then
      begin
        lRemoved := True;
        lRemovalReason := xmtrKicked;
      end
      else if UTF8Encode(lStatus.GetAttribute('code')) = '303' then
        lNickChanged := True;
      lStatus := NXXMPPNextSiblingElement(lStatus);
      while Assigned(lStatus) and not NXXMPPElementMatches(lStatus,
        'http://jabber.org/protocol/muc#user', 'status') do
        lStatus := NXXMPPNextSiblingElement(lStatus);
    end;
    lItem := NXXMPPFindChild(lMUC,
      'http://jabber.org/protocol/muc#user', 'item');
    if Assigned(lItem) then
    begin
      lRole := NXXMPPMUCRoleFromName(UTF8Encode(
        lItem.GetAttribute('role')));
      lAffiliation := NXXMPPMUCAffiliationFromName(UTF8Encode(
        lItem.GetAttribute('affiliation')));
      lRealJID := UTF8Encode(lItem.GetAttribute('jid'));
      lNewNick := UTF8Encode(lItem.GetAttribute('nick'));
    end;
    lOccupantID := '';
    lItem := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:occupant-id:0',
      'occupant-id');
    if Assigned(lItem) then
      lOccupantID := UTF8Encode(lItem.GetAttribute('id'));
    lStatusText := '';
    lPresenceStatus := NXXMPPFindChild(AStanza.Root, 'jabber:client',
      'status');
    if Assigned(lPresenceStatus) then
      lStatusText := NXXMPPDirectText(lPresenceStatus);
    lNick := Copy(lFrom, lSeparator + 1, MaxInt);
    lOccupant := lRoom.Occupant(lNick);
    if not Assigned(lOccupant) and (lOccupantID <> '') then
      lOccupant := lRoom.OccupantByID(lOccupantID);
    if AStanza.TypeValue <> 'unavailable' then
    begin
      if not Assigned(lOccupant) then
      begin
        if lRoom.FOccupants.Count >= FMaximumOccupants then
          Exit;
        lOccupant := TNXXMPPOccupant.Create;
        lRoom.FOccupants.Add(lOccupant);
      end;
      lOccupant.FJID := lFrom;
      lOccupant.FNick := lNick;
      lOccupant.FRole := lRole;
      lOccupant.FAffiliation := lAffiliation;
      lOccupant.FRealJID := lRealJID;
      lOccupant.FOccupantID := lOccupantID;
      lOccupant.FAvailable := True;
      lOccupant.FSelf := lSelf;
      lOccupant.FStatus := lStatusText;
    end;
    if lSelf then
      if lRemoved then
        SetState(lRoom, xrsFailed, lRemovalReason)
      else if AStanza.TypeValue = 'unavailable' then
        SetState(lRoom, xrsLeft, xmtrLeft)
      else if lCreated then
      begin
        if lRoom.FEntryMode <> xremJoin then
        begin
          lRoom.FEntryMode := xremJoin;
          SetState(lRoom, xrsConfiguring, xmtrConfiguring);
          if not BeginInstantRoomConfiguration(lRoom) then
          begin
            lRoom.FLastError.Present := True;
            lRoom.FLastError.ErrorType := '';
            lRoom.FLastError.Condition := 'room-configuration-capacity';
            lRoom.FLastError.Text :=
              'The instant-room configuration request could not be queued.';
            SetState(lRoom, xrsFailed, xmtrConfigurationFailed);
            QueueXML('<presence to=''' + NXXMPPEscapeAttribute(lFrom) +
              ''' type=''unavailable''/>');
          end;
        end
        else
        begin
          SetState(lRoom, xrsFailed, xmtrRoomCreated);
          QueueXML('<presence to=''' + NXXMPPEscapeAttribute(lFrom) +
            ''' type=''unavailable''/>');
        end;
      end
      else if lRoom.FEntryMode = xremCreateInstant then
      begin
        lRoom.FEntryMode := xremJoin;
        lRoom.FLastError.Present := True;
        lRoom.FLastError.ErrorType := 'cancel';
        lRoom.FLastError.Condition := 'room-already-exists';
        lRoom.FLastError.Text :=
          'The requested room already exists and was not created.';
        SetState(lRoom, xrsFailed, xmtrRoomAlreadyExists);
        QueueXML('<presence to=''' + NXXMPPEscapeAttribute(lFrom) +
          ''' type=''unavailable''/>');
      end
      else
      begin
        lRoom.FEntryMode := xremJoin;
        SetState(lRoom, xrsJoined, xmtrJoined);
      end;
    if lNickChanged and Assigned(lOccupant) and (lNewNick <> '') then
    begin
      lOccupant.FNick := lNewNick;
      lOccupant.FJID := lRoomJID + '/' + lNewNick;
      if lSelf then
        lRoom.FNick := lNewNick;
    end;
    if Assigned(FOnOccupant) then
      FOnOccupant(Self, lRoom, lFrom, lNick, lRealJID, lOccupantID,
        lRole, lAffiliation, AStanza.TypeValue <> 'unavailable', lSelf);
    if (AStanza.TypeValue = 'unavailable') and Assigned(lOccupant) and
      not lNickChanged then
      lRoom.FOccupants.Remove(lOccupant);
    if lSelf and Assigned(FOnRoomState) then
      FOnRoomState(Self, lRoom);
  end
  else if AStanza.Kind = xskMessage then
  begin
    if Assigned(NXXMPPFindChild(AStanza.Root, 'urn:xmpp:delay', 'delay')) then
      lContext := xmdcMUCHistory
    else
      lContext := xmdcLive;
    if lContext = xmdcMUCHistory then
    begin
      if lRoom.FHistoryCount >= FMaximumHistoryMessages then
        Exit;
      Inc(lRoom.FHistoryCount);
    end;
    lMessage := TNXXMPPMessage.Create(AStanza, lContext);
    try
      if lMessage.Subject <> '' then
        lRoom.FSubject := lMessage.Subject;
      if (lContext = xmdcLive) and (lMessage.ChatState <> xcsNone) and
        Assigned(FOnChatState) then
        FOnChatState(Self, lRoom, lMessage.FromJID, lMessage.ChatState);
      if Assigned(FOnRoomMessage) and ((lMessage.Body <> '') or
        (lMessage.Subject <> '') or lMessage.Reply.Present or
        (Length(lMessage.Attachments) > 0)) then
        FOnRoomMessage(Self, lRoom, lMessage);
    finally
      lMessage.Free;
    end;
  end;
end;

end.

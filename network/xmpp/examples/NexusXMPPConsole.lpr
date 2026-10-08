(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusXMPPConsole;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  Classes, SysUtils, Crt,
  obNXXMPPClient, obNXXMPPDisco, obNXXMPPMessage, obNXXMPPMUC,
  obNXXMPPRoster, obNXXMPPStanza,
  tpNXXMPPTypes;

type
  TConsoleEvents = class
  private
    FOnlineInitialized: Boolean;
    FDisco: TNXXMPPDiscoModule;
    FDiscoJID: UTF8String;
    FMUC: TNXXMPPMUCModule;
    FRoster: TNXXMPPRosterModule;
  public
    procedure DiscoInfo(ASender: TObject; AInfo: TNXXMPPDiscoInfo);
    procedure Error(ASender: TObject; AStage: TNXXMPPErrorStage;
      const ACondition, AMessage: UTF8String);
    procedure RosterChanged(ASender: TObject;
      const AJID, ASubscription: UTF8String);
    procedure Stanza(ASender: TObject; AStanza: TNXXMPPStanza);
    procedure RoomMessage(ASender: TObject; ARoom: TNXXMPPRoom;
      AMessage: TNXXMPPMessage);
    procedure RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
    procedure State(ASender: TObject; AState: TNXXMPPConnectionState);
    procedure UnrecoverableStanzas(ASender: TObject;
      const AReason: UTF8String; AStanzas: TStrings);
    property Roster: TNXXMPPRosterModule read FRoster write FRoster;
    property Disco: TNXXMPPDiscoModule read FDisco write FDisco;
    property DiscoJID: UTF8String read FDiscoJID write FDiscoJID;
    property MUC: TNXXMPPMUCModule read FMUC write FMUC;
  end;

procedure TConsoleEvents.DiscoInfo(ASender: TObject; AInfo: TNXXMPPDiscoInfo);
var
  lIndex: Integer;
begin
  if AInfo.Error <> '' then
  begin
    WriteLn('Discovery failed: ', AInfo.Error);
    Exit;
  end;
  WriteLn('Discovery response from ', AInfo.FromJID, ':');
  for lIndex := 0 to AInfo.Features.Count - 1 do
    WriteLn('  ', AInfo.Features[lIndex]);
end;

procedure TConsoleEvents.Error(ASender: TObject; AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: UTF8String);
begin
  WriteLn('Error [', ACondition, ']: ', AMessage);
end;

procedure TConsoleEvents.RosterChanged(ASender: TObject;
  const AJID, ASubscription: UTF8String);
begin
  WriteLn('Roster: ', AJID, ' [', ASubscription, ']');
end;

procedure TConsoleEvents.Stanza(ASender: TObject; AStanza: TNXXMPPStanza);
begin
  WriteLn('Stanza: ', AStanza.RawXML);
end;

procedure TConsoleEvents.RoomMessage(ASender: TObject; ARoom: TNXXMPPRoom;
  AMessage: TNXXMPPMessage);
begin
  WriteLn('Room message [', ARoom.JID, '] ', AMessage.FromJID, ': ',
    AMessage.DisplayBody);
end;

procedure TConsoleEvents.RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
begin
  WriteLn('Room state [', ARoom.JID, ']: ', Ord(ARoom.State));
end;

procedure TConsoleEvents.State(ASender: TObject;
  AState: TNXXMPPConnectionState);
begin
  WriteLn('State: ', NXXMPPConnectionStateName(AState));
  if (AState = xcsOnline) and Assigned(FRoster) and
    not FOnlineInitialized then
  begin
    FOnlineInitialized := True;
    TNXXMPPClient(ASender).RequestRoster(FRoster);
    TNXXMPPClient(ASender).SendPresence;
    if Assigned(FDisco) and (FDiscoJID <> '') then
      FDisco.QueryInfo(FDiscoJID, '');
  end;
end;

procedure TConsoleEvents.UnrecoverableStanzas(ASender: TObject;
  const AReason: UTF8String; AStanzas: TStrings);
var
  lIndex: Integer;
begin
  WriteLn('Unrecoverable transmitted stanzas: ', AReason);
  for lIndex := 0 to AStanzas.Count - 1 do
    WriteLn('  ', AStanzas[lIndex]);
end;

var
  lClient: TNXXMPPClient;
  lDisco: TNXXMPPDiscoModule;
  lEvents: TConsoleEvents;
  lKey: Char;
  lMUC: TNXXMPPMUCModule;
  lRoster: TNXXMPPRosterModule;
  lRoomJID: UTF8String;
  lRoomNick: UTF8String;
begin
  if (GetEnvironmentVariable('NEXUS_XMPP_JID') = '') or
    (GetEnvironmentVariable('NEXUS_XMPP_PASSWORD') = '') or
    (GetEnvironmentVariable('NEXUS_XMPP_CA_FILE') = '') then
  begin
    WriteLn('Set NEXUS_XMPP_JID, NEXUS_XMPP_PASSWORD, and ',
      'NEXUS_XMPP_CA_FILE.');
    Halt(2);
  end;
  lClient := TNXXMPPClient.Create;
  lEvents := TConsoleEvents.Create;
  try
    lClient.Config.JID := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_JID'));
    lClient.Config.Password := UTF8String(
      GetEnvironmentVariable('NEXUS_XMPP_PASSWORD'));
    lClient.Config.CAFile := GetEnvironmentVariable('NEXUS_XMPP_CA_FILE');
    lClient.Config.Resource := 'NexusXMPP';
    if GetEnvironmentVariable('NEXUS_XMPP_HOST') <> '' then
    begin
      lClient.Config.EndpointHost := GetEnvironmentVariable('NEXUS_XMPP_HOST');
      lClient.Config.EndpointPort := StrToIntDef(
        GetEnvironmentVariable('NEXUS_XMPP_PORT'), 5222);
      lClient.Config.DirectTLS := SameText(
        GetEnvironmentVariable('NEXUS_XMPP_DIRECT_TLS'), 'true');
    end;
    lDisco := TNXXMPPDiscoModule.Create('client', 'pc', 'NexusXMPP');
    lDisco.OnInfo := @lEvents.DiscoInfo;
    lDisco.AddFeature('http://jabber.org/protocol/disco#info');
    lDisco.AddFeature('urn:xmpp:sm:3');
    lClient.AddModule(lDisco);
    lEvents.Disco := lDisco;
    lEvents.DiscoJID := UTF8String(
      GetEnvironmentVariable('NEXUS_XMPP_DISCO_JID'));
    lMUC := TNXXMPPMUCModule.Create;
    lMUC.OnRoomMessage := @lEvents.RoomMessage;
    lMUC.OnRoomState := @lEvents.RoomState;
    lClient.AddModule(lMUC);
    lEvents.MUC := lMUC;
    lRoomJID := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_ROOM'));
    lRoomNick := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_ROOM_NICK'));
    if lRoomNick = '' then
      lRoomNick := 'NexusXMPP';
    lRoster := TNXXMPPRosterModule.Create;
    lRoster.OnChanged := @lEvents.RosterChanged;
    lEvents.Roster := lRoster;
    lClient.AddModule(lRoster);
    lClient.OnError := @lEvents.Error;
    lClient.OnStanza := @lEvents.Stanza;
    lClient.OnState := @lEvents.State;
    lClient.OnUnrecoverableStanzas := @lEvents.UnrecoverableStanzas;
    lClient.Connect;
    WriteLn('P presence, D discovery, C create instant room, J join room, ',
      'M room message, L leave room, Q disconnect.');
    lKey := #0;
    repeat
      if KeyPressed then
      begin
        lKey := UpCase(ReadKey);
        if lKey = 'P' then
          lClient.SendPresence
        else if (lKey = 'D') and (lEvents.DiscoJID <> '') then
          lDisco.QueryInfo(lEvents.DiscoJID, '')
        else if (lKey = 'C') and (lRoomJID <> '') then
          lMUC.CreateInstantRoom(lRoomJID, lRoomNick, False)
        else if (lKey = 'J') and (lRoomJID <> '') then
          lMUC.Join(lRoomJID, lRoomNick, '', False)
        else if (lKey = 'M') and (lRoomJID <> '') then
          lMUC.SendGroupMessage(lRoomJID, 'NexusXMPP console message')
        else if (lKey = 'L') and (lRoomJID <> '') then
          lMUC.Leave(lRoomJID);
      end
      else
        Sleep(20);
    until lKey = 'Q';
    lClient.Disconnect;
  finally
    lEvents.Free;
    lClient.Free;
  end;
end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusNetXMPPLiveTest;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  Classes, SysUtils,
  obNXXMPPCarbons, obNXXMPPClient, obNXXMPPDisco, obNXXMPPMAM,
  obNXXMPPMessage, obNXXMPPMessageFeatures, obNXXMPPMUC, obNXXMPPPing,
  obNXXMPPStanza,
  tpNXXMPPMessageTypes, tpNXXMPPTypes;

type
  TLiveRecorder = class
  private
    FExpectedBody: UTF8String;
    FExpectedFrom: UTF8String;
  public
    Failed: Boolean;
    CarbonReceived: Boolean;
    CarbonState: TNXXMPPCarbonsState;
    ChatStateReceived: Boolean;
    DiscoComplete: Boolean;
    DiscoItemsComplete: Boolean;
    Features: TStringList;
    Items: TStringList;
    LastMessageID: UTF8String;
    MAMComplete: Boolean;
    ReceiptAccepted: Boolean;
    ReplyReceived: Boolean;
    LastError: UTF8String;
    LastStanza: UTF8String;
    Online: Boolean;
    ReceivedExpectedMessage: Boolean;
    ReceivedRoomMessage: Boolean;
    RoomJoined: Boolean;
    RoomStateValue: TNXXMPPRoomState;
    constructor Create;
    destructor Destroy; override;
    procedure CarbonStateChanged(ASender: TObject;
      AState: TNXXMPPCarbonsState);
    procedure Carbon(ASender: TObject; ASent: Boolean;
      const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage);
    procedure CarbonDiagnostic(ASender: TObject; const ACondition,
      ADetail: UTF8String);
    procedure ChatState(ASender: TObject; const AFromJID: UTF8String;
      AState: TNXXMPPChatState);
    procedure DiscoInfo(ASender: TObject; AInfo: TNXXMPPDiscoInfo);
    procedure DiscoItems(ASender: TObject; AItems: TNXXMPPDiscoItems);
    procedure Error(ASender: TObject; AStage: TNXXMPPErrorStage;
      const ACondition, AMessage: UTF8String);
    procedure Stanza(ASender: TObject; AStanza: TNXXMPPStanza);
    procedure State(ASender: TObject; AState: TNXXMPPConnectionState);
    procedure RoomMessage(ASender: TObject; ARoom: TNXXMPPRoom;
      AMessage: TNXXMPPMessage);
    procedure RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
    procedure MAMFinished(ASender: TObject; const AQueryID, AError,
      AFirst, ALast: UTF8String; ACount: Integer;
      AComplete, AStable: Boolean);
    procedure MessageReceived(ASender: TObject; AMessage: TNXXMPPMessage);
    procedure Receipt(ASender: TObject; const AFromJID,
      AStanzaID: UTF8String; AOutcome: TNXXMPPReceiptOutcome);
    property ExpectedBody: UTF8String read FExpectedBody write FExpectedBody;
    property ExpectedFrom: UTF8String read FExpectedFrom write FExpectedFrom;
  end;

constructor TLiveRecorder.Create;
begin
  inherited Create;
  Features := TStringList.Create;
  Features.CaseSensitive := True;
  Items := TStringList.Create;
  Items.CaseSensitive := True;
end;

destructor TLiveRecorder.Destroy;
begin
  Items.Free;
  Features.Free;
  inherited Destroy;
end;

procedure TLiveRecorder.CarbonStateChanged(ASender: TObject;
  AState: TNXXMPPCarbonsState);
begin
  CarbonState := AState;
end;

procedure TLiveRecorder.Carbon(ASender: TObject; ASent: Boolean;
  const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage);
begin
  if ASent and (AMessage.Body = FExpectedBody) then
    CarbonReceived := True;
end;

procedure TLiveRecorder.CarbonDiagnostic(ASender: TObject;
  const ACondition, ADetail: UTF8String);
begin
  LastError := ACondition + ': ' + ADetail;
end;

procedure TLiveRecorder.ChatState(ASender: TObject;
  const AFromJID: UTF8String; AState: TNXXMPPChatState);
begin
  if AState = xcsComposing then
    ChatStateReceived := True;
end;

procedure TLiveRecorder.DiscoItems(ASender: TObject;
  AItems: TNXXMPPDiscoItems);
var
  lIndex: Integer;
begin
  DiscoItemsComplete := True;
  for lIndex := 0 to High(AItems.Items) do
    Items.Add(string(AItems.Items[lIndex].JID));
  if AItems.Error <> '' then
    LastError := AItems.Error;
end;

procedure TLiveRecorder.DiscoInfo(ASender: TObject; AInfo: TNXXMPPDiscoInfo);
begin
  DiscoComplete := True;
  Features.Assign(AInfo.Features);
  if AInfo.Error <> '' then
    LastError := AInfo.Error;
end;

procedure TLiveRecorder.Error(ASender: TObject; AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: UTF8String);
begin
  LastError := ACondition + ': ' + AMessage;
end;

procedure TLiveRecorder.RoomMessage(ASender: TObject; ARoom: TNXXMPPRoom;
  AMessage: TNXXMPPMessage);
begin
  if AMessage.Body = FExpectedBody then
    ReceivedRoomMessage := True;
end;

procedure TLiveRecorder.RoomState(ASender: TObject; ARoom: TNXXMPPRoom);
begin
  RoomStateValue := ARoom.State;
  RoomJoined := ARoom.State = xrsJoined;
  if (ARoom.State = xrsFailed) and ARoom.LastError.Present then
    LastError := ARoom.LastError.Condition + ': ' + ARoom.LastError.Text;
end;

procedure TLiveRecorder.MAMFinished(ASender: TObject;
  const AQueryID, AError, AFirst, ALast: UTF8String; ACount: Integer;
  AComplete, AStable: Boolean);
begin
  MAMComplete := True;
  if AError <> '' then
    LastError := AError;
end;

procedure TLiveRecorder.MessageReceived(ASender: TObject;
  AMessage: TNXXMPPMessage);
begin
  if AMessage.Body = FExpectedBody then
  begin
    ReceivedExpectedMessage := True;
    LastMessageID := AMessage.ID;
    if Pos('reply ', string(AMessage.Body)) = 1 then
      ReplyReceived := True;
  end;
end;

procedure TLiveRecorder.Receipt(ASender: TObject; const AFromJID,
  AStanzaID: UTF8String; AOutcome: TNXXMPPReceiptOutcome);
begin
  if AOutcome = xroAccepted then
    ReceiptAccepted := True;
end;

procedure TLiveRecorder.Stanza(ASender: TObject; AStanza: TNXXMPPStanza);
begin
  LastStanza := AStanza.RawXML;
  if (AStanza.Kind = xskMessage) and
    (Pos(string(FExpectedFrom), string(AStanza.FromJID)) = 1) and
    (AStanza.TextContent = FExpectedBody) then
    ReceivedExpectedMessage := True;
end;

procedure TLiveRecorder.State(ASender: TObject;
  AState: TNXXMPPConnectionState);
begin
  if AState = xcsOnline then
    Online := True
  else if AState = xcsFailed then
    Failed := True;
end;

procedure ConfigureClient(AClient: TNXXMPPClient; const AJID,
  APassword, AResource: UTF8String);
begin
  AClient.Config.JID := AJID;
  AClient.Config.Password := APassword;
  AClient.Config.AllowPlain := True;
  AClient.Config.CAFile := GetEnvironmentVariable('NEXUS_XMPP_CA_FILE');
  AClient.Config.EndpointHost := GetEnvironmentVariable('NEXUS_XMPP_HOST');
  AClient.Config.EndpointPort := StrToIntDef(
    GetEnvironmentVariable('NEXUS_XMPP_PORT'), 5222);
  AClient.Config.Resource := AResource;
  AClient.Config.ConnectionTimeoutMS := 5000;
  AClient.Config.ReconnectAttempts := 0;
end;

var
  lBody: UTF8String;
  lClient1: TNXXMPPClient;
  lClient2: TNXXMPPClient;
  lClient3: TNXXMPPClient;
  lCarbons1: TNXXMPPCarbonsModule;
  lCarbons2: TNXXMPPCarbonsModule;
  lCarbons3: TNXXMPPCarbonsModule;
  lDeadline: QWord;
  lDisco1: TNXXMPPDiscoModule;
  lDisco2: TNXXMPPDiscoModule;
  lExitCode: Integer;
  lIdentity: TNXXMPPOutgoingMessageIdentity;
  lExpectTLSFailure: Boolean;
  lPassword1: UTF8String;
  lPassword2: UTF8String;
  lMUC1: TNXXMPPMUCModule;
  lMUC2: TNXXMPPMUCModule;
  lMAM1: TNXXMPPMAMModule;
  lMAMFilter: TNXXMPPMAMFilter;
  lMAMOperation: INXXMPPMAMOperation;
  lMAMPage: TNXXMPPMAMPage;
  lMessage1: TNXXMPPMessageModule;
  lMessage2: TNXXMPPMessageModule;
  lPing1: TNXXMPPPingModule;
  lPing2: TNXXMPPPingModule;
  lRecorder1: TLiveRecorder;
  lRecorder2: TLiveRecorder;
  lRecorder3: TLiveRecorder;
  lRunID: UTF8String;
  lMUCService: UTF8String;
  lObservableRoomJID: UTF8String;
  lRoomJID: UTF8String;
  lRoomNick1: UTF8String;
  lRoomNick2: UTF8String;
  lUser1: UTF8String;
  lUser2: UTF8String;
  lSeparator: Integer;
begin
  lExitCode := 1;
  lExpectTLSFailure := GetEnvironmentVariable(
    'NEXUS_XMPP_EXPECT_TLS_FAILURE') = '1';
  lUser1 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_USER1'));
  lUser2 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_USER2'));
  lPassword1 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_PASSWORD1'));
  lPassword2 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_PASSWORD2'));
  lRunID := UTF8String(UIntToStr(GetTickCount64));
  lMUCService := UTF8String(GetEnvironmentVariable(
    'NEXUS_XMPP_MUC_SERVICE'));
  lRoomNick1 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_ROOM_NICK1'));
  lRoomNick2 := UTF8String(GetEnvironmentVariable('NEXUS_XMPP_ROOM_NICK2'));
  if (lUser1 = '') or (lPassword1 = '') or
    (GetEnvironmentVariable('NEXUS_XMPP_CA_FILE') = '') or
    (GetEnvironmentVariable('NEXUS_XMPP_HOST') = '') then
  begin
    WriteLn('Missing required NEXUS_XMPP_* live-test environment.');
    Halt(2);
  end;
  if lMUCService = '' then
  begin
    lSeparator := Pos('@', lUser1);
    if lSeparator = 0 then
    begin
      WriteLn('USER1 must contain a domain for MUC service discovery.');
      Halt(2);
    end;
    lMUCService := 'conference.' + Copy(lUser1, lSeparator + 1, MaxInt);
  end;
  lRoomJID := 'nexus-live-' + lRunID + '@' + lMUCService;
  lObservableRoomJID := UTF8String(GetEnvironmentVariable(
    'NEXUS_XMPP_OBSERVABLE_ROOM'));
  if lObservableRoomJID = '' then
    lObservableRoomJID := 'nexus-test@' + lMUCService;

  lClient1 := TNXXMPPClient.Create;
  lRecorder1 := TLiveRecorder.Create;
  lClient2 := nil;
  lClient3 := nil;
  lRecorder2 := nil;
  lRecorder3 := nil;
  lMUC1 := nil;
  lMUC2 := nil;
  lDisco1 := nil;
  lDisco2 := nil;
  lCarbons1 := nil;
  lCarbons2 := nil;
  lCarbons3 := nil;
  lMAM1 := nil;
  lMessage1 := nil;
  lMessage2 := nil;
  lPing1 := nil;
  lPing2 := nil;
  try
    ConfigureClient(lClient1, lUser1, lPassword1,
      'NexusXMPPLiveTest-' + lRunID + '-1');
    lClient1.OnError := @lRecorder1.Error;
    lClient1.OnState := @lRecorder1.State;
    if not lExpectTLSFailure then
    begin
      if (lUser2 = '') or (lPassword2 = '') then
      begin
        WriteLn('The positive live test requires USER2 and PASSWORD2.');
        lExitCode := 2;
      end
      else
      begin
        lClient2 := TNXXMPPClient.Create;
        lRecorder2 := TLiveRecorder.Create;
        ConfigureClient(lClient2, lUser2, lPassword2,
          'NexusXMPPLiveTest-' + lRunID + '-2');
        lClient2.OnError := @lRecorder2.Error;
        lClient2.OnStanza := @lRecorder2.Stanza;
        lClient2.OnState := @lRecorder2.State;
        lClient3 := TNXXMPPClient.Create;
        lRecorder3 := TLiveRecorder.Create;
        ConfigureClient(lClient3, lUser1, lPassword1,
          'NexusXMPPLiveTest-' + lRunID + '-carbon');
        lClient3.OnError := @lRecorder3.Error;
        lClient3.OnState := @lRecorder3.State;
        lDisco1 := TNXXMPPDiscoModule.Create('client', 'pc',
          'NexusXMPPLiveTest');
        lDisco2 := TNXXMPPDiscoModule.Create('client', 'pc',
          'NexusXMPPLiveTest');
        lDisco1.OnInfo := @lRecorder1.DiscoInfo;
        lDisco1.OnItems := @lRecorder1.DiscoItems;
        lClient1.AddModule(lDisco1);
        lClient2.AddModule(lDisco2);
        lPing1 := TNXXMPPPingModule.Create;
        lPing2 := TNXXMPPPingModule.Create;
        lClient1.AddModule(lPing1);
        lClient2.AddModule(lPing2);
        lMessage1 := TNXXMPPMessageModule.Create;
        lMessage2 := TNXXMPPMessageModule.Create;
        lMessage1.OnReceipt := @lRecorder1.Receipt;
        lMessage1.OnMessage := @lRecorder1.MessageReceived;
        lMessage2.AutomaticReceipts := True;
        lMessage2.OnChatState := @lRecorder2.ChatState;
        lMessage2.OnMessage := @lRecorder2.MessageReceived;
        lClient1.AddModule(lMessage1);
        lClient2.AddModule(lMessage2);
        lCarbons1 := TNXXMPPCarbonsModule.Create(lUser1);
        lCarbons2 := TNXXMPPCarbonsModule.Create(lUser2);
        lCarbons3 := TNXXMPPCarbonsModule.Create(lUser1);
        lCarbons1.OnState := @lRecorder1.CarbonStateChanged;
        lCarbons2.OnState := @lRecorder2.CarbonStateChanged;
        lCarbons3.OnCarbon := @lRecorder3.Carbon;
        lCarbons3.OnDiagnostic := @lRecorder3.CarbonDiagnostic;
        lCarbons3.OnState := @lRecorder3.CarbonStateChanged;
        lClient1.AddModule(lCarbons1);
        lClient2.AddModule(lCarbons2);
        lClient3.AddModule(lCarbons3);
        lMAM1 := TNXXMPPMAMModule.Create;
        lMAM1.OnComplete := @lRecorder1.MAMFinished;
        lClient1.AddModule(lMAM1);
        if lRoomNick1 = '' then
          lRoomNick1 := 'test1-' + lRunID;
        if lRoomNick2 = '' then
          lRoomNick2 := 'test2-' + lRunID;
        lMUC1 := TNXXMPPMUCModule.Create;
        lMUC2 := TNXXMPPMUCModule.Create;
        lMUC1.OnRoomState := @lRecorder1.RoomState;
        lMUC2.OnRoomState := @lRecorder2.RoomState;
        lMUC2.OnRoomMessage := @lRecorder2.RoomMessage;
        lClient1.AddModule(lMUC1);
        lClient2.AddModule(lMUC2);
      end;
    end;

    if (lExitCode <> 2) then
    begin
      lClient1.Connect;
      if Assigned(lClient2) then
        lClient2.Connect;
      if Assigned(lClient3) then
        lClient3.Connect;
      lDeadline := GetTickCount64 + 15000;
      repeat
        if Assigned(lClient2) then
        if Assigned(lClient3) then
        if lRecorder1.Failed or
          (Assigned(lRecorder2) and lRecorder2.Failed) or
          (Assigned(lRecorder3) and lRecorder3.Failed) then
          Break;
        if lRecorder1.Online and
          (not Assigned(lRecorder2) or lRecorder2.Online) and
          (not Assigned(lRecorder3) or lRecorder3.Online) then
          Break;
        Sleep(10);
      until GetTickCount64 >= lDeadline;

      if lExpectTLSFailure then
      begin
        if lRecorder1.Failed then
        begin
          WriteLn('Expected TLS rejection observed: ', lRecorder1.LastError);
          lExitCode := 0;
        end
        else
          WriteLn('Expected TLS rejection was not observed.');
      end
      else if not lRecorder1.Online or not lRecorder2.Online or
        not lRecorder3.Online then
      begin
        WriteLn('Client 1 failure: ', lRecorder1.LastError);
        WriteLn('Client 2 failure: ', lRecorder2.LastError);
        WriteLn('Client 3 failure: ', lRecorder3.LastError);
      end
      else
      begin
        lClient1.SendPresence;
        lClient2.SendPresence;
        lClient3.SendPresence;
        lDisco1.QueryInfo('nexus.local', '');
        lDisco1.QueryItems('nexus.local', '');
        lDeadline := GetTickCount64 + 5000;
        repeat
          Sleep(10);
        until (lRecorder1.DiscoComplete and lRecorder1.DiscoItemsComplete) or
          (GetTickCount64 >= lDeadline);
        if lRecorder1.DiscoComplete and lRecorder1.DiscoItemsComplete then
        begin
          WriteLn('Openfire discovery passed with ',
            lRecorder1.Features.Count, ' advertised features and ',
            lRecorder1.Items.Count, ' server items.');
          WriteLn('  Carbons: ',
            lRecorder1.Features.IndexOf('urn:xmpp:carbons:2') >= 0);
          WriteLn('  Personal MAM: ',
            lRecorder1.Features.IndexOf('urn:xmpp:mam:2') >= 0);
        end
        else
          WriteLn('Openfire discovery did not complete: ',
            lRecorder1.LastError);
        if lRecorder1.Features.IndexOf('urn:xmpp:carbons:2') >= 0 then
        begin
          lCarbons1.SetServerSupport(True);
          lCarbons2.SetServerSupport(True);
          lCarbons3.SetServerSupport(True);
          lCarbons1.Enable;
          lCarbons2.Enable;
          lCarbons3.Enable;
          lDeadline := GetTickCount64 + 5000;
          repeat
            Sleep(10);
          until ((lRecorder1.CarbonState = xcsCarbonsEnabled) and
            (lRecorder2.CarbonState = xcsCarbonsEnabled) and
            (lRecorder3.CarbonState = xcsCarbonsEnabled)) or
            (GetTickCount64 >= lDeadline);
        end;
        lBody := 'NexusXMPP Openfire live test ' +
          UTF8String(UIntToStr(GetTickCount64));
        lRecorder2.ExpectedFrom := lUser1;
        lRecorder2.ExpectedBody := lBody;
        lRecorder3.ExpectedBody := lBody;
        if not lMessage1.SendChatMessage(lUser2, lBody, True, lIdentity) then
          WriteLn('Client 1 rejected the message command.')
        else
        begin
          lDeadline := GetTickCount64 + 15000;
          repeat
            if (lRecorder2.ReceivedExpectedMessage and
              lRecorder1.ReceiptAccepted and
              ((lRecorder1.Features.IndexOf('urn:xmpp:carbons:2') < 0) or
              lRecorder3.CarbonReceived)) or lRecorder1.Failed or
              lRecorder2.Failed or lRecorder3.Failed then
              Break;
            Sleep(10);
          until GetTickCount64 >= lDeadline;
          if lRecorder2.ReceivedExpectedMessage and
            lRecorder1.ReceiptAccepted then
          begin
            lExitCode := 0;
            WriteLn('Authenticated Openfire typed message/receipt exchange passed.');
            lMessage1.SendChatState(lUser2, xcsComposing);
            if lRecorder2.LastMessageID <> '' then
            begin
              lRecorder1.ExpectedBody := 'reply ' + lRunID;
              lMessage2.SendReply(lUser1, 'reply ' + lRunID, lUser1,
                lRecorder2.LastMessageID, False, lIdentity);
            end;
            lDeadline := GetTickCount64 + 5000;
            repeat
              Sleep(10);
            until (lRecorder2.ChatStateReceived and lRecorder1.ReplyReceived) or
              (GetTickCount64 >= lDeadline);
            if lRecorder2.ChatStateReceived and lRecorder1.ReplyReceived then
              WriteLn('Openfire typed chat-state/reply exchange passed.')
            else
            begin
              WriteLn('Openfire typed chat-state/reply exchange failed.');
              lExitCode := 1;
            end;
            if not lRecorder1.DiscoComplete or
              not lRecorder1.DiscoItemsComplete then
              lExitCode := 1;
            if lRecorder1.Features.IndexOf('urn:xmpp:carbons:2') >= 0 then
              if (lRecorder1.CarbonState = xcsCarbonsEnabled) and
                (lRecorder2.CarbonState = xcsCarbonsEnabled) and
                (lRecorder3.CarbonState = xcsCarbonsEnabled) and
                lRecorder3.CarbonReceived then
                WriteLn('Openfire Carbon activation and multi-resource delivery passed.')
              else
              begin
                WriteLn('Openfire advertised Carbons but activation or delivery failed.');
                WriteLn('  Client 1 Carbon state: ', Ord(lRecorder1.CarbonState));
                WriteLn('  Client 2 Carbon state: ', Ord(lRecorder2.CarbonState));
                WriteLn('  Client 3 Carbon state: ', Ord(lRecorder3.CarbonState));
                WriteLn('  Client 3 Carbon received: ', lRecorder3.CarbonReceived);
                WriteLn('  Client 3 detail: ', lRecorder3.LastError);
                lExitCode := 1;
              end;
            if Assigned(lMUC1) then
            begin
              if not lMUC1.CreateInstantRoom(lRoomJID, lRoomNick1,
                False) then
              begin
                WriteLn('The MUC room-creation command was rejected.');
                lExitCode := 1;
              end
              else
              begin
                lDeadline := GetTickCount64 + 15000;
                repeat
                  Sleep(10);
                until lRecorder1.RoomJoined or
                  (lRecorder1.RoomStateValue = xrsFailed) or
                  (GetTickCount64 >= lDeadline);
                if not lRecorder1.RoomJoined then
                begin
                  WriteLn('Openfire MUC room creation did not complete: ',
                    lRecorder1.LastError);
                  lExitCode := 1;
                end
                else
                begin
                  WriteLn('Openfire instant MUC room creation passed: ',
                    lRoomJID);
                  lMUC2.Join(lRoomJID, lRoomNick2, '', False);
                  lDeadline := GetTickCount64 + 15000;
                  repeat
                    Sleep(10);
                  until lRecorder2.RoomJoined or
                    (lRecorder2.RoomStateValue = xrsFailed) or
                    (GetTickCount64 >= lDeadline);
                  if lRecorder2.RoomJoined then
                  begin
                    lBody := 'NexusXMPP MUC live test ' + lRunID;
                    lRecorder2.ExpectedBody := lBody;
                    lMUC1.SendGroupMessage(lRoomJID, lBody);
                    lDeadline := GetTickCount64 + 15000;
                    repeat
                      Sleep(10);
                    until lRecorder2.ReceivedRoomMessage or
                      (GetTickCount64 >= lDeadline);
                    if lRecorder2.ReceivedRoomMessage then
                      WriteLn('Openfire MUC exchange passed.')
                    else
                    begin
                      WriteLn('Openfire MUC message was not received.');
                      lExitCode := 1;
                    end;
                    lMUC2.Leave(lRoomJID);
                  end
                  else
                  begin
                    WriteLn('Openfire second-client MUC join did not complete: ',
                      lRecorder2.LastError);
                    lExitCode := 1;
                  end;
                  lMUC1.Leave(lRoomJID);
                  if lRecorder2.RoomJoined then
                  begin
                    lDeadline := GetTickCount64 + 5000;
                    repeat
                      Sleep(10);
                    until ((lRecorder1.RoomStateValue = xrsLeft) and
                      (lRecorder2.RoomStateValue = xrsLeft)) or
                      (GetTickCount64 >= lDeadline);
                    if (lRecorder1.RoomStateValue = xrsLeft) and
                      (lRecorder2.RoomStateValue = xrsLeft) then
                      WriteLn('Openfire MUC leave and room cleanup passed.')
                    else
                    begin
                      WriteLn('Openfire MUC leave did not complete.');
                      lExitCode := 1;
                    end;
                  end;
                end;
              end;
            end;
            lRecorder1.RoomJoined := False;
            lRecorder2.RoomJoined := False;
            lRecorder2.ReceivedRoomMessage := False;
            if not lMUC1.Join(lObservableRoomJID, lRoomNick1, '', False) or
              not lMUC2.Join(lObservableRoomJID, lRoomNick2, '', False) then
            begin
              WriteLn('The permanent-room join command was rejected.');
              lMUC1.Leave(lObservableRoomJID);
              lMUC2.Leave(lObservableRoomJID);
              lExitCode := 1;
            end
            else
            begin
              lDeadline := GetTickCount64 + 15000;
              repeat
                Sleep(10);
              until (lRecorder1.RoomJoined and lRecorder2.RoomJoined) or
                (lRecorder1.RoomStateValue = xrsFailed) or
                (lRecorder2.RoomStateValue = xrsFailed) or
                (GetTickCount64 >= lDeadline);
              if lRecorder1.RoomJoined and lRecorder2.RoomJoined then
              begin
                lBody := 'NexusXMPP observable permanent-room test ' + lRunID;
                lRecorder2.ExpectedBody := lBody;
                if not lMUC1.SendGroupMessage(lObservableRoomJID, lBody) then
                begin
                  WriteLn('The permanent-room message command was rejected.');
                  lExitCode := 1;
                end
                else
                begin
                  lDeadline := GetTickCount64 + 15000;
                  repeat
                    Sleep(10);
                  until lRecorder2.ReceivedRoomMessage or
                    (GetTickCount64 >= lDeadline);
                  if lRecorder2.ReceivedRoomMessage then
                  begin
                    WriteLn('Openfire permanent-room exchange passed: ',
                      lObservableRoomJID);
                    WriteLn('  Visible message: ', lBody);
                  end
                  else
                  begin
                    WriteLn('The permanent-room message was not received.');
                    lExitCode := 1;
                  end;
                end;
                lMUC1.Leave(lObservableRoomJID);
                lMUC2.Leave(lObservableRoomJID);
                lDeadline := GetTickCount64 + 5000;
                repeat
                  Sleep(10);
                until ((lRecorder1.RoomStateValue = xrsLeft) and
                  (lRecorder2.RoomStateValue = xrsLeft)) or
                  (GetTickCount64 >= lDeadline);
                if not ((lRecorder1.RoomStateValue = xrsLeft) and
                  (lRecorder2.RoomStateValue = xrsLeft)) then
                begin
                  WriteLn('The permanent-room leave did not complete.');
                  lExitCode := 1;
                end;
              end
              else
              begin
                WriteLn('Openfire permanent-room join did not complete.');
                WriteLn('  Client 1 detail: ', lRecorder1.LastError);
                WriteLn('  Client 2 detail: ', lRecorder2.LastError);
                lExitCode := 1;
              end;
            end;
            if lRecorder1.Features.IndexOf('urn:xmpp:mam:2') >= 0 then
            begin
              FillChar(lMAMFilter, SizeOf(lMAMFilter), 0);
              FillChar(lMAMPage, SizeOf(lMAMPage), 0);
              lMAMFilter.WithJID := lUser2;
              lMAMPage.Direction := xmpLastPage;
              lMAMPage.Maximum := 5;
              if lMAM1.Query('', lMAMFilter, lMAMPage, 5, 65536,
                lMAMOperation) then
              begin
                lDeadline := GetTickCount64 + 10000;
                repeat
                  Sleep(10);
                until lRecorder1.MAMComplete or
                  (GetTickCount64 >= lDeadline);
                if lRecorder1.MAMComplete then
                  WriteLn('Openfire bounded personal MAM query completed.')
                else
                  WriteLn('Openfire MAM query did not complete.');
              end;
            end;
          end
          else
          begin
            WriteLn('The expected message was not received.');
            WriteLn('Client 1 failure: ', lRecorder1.LastError);
            WriteLn('Client 2 failure: ', lRecorder2.LastError);
            WriteLn('Client 2 last stanza: ', lRecorder2.LastStanza);
          end;
        end;
      end;
    end;
  finally
    lClient3.Free;
    lClient2.Free;
    lClient1.Free;
    lRecorder3.Free;
    lRecorder2.Free;
    lRecorder1.Free;
  end;
  Halt(lExitCode);
end.

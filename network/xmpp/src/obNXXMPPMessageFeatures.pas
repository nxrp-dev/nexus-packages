(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPMessageFeatures;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPCommand, obNXXMPPConfig, obNXXMPPDispatcher, obNXXMPPMessage,
  obNXXMPPModule, obNXOpenSSLCrypto, obNXXMPPStanza,
  tpNXXMPPMessageTypes, tpNXXMPPTypes,
  utNXXMPPIDs, utNXXMPPXML;

type
  TNXXMPPMessageEvent = procedure(ASender: TObject;
    AMessage: TNXXMPPMessage) of object;
  TNXXMPPChatStateEvent = procedure(ASender: TObject;
    const AFromJID: UTF8String; AState: TNXXMPPChatState) of object;
  TNXXMPPReceiptEvent = procedure(ASender: TObject;
    const AFromJID, AStanzaID: UTF8String;
    AOutcome: TNXXMPPReceiptOutcome) of object;

  TNXXMPPReceiptCorrelation = class
  public
    ExpiresAt: QWord;
    ToJID: UTF8String;
  end;

  TNXXMPPMessageOperation = class(TNXXMPPModuleOperation)
  public
    XML: UTF8String;
  end;

  TNXXMPPMessageModule = class(TNXXMPPModule)
  private
    FAutomaticReceipts: Boolean;
    FOnChatState: TNXXMPPChatStateEvent;
    FOnMessage: TNXXMPPMessageEvent;
    FOnReceipt: TNXXMPPReceiptEvent;
    FCompletedReceipts: TStringList;
    FPendingReceipts: TStringList;
    FReceiptCapacity: Integer;
    FReceiptTimeoutMS: Cardinal;
    FReplyFallbackMaximumCharacters: Integer;
    procedure ExpireReceipts;
    function TrackReceipt(const AID, AToJID: UTF8String): Boolean;
    function QueueMessage(const AToJID, AType, ABody, AExtra: UTF8String;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    procedure ProcessCommand(AOperation: TNXXMPPModuleOperation); override;
    procedure PumpLifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    function SendChatMessage(const AToJID, ABody: UTF8String;
      ARequestReceipt: Boolean;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    function SendChatState(const AToJID: UTF8String;
      AState: TNXXMPPChatState): Boolean;
    function SendReply(const AToJID, ABody, AReplyToJID,
      AReplyID: UTF8String; ARequestReceipt: Boolean;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    function SendReplyToMessage(const AToJID, ABody: UTF8String;
      AMessage: TNXXMPPMessage; ARequestReceipt: Boolean;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    function SendReplyWithFallback(const AToJID, ABody, AFallbackText,
      AReplyToJID, AReplyID: UTF8String; ARequestReceipt: Boolean;
      out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
    property AutomaticReceipts: Boolean read FAutomaticReceipts
      write FAutomaticReceipts;
    property OnChatState: TNXXMPPChatStateEvent read FOnChatState
      write FOnChatState;
    property OnMessage: TNXXMPPMessageEvent read FOnMessage write FOnMessage;
    property OnReceipt: TNXXMPPReceiptEvent read FOnReceipt write FOnReceipt;
  end;

implementation

constructor TNXXMPPMessageModule.Create;
begin
  inherited Create;
  FCompletedReceipts := TStringList.Create;
  FCompletedReceipts.CaseSensitive := True;
  FPendingReceipts := TStringList.Create;
  FPendingReceipts.CaseSensitive := True;
  FReceiptCapacity := 256;
  FReceiptTimeoutMS := 300000;
  FReplyFallbackMaximumCharacters := 4096;
end;

destructor TNXXMPPMessageModule.Destroy;
begin
  while FCompletedReceipts.Count > 0 do
  begin
    FCompletedReceipts.Objects[0].Free;
    FCompletedReceipts.Delete(0);
  end;
  FCompletedReceipts.Free;
  while FPendingReceipts.Count > 0 do
  begin
    FPendingReceipts.Objects[0].Free;
    FPendingReceipts.Delete(0);
  end;
  FPendingReceipts.Free;
  inherited Destroy;
end;

procedure TNXXMPPMessageModule.Configure(AConfig: TNXXMPPClientConfig);
begin
  FReceiptCapacity := AConfig.ReceiptCapacity;
  FReceiptTimeoutMS := AConfig.ReceiptTimeoutMS;
  FReplyFallbackMaximumCharacters := AConfig.ReplyFallbackMaximumCharacters;
end;

function NXXMPPUTF8CharacterCount(const AValue: UTF8String): Integer;
var
  lIndex: Integer;
begin
  Result := 0;
  lIndex := 1;
  while lIndex <= Length(AValue) do
  begin
    if Byte(AValue[lIndex]) < $80 then Inc(lIndex)
    else if (Byte(AValue[lIndex]) and $E0) = $C0 then Inc(lIndex, 2)
    else if (Byte(AValue[lIndex]) and $F0) = $E0 then Inc(lIndex, 3)
    else if (Byte(AValue[lIndex]) and $F8) = $F0 then Inc(lIndex, 4)
    else Exit(-1);
    if lIndex > Length(AValue) + 1 then Exit(-1);
    Inc(Result);
  end;
end;

procedure TNXXMPPMessageModule.ExpireReceipts;
var
  lCorrelation: TNXXMPPReceiptCorrelation;
  lIndex: Integer;
begin
  for lIndex := FPendingReceipts.Count - 1 downto 0 do
  begin
    lCorrelation := TNXXMPPReceiptCorrelation(
      FPendingReceipts.Objects[lIndex]);
    if GetTickCount64 >= lCorrelation.ExpiresAt then
    begin
      if Assigned(FOnReceipt) then
        FOnReceipt(Self, '', UTF8String(FPendingReceipts[lIndex]), xroExpired);
      lCorrelation.Free;
      FPendingReceipts.Delete(lIndex);
    end;
  end;
end;

function NXXMPPBareJID(const AJID: UTF8String): UTF8String;
var
  lSeparator: Integer;
begin
  lSeparator := Pos('/', AJID);
  if lSeparator > 0 then
    Result := Copy(AJID, 1, lSeparator - 1)
  else
    Result := AJID;
end;

function TNXXMPPMessageModule.TrackReceipt(const AID,
  AToJID: UTF8String): Boolean;
var
  lCorrelation: TNXXMPPReceiptCorrelation;
begin
  ExpireReceipts;
  Result := FPendingReceipts.Count < FReceiptCapacity;
  if not Result then
    Exit;
  lCorrelation := TNXXMPPReceiptCorrelation.Create;
  lCorrelation.ExpiresAt := GetTickCount64 + FReceiptTimeoutMS;
  lCorrelation.ToJID := AToJID;
  FPendingReceipts.AddObject(string(AID), lCorrelation);
end;

procedure TNXXMPPMessageModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add('urn:xmpp:sid:0');
  AFeatures.Add('urn:xmpp:reply:0');
  AFeatures.Add('urn:xmpp:fallback:0');
  AFeatures.Add('urn:xmpp:receipts');
  AFeatures.Add('http://jabber.org/protocol/chatstates');
end;

procedure TNXXMPPMessageModule.RegisterHandlers(
  ADispatcher: TNXXMPPDispatcher);
begin
end;

function TNXXMPPMessageModule.QueueMessage(const AToJID, AType, ABody,
  AExtra: UTF8String; out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
var
  lOperation: TNXXMPPMessageOperation;
begin
  AIdentity.StanzaID := '';
  AIdentity.OriginID := '';
  if (AToJID = '') or ((ABody = '') and (AExtra = '')) then
    Exit(False);
  AIdentity.StanzaID := NXXMPPCreateID;
  AIdentity.OriginID := NXXMPPCreateID;
  lOperation := TNXXMPPMessageOperation.Create;
  lOperation.XML := '<message to=''' + NXXMPPEscapeAttribute(AToJID) +
    ''' type=''' + NXXMPPEscapeAttribute(AType) + ''' id=''' +
    NXXMPPEscapeAttribute(AIdentity.StanzaID) + '''>';
  if ABody <> '' then
    lOperation.XML := lOperation.XML + '<body>' + NXXMPPEscapeText(ABody) +
      '</body>';
  lOperation.XML := lOperation.XML +
    '<origin-id xmlns=''urn:xmpp:sid:0'' id=''' +
    NXXMPPEscapeAttribute(AIdentity.OriginID) + '''/>' + AExtra +
    '</message>';
  Result := Submit(lOperation);
  if not Result then
  begin
    AIdentity.StanzaID := '';
    AIdentity.OriginID := '';
  end;
end;

function TNXXMPPMessageModule.SendChatMessage(const AToJID,
  ABody: UTF8String; ARequestReceipt: Boolean;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
var
  lExtra: UTF8String;
begin
  if ARequestReceipt then
  begin
    ExpireReceipts;
    if FPendingReceipts.Count >= FReceiptCapacity then
    begin
      AIdentity.StanzaID := '';
      AIdentity.OriginID := '';
      Exit(False);
    end;
  end;
  if ARequestReceipt then
    lExtra := '<request xmlns=''urn:xmpp:receipts''/>'
  else
    lExtra := '';
  Result := QueueMessage(AToJID, 'chat', ABody, lExtra, AIdentity);
  if Result and ARequestReceipt then
  begin
    TrackReceipt(AIdentity.StanzaID, AToJID);
  end;
end;

function TNXXMPPMessageModule.SendReply(const AToJID, ABody,
  AReplyToJID, AReplyID: UTF8String; ARequestReceipt: Boolean;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
var
  lExtra: UTF8String;
begin
  if ARequestReceipt then
  begin
    ExpireReceipts;
    if FPendingReceipts.Count >= FReceiptCapacity then
    begin
      AIdentity.StanzaID := '';
      AIdentity.OriginID := '';
      Exit(False);
    end;
  end;
  if AReplyID = '' then
    Exit(False);
  lExtra := '<reply xmlns=''urn:xmpp:reply:0'' id=''' +
    NXXMPPEscapeAttribute(AReplyID) + '''';
  if AReplyToJID <> '' then
    lExtra := lExtra + ' to=''' + NXXMPPEscapeAttribute(AReplyToJID) + '''';
  lExtra := lExtra + '/>';
  if ARequestReceipt then
    lExtra := lExtra + '<request xmlns=''urn:xmpp:receipts''/>';
  Result := QueueMessage(AToJID, 'chat', ABody, lExtra, AIdentity);
  if Result and ARequestReceipt then
  begin
    TrackReceipt(AIdentity.StanzaID, AToJID);
  end;
end;

function TNXXMPPMessageModule.SendReplyToMessage(const AToJID,
  ABody: UTF8String; AMessage: TNXXMPPMessage; ARequestReceipt: Boolean;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
begin
  AIdentity.StanzaID := '';
  AIdentity.OriginID := '';
  if not Assigned(AMessage) or not AMessage.Valid or
    (AMessage.TypeValue = 'groupchat') or (AMessage.ID = '') then
    Exit(False);
  Result := SendReply(AToJID, ABody, AMessage.FromJID, AMessage.ID,
    ARequestReceipt, AIdentity);
end;

function TNXXMPPMessageModule.SendChatState(const AToJID: UTF8String;
  AState: TNXXMPPChatState): Boolean;
var
  lIdentity: TNXXMPPOutgoingMessageIdentity;
  lName: UTF8String;
begin
  lName := NXXMPPChatStateName(AState);
  if lName = '' then
    Exit(False);
  Result := QueueMessage(AToJID, 'chat', '', '<' + lName +
    ' xmlns=''http://jabber.org/protocol/chatstates''/>', lIdentity);
end;

function TNXXMPPMessageModule.SendReplyWithFallback(const AToJID, ABody,
  AFallbackText, AReplyToJID, AReplyID: UTF8String;
  ARequestReceipt: Boolean;
  out AIdentity: TNXXMPPOutgoingMessageIdentity): Boolean;
var
  lExtra: UTF8String;
  lFallbackCharacters: Integer;
begin
  AIdentity.StanzaID := '';
  AIdentity.OriginID := '';
  lFallbackCharacters := NXXMPPUTF8CharacterCount(AFallbackText);
  if (AReplyID = '') or (lFallbackCharacters < 0) or
    (lFallbackCharacters > FReplyFallbackMaximumCharacters) then
    Exit(False);
  if ARequestReceipt then
  begin
    ExpireReceipts;
    if FPendingReceipts.Count >= FReceiptCapacity then
      Exit(False);
  end;
  lExtra := '<reply xmlns=''urn:xmpp:reply:0'' id=''' +
    NXXMPPEscapeAttribute(AReplyID) + '''';
  if AReplyToJID <> '' then
    lExtra := lExtra + ' to=''' + NXXMPPEscapeAttribute(AReplyToJID) + '''';
  lExtra := lExtra + '/><fallback xmlns=''urn:xmpp:fallback:0'' for=' +
    '''urn:xmpp:reply:0''><body start=''0'' end=''' +
    UTF8String(IntToStr(lFallbackCharacters)) + '''/></fallback>';
  if ARequestReceipt then
    lExtra := lExtra + '<request xmlns=''urn:xmpp:receipts''/>';
  Result := QueueMessage(AToJID, 'chat', AFallbackText + ABody, lExtra,
    AIdentity);
  if Result and ARequestReceipt then
    TrackReceipt(AIdentity.StanzaID, AToJID);
end;

procedure TNXXMPPMessageModule.ProcessCommand(
  AOperation: TNXXMPPModuleOperation);
begin
  if not (AOperation is TNXXMPPMessageOperation) then
    inherited ProcessCommand(AOperation);
  Send(TNXXMPPMessageOperation(AOperation).XML, xrpStreamManaged);
end;

procedure TNXXMPPMessageModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lCorrelation: TNXXMPPReceiptCorrelation;
  lIdentity: TNXXMPPOutgoingMessageIdentity;
  lIndex: Integer;
  lMessage: TNXXMPPMessage;
begin
  if not Assigned(AStanza) or (AStanza.Kind <> xskMessage) then
    Exit;
  lMessage := TNXXMPPMessage.Create(AStanza);
  try
    ExpireReceipts;
    if FAutomaticReceipts and lMessage.Valid and
      (lMessage.Context = xmdcLive) and (lMessage.TypeValue = 'chat') and
      (lMessage.ReceiptKind = xrkRequest) and (lMessage.ID <> '') and
      (lMessage.FromJID <> '') then
      QueueMessage(lMessage.FromJID, 'chat', '',
        '<received xmlns=''urn:xmpp:receipts'' id=''' +
        NXXMPPEscapeAttribute(lMessage.ID) + '''/>', lIdentity);
    if lMessage.ReceiptKind = xrkReceived then
    begin
      lIdentity.StanzaID := lMessage.ReceiptID;
      if not lMessage.Valid or (lIdentity.StanzaID = '') then
      begin
        if Assigned(FOnReceipt) then
          FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID,
            xroMalformed);
      end
      else if FPendingReceipts.IndexOf(string(lIdentity.StanzaID)) >= 0 then
      begin
        lIndex := FPendingReceipts.IndexOf(string(lIdentity.StanzaID));
        lCorrelation := TNXXMPPReceiptCorrelation(
          FPendingReceipts.Objects[lIndex]);
        if NXXMPPBareJID(lMessage.FromJID) <>
          NXXMPPBareJID(lCorrelation.ToJID) then
        begin
          if Assigned(FOnReceipt) then
            FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID,
              xroMalformed);
        end;
        if NXXMPPBareJID(lMessage.FromJID) =
          NXXMPPBareJID(lCorrelation.ToJID) then
        begin
          FPendingReceipts.Objects[lIndex] := nil;
          FPendingReceipts.Delete(lIndex);
          while FCompletedReceipts.Count >= FReceiptCapacity do
          begin
            FCompletedReceipts.Objects[0].Free;
            FCompletedReceipts.Delete(0);
          end;
          FCompletedReceipts.AddObject(string(lIdentity.StanzaID),
            lCorrelation);
          if Assigned(FOnReceipt) then
            FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID,
              xroAccepted);
        end;
      end
      else if FCompletedReceipts.IndexOf(string(lIdentity.StanzaID)) >= 0 then
      begin
        lIndex := FCompletedReceipts.IndexOf(string(lIdentity.StanzaID));
        lCorrelation := TNXXMPPReceiptCorrelation(
          FCompletedReceipts.Objects[lIndex]);
        if Assigned(FOnReceipt) then
          if NXXMPPBareJID(lMessage.FromJID) =
            NXXMPPBareJID(lCorrelation.ToJID) then
            FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID,
              xroDuplicate)
          else
            FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID,
              xroMalformed);
      end
      else if Assigned(FOnReceipt) then
        FOnReceipt(Self, lMessage.FromJID, lIdentity.StanzaID, xroUnknown);
    end;
    if (lMessage.ChatState <> xcsNone) and Assigned(FOnChatState) then
      FOnChatState(Self, lMessage.FromJID, lMessage.ChatState);
    if Assigned(FOnMessage) and ((lMessage.Body <> '') or
      (lMessage.Subject <> '') or lMessage.Reply.Present or
      (Length(lMessage.Attachments) > 0)) then
      FOnMessage(Self, lMessage);
  finally
    lMessage.Free;
  end;
end;

procedure TNXXMPPMessageModule.PumpLifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
var
  lCorrelation: TNXXMPPReceiptCorrelation;
begin
  if not (ALifecycle in [xmlNewSession, xmlPermanentLoss,
    xmlFinalDisconnect]) then
    Exit;
  while FPendingReceipts.Count > 0 do
  begin
    if Assigned(FOnReceipt) then
      FOnReceipt(Self, '', UTF8String(FPendingReceipts[0]), xroFailed);
    lCorrelation := TNXXMPPReceiptCorrelation(FPendingReceipts.Objects[0]);
    lCorrelation.Free;
    FPendingReceipts.Delete(0);
  end;
  while FCompletedReceipts.Count > 0 do
  begin
    FCompletedReceipts.Objects[0].Free;
    FCompletedReceipts.Delete(0);
  end;
end;

end.

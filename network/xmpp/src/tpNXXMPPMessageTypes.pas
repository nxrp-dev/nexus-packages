(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXXMPPMessageTypes;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

type
  TNXXMPPUTF8Array = array of UTF8String;
  TNXXMPPMessageDeliveryContext = (xmdcLive, xmdcMUCHistory,
    xmdcCarbonSent, xmdcCarbonReceived, xmdcMAM);

  TNXXMPPChatState = (xcsNone, xcsActive, xcsComposing, xcsPaused,
    xcsInactive, xcsGone);

  TNXXMPPReceiptKind = (xrkNone, xrkRequest, xrkReceived);
  TNXXMPPReceiptOutcome = (xroAccepted, xroDuplicate, xroUnknown,
    xroMalformed, xroExpired, xroFailed);

  TNXXMPPStanzaID = record
    ByJID: UTF8String;
    ID: UTF8String;
  end;

  TNXXMPPStanzaIDArray = array of TNXXMPPStanzaID;

  TNXXMPPReplyReference = record
    Present: Boolean;
    ToJID: UTF8String;
    ID: UTF8String;
  end;

  TNXXMPPDelay = record
    Present: Boolean;
    Valid: Boolean;
    FromJID: UTF8String;
    Stamp: UTF8String;
    Timestamp: TDateTime;
    Reason: UTF8String;
  end;

  TNXXMPPOutgoingMessageIdentity = record
    StanzaID: UTF8String;
    OriginID: UTF8String;
  end;

  TNXXMPPMAMFilter = record
    WithJID: UTF8String;
    StartTimestamp: UTF8String;
    EndTimestamp: UTF8String;
    BeforeID: UTF8String;
    AfterID: UTF8String;
    IDs: TNXXMPPUTF8Array;
    IncludeGroupchat: Boolean;
    IncludeGroupchatSpecified: Boolean;
  end;

  TNXXMPPMAMPageDirection = (xmpForward, xmpBackward, xmpLastPage);

  TNXXMPPMAMPage = record
    Direction: TNXXMPPMAMPageDirection;
    Anchor: UTF8String;
    Maximum: Integer;
  end;

  TNXXMPPMUCRole = (xmrNone, xmrModerator, xmrParticipant, xmrVisitor);
  TNXXMPPMUCAffiliation = (xmaNone, xmaOwner, xmaAdmin, xmaMember,
    xmaOutcast);
  TNXXMPPMUCStatusCodeArray = array of Cardinal;

  TNXXMPPMUCError = record
    Present: Boolean;
    ErrorType: UTF8String;
    Condition: UTF8String;
    Text: UTF8String;
  end;

  TNXXMPPMUCTransitionReason = (xmtrNone, xmtrJoinRequested,
    xmtrCreateRequested, xmtrConfiguring, xmtrRoomConfigured,
    xmtrRoomAlreadyExists, xmtrConfigurationFailed, xmtrJoined,
    xmtrLeaveRequested, xmtrLeft, xmtrTemporaryLoss,
    xmtrResumedVerified, xmtrFreshSessionRejoin, xmtrSelfPingFailed,
    xmtrKicked, xmtrBanned, xmtrRoomCreated, xmtrServiceError,
    xmtrPermanentLoss);

  TNXXMPPMUCHistoryRequest = record
    MaxChars: Integer;
    MaxStanzas: Integer;
    Seconds: Integer;
    SinceTimestamp: UTF8String;
  end;

function NXXMPPChatStateFromName(const AValue: UTF8String): TNXXMPPChatState;
function NXXMPPChatStateName(AValue: TNXXMPPChatState): UTF8String;
function NXXMPPMUCRoleFromName(const AValue: UTF8String): TNXXMPPMUCRole;
function NXXMPPMUCAffiliationFromName(
  const AValue: UTF8String): TNXXMPPMUCAffiliation;

implementation

function NXXMPPChatStateFromName(
  const AValue: UTF8String): TNXXMPPChatState;
begin
  if AValue = 'active' then
    Result := xcsActive
  else if AValue = 'composing' then
    Result := xcsComposing
  else if AValue = 'paused' then
    Result := xcsPaused
  else if AValue = 'inactive' then
    Result := xcsInactive
  else if AValue = 'gone' then
    Result := xcsGone
  else
    Result := xcsNone;
end;

function NXXMPPMUCRoleFromName(const AValue: UTF8String): TNXXMPPMUCRole;
begin
  if AValue = 'moderator' then Result := xmrModerator
  else if AValue = 'participant' then Result := xmrParticipant
  else if AValue = 'visitor' then Result := xmrVisitor
  else Result := xmrNone;
end;

function NXXMPPMUCAffiliationFromName(
  const AValue: UTF8String): TNXXMPPMUCAffiliation;
begin
  if AValue = 'owner' then Result := xmaOwner
  else if AValue = 'admin' then Result := xmaAdmin
  else if AValue = 'member' then Result := xmaMember
  else if AValue = 'outcast' then Result := xmaOutcast
  else Result := xmaNone;
end;

function NXXMPPChatStateName(AValue: TNXXMPPChatState): UTF8String;
begin
  case AValue of
    xcsActive: Result := 'active';
    xcsComposing: Result := 'composing';
    xcsPaused: Result := 'paused';
    xcsInactive: Result := 'inactive';
    xcsGone: Result := 'gone';
  else
    Result := '';
  end;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPStreamManagement;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPError, obNXXMPPStanza, tpNXXMPPTypes,
  utNXXMPPXML;

type
  TNXXMPPStreamManagement = class
  private
    FDisconnected: Boolean;
    FDisconnectedAtMS: QWord;
    FEnabled: Boolean;
    FHandledIncoming: Cardinal;
    FHandledOutgoing: Cardinal;
    FLastAcknowledged: Cardinal;
    FLastAcknowledgedSerial: QWord;
    FOutgoingSerial: QWord;
    FOutstandingOutgoing: QWord;
    FReplay: TStringList;
    FReplayCapacity: Integer;
    FReplayReserved: Boolean;
    FResumeAllowed: Boolean;
    FResumeHasMaximum: Boolean;
    FResumeID: UTF8String;
    FResumeMaximumSeconds: Cardinal;
  public
    constructor Create(AReplayCapacity: Integer);
    destructor Destroy; override;
    procedure Acknowledge(AHandled: Cardinal);
    function AcknowledgementXML: UTF8String;
    function CanResume(ANowMS: QWord): Boolean;
    procedure Enable(const AResumeID: UTF8String; AResumeAllowed: Boolean;
      AResumeHasMaximum: Boolean; AResumeMaximumSeconds: Cardinal);
    procedure IncomingHandled;
    procedure MarkDisconnected(ANowMS: QWord);
    procedure OutgoingCancelled(AReplayable: Boolean);
    procedure OutgoingSent(const AXML: UTF8String; AReplayable: Boolean);
    procedure PrepareOutgoing(AReplayable: Boolean);
    function ProcessResumeResponse(AStanza: TNXXMPPStanza): Boolean;
    function ReplayCount: Integer;
    function ReplayXML(AIndex: Integer): UTF8String;
    function RequestAcknowledgementXML: UTF8String;
    function ResumeRejected: TStringList;
    function ResumeRequestXML: UTF8String;
    procedure Reset;
    property Enabled: Boolean read FEnabled;
    property HandledIncoming: Cardinal read FHandledIncoming;
    property HandledOutgoing: Cardinal read FHandledOutgoing;
    property ResumeID: UTF8String read FResumeID;
  end;

procedure NXXMPPIncrementSMCounter(var ACounter: Cardinal);
function NXXMPPSMCounterDelta(APrevious, ACurrent: Cardinal): QWord;

implementation

const
  cNXXMPPCounterModulus = QWord(High(Cardinal)) + 1;

procedure NXXMPPIncrementSMCounter(var ACounter: Cardinal);
begin
  if ACounter = High(Cardinal) then
    ACounter := 0
  else
    Inc(ACounter);
end;

function NXXMPPSMCounterDelta(APrevious, ACurrent: Cardinal): QWord;
begin
  Result := (QWord(ACurrent) + cNXXMPPCounterModulus -
    QWord(APrevious)) mod cNXXMPPCounterModulus;
end;

constructor TNXXMPPStreamManagement.Create(AReplayCapacity: Integer);
begin
  inherited Create;
  if AReplayCapacity < 1 then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-replay-capacity',
      'The stream-management replay capacity must be positive.');
  FReplayCapacity := AReplayCapacity;
  FReplay := TStringList.Create;
  FReplay.NameValueSeparator := '=';
end;

destructor TNXXMPPStreamManagement.Destroy;
begin
  FReplay.Free;
  inherited Destroy;
end;

procedure TNXXMPPStreamManagement.Reset;
begin
  FDisconnected := False;
  FDisconnectedAtMS := 0;
  FEnabled := False;
  FHandledIncoming := 0;
  FHandledOutgoing := 0;
  FLastAcknowledged := 0;
  FLastAcknowledgedSerial := 0;
  FOutgoingSerial := 0;
  FOutstandingOutgoing := 0;
  FReplay.Clear;
  FReplayReserved := False;
  FResumeAllowed := False;
  FResumeHasMaximum := False;
  FResumeID := '';
  FResumeMaximumSeconds := 0;
end;

procedure TNXXMPPStreamManagement.Enable(const AResumeID: UTF8String;
  AResumeAllowed: Boolean; AResumeHasMaximum: Boolean;
  AResumeMaximumSeconds: Cardinal);
begin
  Reset;
  FEnabled := True;
  FResumeAllowed := AResumeAllowed;
  if AResumeAllowed then
  begin
    FResumeID := AResumeID;
    FResumeHasMaximum := AResumeHasMaximum;
    FResumeMaximumSeconds := AResumeMaximumSeconds;
  end;
end;

procedure TNXXMPPStreamManagement.MarkDisconnected(ANowMS: QWord);
begin
  if not FEnabled or FDisconnected then
    Exit;
  FDisconnected := True;
  FDisconnectedAtMS := ANowMS;
end;

function TNXXMPPStreamManagement.CanResume(ANowMS: QWord): Boolean;
var
  lElapsedMS: QWord;
begin
  Result := FEnabled and FResumeAllowed and (FResumeID <> '') and
    FDisconnected;
  if not Result or not FResumeHasMaximum then
    Exit;
  if ANowMS < FDisconnectedAtMS then
    Exit(False);
  lElapsedMS := ANowMS - FDisconnectedAtMS;
  Result := lElapsedMS <= QWord(FResumeMaximumSeconds) * 1000;
end;

procedure TNXXMPPStreamManagement.IncomingHandled;
begin
  if FEnabled then
    NXXMPPIncrementSMCounter(FHandledIncoming);
end;

procedure TNXXMPPStreamManagement.PrepareOutgoing(AReplayable: Boolean);
begin
  if not FEnabled or not AReplayable then
    Exit;
  if FReplayReserved then
    raise ENXXMPPError.Create(xesProtocol, 'replay-reservation-active',
      'A stream-management replay reservation is already active.');
  if FReplay.Count >= FReplayCapacity then
    raise ENXXMPPError.Create(xesProtocol, 'replay-queue-full',
      'The stream-management replay queue is full.');
  FReplayReserved := True;
end;

procedure TNXXMPPStreamManagement.OutgoingCancelled(AReplayable: Boolean);
begin
  if FEnabled and AReplayable then
    FReplayReserved := False;
end;

procedure TNXXMPPStreamManagement.OutgoingSent(const AXML: UTF8String;
  AReplayable: Boolean);
begin
  if not FEnabled then
    Exit;
  if AReplayable and not FReplayReserved then
    raise ENXXMPPError.Create(xesProtocol, 'missing-replay-reservation',
      'A replayable stanza must reserve replay capacity before transmission.');
  Inc(FOutgoingSerial);
  Inc(FOutstandingOutgoing);
  NXXMPPIncrementSMCounter(FHandledOutgoing);
  if AReplayable then
  begin
    FReplay.Add(UIntToStr(FOutgoingSerial) + '=' + string(AXML));
    FReplayReserved := False;
  end;
end;

procedure TNXXMPPStreamManagement.Acknowledge(AHandled: Cardinal);
var
  lAcknowledgedSerial: QWord;
  lDelta: QWord;
  lSequence: QWord;
begin
  if not FEnabled then
    raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-acknowledgement',
      'The stream-management acknowledgement has no active stream.');
  lDelta := NXXMPPSMCounterDelta(FLastAcknowledged, AHandled);
  if lDelta > FOutstandingOutgoing then
    raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-acknowledgement',
      'The stream-management acknowledgement is outside the sent range.');
  lAcknowledgedSerial := FLastAcknowledgedSerial + lDelta;
  FLastAcknowledged := AHandled;
  FLastAcknowledgedSerial := lAcknowledgedSerial;
  Dec(FOutstandingOutgoing, lDelta);
  while FReplay.Count > 0 do
  begin
    if not TryStrToQWord(FReplay.Names[0], lSequence) or
      (lSequence > lAcknowledgedSerial) then
      Break;
    FReplay.Delete(0);
  end;
end;

function TNXXMPPStreamManagement.AcknowledgementXML: UTF8String;
begin
  Result := '<a xmlns=''urn:xmpp:sm:3'' h=''' +
    UTF8String(UIntToStr(FHandledIncoming)) + '''/>';
end;

function TNXXMPPStreamManagement.RequestAcknowledgementXML: UTF8String;
begin
  Result := '<r xmlns=''urn:xmpp:sm:3''/>';
end;

function TNXXMPPStreamManagement.ResumeRequestXML: UTF8String;
begin
  if not CanResume(GetTickCount64) then
    raise ENXXMPPError.Create(xesProtocol, 'stream-not-resumable',
      'The prior stream is not eligible for resumption.');
  Result := '<resume xmlns=''urn:xmpp:sm:3'' h=''' +
    UTF8String(UIntToStr(FHandledIncoming)) + ''' previd=''' +
    NXXMPPEscapeAttribute(FResumeID) + '''/>';
end;

function TNXXMPPStreamManagement.ResumeRejected: TStringList;
var
  lIndex: Integer;
begin
  Result := TStringList.Create;
  for lIndex := 0 to FReplay.Count - 1 do
    Result.Add(string(ReplayXML(lIndex)));
  Reset;
end;

function TNXXMPPStreamManagement.ProcessResumeResponse(
  AStanza: TNXXMPPStanza): Boolean;
var
  lHandled: QWord;
begin
  Result := Assigned(AStanza) and
    (AStanza.NamespaceURI = 'urn:xmpp:sm:3') and
    (AStanza.LocalName = 'resumed');
  if not Result then
    Exit;
  if AStanza.Attribute('previd') <> FResumeID then
    raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-previd',
      'The resumed stream identifier does not match the requested session.');
  if not TryStrToQWord(string(AStanza.Attribute('h')), lHandled) or
    (lHandled > High(Cardinal)) then
    raise ENXXMPPError.Create(xesProtocol, 'invalid-sm-acknowledgement',
      'The resumed stream acknowledgement counter is invalid.');
  Acknowledge(Cardinal(lHandled));
  FDisconnected := False;
end;

function TNXXMPPStreamManagement.ReplayCount: Integer;
begin
  Result := FReplay.Count;
end;

function TNXXMPPStreamManagement.ReplayXML(AIndex: Integer): UTF8String;
begin
  Result := UTF8String(FReplay.ValueFromIndex[AIndex]);
end;

end.

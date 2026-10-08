(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPMessage;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, obNXXMPPStanza, tpNXXMPPMessageTypes,
  tpNXXMPPFileTypes, tpNXXMPPTypes, utNXXMPPDateTime, utNXXMPPDOM;

type
  TNXXMPPMessage = class
  private
    FBody: UTF8String;
    FAttachments: TNXXMPPFileShareArray;
    FChatState: TNXXMPPChatState;
    FContext: TNXXMPPMessageDeliveryContext;
    FDelay: TNXXMPPDelay;
    FDisplayBody: UTF8String;
    FFromJID: UTF8String;
    FID: UTF8String;
    FOriginID: UTF8String;
    FRawXML: UTF8String;
    FReceiptID: UTF8String;
    FReceiptKind: TNXXMPPReceiptKind;
    FReply: TNXXMPPReplyReference;
    FStanzaIDs: TNXXMPPStanzaIDArray;
    FSubject: UTF8String;
    FToJID: UTF8String;
    FTypeValue: UTF8String;
    FValid: Boolean;
    FValidationError: UTF8String;
    procedure Invalidate(const AReason: UTF8String);
    procedure ParseFileShare(AElement: TDOMElement;
      var AMetadataBytes: Integer);
    procedure Parse(AStanza: TNXXMPPStanza);
  public
    constructor Create(AStanza: TNXXMPPStanza;
      AContext: TNXXMPPMessageDeliveryContext = xmdcLive);
    function StanzaIDFor(const AByJID: UTF8String;
      out AID: UTF8String): Boolean;
    property Body: UTF8String read FBody;
    property Attachments: TNXXMPPFileShareArray read FAttachments;
    property ChatState: TNXXMPPChatState read FChatState;
    property Context: TNXXMPPMessageDeliveryContext read FContext;
    property Delay: TNXXMPPDelay read FDelay;
    property DisplayBody: UTF8String read FDisplayBody;
    property FromJID: UTF8String read FFromJID;
    property ID: UTF8String read FID;
    property OriginID: UTF8String read FOriginID;
    property RawXML: UTF8String read FRawXML;
    property ReceiptID: UTF8String read FReceiptID;
    property ReceiptKind: TNXXMPPReceiptKind read FReceiptKind;
    property Reply: TNXXMPPReplyReference read FReply;
    property StanzaIDs: TNXXMPPStanzaIDArray read FStanzaIDs;
    property Subject: UTF8String read FSubject;
    property ToJID: UTF8String read FToJID;
    property TypeValue: UTF8String read FTypeValue;
    property Valid: Boolean read FValid;
    property ValidationError: UTF8String read FValidationError;
  end;

implementation

type
  TNXXMPPFallbackRange = record
    StartCharacter: Integer;
    EndCharacter: Integer;
    ForNamespace: UTF8String;
    WholeBody: Boolean;
  end;
  TNXXMPPFallbackRangeArray = array of TNXXMPPFallbackRange;

function NXXMPPUTF8Offset(const AValue: UTF8String; ACharacterIndex: Integer;
  out AByteOffset: Integer): Boolean;
var
  lCharacter: Integer;
  lLength: Integer;
begin
  Result := False;
  AByteOffset := 1;
  if ACharacterIndex < 0 then
    Exit;
  lCharacter := 0;
  while (AByteOffset <= Length(AValue)) and
    (lCharacter < ACharacterIndex) do
  begin
    if Byte(AValue[AByteOffset]) < $80 then
      lLength := 1
    else if (Byte(AValue[AByteOffset]) and $E0) = $C0 then
      lLength := 2
    else if (Byte(AValue[AByteOffset]) and $F0) = $E0 then
      lLength := 3
    else if (Byte(AValue[AByteOffset]) and $F8) = $F0 then
      lLength := 4
    else
      Exit;
    Inc(AByteOffset, lLength);
    Inc(lCharacter);
  end;
  Result := lCharacter = ACharacterIndex;
end;

constructor TNXXMPPMessage.Create(AStanza: TNXXMPPStanza;
  AContext: TNXXMPPMessageDeliveryContext);
begin
  inherited Create;
  FContext := AContext;
  FValid := True;
  Parse(AStanza);
end;

procedure TNXXMPPMessage.Invalidate(const AReason: UTF8String);
begin
  FValid := False;
  if FValidationError = '' then
    FValidationError := AReason;
end;

procedure TNXXMPPMessage.ParseFileShare(AElement: TDOMElement;
  var AMetadataBytes: Integer);
var
  lChild: TDOMElement;
  lFile: TDOMElement;
  lHash: TNXXMPPFileHash;
  lIndex: Integer;
  lShare: TNXXMPPFileShare;
  lSize: Int64;
  lSource: TNXXMPPFileSource;
  lSources: TDOMElement;
  lText: UTF8String;
  lDescriptionSeen: Boolean;
  lMediaTypeSeen: Boolean;
  lNameSeen: Boolean;
begin
  lShare := Default(TNXXMPPFileShare);
  lDescriptionSeen := False;
  lMediaTypeSeen := False;
  lNameSeen := False;
  if Length(FAttachments) >= cNXXMPPFileMaximumAttachments then
  begin
    Invalidate('The message contains too many file shares.');
    Exit;
  end;
  AMetadataBytes := AMetadataBytes + Length(NXXMPPElementXML(AElement));
  if AMetadataBytes > cNXXMPPFileMaximumMetadataBytes then
  begin
    Invalidate('The message file metadata is too large.');
    Exit;
  end;

  lShare.ID := UTF8Encode(AElement.GetAttribute('id'));
  lShare.Disposition := UTF8Encode(AElement.GetAttribute('disposition'));
  if Length(lShare.ID) > cNXXMPPFileMaximumShareIDBytes then
    Invalidate('The file share id is too long.');
  for lIndex := 0 to High(FAttachments) do
    if (lShare.ID <> '') and (FAttachments[lIndex].ID = lShare.ID) then
      Invalidate('The message contains duplicate file share ids.');

  lFile := nil;
  lSources := nil;
  lChild := NXXMPPFirstChildElement(AElement);
  while Assigned(lChild) do
  begin
    if NXXMPPElementMatches(lChild, cNXXMPPFileMetadataNamespace,
      'file') then
    begin
      if Assigned(lFile) then
        Invalidate('A file share contains more than one file metadata element.')
      else
        lFile := lChild;
    end
    else if NXXMPPElementMatches(lChild, cNXXMPPFileSharingNamespace,
      'sources') then
    begin
      if Assigned(lSources) then
        Invalidate('A file share contains more than one sources element.')
      else
        lSources := lChild;
    end;
    lChild := NXXMPPNextSiblingElement(lChild);
  end;
  if not Assigned(lFile) then
    Invalidate('A file share requires file metadata.');
  if not Assigned(lSources) then
    Invalidate('A file share requires sources.');

  if Assigned(lFile) then
  begin
    lChild := NXXMPPFirstChildElement(lFile);
    while Assigned(lChild) do
    begin
      if NXXMPPElementMatches(lChild, cNXXMPPFileMetadataNamespace,
        'name') then
      begin
        if lNameSeen then
          Invalidate('A file share contains more than one name.');
        lNameSeen := True;
        lShare.Name := NXXMPPDirectText(lChild);
        if Length(lShare.Name) > cNXXMPPFileMaximumNameBytes then
          Invalidate('The file name is too long.');
      end
      else if NXXMPPElementMatches(lChild, cNXXMPPFileMetadataNamespace,
        'media-type') then
      begin
        if lMediaTypeSeen then
          Invalidate('A file share contains more than one media type.');
        lMediaTypeSeen := True;
        lShare.MediaType := NXXMPPDirectText(lChild);
        if Length(lShare.MediaType) > cNXXMPPFileMaximumMediaTypeBytes then
          Invalidate('The file media type is too long.');
      end
      else if NXXMPPElementMatches(lChild, cNXXMPPFileMetadataNamespace,
        'desc') then
      begin
        if lDescriptionSeen then
          Invalidate('A file share contains more than one description.');
        lDescriptionSeen := True;
        lShare.Description := NXXMPPDirectText(lChild);
        if Length(lShare.Description) > cNXXMPPFileMaximumDescriptionBytes then
          Invalidate('The file description is too long.');
      end
      else if NXXMPPElementMatches(lChild, cNXXMPPFileMetadataNamespace,
        'size') then
      begin
        if lShare.HasSize then
          Invalidate('A file share contains more than one size.');
        lText := NXXMPPDirectText(lChild);
        if not TryStrToInt64(string(lText), lSize) or (lSize < 0) then
          Invalidate('The declared file size is invalid.')
        else
        begin
          lShare.HasSize := True;
          lShare.DeclaredSize := lSize;
        end;
      end
      else if NXXMPPElementMatches(lChild, cNXXMPPFileHashNamespace,
        'hash') then
      begin
        if Length(lShare.Hashes) >= cNXXMPPFileMaximumHashes then
          Invalidate('A file share contains too many hashes.')
        else
        begin
          lHash.Algorithm := UTF8Encode(lChild.GetAttribute('algo'));
          lHash.Value := NXXMPPDirectText(lChild);
          if (lHash.Algorithm = '') or (lHash.Value = '') then
            Invalidate('A file hash requires an algorithm and value.')
          else
          begin
            SetLength(lShare.Hashes, Length(lShare.Hashes) + 1);
            lShare.Hashes[High(lShare.Hashes)] := lHash;
          end;
        end;
      end;
      lChild := NXXMPPNextSiblingElement(lChild);
    end;
  end;

  if Assigned(lSources) then
  begin
    lChild := NXXMPPFirstChildElement(lSources);
    while Assigned(lChild) do
    begin
      if NXXMPPElementMatches(lChild, cNXXMPPURLDataNamespace,
        'url-data') then
      begin
        if Length(lShare.Sources) >= cNXXMPPFileMaximumSources then
          Invalidate('A file share contains too many URL sources.')
        else
        begin
          lSource.URL := UTF8Encode(lChild.GetAttribute('target'));
          if lSource.URL = '' then
            Invalidate('A file URL source requires a target.')
          else if Length(lSource.URL) > cNXXMPPFileMaximumURLBytes then
            Invalidate('A file URL source is too long.')
          else
          begin
            SetLength(lShare.Sources, Length(lShare.Sources) + 1);
            lShare.Sources[High(lShare.Sources)] := lSource;
          end;
        end;
      end;
      lChild := NXXMPPNextSiblingElement(lChild);
    end;
  end;
  if Length(lShare.Sources) = 0 then
    Invalidate('A file share contains no supported URL source.');

  SetLength(FAttachments, Length(FAttachments) + 1);
  FAttachments[High(FAttachments)] := lShare;
  if (Length(FAttachments) > 1) and (lShare.ID = '') then
    Invalidate('Every file in a multi-file message requires an id.');
  if (Length(FAttachments) = 2) and (FAttachments[0].ID = '') then
    Invalidate('Every file in a multi-file message requires an id.');
end;

procedure TNXXMPPMessage.Parse(AStanza: TNXXMPPStanza);
var
  lChild: TDOMElement;
  lID: TNXXMPPStanzaID;
  lLocalName: UTF8String;
  lNamespace: UTF8String;
  lState: TNXXMPPChatState;
  lIndex: Integer;
  lFallbackFor: UTF8String;
  lFallbackRange: TNXXMPPFallbackRange;
  lFallbackRanges: TNXXMPPFallbackRangeArray;
  lMetadataBytes: Integer;
  lRange: TDOMElement;
  lStartByte: Integer;
  lEndByte: Integer;
  lSwap: TNXXMPPFallbackRange;
  lSort: Integer;
begin
  lMetadataBytes := 0;
  SetLength(lFallbackRanges, 0);
  if not Assigned(AStanza) or (AStanza.Kind <> xskMessage) then
  begin
    Invalidate('The retained stanza is not a message.');
    Exit;
  end;
  FRawXML := AStanza.RawXML;
  FFromJID := AStanza.FromJID;
  FToJID := AStanza.ToJID;
  FID := AStanza.ID;
  FTypeValue := AStanza.TypeValue;
  lChild := NXXMPPFirstChildElement(AStanza.Root);
  while Assigned(lChild) do
  begin
    lLocalName := NXXMPPElementLocalName(lChild);
    lNamespace := NXXMPPElementNamespaceURI(lChild);
    if (lNamespace = 'jabber:client') and (lLocalName = 'body') then
    begin
      if FBody = '' then
        FBody := NXXMPPDirectText(lChild);
    end
    else if (lNamespace = 'jabber:client') and (lLocalName = 'subject') then
    begin
      if FSubject = '' then
        FSubject := NXXMPPDirectText(lChild);
    end
    else if (lNamespace = 'urn:xmpp:sid:0') and
      (lLocalName = 'origin-id') then
    begin
      if FOriginID <> '' then
        Invalidate('The message contains more than one origin-id.')
      else
        FOriginID := UTF8Encode(lChild.GetAttribute('id'));
      if FOriginID = '' then
        Invalidate('The message origin-id is empty.');
    end
    else if (lNamespace = 'urn:xmpp:sid:0') and
      (lLocalName = 'stanza-id') then
    begin
      lID.ByJID := UTF8Encode(lChild.GetAttribute('by'));
      lID.ID := UTF8Encode(lChild.GetAttribute('id'));
      if (lID.ByJID = '') or (lID.ID = '') then
        Invalidate('A stanza-id requires both by and id.')
      else
      begin
        for lIndex := 0 to High(FStanzaIDs) do
          if FStanzaIDs[lIndex].ByJID = lID.ByJID then
            Invalidate('A stanza-id issuer occurs more than once.');
        SetLength(FStanzaIDs, Length(FStanzaIDs) + 1);
        FStanzaIDs[High(FStanzaIDs)] := lID;
      end;
    end
    else if (lNamespace = 'urn:xmpp:reply:0') and
      (lLocalName = 'reply') then
    begin
      if FReply.Present then
        Invalidate('The message contains more than one reply element.')
      else
      begin
        FReply.Present := True;
        FReply.ToJID := UTF8Encode(lChild.GetAttribute('to'));
        FReply.ID := UTF8Encode(lChild.GetAttribute('id'));
        if FReply.ID = '' then
          Invalidate('A reply reference requires an id.');
      end;
    end
    else if (lNamespace = 'urn:xmpp:receipts') and
      (lLocalName = 'request') then
    begin
      if FReceiptKind <> xrkNone then
        Invalidate('The message contains conflicting receipt elements.')
      else
        FReceiptKind := xrkRequest;
    end
    else if (lNamespace = 'urn:xmpp:receipts') and
      (lLocalName = 'received') then
    begin
      if FReceiptKind <> xrkNone then
        Invalidate('The message contains conflicting receipt elements.')
      else
      begin
        FReceiptKind := xrkReceived;
        FReceiptID := UTF8Encode(lChild.GetAttribute('id'));
        if FReceiptID = '' then
          Invalidate('A delivery receipt requires an id.');
      end;
    end
    else if lNamespace = 'http://jabber.org/protocol/chatstates' then
    begin
      lState := NXXMPPChatStateFromName(lLocalName);
      if lState <> xcsNone then
      begin
        if FChatState <> xcsNone then
          Invalidate('The message contains more than one chat state.')
        else
          FChatState := lState;
      end;
    end
    else if (lNamespace = 'urn:xmpp:delay') and
      (lLocalName = 'delay') then
    begin
      if FDelay.Present then
        Invalidate('The message contains more than one delay element.')
      else
      begin
        FDelay.Present := True;
        FDelay.FromJID := UTF8Encode(lChild.GetAttribute('from'));
        FDelay.Stamp := UTF8Encode(lChild.GetAttribute('stamp'));
        FDelay.Valid := NXXMPPTryParseTimestamp(FDelay.Stamp,
          FDelay.Timestamp);
        if not FDelay.Valid then
          Invalidate('The message delay timestamp is invalid.');
        FDelay.Reason := NXXMPPDirectText(lChild);
      end;
    end
    else if (lNamespace = cNXXMPPFileSharingNamespace) and
      (lLocalName = 'file-sharing') then
      ParseFileShare(lChild, lMetadataBytes)
    else if (lNamespace = 'urn:xmpp:fallback:0') and
      (lLocalName = 'fallback') then
    begin
      lFallbackFor := UTF8Encode(lChild.GetAttribute('for'));
      if (lFallbackFor = 'urn:xmpp:reply:0') or
        (lFallbackFor = cNXXMPPFileSharingNamespace) then
      begin
        lFallbackRange.ForNamespace := lFallbackFor;
        lRange := NXXMPPFindChild(lChild, 'urn:xmpp:fallback:0', 'body');
        if not Assigned(lRange) then
          Invalidate('The message fallback body is missing.')
        else
        begin
          lFallbackRange.WholeBody :=
            (not lRange.HasAttribute('start')) and
            (not lRange.HasAttribute('end'));
          if lFallbackRange.WholeBody then
          begin
            lFallbackRange.StartCharacter := 0;
            lFallbackRange.EndCharacter := MaxInt;
          end
          else if not TryStrToInt(string(UTF8Encode(
            lRange.GetAttribute('start'))), lFallbackRange.StartCharacter) or
            not TryStrToInt(string(UTF8Encode(lRange.GetAttribute('end'))),
              lFallbackRange.EndCharacter) or
            (lFallbackRange.StartCharacter < 0) or
            (lFallbackRange.EndCharacter < lFallbackRange.StartCharacter) then
            Invalidate('The message fallback body range is invalid.')
          else
          begin
            SetLength(lFallbackRanges, Length(lFallbackRanges) + 1);
            lFallbackRanges[High(lFallbackRanges)] := lFallbackRange;
          end;
          if lFallbackRange.WholeBody then
          begin
            SetLength(lFallbackRanges, Length(lFallbackRanges) + 1);
            lFallbackRanges[High(lFallbackRanges)] := lFallbackRange;
          end;
        end;
      end;
    end;
    lChild := NXXMPPNextSiblingElement(lChild);
  end;
  FDisplayBody := FBody;
  for lIndex := 0 to High(lFallbackRanges) - 1 do
    for lSort := lIndex + 1 to High(lFallbackRanges) do
      if lFallbackRanges[lIndex].StartCharacter <
        lFallbackRanges[lSort].StartCharacter then
      begin
        lSwap := lFallbackRanges[lIndex];
        lFallbackRanges[lIndex] := lFallbackRanges[lSort];
        lFallbackRanges[lSort] := lSwap;
      end;
  for lIndex := 0 to High(lFallbackRanges) do
  begin
    if ((lFallbackRanges[lIndex].ForNamespace = 'urn:xmpp:reply:0') and
      not FReply.Present) or
      ((lFallbackRanges[lIndex].ForNamespace =
      cNXXMPPFileSharingNamespace) and (Length(FAttachments) = 0)) then
      Continue;
    if lFallbackRanges[lIndex].WholeBody then
      FDisplayBody := ''
    else if not NXXMPPUTF8Offset(FBody,
      lFallbackRanges[lIndex].StartCharacter, lStartByte) or
      not NXXMPPUTF8Offset(FBody, lFallbackRanges[lIndex].EndCharacter,
        lEndByte) then
      Invalidate('The message fallback body range exceeds the body.')
    else
      Delete(FDisplayBody, lStartByte, lEndByte - lStartByte);
  end;
end;

function TNXXMPPMessage.StanzaIDFor(const AByJID: UTF8String;
  out AID: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  AID := '';
  for lIndex := 0 to High(FStanzaIDs) do
    if FStanzaIDs[lIndex].ByJID = AByJID then
    begin
      AID := FStanzaIDs[lIndex].ID;
      Exit(True);
    end;
  Result := False;
end;

end.

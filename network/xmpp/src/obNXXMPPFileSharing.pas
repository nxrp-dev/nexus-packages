(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPFileSharing;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, DOM, obNXXMPPCommand, obNXXMPPConfig,
  obNXXMPPDisco, obNXXMPPDispatcher, obNXXMPPJID, obNXXMPPModule,
  obNXXMPPStanza, tpNXXMPPFileTypes, tpNXXMPPMessageTypes, tpNXXMPPTypes;

type
  TNXXMPPHTTPUploadServiceEvent = procedure(ASender: TObject;
    const AService: TNXXMPPHTTPUploadService;
    const AError: UTF8String) of object;
  TNXXMPPHTTPUploadSlotEvent = procedure(ASender: TObject;
    const ASlot: TNXXMPPHTTPUploadSlot; const AError: UTF8String) of object;

  TNXXMPPFileSharingModule = class(TNXXMPPModule)
  private
    FDomain: UTF8String;
    FRequests: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    procedure Lifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    procedure ProcessCommand(AOperation: TNXXMPPModuleOperation); override;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    function DiscoverUploadService(AFileSize: Int64;
      AHandler: TNXXMPPHTTPUploadServiceEvent): Boolean; virtual;
    function RequestUploadSlot(const AServiceJID, AFileName,
      AMediaType: UTF8String; AFileSize: Int64;
      AHandler: TNXXMPPHTTPUploadSlotEvent): Boolean; virtual;
    function SendFileShare(const AToJID, AMessageType: UTF8String;
      const AReplyJID, AReplyID: UTF8String;
      const AShare: TNXXMPPFileShare): Boolean; virtual;
  end;

implementation

uses
  utNXXMPPDOM, utNXXMPPIDs, utNXXMPPXML;

type
  TNXXMPPFileOperationKind = (xfokDiscover, xfokSlot, xfokSend);

  TNXXMPPFileOperation = class(TNXXMPPModuleOperation)
  public
    Kind: TNXXMPPFileOperationKind;
    FileName: UTF8String;
    FileSize: Int64;
    MediaType: UTF8String;
    ServiceHandler: TNXXMPPHTTPUploadServiceEvent;
    ServiceJID: UTF8String;
    Share: TNXXMPPFileShare;
    SlotHandler: TNXXMPPHTTPUploadSlotEvent;
    ToJID: UTF8String;
    MessageType: UTF8String;
    ReplyID: UTF8String;
    ReplyJID: UTF8String;
  end;

  TNXXMPPDiscoveryRequest = class
  private
    FCandidates: TNXXMPPUTF8Array;
    FFileSize: Int64;
    FHandler: TNXXMPPHTTPUploadServiceEvent;
    FIndex: Integer;
    FModule: TNXXMPPFileSharingModule;
    procedure CompleteInfo(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure CompleteItems(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure Finish(const AService: TNXXMPPHTTPUploadService;
      const AError: UTF8String);
    procedure QueryNext;
  end;

  TNXXMPPSlotRequest = class
  private
    FHandler: TNXXMPPHTTPUploadSlotEvent;
    FModule: TNXXMPPFileSharingModule;
    procedure Complete(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
  end;

function NXXMPPStripNewlines(const AValue: UTF8String): UTF8String;
var
  lIndex: Integer;
begin
  Result := '';
  for lIndex := 1 to Length(AValue) do
    if not (AValue[lIndex] in [#10, #13]) then
      Result := Result + AValue[lIndex];
end;

function NXXMPPAllowedSlotHeader(const AName: UTF8String): Boolean;
begin
  Result := SameText(string(AName), 'Authorization') or
    SameText(string(AName), 'Cookie') or SameText(string(AName), 'Expires');
end;

function NXXMPPParseMaximumSize(AInfo: TNXXMPPDiscoInfo;
  out AHasMaximum: Boolean; out AMaximum: Int64): Boolean;
var
  lField: TNXXMPPDataFormField;
  lForm: TNXXMPPDataForm;
begin
  Result := True;
  AHasMaximum := False;
  AMaximum := 0;
  lForm := AInfo.DataForm('urn:xmpp:http:upload:0');
  if not Assigned(lForm) then
    Exit;
  lField := lForm.Field('max-file-size');
  if not Assigned(lField) then
    Exit;
  Result := (lField.Values.Count = 1) and
    TryStrToInt64(lField.Values[0], AMaximum) and (AMaximum >= 0);
  AHasMaximum := Result;
end;

constructor TNXXMPPFileSharingModule.Create;
begin
  inherited Create;
  FRequests := TObjectList.Create(True);
end;

destructor TNXXMPPFileSharingModule.Destroy;
begin
  FRequests.Free;
  inherited Destroy;
end;

procedure TNXXMPPFileSharingModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add(cNXXMPPFileSharingNamespace);
  AFeatures.Add(cNXXMPPFileMetadataNamespace);
  AFeatures.Add(cNXXMPPFileHashNamespace);
  AFeatures.Add('urn:xmpp:fallback:0');
  AFeatures.Add('jabber:x:oob');
end;

procedure TNXXMPPFileSharingModule.Configure(AConfig: TNXXMPPClientConfig);
var
  lJID: TNXXMPPJID;
begin
  lJID := TNXXMPPJID.Create(AConfig.JID);
  try
    FDomain := lJID.DomainPart;
  finally
    lJID.Free;
  end;
end;

procedure TNXXMPPFileSharingModule.Lifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
begin
  { The request manager owns IQ cancellation and invokes each completion
    after lifecycle notification. Pending callback objects remain alive until
    that terminal completion arrives. }
end;

procedure TNXXMPPFileSharingModule.RegisterHandlers(
  ADispatcher: TNXXMPPDispatcher);
begin
end;

function TNXXMPPFileSharingModule.DiscoverUploadService(AFileSize: Int64;
  AHandler: TNXXMPPHTTPUploadServiceEvent): Boolean;
var
  lOperation: TNXXMPPFileOperation;
begin
  if (AFileSize < 0) or not Assigned(AHandler) then
    Exit(False);
  lOperation := TNXXMPPFileOperation.Create;
  lOperation.Kind := xfokDiscover;
  lOperation.FileSize := AFileSize;
  lOperation.ServiceHandler := AHandler;
  Result := Submit(lOperation);
end;

function TNXXMPPFileSharingModule.RequestUploadSlot(const AServiceJID,
  AFileName, AMediaType: UTF8String; AFileSize: Int64;
  AHandler: TNXXMPPHTTPUploadSlotEvent): Boolean;
var
  lOperation: TNXXMPPFileOperation;
begin
  if (AServiceJID = '') or (AFileName = '') or (AFileSize < 0) or
    not Assigned(AHandler) then
    Exit(False);
  lOperation := TNXXMPPFileOperation.Create;
  lOperation.Kind := xfokSlot;
  lOperation.ServiceJID := AServiceJID;
  lOperation.FileName := AFileName;
  lOperation.MediaType := AMediaType;
  lOperation.FileSize := AFileSize;
  lOperation.SlotHandler := AHandler;
  Result := Submit(lOperation);
end;

function TNXXMPPFileSharingModule.SendFileShare(const AToJID,
  AMessageType, AReplyJID, AReplyID: UTF8String;
  const AShare: TNXXMPPFileShare): Boolean;
var
  lOperation: TNXXMPPFileOperation;
begin
  if (AToJID = '') or (Length(AShare.Sources) = 0) then
    Exit(False);
  lOperation := TNXXMPPFileOperation.Create;
  lOperation.Kind := xfokSend;
  lOperation.ToJID := AToJID;
  lOperation.MessageType := AMessageType;
  lOperation.ReplyJID := AReplyJID;
  lOperation.ReplyID := AReplyID;
  lOperation.Share := AShare;
  Result := Submit(lOperation);
end;

procedure TNXXMPPFileSharingModule.ProcessCommand(
  AOperation: TNXXMPPModuleOperation);
var
  lDiscovery: TNXXMPPDiscoveryRequest;
  lFile: TNXXMPPFileOperation;
  lHash: Integer;
  lPayload: UTF8String;
  lOriginID: UTF8String;
  lSlot: TNXXMPPSlotRequest;
  lStanzaID: UTF8String;
begin
  if not (AOperation is TNXXMPPFileOperation) then
  begin
    inherited ProcessCommand(AOperation);
    Exit;
  end;
  lFile := TNXXMPPFileOperation(AOperation);
  case lFile.Kind of
    xfokDiscover:
      begin
        lDiscovery := TNXXMPPDiscoveryRequest.Create;
        lDiscovery.FModule := Self;
        lDiscovery.FFileSize := lFile.FileSize;
        lDiscovery.FHandler := lFile.ServiceHandler;
        FRequests.Add(lDiscovery);
        if not SubmitIQ(xitGet, FDomain, FDomain,
          '<query xmlns=''http://jabber.org/protocol/disco#items''/>',
          @lDiscovery.CompleteItems) then
          lDiscovery.Finish(Default(TNXXMPPHTTPUploadService),
            'The upload-service discovery request could not be submitted.');
      end;
    xfokSlot:
      begin
        lSlot := TNXXMPPSlotRequest.Create;
        lSlot.FModule := Self;
        lSlot.FHandler := lFile.SlotHandler;
        FRequests.Add(lSlot);
        lPayload := '<request xmlns=''urn:xmpp:http:upload:0'' filename=''' +
          NXXMPPEscapeAttribute(lFile.FileName) + ''' size=''' +
          UTF8String(IntToStr(lFile.FileSize)) + '''';
        if lFile.MediaType <> '' then
          lPayload := lPayload + ' content-type=''' +
            NXXMPPEscapeAttribute(lFile.MediaType) + '''';
        if not SubmitIQ(xitGet, lFile.ServiceJID, lFile.ServiceJID,
          lPayload + '/>', @lSlot.Complete) then
        begin
          FRequests.Extract(lSlot);
          lSlot.FHandler(Self, Default(TNXXMPPHTTPUploadSlot),
            'The upload-slot request could not be submitted.');
          lSlot.Free;
        end;
      end;
    xfokSend:
      begin
        lStanzaID := NXXMPPCreateID;
        lOriginID := NXXMPPCreateID;
        lPayload := '<message xmlns=''jabber:client'' to=''' +
          NXXMPPEscapeAttribute(lFile.ToJID) + ''' type=''' +
          NXXMPPEscapeAttribute(lFile.MessageType) + ''' id=''' +
          NXXMPPEscapeAttribute(lStanzaID) + '''><body>' +
          NXXMPPEscapeText(lFile.Share.Sources[0].URL) + '</body>' +
          '<origin-id xmlns=''urn:xmpp:sid:0'' id=''' +
          NXXMPPEscapeAttribute(lOriginID) + '''/>';
        if lFile.ReplyID <> '' then
        begin
          lPayload := lPayload + '<reply xmlns=''urn:xmpp:reply:0'' id=''' +
            NXXMPPEscapeAttribute(lFile.ReplyID) + '''';
          if lFile.ReplyJID <> '' then
            lPayload := lPayload + ' to=''' +
              NXXMPPEscapeAttribute(lFile.ReplyJID) + '''';
          lPayload := lPayload + '/>';
        end;
        lPayload := lPayload +
          '<file-sharing xmlns=''urn:xmpp:sfs:0''';
        if lFile.Share.ID <> '' then
          lPayload := lPayload + ' id=''' +
            NXXMPPEscapeAttribute(lFile.Share.ID) + '''';
        if lFile.Share.Disposition <> '' then
          lPayload := lPayload + ' disposition=''' +
            NXXMPPEscapeAttribute(lFile.Share.Disposition) + '''';
        lPayload := lPayload + '><file xmlns=''urn:xmpp:file:metadata:0''>' +
          '<media-type>' + NXXMPPEscapeText(lFile.Share.MediaType) +
          '</media-type><name>' + NXXMPPEscapeText(lFile.Share.Name) +
          '</name><size>' + UTF8String(IntToStr(lFile.Share.DeclaredSize)) +
          '</size>';
        if lFile.Share.Description <> '' then
          lPayload := lPayload + '<desc>' +
            NXXMPPEscapeText(lFile.Share.Description) + '</desc>';
        for lHash := 0 to High(lFile.Share.Hashes) do
          lPayload := lPayload + '<hash xmlns=''urn:xmpp:hashes:2'' algo=''' +
            NXXMPPEscapeAttribute(lFile.Share.Hashes[lHash].Algorithm) + '''>' +
            NXXMPPEscapeText(lFile.Share.Hashes[lHash].Value) + '</hash>';
        lPayload := lPayload + '</file><sources>';
        for lHash := 0 to High(lFile.Share.Sources) do
          lPayload := lPayload + '<url-data ' +
            'xmlns=''http://jabber.org/protocol/url-data'' target=''' +
            NXXMPPEscapeAttribute(lFile.Share.Sources[lHash].URL) + '''/>';
        lPayload := lPayload + '</sources></file-sharing>' +
          '<x xmlns=''jabber:x:oob''><url>' +
          NXXMPPEscapeText(lFile.Share.Sources[0].URL) + '</url></x>' +
          '<fallback xmlns=''urn:xmpp:fallback:0'' ' +
          'for=''urn:xmpp:sfs:0''><body/></fallback></message>';
        Send(lPayload, xrpStreamManaged);
      end;
  end;
end;

procedure TNXXMPPDiscoveryRequest.Finish(
  const AService: TNXXMPPHTTPUploadService; const AError: UTF8String);
var
  lHandler: TNXXMPPHTTPUploadServiceEvent;
  lModule: TNXXMPPFileSharingModule;
begin
  lHandler := FHandler;
  lModule := FModule;
  lModule.FRequests.Extract(Self);
  if Assigned(lHandler) then
    lHandler(lModule, AService, AError);
  Free;
end;

procedure TNXXMPPDiscoveryRequest.CompleteItems(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lIndex: Integer;
  lItems: TNXXMPPDiscoItems;
begin
  lItems := TNXXMPPDiscoModule.ParseItemsResponse(AStanza, AError);
  try
    if lItems.Error <> '' then
    begin
      Finish(Default(TNXXMPPHTTPUploadService), lItems.Error);
      Exit;
    end;
    SetLength(FCandidates, Length(lItems.Items) + 1);
    FCandidates[0] := FModule.FDomain;
    for lIndex := 0 to High(lItems.Items) do
      FCandidates[lIndex + 1] := lItems.Items[lIndex].JID;
    FIndex := 0;
    QueryNext;
  finally
    lItems.Free;
  end;
end;

procedure TNXXMPPDiscoveryRequest.QueryNext;
begin
  if FIndex > High(FCandidates) then
  begin
    Finish(Default(TNXXMPPHTTPUploadService),
      'No HTTP upload service accepts the file size.');
    Exit;
  end;
  if not FModule.SubmitIQ(xitGet, FCandidates[FIndex], FCandidates[FIndex],
    '<query xmlns=''http://jabber.org/protocol/disco#info''/>',
    @CompleteInfo) then
    Finish(Default(TNXXMPPHTTPUploadService),
      'The upload-service info request could not be submitted.');
end;

procedure TNXXMPPDiscoveryRequest.CompleteInfo(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lInfo: TNXXMPPDiscoInfo;
  lService: TNXXMPPHTTPUploadService;
begin
  lInfo := TNXXMPPDiscoModule.ParseInfoResponse(AStanza, AError);
  try
    if (lInfo.Error = '') and
      (lInfo.Features.IndexOf('urn:xmpp:http:upload:0') >= 0) then
    begin
      lService := Default(TNXXMPPHTTPUploadService);
      lService.JID := FCandidates[FIndex];
      if not NXXMPPParseMaximumSize(lInfo, lService.HasMaximumSize,
        lService.MaximumSize) then
      begin
        Finish(Default(TNXXMPPHTTPUploadService),
          'The upload service has a malformed maximum file size.');
        Exit;
      end;
      if (not lService.HasMaximumSize) or
        (FFileSize <= lService.MaximumSize) then
      begin
        Finish(lService, '');
        Exit;
      end;
    end;
  finally
    lInfo.Free;
  end;
  Inc(FIndex);
  QueryNext;
end;

procedure TNXXMPPSlotRequest.Complete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lChild: TDOMElement;
  lHeader: TNXXMPPHTTPHeader;
  lPut: TDOMElement;
  lGet: TDOMElement;
  lSlot: TDOMElement;
  lValue: TNXXMPPHTTPUploadSlot;
  lError: UTF8String;
  lHandler: TNXXMPPHTTPUploadSlotEvent;
  lModule: TNXXMPPFileSharingModule;
begin
  lValue := Default(TNXXMPPHTTPUploadSlot);
  lError := AError;
  if (lError = '') and not Assigned(AStanza) then
    lError := 'The upload slot response is missing.';
  if (lError = '') and Assigned(AStanza) then
  begin
    lSlot := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:http:upload:0', 'slot');
    if Assigned(lSlot) then
    begin
      lPut := NXXMPPFindChild(lSlot, 'urn:xmpp:http:upload:0', 'put');
      lGet := NXXMPPFindChild(lSlot, 'urn:xmpp:http:upload:0', 'get');
      if Assigned(lPut) then
        lValue.PutURL := UTF8Encode(lPut.GetAttribute('url'));
      if Assigned(lGet) then
        lValue.GetURL := UTF8Encode(lGet.GetAttribute('url'));
      if Assigned(lPut) then
      begin
        lChild := NXXMPPFirstChildElement(lPut);
        while Assigned(lChild) do
        begin
          if NXXMPPElementMatches(lChild, 'urn:xmpp:http:upload:0',
            'header') then
          begin
            lHeader.Name := NXXMPPStripNewlines(
              UTF8Encode(lChild.GetAttribute('name')));
            lHeader.Value := NXXMPPStripNewlines(NXXMPPDirectText(lChild));
            if NXXMPPAllowedSlotHeader(lHeader.Name) then
            begin
              SetLength(lValue.Headers, Length(lValue.Headers) + 1);
              lValue.Headers[High(lValue.Headers)] := lHeader;
            end;
          end;
          lChild := NXXMPPNextSiblingElement(lChild);
        end;
      end;
    end;
    if (lValue.PutURL = '') or (lValue.GetURL = '') then
      lError := 'The upload slot is malformed.';
  end;
  lHandler := FHandler;
  lModule := FModule;
  lModule.FRequests.Extract(Self);
  if Assigned(lHandler) then
    lHandler(lModule, lValue, lError);
  Free;
end;

end.

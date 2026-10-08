(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPMAM;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, DOM, obNXXMPPConfig, obNXXMPPDispatcher,
  obNXXMPPForwarding, obNXXMPPMessage, obNXXMPPModule, obNXXMPPStanza,
  tpNXXMPPMessageTypes, tpNXXMPPTypes, utNXXMPPDateTime, utNXXMPPDOM, utNXXMPPIDs,
  utNXXMPPXML;

type
  TNXXMPPMAMModule = class;
  TNXXMPPMAMState = (xmsActive, xmsCompleted, xmsCancelled, xmsFailed,
    xmsLimitExceeded);

  INXXMPPMAMOperation = interface
    ['{8E23C93D-F616-479A-B031-76C4701C3A13}']
    function GetQueryID: UTF8String;
    function GetState: TNXXMPPMAMState;
    function GetError: UTF8String;
    function GetFirst: UTF8String;
    function GetLast: UTF8String;
    function GetArchiveCount: Int64;
    function GetFirstIndex: Int64;
    function GetComplete: Boolean;
    function GetArchiveJID: UTF8String;
    function GetFilter: TNXXMPPMAMFilter;
    function GetMaximumBytes: QWord;
    function GetMaximumResults: Integer;
    function GetPage: TNXXMPPMAMPage;
    function GetResultCount: Integer;
    function GetStable: Boolean;
    function Cancel: Boolean;
    property QueryID: UTF8String read GetQueryID;
    property ArchiveJID: UTF8String read GetArchiveJID;
    property Filter: TNXXMPPMAMFilter read GetFilter;
    property Page: TNXXMPPMAMPage read GetPage;
    property MaximumResults: Integer read GetMaximumResults;
    property MaximumBytes: QWord read GetMaximumBytes;
    property ResultCount: Integer read GetResultCount;
    property State: TNXXMPPMAMState read GetState;
    property Error: UTF8String read GetError;
    property First: UTF8String read GetFirst;
    property Last: UTF8String read GetLast;
    property ArchiveCount: Int64 read GetArchiveCount;
    property FirstIndex: Int64 read GetFirstIndex;
    property Complete: Boolean read GetComplete;
    property Stable: Boolean read GetStable;
  end;

  TNXXMPPMAMResultEvent = procedure(ASender: TObject;
    const AQueryID, AResultID, AArchiveJID: UTF8String;
    const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage) of object;
  TNXXMPPMAMCompleteEvent = procedure(ASender: TObject;
    const AQueryID, AError, AFirst, ALast: UTF8String; ACount: Integer;
    AComplete, AStable: Boolean) of object;
  TNXXMPPMAMDiagnosticEvent = procedure(ASender: TObject;
    const ACondition, AQueryID, ADetail: UTF8String) of object;

  TNXXMPPMAMOperation = class(TInterfacedObject, INXXMPPMAMOperation)
  private
    FModule: TNXXMPPMAMModule;
    FState: TNXXMPPMAMState;
    FError: UTF8String;
    FFirst: UTF8String;
    FLast: UTF8String;
    FArchiveCount: Int64;
    FFirstIndex: Int64;
    FComplete: Boolean;
    FStable: Boolean;
    FFilter: TNXXMPPMAMFilter;
    FPage: TNXXMPPMAMPage;
    function GetArchiveCount: Int64;
    function GetArchiveJID: UTF8String;
    function GetComplete: Boolean;
    function GetError: UTF8String;
    function GetFirst: UTF8String;
    function GetFirstIndex: Int64;
    function GetFilter: TNXXMPPMAMFilter;
    function GetLast: UTF8String;
    function GetMaximumBytes: QWord;
    function GetMaximumResults: Integer;
    function GetPage: TNXXMPPMAMPage;
    function GetQueryID: UTF8String;
    function GetState: TNXXMPPMAMState;
    function GetStable: Boolean;
    function GetResultCount: Integer;
    procedure FinalComplete(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
  public
    ArchiveJID: UTF8String;
    ByteCount: QWord;
    Cancelled: Boolean;
    MaxBytes: QWord;
    MaxResults: Integer;
    QueryID: UTF8String;
    ResultIDs: TStringList;
    ResultCount: Integer;
    constructor Create(AModule: TNXXMPPMAMModule);
    destructor Destroy; override;
    function Cancel: Boolean;
  end;

  TNXXMPPMAMModule = class(TNXXMPPModule)
  private
    FOperations: TObjectList;
    FCancelledOperations: TObjectList;
    FOnComplete: TNXXMPPMAMCompleteEvent;
    FOnResult: TNXXMPPMAMResultEvent;
    FOnDiagnostic: TNXXMPPMAMDiagnosticEvent;
    FConcurrentCapacity: Integer;
    FMaximumBytes: QWord;
    FMaximumPageSize: Integer;
    FMaximumResults: Integer;
    FMaximumForwardingDepth: Integer;
    function FindOperation(const AQueryID: UTF8String): TNXXMPPMAMOperation;
    function IsCancelledOperation(const AQueryID: UTF8String): Boolean;
    procedure Diagnostic(const ACondition, AQueryID,
      ADetail: UTF8String);
    procedure FinalComplete(AOperation: TNXXMPPMAMOperation;
      AStanza: TNXXMPPStanza; const AError: UTF8String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    function Cancel(const AQueryID: UTF8String): Boolean;
    function Query(const AArchiveJID: UTF8String;
      const AFilter: TNXXMPPMAMFilter; const APage: TNXXMPPMAMPage;
      AMaxResults: Integer; AMaxBytes: QWord;
      out AOperation: INXXMPPMAMOperation): Boolean;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    property OnComplete: TNXXMPPMAMCompleteEvent read FOnComplete
      write FOnComplete;
    property OnResult: TNXXMPPMAMResultEvent read FOnResult write FOnResult;
    property OnDiagnostic: TNXXMPPMAMDiagnosticEvent read FOnDiagnostic
      write FOnDiagnostic;
  end;

implementation

procedure TNXXMPPMAMModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add('urn:xmpp:mam:2');
end;

constructor TNXXMPPMAMOperation.Create(AModule: TNXXMPPMAMModule);
begin
  inherited Create;
  FModule := AModule;
  FState := xmsActive;
  FArchiveCount := -1;
  FFirstIndex := -1;
  ResultIDs := TStringList.Create;
  ResultIDs.CaseSensitive := True;
  ResultIDs.Sorted := True;
  ResultIDs.Duplicates := dupIgnore;
end;

function TNXXMPPMAMOperation.GetError: UTF8String;
begin Result := FError; end;
function TNXXMPPMAMOperation.GetArchiveJID: UTF8String;
begin Result := ArchiveJID; end;
function TNXXMPPMAMOperation.GetFilter: TNXXMPPMAMFilter;
begin Result := FFilter; end;
function TNXXMPPMAMOperation.GetMaximumBytes: QWord;
begin Result := MaxBytes; end;
function TNXXMPPMAMOperation.GetMaximumResults: Integer;
begin Result := MaxResults; end;
function TNXXMPPMAMOperation.GetPage: TNXXMPPMAMPage;
begin Result := FPage; end;
function TNXXMPPMAMOperation.GetResultCount: Integer;
begin Result := ResultCount; end;
function TNXXMPPMAMOperation.GetFirst: UTF8String;
begin Result := FFirst; end;
function TNXXMPPMAMOperation.GetLast: UTF8String;
begin Result := FLast; end;
function TNXXMPPMAMOperation.GetArchiveCount: Int64;
begin Result := FArchiveCount; end;
function TNXXMPPMAMOperation.GetFirstIndex: Int64;
begin Result := FFirstIndex; end;
function TNXXMPPMAMOperation.GetComplete: Boolean;
begin Result := FComplete; end;
function TNXXMPPMAMOperation.GetStable: Boolean;
begin Result := FStable; end;

function TNXXMPPMAMOperation.GetQueryID: UTF8String;
begin
  Result := QueryID;
end;

function TNXXMPPMAMOperation.GetState: TNXXMPPMAMState;
begin
  Result := FState;
end;

function TNXXMPPMAMOperation.Cancel: Boolean;
begin
  Result := Assigned(FModule) and FModule.Cancel(QueryID);
end;

destructor TNXXMPPMAMOperation.Destroy;
begin
  ResultIDs.Free;
  inherited Destroy;
end;

procedure TNXXMPPMAMOperation.FinalComplete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  FModule.FinalComplete(Self, AStanza, AError);
end;

constructor TNXXMPPMAMModule.Create;
begin
  inherited Create;
  FOperations := TObjectList.Create(False);
  FCancelledOperations := TObjectList.Create(False);
  FConcurrentCapacity := 8;
  FMaximumBytes := 4 * 1024 * 1024;
  FMaximumPageSize := 100;
  FMaximumResults := 1000;
  FMaximumForwardingDepth := 1;
end;

procedure TNXXMPPMAMModule.Configure(AConfig: TNXXMPPClientConfig);
begin
  FConcurrentCapacity := AConfig.MAMConcurrentCapacity;
  FMaximumBytes := AConfig.MAMMaximumBytes;
  FMaximumPageSize := AConfig.MAMMaximumPageSize;
  FMaximumResults := AConfig.MAMMaximumResults;
  FMaximumForwardingDepth := AConfig.ForwardingMaximumDepth;
end;

destructor TNXXMPPMAMModule.Destroy;
var
  lOperation: TNXXMPPMAMOperation;
begin
  while FOperations.Count > 0 do
  begin
    lOperation := TNXXMPPMAMOperation(FOperations.Extract(FOperations[0]));
    lOperation.FModule := nil;
    lOperation._Release;
  end;
  while FCancelledOperations.Count > 0 do
  begin
    lOperation := TNXXMPPMAMOperation(
      FCancelledOperations.Extract(FCancelledOperations[0]));
    lOperation.FModule := nil;
    lOperation._Release;
  end;
  FCancelledOperations.Free;
  FOperations.Free;
  inherited Destroy;
end;

procedure TNXXMPPMAMModule.RegisterHandlers(ADispatcher: TNXXMPPDispatcher);
begin
end;

function TNXXMPPMAMModule.FindOperation(
  const AQueryID: UTF8String): TNXXMPPMAMOperation;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to FOperations.Count - 1 do
    if TNXXMPPMAMOperation(FOperations[lIndex]).QueryID = AQueryID then
      Exit(TNXXMPPMAMOperation(FOperations[lIndex]));
end;

function TNXXMPPMAMModule.IsCancelledOperation(
  const AQueryID: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  Result := False;
  for lIndex := 0 to FCancelledOperations.Count - 1 do
    if TNXXMPPMAMOperation(FCancelledOperations[lIndex]).QueryID =
      AQueryID then
      Exit(True);
end;

procedure TNXXMPPMAMModule.Diagnostic(const ACondition, AQueryID,
  ADetail: UTF8String);
begin
  if Assigned(FOnDiagnostic) then
    FOnDiagnostic(Self, ACondition, AQueryID, ADetail);
end;

function TNXXMPPMAMModule.Query(const AArchiveJID: UTF8String;
  const AFilter: TNXXMPPMAMFilter; const APage: TNXXMPPMAMPage;
  AMaxResults: Integer; AMaxBytes: QWord;
  out AOperation: INXXMPPMAMOperation): Boolean;
var
  lOperation: TNXXMPPMAMOperation;
  lPayload: UTF8String;
  lIndex: Integer;
  lTimestamp: TDateTime;
begin
  AOperation := nil;
  if (APage.Maximum < 1) or (APage.Maximum > FMaximumPageSize) or
    (AMaxResults < 1) or (AMaxResults > FMaximumResults) or
    (AMaxBytes < 1) or (AMaxBytes > FMaximumBytes) then
    Exit(False);
  if ((AFilter.StartTimestamp <> '') and not NXXMPPTryParseTimestamp(
    AFilter.StartTimestamp, lTimestamp)) or
    ((AFilter.EndTimestamp <> '') and not NXXMPPTryParseTimestamp(
    AFilter.EndTimestamp, lTimestamp)) then
    Exit(False);
  if FOperations.Count >= FConcurrentCapacity then
    Exit(False);
  lOperation := TNXXMPPMAMOperation.Create(Self);
  lOperation.QueryID := NXXMPPCreateID;
  lPayload := '<query xmlns=''urn:xmpp:mam:2'' queryid=''' +
    NXXMPPEscapeAttribute(lOperation.QueryID) + '''>';
  lPayload := lPayload + '<x xmlns=''jabber:x:data'' type=''submit''>' +
    '<field var=''FORM_TYPE'' type=''hidden''><value>urn:xmpp:mam:2' +
    '</value></field>';
  if AFilter.WithJID <> '' then
    lPayload := lPayload + '<field var=''with''><value>' +
      NXXMPPEscapeText(AFilter.WithJID) + '</value></field>';
  if AFilter.StartTimestamp <> '' then
    lPayload := lPayload + '<field var=''start''><value>' +
      NXXMPPEscapeText(AFilter.StartTimestamp) + '</value></field>';
  if AFilter.EndTimestamp <> '' then
    lPayload := lPayload + '<field var=''end''><value>' +
      NXXMPPEscapeText(AFilter.EndTimestamp) + '</value></field>';
  if AFilter.BeforeID <> '' then
    lPayload := lPayload + '<field var=''before-id''><value>' +
      NXXMPPEscapeText(AFilter.BeforeID) + '</value></field>';
  if AFilter.AfterID <> '' then
    lPayload := lPayload + '<field var=''after-id''><value>' +
      NXXMPPEscapeText(AFilter.AfterID) + '</value></field>';
  if Length(AFilter.IDs) > 0 then
  begin
    lPayload := lPayload + '<field var=''ids''>';
    for lIndex := 0 to High(AFilter.IDs) do
      lPayload := lPayload + '<value>' +
        NXXMPPEscapeText(AFilter.IDs[lIndex]) + '</value>';
    lPayload := lPayload + '</field>';
  end;
  if AFilter.IncludeGroupchatSpecified then
    if AFilter.IncludeGroupchat then
      lPayload := lPayload + '<field var=''include-groupchat''><value>true' +
        '</value></field>'
    else
      lPayload := lPayload + '<field var=''include-groupchat''><value>false' +
        '</value></field>';
  lPayload := lPayload + '</x>';
  lPayload := lPayload + '<set xmlns=''http://jabber.org/protocol/rsm''>' +
    '<max>' + UTF8String(IntToStr(APage.Maximum)) + '</max>';
  case APage.Direction of
    xmpBackward: lPayload := lPayload + '<before>' +
      NXXMPPEscapeText(APage.Anchor) + '</before>';
    xmpLastPage: lPayload := lPayload + '<before/>';
    xmpForward: if APage.Anchor <> '' then
      lPayload := lPayload + '<after>' + NXXMPPEscapeText(APage.Anchor) +
        '</after>';
  end;
  lPayload := lPayload + '</set></query>';
  lOperation.ArchiveJID := AArchiveJID;
  lOperation.FFilter := AFilter;
  lOperation.FPage := APage;
  lOperation.MaxResults := AMaxResults;
  lOperation.MaxBytes := AMaxBytes;
  lOperation._AddRef;
  FOperations.Add(lOperation);
  Result := SubmitIQ(xitSet, AArchiveJID, AArchiveJID, lPayload,
    @lOperation.FinalComplete);
  if not Result then
  begin
    FOperations.Extract(lOperation);
    lOperation._Release;
    AOperation := nil;
  end;
  if Result then
    AOperation := lOperation as INXXMPPMAMOperation;
end;

function TNXXMPPMAMModule.Cancel(const AQueryID: UTF8String): Boolean;
var
  lOperation: TNXXMPPMAMOperation;
begin
  lOperation := FindOperation(AQueryID);
  Result := Assigned(lOperation);
  if Result then
  begin
    lOperation.Cancelled := True;
    lOperation.FState := xmsCancelled;
    lOperation.FError := 'cancelled';
    FOperations.Extract(lOperation);
    FCancelledOperations.Add(lOperation);
    if Assigned(FOnComplete) then
      FOnComplete(Self, AQueryID, 'cancelled', '', '',
        lOperation.ResultCount, False, False);
  end;
end;

procedure TNXXMPPMAMModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lForwarded: TNXXMPPForwarded;
  lForwardedElement: TDOMElement;
  lOperation: TNXXMPPMAMOperation;
  lQueryID: UTF8String;
  lResult: TDOMElement;
  lResultID: UTF8String;
begin
  if not Assigned(AStanza) or (AStanza.Kind <> xskMessage) then
    Exit;
  lResult := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:mam:2', 'result');
  if not Assigned(lResult) then
    Exit;
  lQueryID := UTF8Encode(lResult.GetAttribute('queryid'));
  lResultID := UTF8Encode(lResult.GetAttribute('id'));
  if lQueryID = '' then
  begin
    Diagnostic('mam-missing-query-id', '',
      'A MAM result did not identify its query.');
    Exit;
  end;
  lOperation := FindOperation(lQueryID);
  if not Assigned(lOperation) then
  begin
    if IsCancelledOperation(lQueryID) then
      Diagnostic('mam-late-result', lQueryID,
        'A MAM result arrived after local termination.')
    else
      Diagnostic('mam-unknown-query', lQueryID,
        'A MAM result does not match an active query.');
    Exit;
  end;
  if (lOperation.ArchiveJID <> '') and
    (AStanza.FromJID <> lOperation.ArchiveJID) then
  begin
    Diagnostic('mam-archive-authority', lQueryID,
      'A MAM result came from the wrong archive entity.');
    Exit;
  end;
  if lResultID = '' then
  begin
    Diagnostic('mam-missing-result-id', lQueryID,
      'A MAM result did not provide an archive result id.');
    Exit;
  end;
  if lOperation.ResultIDs.IndexOf(lResultID) >= 0 then
  begin
    Diagnostic('mam-duplicate-result', lQueryID,
      'A duplicate MAM result id was ignored.');
    Exit;
  end;
  if (lOperation.ResultCount >= lOperation.MaxResults) or
    (lOperation.ByteCount + Length(AStanza.RawXML) > lOperation.MaxBytes) then
  begin
    lOperation.Cancelled := True;
    lOperation.FState := xmsLimitExceeded;
    lOperation.FError := 'mam-limit-exceeded';
    FOperations.Extract(lOperation);
    FCancelledOperations.Add(lOperation);
    if Assigned(FOnComplete) then
      FOnComplete(Self, lQueryID, 'mam-limit-exceeded', '', '',
        lOperation.ResultCount, False, False);
    Diagnostic('mam-limit-exceeded', lQueryID,
      'The MAM result limit was reached.');
    Exit;
  end;
  lForwardedElement := NXXMPPFindChild(lResult, 'urn:xmpp:forward:0',
    'forwarded');
  lForwarded := TNXXMPPForwarding.Decode(lForwardedElement, xmdcMAM,
    FMaximumForwardingDepth);
  try
    if not lForwarded.Valid then
    begin
      Diagnostic('mam-forward-invalid', lQueryID,
        lForwarded.ValidationError);
      Exit;
    end;
    Inc(lOperation.ResultCount);
    Inc(lOperation.ByteCount, Length(AStanza.RawXML));
    lOperation.ResultIDs.Add(lResultID);
    if Assigned(FOnResult) then
      FOnResult(Self, lQueryID, lResultID, lOperation.ArchiveJID,
        lForwarded.Delay, lForwarded.Message);
  finally
    lForwarded.Free;
  end;
end;

procedure TNXXMPPMAMModule.FinalComplete(AOperation: TNXXMPPMAMOperation;
  AStanza: TNXXMPPStanza; const AError: UTF8String);
var
  lComplete: Boolean;
  lCount: Integer;
  lFin: TDOMElement;
  lFirst: UTF8String;
  lLast: UTF8String;
  lQueryID: UTF8String;
  lSet: TDOMElement;
  lStable: Boolean;
  lCountElement: TDOMElement;
  lFirstElement: TDOMElement;
  lNumberText: UTF8String;
begin
  lQueryID := '';
  lFin := nil;
  if Assigned(AStanza) then
    lFin := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:mam:2', 'fin');
  if Assigned(lFin) then
    lQueryID := UTF8Encode(lFin.GetAttribute('queryid'));
  if not Assigned(AOperation) or ((FOperations.IndexOf(AOperation) < 0) and
    (FCancelledOperations.IndexOf(AOperation) < 0)) then
    Exit;
  if (lQueryID <> '') and (lQueryID <> AOperation.QueryID) then
  begin
    lFin := nil;
    if not AOperation.Cancelled then
      AOperation.FError := 'mam-query-id-mismatch';
  end;
  lQueryID := AOperation.QueryID;
  if not Assigned(lFin) and (AError = '') and not AOperation.Cancelled and
    (AOperation.FError = '') then
    AOperation.FError := 'mam-missing-final';
  lCount := AOperation.ResultCount;
  lComplete := Assigned(lFin) and
    ((UTF8Encode(lFin.GetAttribute('complete')) = 'true') or
    (UTF8Encode(lFin.GetAttribute('complete')) = '1'));
  lStable := Assigned(lFin) and
    ((UTF8Encode(lFin.GetAttribute('stable')) = 'true') or
    (UTF8Encode(lFin.GetAttribute('stable')) = '1'));
  lSet := NXXMPPFindChild(lFin, 'http://jabber.org/protocol/rsm', 'set');
  if Assigned(lSet) then
  begin
    lFirstElement := NXXMPPFindChild(lSet,
      'http://jabber.org/protocol/rsm', 'first');
    lFirst := NXXMPPDirectText(lFirstElement);
    lLast := NXXMPPDirectText(NXXMPPFindChild(lSet,
      'http://jabber.org/protocol/rsm', 'last'));
    if Assigned(lFirstElement) then
    begin
      lNumberText := UTF8Encode(lFirstElement.GetAttribute('index'));
      if (lNumberText <> '') and not TryStrToInt64(string(lNumberText),
        AOperation.FFirstIndex) then
        AOperation.FError := 'mam-invalid-rsm';
    end;
    lCountElement := NXXMPPFindChild(lSet,
      'http://jabber.org/protocol/rsm', 'count');
    if Assigned(lCountElement) then
    begin
      lNumberText := NXXMPPDirectText(lCountElement);
      if not TryStrToInt64(string(lNumberText), AOperation.FArchiveCount) then
        AOperation.FError := 'mam-invalid-rsm';
    end;
  end;
  if FOperations.IndexOf(AOperation) >= 0 then
    FOperations.Extract(AOperation)
  else
    FCancelledOperations.Extract(AOperation);
  if not AOperation.Cancelled then
    if (AError = '') and Assigned(lFin) and (AOperation.FError = '') then
      AOperation.FState := xmsCompleted
    else
      AOperation.FState := xmsFailed;
  if AOperation.FError = '' then
    AOperation.FError := AError;
  AOperation.FFirst := lFirst;
  AOperation.FLast := lLast;
  AOperation.FComplete := lComplete;
  AOperation.FStable := lStable;
  if Assigned(FOnComplete) and not AOperation.Cancelled then
    FOnComplete(Self, lQueryID, AOperation.FError, lFirst, lLast, lCount,
      lComplete, lStable);
  AOperation.FModule := nil;
  AOperation._Release;
end;

end.

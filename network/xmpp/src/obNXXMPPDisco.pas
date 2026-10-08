(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPDisco;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, DOM, SyncObjs, obNXXMPPConfig, obNXXMPPDispatcher, obNXXMPPModule,
  obNXXMPPOpenSSL, obNXXMPPStanza, synacode, tpNXXMPPTypes,
  utNXXMPPDOM, utNXXMPPXML;

type
  TNXXMPPDiscoModule = class;
  TNXXMPPDataFormField = class
  private
    FName: UTF8String;
    FValues: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: UTF8String read FName;
    property Values: TStringList read FValues;
  end;

  TNXXMPPDataForm = class
  private
    FFields: TObjectList;
    FFormType: UTF8String;
  public
    constructor Create;
    destructor Destroy; override;
    function Canonical: UTF8String;
    function Field(const AName: UTF8String): TNXXMPPDataFormField;
    property Fields: TObjectList read FFields;
    property FormType: UTF8String read FFormType;
  end;

  TNXXMPPDiscoIdentity = record
    Category: UTF8String;
    IdentityType: UTF8String;
    Language: UTF8String;
    Name: UTF8String;
  end;
  TNXXMPPDiscoIdentityArray = array of TNXXMPPDiscoIdentity;

  TNXXMPPDiscoInfo = class
  private
    FError: UTF8String;
    FDataForms: TObjectList;
    FFeatures: TStringList;
    FForms: TStringList;
    FFromJID: UTF8String;
    FIdentities: TNXXMPPDiscoIdentityArray;
    FNode: UTF8String;
  public
    constructor Create;
    destructor Destroy; override;
    property Error: UTF8String read FError;
    property DataForms: TObjectList read FDataForms;
    property Features: TStringList read FFeatures;
    property Forms: TStringList read FForms;
    property FromJID: UTF8String read FFromJID;
    property Identities: TNXXMPPDiscoIdentityArray read FIdentities;
    property Node: UTF8String read FNode;
    function DataForm(const AFormType: UTF8String): TNXXMPPDataForm;
  end;

  TNXXMPPDiscoItem = record
    JID: UTF8String;
    Name: UTF8String;
    Node: UTF8String;
  end;
  TNXXMPPDiscoItemArray = array of TNXXMPPDiscoItem;

  TNXXMPPDiscoItems = class
  private
    FError: UTF8String;
    FFromJID: UTF8String;
    FItems: TNXXMPPDiscoItemArray;
    FNode: UTF8String;
  public
    property Error: UTF8String read FError;
    property FromJID: UTF8String read FFromJID;
    property Items: TNXXMPPDiscoItemArray read FItems;
    property Node: UTF8String read FNode;
  end;

  TNXXMPPDiscoInfoEvent = procedure(ASender: TObject;
    AInfo: TNXXMPPDiscoInfo) of object;
  TNXXMPPDiscoItemsEvent = procedure(ASender: TObject;
    AItems: TNXXMPPDiscoItems) of object;

  TNXXMPPCapabilityEntry = class
  public
    EntityJID: UTF8String;
    ExpiresAt: QWord;
    Features: TStringList;
    Node: UTF8String;
    Verification: UTF8String;
    constructor Create;
    destructor Destroy; override;
  end;

  TNXXMPPCapabilityCache = class
  private
    FCriticalSection: TCriticalSection;
    FEntries: TObjectList;
    FMaximum: Integer;
    FTTLMS: Cardinal;
    procedure EvictExpired;
  public
    constructor Create(AMaximum: Integer = 128;
      ATTLMS: Cardinal = 3600000);
    destructor Destroy; override;
    procedure Clear;
    procedure Configure(AMaximum: Integer; ATTLMS: Cardinal);
    function StoreVerified(const AEntityJID, ANode,
      AVerification: UTF8String; AInfo: TNXXMPPDiscoInfo): Boolean;
    function Supports(const AEntityJID, ANode,
      AFeature: UTF8String): Boolean;
    function Contains(const AEntityJID, ANode: UTF8String): Boolean;
    property Capacity: Integer read FMaximum;
  end;

  TNXXMPPCapsRequest = class
  private
    FEntityJID: UTF8String;
    FModule: TNXXMPPDiscoModule;
    FNode: UTF8String;
    FVerification: UTF8String;
    procedure Complete(AStanza: TNXXMPPStanza; const AError: UTF8String);
  end;

  TNXXMPPDiscoModule = class(TNXXMPPModule)
  private
    FCategory: UTF8String;
    FCapabilities: TNXXMPPCapabilityCache;
    FFeatures: TStringList;
    FIdentityName: UTF8String;
    FIdentityType: UTF8String;
    FOnInfo: TNXXMPPDiscoInfoEvent;
    FOnItems: TNXXMPPDiscoItemsEvent;
    FCapsRequests: TObjectList;
    procedure CompleteInfo(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure CompleteItems(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure HandleInfo(AStanza: TNXXMPPStanza);
    procedure CompleteCaps(ARequest: TNXXMPPCapsRequest;
      AStanza: TNXXMPPStanza; const AError: UTF8String);
  public
    constructor Create(const ACategory, AType, AName: UTF8String);
    destructor Destroy; override;
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    procedure AddFeature(const AFeature: UTF8String);
    procedure Lifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    function QueryInfo(const AJID, ANode: UTF8String): Boolean;
    function QueryItems(const AJID, ANode: UTF8String): Boolean;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    class function CapabilityHash(AInfo: TNXXMPPDiscoInfo): UTF8String;
      static;
    class function ParseInfoResponse(AStanza: TNXXMPPStanza;
      const AError: UTF8String): TNXXMPPDiscoInfo; static;
    class function ParseItemsResponse(AStanza: TNXXMPPStanza;
      const AError: UTF8String): TNXXMPPDiscoItems; static;
    property OnInfo: TNXXMPPDiscoInfoEvent read FOnInfo write FOnInfo;
    property OnItems: TNXXMPPDiscoItemsEvent read FOnItems write FOnItems;
    property Capabilities: TNXXMPPCapabilityCache read FCapabilities;
  end;

implementation

constructor TNXXMPPDataFormField.Create;
begin
  inherited Create;
  FValues := TStringList.Create;
  FValues.CaseSensitive := True;
end;

destructor TNXXMPPDataFormField.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

constructor TNXXMPPDataForm.Create;
begin
  inherited Create;
  FFields := TObjectList.Create(True);
end;

destructor TNXXMPPDataForm.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TNXXMPPDataForm.Field(
  const AName: UTF8String): TNXXMPPDataFormField;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FFields.Count - 1 do
    if TNXXMPPDataFormField(FFields[lIndex]).Name = AName then
      Exit(TNXXMPPDataFormField(FFields[lIndex]));
  Result := nil;
end;

function TNXXMPPDataForm.Canonical: UTF8String;
var
  lField: TNXXMPPDataFormField;
  lFieldCanonical: UTF8String;
  lFields: TStringList;
  lIndex: Integer;
  lValue: Integer;
  lValues: TStringList;
begin
  Result := FFormType + '<';
  lFields := TStringList.Create;
  try
    lFields.CaseSensitive := True;
    lFields.Sorted := True;
    lFields.Duplicates := dupAccept;
    for lIndex := 0 to FFields.Count - 1 do
    begin
      lField := TNXXMPPDataFormField(FFields[lIndex]);
      if lField.Name = 'FORM_TYPE' then
        Continue;
      lValues := TStringList.Create;
      try
        lValues.Assign(lField.Values);
        lValues.CaseSensitive := True;
        lValues.Sorted := True;
        lFieldCanonical := lField.Name + '<';
        for lValue := 0 to lValues.Count - 1 do
          lFieldCanonical := lFieldCanonical + UTF8String(lValues[lValue]) +
            '<';
        lFields.Add(string(lFieldCanonical));
      finally
        lValues.Free;
      end;
    end;
    for lIndex := 0 to lFields.Count - 1 do
      Result := Result + UTF8String(lFields[lIndex]);
  finally
    lFields.Free;
  end;
end;

procedure TNXXMPPCapsRequest.Complete(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  FModule.CompleteCaps(Self, AStanza, AError);
  Free;
end;

constructor TNXXMPPCapabilityEntry.Create;
begin
  inherited Create;
  Features := TStringList.Create;
  Features.CaseSensitive := True;
  Features.Sorted := True;
  Features.Duplicates := dupIgnore;
end;

destructor TNXXMPPCapabilityEntry.Destroy;
begin
  Features.Free;
  inherited Destroy;
end;

constructor TNXXMPPCapabilityCache.Create(AMaximum: Integer;
  ATTLMS: Cardinal);
begin
  inherited Create;
  if AMaximum < 1 then
    raise EArgumentOutOfRangeException.Create('Capability capacity must be positive.');
  FMaximum := AMaximum;
  FTTLMS := ATTLMS;
  FCriticalSection := TCriticalSection.Create;
  FEntries := TObjectList.Create(True);
end;

destructor TNXXMPPCapabilityCache.Destroy;
begin
  FEntries.Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TNXXMPPCapabilityCache.Clear;
begin
  FCriticalSection.Acquire;
  try
    FEntries.Clear;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPCapabilityCache.Configure(AMaximum: Integer;
  ATTLMS: Cardinal);
begin
  if (AMaximum < 1) or (ATTLMS < 1) then
    raise EArgumentOutOfRangeException.Create(
      'Capability cache limits must be positive.');
  FCriticalSection.Acquire;
  try
    FMaximum := AMaximum;
    FTTLMS := ATTLMS;
    FEntries.Clear;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TNXXMPPCapabilityCache.EvictExpired;
var
  lIndex: Integer;
  lNow: QWord;
begin
  lNow := GetTickCount64;
  for lIndex := FEntries.Count - 1 downto 0 do
    if TNXXMPPCapabilityEntry(FEntries[lIndex]).ExpiresAt <= lNow then
      FEntries.Delete(lIndex);
end;

function TNXXMPPCapabilityCache.StoreVerified(const AEntityJID, ANode,
  AVerification: UTF8String; AInfo: TNXXMPPDiscoInfo): Boolean;
var
  lEntry: TNXXMPPCapabilityEntry;
  lIndex: Integer;
begin
  Result := (AEntityJID <> '') and (ANode <> '') and
    (AVerification <> '') and
    (TNXXMPPDiscoModule.CapabilityHash(AInfo) = AVerification);
  if not Result then
    Exit;
  lEntry := TNXXMPPCapabilityEntry.Create;
  lEntry.EntityJID := AEntityJID;
  lEntry.Node := ANode;
  lEntry.Verification := AVerification;
  lEntry.ExpiresAt := GetTickCount64 + FTTLMS;
  lEntry.Features.Assign(AInfo.Features);
  FCriticalSection.Acquire;
  try
    EvictExpired;
    for lIndex := FEntries.Count - 1 downto 0 do
      if (TNXXMPPCapabilityEntry(FEntries[lIndex]).EntityJID = AEntityJID) and
        (TNXXMPPCapabilityEntry(FEntries[lIndex]).Node = ANode) then
        FEntries.Delete(lIndex);
    while FEntries.Count >= FMaximum do
      FEntries.Delete(0);
    FEntries.Add(lEntry);
    lEntry := nil;
  finally
    FCriticalSection.Release;
    lEntry.Free;
  end;
end;

function TNXXMPPCapabilityCache.Supports(const AEntityJID, ANode,
  AFeature: UTF8String): Boolean;
var
  lEntry: TNXXMPPCapabilityEntry;
  lIndex: Integer;
begin
  Result := False;
  FCriticalSection.Acquire;
  try
    EvictExpired;
    for lIndex := 0 to FEntries.Count - 1 do
    begin
      lEntry := TNXXMPPCapabilityEntry(FEntries[lIndex]);
      if (lEntry.EntityJID = AEntityJID) and (lEntry.Node = ANode) then
        Exit(lEntry.Features.IndexOf(string(AFeature)) >= 0);
    end;
  finally
    FCriticalSection.Release;
  end;
end;

function TNXXMPPCapabilityCache.Contains(const AEntityJID,
  ANode: UTF8String): Boolean;
var
  lIndex: Integer;
begin
  Result := False;
  FCriticalSection.Acquire;
  try
    EvictExpired;
    for lIndex := 0 to FEntries.Count - 1 do
      if (TNXXMPPCapabilityEntry(FEntries[lIndex]).EntityJID = AEntityJID) and
        (TNXXMPPCapabilityEntry(FEntries[lIndex]).Node = ANode) then
        Exit(True);
  finally
    FCriticalSection.Release;
  end;
end;

constructor TNXXMPPDiscoInfo.Create;
begin
  inherited Create;
  FDataForms := TObjectList.Create(True);
  FFeatures := TStringList.Create;
  FFeatures.CaseSensitive := True;
  FFeatures.Sorted := True;
  FFeatures.Duplicates := dupIgnore;
  FForms := TStringList.Create;
  FForms.CaseSensitive := True;
  FForms.Sorted := True;
  FForms.Duplicates := dupIgnore;
end;

destructor TNXXMPPDiscoInfo.Destroy;
begin
  FDataForms.Free;
  FForms.Free;
  FFeatures.Free;
  inherited Destroy;
end;

function TNXXMPPDiscoInfo.DataForm(
  const AFormType: UTF8String): TNXXMPPDataForm;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FDataForms.Count - 1 do
    if TNXXMPPDataForm(FDataForms[lIndex]).FormType = AFormType then
      Exit(TNXXMPPDataForm(FDataForms[lIndex]));
  Result := nil;
end;

function NXXMPPParseDataForm(AElement: TDOMElement;
  out AForm: TNXXMPPDataForm): Boolean;
var
  lFieldElement: TDOMElement;
  lField: TNXXMPPDataFormField;
  lValue: TDOMElement;
begin
  Result := False;
  AForm := TNXXMPPDataForm.Create;
  try
    lFieldElement := NXXMPPFirstChildElement(AElement);
    while Assigned(lFieldElement) do
    begin
      if NXXMPPElementMatches(lFieldElement, 'jabber:x:data', 'field') then
      begin
        lField := TNXXMPPDataFormField.Create;
        lField.FName := UTF8Encode(lFieldElement.GetAttribute('var'));
        if (lField.Name = '') or Assigned(AForm.Field(lField.Name)) then
        begin
          lField.Free;
          Exit;
        end;
        lValue := NXXMPPFirstChildElement(lFieldElement);
        while Assigned(lValue) do
        begin
          if NXXMPPElementMatches(lValue, 'jabber:x:data', 'value') then
            lField.Values.Add(string(NXXMPPDirectText(lValue)));
          lValue := NXXMPPNextSiblingElement(lValue);
        end;
        if lField.Name = 'FORM_TYPE' then
        begin
          if (AForm.FFormType <> '') or (lField.Values.Count <> 1) then
          begin
            lField.Free;
            Exit;
          end;
          AForm.FFormType := UTF8String(lField.Values[0]);
        end;
        AForm.Fields.Add(lField);
      end;
      lFieldElement := NXXMPPNextSiblingElement(lFieldElement);
    end;
    if AForm.FormType = '' then
      Exit;
    Result := True;
  finally
    if not Result then
      FreeAndNil(AForm);
  end;
end;

constructor TNXXMPPDiscoModule.Create(const ACategory, AType,
  AName: UTF8String);
begin
  inherited Create;
  FCategory := ACategory;
  FIdentityType := AType;
  FIdentityName := AName;
  FCapabilities := TNXXMPPCapabilityCache.Create;
  FCapsRequests := TObjectList.Create(True);
  FFeatures := TStringList.Create;
  FFeatures.CaseSensitive := True;
  FFeatures.Sorted := True;
  FFeatures.Duplicates := dupIgnore;
end;

destructor TNXXMPPDiscoModule.Destroy;
begin
  FCapsRequests.Free;
  FCapabilities.Free;
  FFeatures.Free;
  inherited Destroy;
end;

procedure TNXXMPPDiscoModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add('http://jabber.org/protocol/disco#info');
  AFeatures.Add('http://jabber.org/protocol/disco#items');
  AFeatures.Add('http://jabber.org/protocol/caps');
end;

procedure TNXXMPPDiscoModule.Configure(AConfig: TNXXMPPClientConfig);
begin
  FCapabilities.Configure(AConfig.CapabilityCacheCapacity,
    AConfig.CapabilityCacheTTLMS);
end;

procedure TNXXMPPDiscoModule.Lifecycle(ALifecycle: TNXXMPPModuleLifecycle);
begin
  if ALifecycle in [xmlNewSession, xmlPermanentLoss, xmlFinalDisconnect] then
    FCapabilities.Clear;
end;

procedure TNXXMPPDiscoModule.AddFeature(const AFeature: UTF8String);
begin
  if AFeature <> '' then
    FFeatures.Add(string(AFeature));
end;

function TNXXMPPDiscoModule.QueryInfo(const AJID, ANode: UTF8String): Boolean;
var
  lPayload: UTF8String;
begin
  if AJID = '' then
    Exit(False);
  lPayload := '<query xmlns=''http://jabber.org/protocol/disco#info''';
  if ANode <> '' then
    lPayload := lPayload + ' node=''' + NXXMPPEscapeAttribute(ANode) + '''';
  Result := SubmitIQ(xitGet, AJID, AJID, lPayload + '/>', @CompleteInfo);
end;

function TNXXMPPDiscoModule.QueryItems(const AJID, ANode: UTF8String): Boolean;
var
  lPayload: UTF8String;
begin
  if AJID = '' then
    Exit(False);
  lPayload := '<query xmlns=''http://jabber.org/protocol/disco#items''';
  if ANode <> '' then
    lPayload := lPayload + ' node=''' + NXXMPPEscapeAttribute(ANode) + '''';
  Result := SubmitIQ(xitGet, AJID, AJID, lPayload + '/>', @CompleteItems);
end;

procedure TNXXMPPDiscoModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lCaps: TDOMElement;
  lHash: UTF8String;
  lIndex: Integer;
  lKey: UTF8String;
  lNode: UTF8String;
  lRequest: TNXXMPPCapsRequest;
  lVerification: UTF8String;
begin
  if not Assigned(AStanza) or (AStanza.Kind <> xskPresence) or
    (AStanza.FromJID = '') then
    Exit;
  lCaps := NXXMPPFindChild(AStanza.Root,
    'http://jabber.org/protocol/caps', 'c');
  if not Assigned(lCaps) then
    Exit;
  lHash := UTF8Encode(lCaps.GetAttribute('hash'));
  lNode := UTF8Encode(lCaps.GetAttribute('node'));
  lVerification := UTF8Encode(lCaps.GetAttribute('ver'));
  if (lNode = '') or (lVerification = '') then
    Exit;
  if lHash <> 'sha-1' then
  begin
    QueryInfo(AStanza.FromJID, '');
    Exit;
  end;
  lKey := lNode + '#' + lVerification;
  if FCapabilities.Contains(AStanza.FromJID, lKey) then
    Exit;
  for lIndex := 0 to FCapsRequests.Count - 1 do
    if (TNXXMPPCapsRequest(FCapsRequests[lIndex]).FEntityJID =
      AStanza.FromJID) and
      (TNXXMPPCapsRequest(FCapsRequests[lIndex]).FNode = lKey) then
      Exit;
  if FCapsRequests.Count >= FCapabilities.Capacity then
    Exit;
  lRequest := TNXXMPPCapsRequest.Create;
  lRequest.FModule := Self;
  lRequest.FEntityJID := AStanza.FromJID;
  lRequest.FNode := lKey;
  lRequest.FVerification := lVerification;
  FCapsRequests.Add(lRequest);
  if not SubmitIQ(xitGet, lRequest.FEntityJID, lRequest.FEntityJID,
    '<query xmlns=''http://jabber.org/protocol/disco#info'' node=''' +
    NXXMPPEscapeAttribute(lKey) + '''/>', @lRequest.Complete) then
  begin
    FCapsRequests.Extract(lRequest);
    lRequest.Free;
  end;
end;

procedure TNXXMPPDiscoModule.CompleteCaps(ARequest: TNXXMPPCapsRequest;
  AStanza: TNXXMPPStanza; const AError: UTF8String);
var
  lInfo: TNXXMPPDiscoInfo;
begin
  if FCapsRequests.IndexOf(ARequest) < 0 then
    Exit;
  FCapsRequests.Extract(ARequest);
  lInfo := ParseInfoResponse(AStanza, AError);
  try
    if (lInfo.Error = '') and (lInfo.Node = ARequest.FNode) then
      FCapabilities.StoreVerified(ARequest.FEntityJID, ARequest.FNode,
        ARequest.FVerification, lInfo);
    if Assigned(FOnInfo) then
      FOnInfo(Self, lInfo);
  finally
    lInfo.Free;
  end;
end;

procedure TNXXMPPDiscoModule.CompleteInfo(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lInfo: TNXXMPPDiscoInfo;
begin
  lInfo := ParseInfoResponse(AStanza, AError);
  try
    if Assigned(FOnInfo) then
      FOnInfo(Self, lInfo);
  finally
    lInfo.Free;
  end;
end;

class function TNXXMPPDiscoModule.ParseInfoResponse(AStanza: TNXXMPPStanza;
  const AError: UTF8String): TNXXMPPDiscoInfo;
var
  lChild: TDOMElement;
  lIdentity: TNXXMPPDiscoIdentity;
  lQuery: TDOMElement;
  lCanonicalForm: UTF8String;
  lDataForm: TNXXMPPDataForm;
  lIndex: Integer;
  lDuplicate: Boolean;
begin
  Result := TNXXMPPDiscoInfo.Create;
  Result.FError := AError;
    if Assigned(AStanza) then
    begin
      Result.FFromJID := AStanza.FromJID;
      lQuery := NXXMPPFindChild(AStanza.Root,
        'http://jabber.org/protocol/disco#info', 'query');
      if not Assigned(lQuery) then
        Result.FError := 'The disco info response has no query element.'
      else
      begin
        Result.FNode := UTF8Encode(lQuery.GetAttribute('node'));
        lChild := NXXMPPFirstChildElement(lQuery);
        while Assigned(lChild) do
        begin
          if NXXMPPElementMatches(lChild,
            'http://jabber.org/protocol/disco#info', 'identity') then
          begin
            lIdentity.Category := UTF8Encode(lChild.GetAttribute('category'));
            lIdentity.IdentityType := UTF8Encode(lChild.GetAttribute('type'));
            lIdentity.Language := UTF8Encode(
              lChild.GetAttribute('xml:lang'));
            lIdentity.Name := UTF8Encode(lChild.GetAttribute('name'));
            lDuplicate := False;
            for lIndex := 0 to High(Result.FIdentities) do
              if (Result.FIdentities[lIndex].Category = lIdentity.Category) and
                (Result.FIdentities[lIndex].IdentityType =
                  lIdentity.IdentityType) and
                (Result.FIdentities[lIndex].Language = lIdentity.Language) and
                (Result.FIdentities[lIndex].Name = lIdentity.Name) then
                lDuplicate := True;
            if lDuplicate then
              Result.FError := 'The disco info response repeats an identity.'
            else
            begin
              SetLength(Result.FIdentities, Length(Result.FIdentities) + 1);
              Result.FIdentities[High(Result.FIdentities)] := lIdentity;
            end;
          end
          else if NXXMPPElementMatches(lChild,
            'http://jabber.org/protocol/disco#info', 'feature') then
          begin
            if Result.FFeatures.IndexOf(string(UTF8Encode(
              lChild.GetAttribute('var')))) >= 0 then
              Result.FError := 'The disco info response repeats a feature.'
            else
              Result.FFeatures.Add(string(UTF8Encode(
                lChild.GetAttribute('var'))));
          end
          else if NXXMPPElementMatches(lChild, 'jabber:x:data', 'x') then
          begin
            if not NXXMPPParseDataForm(lChild, lDataForm) then
              Result.FError := 'The disco info response has an invalid data form.'
            else
            begin
              lCanonicalForm := lDataForm.Canonical;
              if Result.FForms.IndexOf(string(lCanonicalForm)) >= 0 then
              begin
                Result.FError := 'The disco info response repeats a data form.';
                lDataForm.Free;
              end
              else
              begin
                Result.FDataForms.Add(lDataForm);
                Result.FForms.Add(string(lCanonicalForm));
              end;
            end;
          end;
          lChild := NXXMPPNextSiblingElement(lChild);
        end;
      end;
    end;
end;

procedure TNXXMPPDiscoModule.CompleteItems(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
var
  lItems: TNXXMPPDiscoItems;
begin
  lItems := ParseItemsResponse(AStanza, AError);
  try
    if Assigned(FOnItems) then
      FOnItems(Self, lItems);
  finally
    lItems.Free;
  end;
end;

class function TNXXMPPDiscoModule.ParseItemsResponse(
  AStanza: TNXXMPPStanza; const AError: UTF8String): TNXXMPPDiscoItems;
var
  lChild: TDOMElement;
  lItem: TNXXMPPDiscoItem;
  lQuery: TDOMElement;
begin
  Result := TNXXMPPDiscoItems.Create;
  Result.FError := AError;
    if Assigned(AStanza) then
    begin
      Result.FFromJID := AStanza.FromJID;
      lQuery := NXXMPPFindChild(AStanza.Root,
        'http://jabber.org/protocol/disco#items', 'query');
      if not Assigned(lQuery) then
        Result.FError := 'The disco items response has no query element.'
      else
      begin
        Result.FNode := UTF8Encode(lQuery.GetAttribute('node'));
        lChild := NXXMPPFirstChildElement(lQuery);
        while Assigned(lChild) do
        begin
          if NXXMPPElementMatches(lChild,
            'http://jabber.org/protocol/disco#items', 'item') then
          begin
            lItem.JID := UTF8Encode(lChild.GetAttribute('jid'));
            lItem.Name := UTF8Encode(lChild.GetAttribute('name'));
            lItem.Node := UTF8Encode(lChild.GetAttribute('node'));
            if lItem.JID <> '' then
            begin
              SetLength(Result.FItems, Length(Result.FItems) + 1);
              Result.FItems[High(Result.FItems)] := lItem;
            end;
          end;
          lChild := NXXMPPNextSiblingElement(lChild);
        end;
      end;
    end;
end;

class function TNXXMPPDiscoModule.CapabilityHash(
  AInfo: TNXXMPPDiscoInfo): UTF8String;
var
  lCanonical: RawByteString;
  lIdentities: TStringList;
  lIndex: Integer;
begin
  Result := '';
  if not Assigned(AInfo) or (AInfo.Error <> '') then
    Exit;
  lIdentities := TStringList.Create;
  try
    lIdentities.CaseSensitive := True;
    lIdentities.Sorted := True;
    for lIndex := 0 to High(AInfo.Identities) do
      lIdentities.Add(string(AInfo.Identities[lIndex].Category + '/' +
        AInfo.Identities[lIndex].IdentityType + '/' +
        AInfo.Identities[lIndex].Language + '/' +
        AInfo.Identities[lIndex].Name));
    lCanonical := '';
    for lIndex := 0 to lIdentities.Count - 1 do
      lCanonical := lCanonical + RawByteString(lIdentities[lIndex]) + '<';
    for lIndex := 0 to AInfo.Features.Count - 1 do
      lCanonical := lCanonical + RawByteString(AInfo.Features[lIndex]) + '<';
    for lIndex := 0 to AInfo.Forms.Count - 1 do
      lCanonical := lCanonical + RawByteString(AInfo.Forms[lIndex]);
    Result := UTF8String(EncodeBase64(TNXXMPPOpenSSL.SHA1(lCanonical)));
  finally
    lIdentities.Free;
  end;
end;

procedure TNXXMPPDiscoModule.RegisterHandlers(
  ADispatcher: TNXXMPPDispatcher);
begin
  ADispatcher.RegisterIQResponder(xitGet,
    'http://jabber.org/protocol/disco#info', 'query', @HandleInfo);
end;

procedure TNXXMPPDiscoModule.HandleInfo(AStanza: TNXXMPPStanza);
var
  lIndex: Integer;
  lResult: UTF8String;
begin
  lResult := '<iq type=''result'' id=''' + NXXMPPEscapeAttribute(AStanza.ID) +
    '''';
  if AStanza.FromJID <> '' then
    lResult := lResult + ' to=''' +
      NXXMPPEscapeAttribute(AStanza.FromJID) + '''';
  lResult := lResult + '><query xmlns=' +
    '''http://jabber.org/protocol/disco#info''><identity category=''' +
    NXXMPPEscapeAttribute(FCategory) + ''' type=''' +
    NXXMPPEscapeAttribute(FIdentityType) + ''' name=''' +
    NXXMPPEscapeAttribute(FIdentityName) + '''/>';
  for lIndex := 0 to FFeatures.Count - 1 do
    lResult := lResult + '<feature var=''' +
      NXXMPPEscapeAttribute(UTF8String(FFeatures[lIndex])) + '''/>';
  Send(lResult + '</query></iq>');
end;

end.

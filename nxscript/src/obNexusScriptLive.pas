(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptLive;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, tpNexusScript, tpNexusScriptLive,
  obNexusScriptModel;

type
  ENexusScriptLive = class(Exception);
  TNexusScriptLiveDefinition = class;
  TNexusScriptLiveProperty = class;
  TNexusScriptLiveValue = class;

  TNexusScriptLiveNode = class
  private
    FName: string;
    FSourceRange: TNexusScriptRange;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    property Name: string read FName;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNexusScriptLiveReference = class
  private
    FPath: string;
    FTarget: TNexusScriptLiveNode;
  public
    property Path: string read FPath;
    property Target: TNexusScriptLiveNode read FTarget;
  end;

  TNexusScriptLiveValue = class(TNexusScriptLiveNode)
  private
    FKind: TNexusScriptLiveValueKind;
    FText: string;
    FOriginalDefinitionName: string;
    FDefinition: TNexusScriptLiveDefinition;
    FItems: TList<TNexusScriptLiveValue>;
    FReference: TNexusScriptLiveReference;
    FReferenceRanges: TList<TNexusScriptRange>;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function AsText: string;
    function AsDefinition: TNexusScriptLiveDefinition;
    function FindItem(const AName: string): TNexusScriptLiveValue;
    property Kind: TNexusScriptLiveValueKind read FKind;
    property OriginalDefinitionName: string read FOriginalDefinitionName;
    property Items: TList<TNexusScriptLiveValue> read FItems;
    property Reference: TNexusScriptLiveReference read FReference;
    property ReferenceRanges: TList<TNexusScriptRange> read FReferenceRanges;
  end;

  TNexusScriptLiveProperty = class(TNexusScriptLiveNode)
  private
    FParent: TNexusScriptLiveDefinition;
    FValue: TNexusScriptLiveValue;
    FContributorRanges: TList<TNexusScriptRange>;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Parent: TNexusScriptLiveDefinition read FParent;
    property Value: TNexusScriptLiveValue read FValue;
    property ContributorRanges: TList<TNexusScriptRange> read FContributorRanges;
  end;

  TNexusScriptLiveTarget = class(TNexusScriptLiveNode)
  private
    FValues: TStringList;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Values: TStringList read FValues;
  end;

  TNexusScriptLiveDefinition = class(TNexusScriptLiveNode)
  private
    FKind: string;
    FParent: TNexusScriptLiveDefinition;
    FProperties: TList<TNexusScriptLiveProperty>;
    FChildren: TList<TNexusScriptLiveDefinition>;
    FTargets: TList<TNexusScriptLiveTarget>;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindProperty(const AName: string): TNexusScriptLiveProperty;
    function FindChild(const AName: string): TNexusScriptLiveDefinition;
    property Kind: string read FKind;
    property Parent: TNexusScriptLiveDefinition read FParent;
    property Properties: TList<TNexusScriptLiveProperty> read FProperties;
    property Children: TList<TNexusScriptLiveDefinition> read FChildren;
    property Targets: TList<TNexusScriptLiveTarget> read FTargets;
  end;

  { Owns every node once. All navigation and reference links are non-owning. }
  TNexusScriptLiveDocument = class
  private
    FSourceName: string;
    FCompiledAt: TDateTime;
    FNodes: TObjectList<TNexusScriptLiveNode>;
    FRoots: TList<TNexusScriptLiveDefinition>;
    FDefinitions: TList<TNexusScriptLiveDefinition>;
  public
    constructor Create;
    destructor Destroy; override;
    function FindDefinition(const AName: string): TNexusScriptLiveDefinition;
    property SourceName: string read FSourceName;
    property CompiledAt: TDateTime read FCompiledAt;
    property Roots: TList<TNexusScriptLiveDefinition> read FRoots;
    property Definitions: TList<TNexusScriptLiveDefinition> read FDefinitions;
  end;

  { Returns an owned snapshot, not a stream artifact or a borrowed compiler view. }
  TNexusScriptLiveEmitter = class
  public
    class function Emit(ADocument: TNexusScriptCompiledDocument):
      TNexusScriptLiveDocument; static;
  end;

implementation

uses obNexusScriptDefinitionView;

type
  TNexusScriptLiveBuilder = class
  private
    FDocument: TNexusScriptLiveDocument;
    FDefinitions: TDictionary<TNexusScriptCompiledDefinition, TNexusScriptLiveDefinition>;
    FProperties: TDictionary<TNexusScriptCompiledProperty, TNexusScriptLiveProperty>;
    FValues: TDictionary<TNexusScriptCompiledValue, TNexusScriptLiveValue>;
    function CopyDefinition(ASource: TNexusScriptCompiledDefinition): TNexusScriptLiveDefinition;
    function CopyProperty(ASource: TNexusScriptCompiledProperty): TNexusScriptLiveProperty;
    function CopyValue(ASource: TNexusScriptCompiledValue): TNexusScriptLiveValue;
    procedure ConnectReference(ASource: TNexusScriptCompiledValue; AValue: TNexusScriptLiveValue);
  public
    constructor Create(ADocument: TNexusScriptLiveDocument);
    destructor Destroy; override;
    procedure Build(ASource: TNexusScriptCompiledDocument);
  end;

constructor TNexusScriptLiveNode.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FName := AName;
  FSourceRange := ASourceRange;
end;

constructor TNexusScriptLiveValue.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create(AName, ASourceRange);
  FItems := TList<TNexusScriptLiveValue>.Create;
  FReferenceRanges := TList<TNexusScriptRange>.Create;
end;

destructor TNexusScriptLiveValue.Destroy;
begin
  FReferenceRanges.Free;
  FReference.Free;
  FItems.Free;
  inherited Destroy;
end;

function TNexusScriptLiveValue.AsText: string;
begin
  if FKind <> nslvText then
    raise ENexusScriptLive.Create('The value is not text.');
  Result := FText;
end;

function TNexusScriptLiveValue.AsDefinition: TNexusScriptLiveDefinition;
begin
  if FKind <> nslvDefinition then
    raise ENexusScriptLive.Create('The value is not a definition.');
  Result := FDefinition;
end;

function TNexusScriptLiveValue.FindItem(const AName: string): TNexusScriptLiveValue;
var
  lItem: TNexusScriptLiveValue;
begin
  for lItem in FItems do
    if SameText(lItem.Name, AName) then Exit(lItem);
  Result := nil;
end;

constructor TNexusScriptLiveProperty.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create(AName, ASourceRange);
  FContributorRanges := TList<TNexusScriptRange>.Create;
end;

destructor TNexusScriptLiveProperty.Destroy;
begin
  FContributorRanges.Free;
  inherited Destroy;
end;

constructor TNexusScriptLiveTarget.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create(AName, ASourceRange);
  FValues := TStringList.Create;
end;

destructor TNexusScriptLiveTarget.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

constructor TNexusScriptLiveDefinition.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create(AName, ASourceRange);
  FProperties := TList<TNexusScriptLiveProperty>.Create;
  FChildren := TList<TNexusScriptLiveDefinition>.Create;
  FTargets := TList<TNexusScriptLiveTarget>.Create;
end;

destructor TNexusScriptLiveDefinition.Destroy;
begin
  FTargets.Free;
  FChildren.Free;
  FProperties.Free;
  inherited Destroy;
end;

function TNexusScriptLiveDefinition.FindProperty(const AName: string): TNexusScriptLiveProperty;
var
  lProperty: TNexusScriptLiveProperty;
begin
  for lProperty in FProperties do
    if SameText(lProperty.Name, AName) then Exit(lProperty);
  Result := nil;
end;

function TNexusScriptLiveDefinition.FindChild(const AName: string): TNexusScriptLiveDefinition;
var
  lChild: TNexusScriptLiveDefinition;
begin
  for lChild in FChildren do
    if SameText(lChild.Name, AName) then Exit(lChild);
  Result := nil;
end;

constructor TNexusScriptLiveDocument.Create;
begin
  inherited Create;
  FNodes := TObjectList<TNexusScriptLiveNode>.Create(True);
  FRoots := TList<TNexusScriptLiveDefinition>.Create;
  FDefinitions := TList<TNexusScriptLiveDefinition>.Create;
end;

destructor TNexusScriptLiveDocument.Destroy;
begin
  FDefinitions.Free;
  FRoots.Free;
  FNodes.Free;
  inherited Destroy;
end;

function TNexusScriptLiveDocument.FindDefinition(const AName: string): TNexusScriptLiveDefinition;
var
  lRoot: TNexusScriptLiveDefinition;
begin
  for lRoot in FRoots do
    if SameText(lRoot.Name, AName) then Exit(lRoot);
  Result := nil;
end;

constructor TNexusScriptLiveBuilder.Create(ADocument: TNexusScriptLiveDocument);
begin
  inherited Create;
  FDocument := ADocument;
  FDefinitions := TDictionary<TNexusScriptCompiledDefinition, TNexusScriptLiveDefinition>.Create;
  FProperties := TDictionary<TNexusScriptCompiledProperty, TNexusScriptLiveProperty>.Create;
  FValues := TDictionary<TNexusScriptCompiledValue, TNexusScriptLiveValue>.Create;
end;

destructor TNexusScriptLiveBuilder.Destroy;
begin
  FValues.Free;
  FProperties.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

function TNexusScriptLiveBuilder.CopyDefinition(
  ASource: TNexusScriptCompiledDefinition): TNexusScriptLiveDefinition;
var
  lProperty: TNexusScriptCompiledProperty;
  lPropertyCopy: TNexusScriptLiveProperty;
  lChild: TNexusScriptCompiledDefinition;
  lTarget: TNexusScriptTarget;
  lTargetCopy: TNexusScriptLiveTarget;
begin
  if ASource = nil then Exit(nil);
  if FDefinitions.TryGetValue(ASource, Result) then Exit;
  Result := TNexusScriptLiveDefinition.Create(ASource.Name, ASource.SourceRange);
  FDocument.FNodes.Add(Result);
  FDefinitions.Add(ASource, Result);
  FDocument.FDefinitions.Add(Result);
  Result.FKind := ASource.Kind;
  Result.FParent := CopyDefinition(ASource.Parent);
  for lProperty in ASource.Properties do
  begin
    lPropertyCopy := CopyProperty(lProperty);
    lPropertyCopy.FParent := Result;
    Result.FProperties.Add(lPropertyCopy);
  end;
  for lChild in ASource.Children do
    Result.FChildren.Add(CopyDefinition(lChild));
  for lTarget in ASource.Targets do
  begin
    lTargetCopy := TNexusScriptLiveTarget.Create(lTarget.Name, lTarget.SourceRange);
    FDocument.FNodes.Add(lTargetCopy);
    lTargetCopy.FValues.Assign(lTarget.Values);
    Result.FTargets.Add(lTargetCopy);
  end;
end;

function TNexusScriptLiveBuilder.CopyProperty(
  ASource: TNexusScriptCompiledProperty): TNexusScriptLiveProperty;
begin
  if FProperties.TryGetValue(ASource, Result) then Exit;
  Result := TNexusScriptLiveProperty.Create(ASource.Name, ASource.SourceRange);
  FDocument.FNodes.Add(Result);
  FProperties.Add(ASource, Result);
  Result.FContributorRanges.AddRange(ASource.ContributorRanges);
  Result.FValue := CopyValue(ASource.Value);
end;

procedure TNexusScriptLiveBuilder.ConnectReference(
  ASource: TNexusScriptCompiledValue; AValue: TNexusScriptLiveValue);
begin
  if ASource.Kind <> nsvReference then Exit;
  AValue.FReference := TNexusScriptLiveReference.Create;
  AValue.FReference.FPath := ASource.SourceText;
  if ASource.ResolvedValue <> nil then
    AValue.FReference.FTarget := CopyValue(ASource.ResolvedValue)
  else if ASource.ResolvedProperty <> nil then
    AValue.FReference.FTarget := CopyProperty(ASource.ResolvedProperty)
  else if ASource.ResolvedDefinition <> nil then
    AValue.FReference.FTarget := CopyDefinition(ASource.ResolvedDefinition)
  else
    raise ENexusScriptLive.CreateFmt('Reference @%s has no compiled target.',
      [ASource.SourceText]);
end;

function TNexusScriptLiveBuilder.CopyValue(
  ASource: TNexusScriptCompiledValue): TNexusScriptLiveValue;
var
  lValue: TNexusScriptCompiledValue;
  lItem: TNexusScriptCompiledValue;
begin
  if FValues.TryGetValue(ASource, Result) then Exit;
  if ASource.EvaluationState <> nsvesCompleted then
    raise ENexusScriptLive.Create('Live emission requires completed compiled values.');
  Result := TNexusScriptLiveValue.Create(ASource.EffectiveName, ASource.SourceRange);
  FDocument.FNodes.Add(Result);
  FValues.Add(ASource, Result);
  Result.FReferenceRanges.AddRange(ASource.ReferenceRanges);
  Result.FOriginalDefinitionName := ASource.OriginalDefinitionName;
  lValue := ASource.SemanticValue;
  if ASource.DefinitionValue <> nil then
  begin
    Result.FKind := nslvDefinition;
    Result.FDefinition := CopyDefinition(ASource.DefinitionValue);
  end
  else if lValue.Kind = nsvArray then
  begin
    Result.FKind := nslvArray;
    for lItem in lValue.Items do Result.FItems.Add(CopyValue(lItem));
  end
  else if lValue.HasEffectiveText then
  begin
    Result.FKind := nslvText;
    Result.FText := lValue.EffectiveText;
  end
  else
    raise ENexusScriptLive.Create('Compiled value has no effective Live value.');
  ConnectReference(ASource, Result);
end;

procedure TNexusScriptLiveBuilder.Build(ASource: TNexusScriptCompiledDocument);
var
  lView: TNexusScriptDefinitionView;
  lRoot: TNexusScriptCompiledDefinition;
begin
  FDocument.FSourceName := ASource.SourceName;
  FDocument.FCompiledAt := ASource.CompiledAt;
  lView := TNexusScriptDefinitionView.Create;
  try
    lView.AddDocument(ASource);
    for lRoot in lView.Roots do
      FDocument.FRoots.Add(CopyDefinition(lRoot));
  finally
    lView.Free;
  end;
end;

class function TNexusScriptLiveEmitter.Emit(ADocument: TNexusScriptCompiledDocument):
  TNexusScriptLiveDocument;
var
  lBuilder: TNexusScriptLiveBuilder;
begin
  if ADocument = nil then
    raise ENexusScriptLive.Create('Compiled document is required.');
  Result := TNexusScriptLiveDocument.Create;
  try
    lBuilder := TNexusScriptLiveBuilder.Create(Result);
    try
      lBuilder.Build(ADocument);
    finally
      lBuilder.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.

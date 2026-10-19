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
  obNexusScriptModel, obNexusScriptTextConstraints;

type
  ENexusScriptLive = class(Exception);
  TNexusScriptLiveDocument = class;
  TNexusScriptLiveExternal = class;
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

  { One identity per case-sensitive path, shared by every use in the document. }
  TNexusScriptLiveExternal = class(TNexusScriptLiveNode)
  private
    FDocument: TNexusScriptLiveDocument;
    FPath: string;
    FParent: TNexusScriptLiveExternal;
    FChildren: TList<TNexusScriptLiveExternal>;
    FIsSelectedTarget: Boolean;
    FSelectedValue: string;
    FResolving: Boolean;
    function ReadValue(const ARange: TNexusScriptRange): string;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindChild(const AName: string): TNexusScriptLiveExternal;
    property Path: string read FPath;
    property Parent: TNexusScriptLiveExternal read FParent;
    property Children: TList<TNexusScriptLiveExternal> read FChildren;
    property IsSelectedTarget: Boolean read FIsSelectedTarget;
  end;

  TNexusScriptLiveReference = class
  private
    FPath: string;
    FKind: TNexusScriptLiveReferenceKind;
    FTarget: TNexusScriptLiveNode;
  public
    property Kind: TNexusScriptLiveReferenceKind read FKind;
    property Path: string read FPath;
    property Target: TNexusScriptLiveNode read FTarget;
  end;

  TNexusScriptLiveValue = class(TNexusScriptLiveNode)
  private
    FKind: TNexusScriptLiveValueKind;
    FText: string;
    FRequiresContext: Boolean;
    FTextConstraints: TNexusScriptTextConstraintList;
    FResolving: Boolean;
    FExternal: TNexusScriptLiveExternal;
    FValueSource: TNexusScriptLiveValue;
    FOperands: TList<TNexusScriptLiveValue>;
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
    property RequiresContext: Boolean read FRequiresContext;
    property External: TNexusScriptLiveExternal read FExternal;
    property Operands: TList<TNexusScriptLiveValue> read FOperands;
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
    FExternal: TNexusScriptLiveExternal;
    FContributorRanges: TList<TNexusScriptRange>;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Parent: TNexusScriptLiveDefinition read FParent;
    property External: TNexusScriptLiveExternal read FExternal;
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
    FExternalAssignments: TList<TNexusScriptLiveProperty>;
    FChildren: TList<TNexusScriptLiveDefinition>;
    FTargets: TList<TNexusScriptLiveTarget>;
  public
    constructor Create(const AName: string; const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindProperty(const AName: string): TNexusScriptLiveProperty;
    function FindExternalAssignment(const APath: string): TNexusScriptLiveProperty;
    function FindChild(const AName: string): TNexusScriptLiveDefinition;
    property Kind: string read FKind;
    property Parent: TNexusScriptLiveDefinition read FParent;
    property ExternalAssignments: TList<TNexusScriptLiveProperty> read FExternalAssignments;
    property Properties: TList<TNexusScriptLiveProperty> read FProperties;
    property Children: TList<TNexusScriptLiveDefinition> read FChildren;
    property Targets: TList<TNexusScriptLiveTarget> read FTargets;
  end;

  { Desired results own their text and provenance, independently of the Live document. }
  TNexusScriptExternalResult = class
  private
    FPath: string;
    FValue: string;
    FSourceRange: TNexusScriptRange;
  public
    property Path: string read FPath;
    property Value: string read FValue;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;
  TNexusScriptExternalResultList = TObjectList<TNexusScriptExternalResult>;

  { Owns every node once. All navigation and reference links are non-owning. }
  TNexusScriptLiveDocument = class
  private
    FSourceName: string;
    FCompiledAt: TDateTime;
    FNodes: TObjectList<TNexusScriptLiveNode>;
    FRoots: TList<TNexusScriptLiveDefinition>;
    FDefinitions: TList<TNexusScriptLiveDefinition>;
    FExternalRoot: TNexusScriptLiveExternal;
    FExternalAssignments: TList<TNexusScriptLiveProperty>;
    FOnReadExternal: TNexusScriptExternalReadEvent;
    FOnExternalResult: TNexusScriptExternalResultEvent;
    function RequireExternal(const APath: string;
      const ARange: TNexusScriptRange): TNexusScriptLiveExternal;
  public
    constructor Create;
    destructor Destroy; override;
    function FindDefinition(const AName: string): TNexusScriptLiveDefinition;
    function FindExternal(const APath: string): TNexusScriptLiveExternal;
    function EvaluateExternalAssignments: TNexusScriptExternalResultList;
    procedure PublishExternalAssignments;
    property ExternalRoot: TNexusScriptLiveExternal read FExternalRoot;
    property ExternalAssignments: TList<TNexusScriptLiveProperty> read FExternalAssignments;
    property OnReadExternal: TNexusScriptExternalReadEvent read FOnReadExternal write FOnReadExternal;
    property OnExternalResult: TNexusScriptExternalResultEvent read FOnExternalResult write FOnExternalResult;
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
  FOperands := TList<TNexusScriptLiveValue>.Create;
  FTextConstraints := TNexusScriptTextConstraintList.Create(True);
  FReferenceRanges := TList<TNexusScriptRange>.Create;
end;

destructor TNexusScriptLiveValue.Destroy;
begin
  FTextConstraints.Free;
  FOperands.Free;
  FReferenceRanges.Free;
  FReference.Free;
  FItems.Free;
  inherited Destroy;
end;

function LiveError(const AMessage: string; const ARange: TNexusScriptRange): ENexusScriptLive;
begin
  Result := ENexusScriptLive.CreateFmt('%s(%d,%d): %s',
    [ARange.SourceName, ARange.StartPosition.Line, ARange.StartPosition.Column, AMessage]);
end;

function TNexusScriptLiveValue.AsText: string;
var
  lOperand: TNexusScriptLiveValue;
  lConstraint: TNexusScriptTextConstraint;
  lCode, lMessage: string;
begin
  if FKind <> nslvText then
    raise LiveError('The value is not text.', SourceRange);
  if FResolving then
    raise LiveError('Value dependency cycle during Live evaluation.', SourceRange);
  FResolving := True;
  try
    if FExternal <> nil then
      Result := FExternal.ReadValue(SourceRange)
    else if FValueSource <> nil then
      Result := FValueSource.AsText
    else if FRequiresContext then
    begin
      Result := '';
      for lOperand in FOperands do Result := Result + lOperand.AsText;
    end
    else
      Result := FText;
    for lConstraint in FTextConstraints do
      if not lConstraint.Check(Result, lCode, lMessage) then
        raise LiveError(lCode + ': ' + lMessage, SourceRange);
  finally
    FResolving := False;
  end;
end;

constructor TNexusScriptLiveExternal.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create(AName, ASourceRange);
  FChildren := TList<TNexusScriptLiveExternal>.Create;
end;

destructor TNexusScriptLiveExternal.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TNexusScriptLiveExternal.FindChild(const AName: string): TNexusScriptLiveExternal;
var
  lChild: TNexusScriptLiveExternal;
begin
  for lChild in FChildren do
    if lChild.Name = AName then Exit(lChild);
  Result := nil;
end;

function TNexusScriptLiveExternal.ReadValue(const ARange: TNexusScriptRange): string;
var
  lHandled: Boolean;
begin
  if FIsSelectedTarget then Exit(FSelectedValue);
  if FResolving then
    raise LiveError('External dependency cycle at $' + FPath, ARange);
  FResolving := True;
  try
    Result := '';
    lHandled := False;
    if Assigned(FDocument.FOnReadExternal) then
      FDocument.FOnReadExternal(FPath, Result, lHandled);
    if not lHandled then
      raise LiveError('Unresolved external reference $' + FPath, ARange);
  finally
    FResolving := False;
  end;
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
  FExternalAssignments := TList<TNexusScriptLiveProperty>.Create;
  FChildren := TList<TNexusScriptLiveDefinition>.Create;
  FTargets := TList<TNexusScriptLiveTarget>.Create;
end;

destructor TNexusScriptLiveDefinition.Destroy;
begin
  FExternalAssignments.Free;
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

function TNexusScriptLiveDefinition.FindExternalAssignment(const APath: string): TNexusScriptLiveProperty;
var
  lAssignment: TNexusScriptLiveProperty;
begin
  for lAssignment in FExternalAssignments do
    if lAssignment.Name = APath then Exit(lAssignment);
  Result := nil;
end;

constructor TNexusScriptLiveDocument.Create;
begin
  inherited Create;
  FNodes := TObjectList<TNexusScriptLiveNode>.Create(True);
  FExternalAssignments := TList<TNexusScriptLiveProperty>.Create;
  FExternalRoot := TNexusScriptLiveExternal.Create('', Default(TNexusScriptRange));
  FExternalRoot.FDocument := Self;
  FNodes.Add(FExternalRoot);
  FRoots := TList<TNexusScriptLiveDefinition>.Create;
  FDefinitions := TList<TNexusScriptLiveDefinition>.Create;
end;

destructor TNexusScriptLiveDocument.Destroy;
begin
  FExternalAssignments.Free;
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

function TNexusScriptLiveDocument.FindExternal(const APath: string): TNexusScriptLiveExternal;
var
  lParts: TStringArray;
  lPart: string;
begin
  Result := FExternalRoot;
  lParts := APath.Split('.');
  for lPart in lParts do
  begin
    Result := Result.FindChild(lPart);
    if Result = nil then Exit;
  end;
end;

function TNexusScriptLiveDocument.RequireExternal(const APath: string;
  const ARange: TNexusScriptRange): TNexusScriptLiveExternal;
var
  lParts: TStringArray;
  lPart: string;
  lChild: TNexusScriptLiveExternal;
begin
  Result := FExternalRoot;
  lParts := APath.Split('.');
  for lPart in lParts do
  begin
    lChild := Result.FindChild(lPart);
    if lChild = nil then
    begin
      lChild := TNexusScriptLiveExternal.Create(lPart, ARange);
      FNodes.Add(lChild);
      lChild.FDocument := Self;
      lChild.FParent := Result;
      lChild.FPath := lPart;
      if Result.FPath <> '' then lChild.FPath := Result.FPath + '.' + lPart;
      Result.FChildren.Add(lChild);
    end;
    Result := lChild;
  end;
end;

function TNexusScriptLiveDocument.EvaluateExternalAssignments: TNexusScriptExternalResultList;
var
  lAssignment: TNexusScriptLiveProperty;
  lResult: TNexusScriptExternalResult;
begin
  Result := TNexusScriptExternalResultList.Create(True);
  try
    for lAssignment in FExternalAssignments do
    begin
      lResult := TNexusScriptExternalResult.Create;
      Result.Add(lResult);
      lResult.FPath := lAssignment.External.Path;
      lResult.FSourceRange := lAssignment.SourceRange;
      lResult.FValue := lAssignment.Value.AsText;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TNexusScriptLiveDocument.PublishExternalAssignments;
var
  lResults: TNexusScriptExternalResultList;
  lResult: TNexusScriptExternalResult;
  lHandled: Boolean;
begin
  if (FExternalAssignments.Count > 0) and not Assigned(FOnExternalResult) then
    raise ENexusScriptLive.Create('An external-result handler is required.');
  { Evaluate all desired values before delivering any result to the processor. }
  lResults := EvaluateExternalAssignments;
  try
    for lResult in lResults do
    begin
      lHandled := False;
      FOnExternalResult(lResult.Path, lResult.Value, lHandled);
      if not lHandled then
        raise LiveError('External result was not accepted for $' + lResult.Path,
          lResult.SourceRange);
    end;
  finally
    lResults.Free;
  end;
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
    if lProperty.IsExternal then
      Result.FExternalAssignments.Add(lPropertyCopy)
    else
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
  if ASource.IsExternal then
  begin
    Result.FExternal := FDocument.RequireExternal(ASource.Name, ASource.SourceRange);
    if Result.FExternal.IsSelectedTarget then
      raise LiveError('Selected Target $' + ASource.Name + ' is read-only', ASource.SourceRange);
  end;
end;

procedure TNexusScriptLiveBuilder.ConnectReference(
  ASource: TNexusScriptCompiledValue; AValue: TNexusScriptLiveValue);
begin
  if not (ASource.Kind in [nsvReference, nsvExternalReference]) then Exit;
  AValue.FReference := TNexusScriptLiveReference.Create;
  AValue.FReference.FPath := ASource.SourceText;
  if ASource.Kind = nsvExternalReference then
  begin
    AValue.FReference.FKind := nslrExternal;
    AValue.FReference.FTarget := AValue.FExternal;
  end
  else if ASource.ResolvedValue <> nil then
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
  Result.FTextConstraints.Assign(ASource.TextConstraints);
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
  else if ASource.RequiresContext then
  begin
    Result.FKind := nslvText;
    Result.FRequiresContext := True;
    case ASource.Kind of
      nsvExternalReference:
        Result.FExternal := FDocument.RequireExternal(ASource.SourceText, ASource.SourceRange);
      nsvReference:
        if ASource.ResolvedValue <> nil then
          Result.FValueSource := CopyValue(ASource.ResolvedValue)
        else if ASource.ResolvedProperty <> nil then
          Result.FValueSource := CopyProperty(ASource.ResolvedProperty).Value;
      nsvTextComposition:
        for lItem in ASource.Items do Result.FOperands.Add(CopyValue(lItem));
    else
      raise LiveError('Unsupported deferred value.', ASource.SourceRange);
    end;
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
  lRoot, lDefinition: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
  lAssignment, lPrevious: TNexusScriptLiveProperty;
  lTarget: TNexusScriptLiveExternal;
  lIndex: Integer;
begin
  for lIndex := 0 to ASource.SelectedTargets.Count - 1 do
  begin
    lTarget := FDocument.RequireExternal(ASource.SelectedTargets[lIndex].Name,
      Default(TNexusScriptRange));
    lTarget.FIsSelectedTarget := True;
    lTarget.FSelectedValue := ASource.SelectedTargets[lIndex].Value;
  end;
  FDocument.FSourceName := ASource.SourceName;
  FDocument.FCompiledAt := ASource.CompiledAt;
  lView := TNexusScriptDefinitionView.Create;
  try
    lView.AddDocument(ASource);
    for lRoot in lView.Roots do
      FDocument.FRoots.Add(CopyDefinition(lRoot));
    { Public contributions only: private module dependencies are not declarations here. }
    for lDefinition in lView.Definitions do
      for lProperty in lDefinition.Properties do
        if lProperty.IsExternal then
        begin
          lAssignment := CopyProperty(lProperty);
          for lPrevious in FDocument.FExternalAssignments do
            if lPrevious.External = lAssignment.External then
              raise LiveError('Conflicting external assignments for $' + lProperty.Name +
                ' (previous declaration at ' + lPrevious.SourceRange.SourceName + ':' +
                IntToStr(lPrevious.SourceRange.StartPosition.Line) + ')', lProperty.SourceRange);
          FDocument.FExternalAssignments.Add(lAssignment);
        end;
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

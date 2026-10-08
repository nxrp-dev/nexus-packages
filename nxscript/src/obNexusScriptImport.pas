(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptImport;

{$mode delphi}{$H+}

interface

uses obNexusScriptModel;

procedure PreserveNexusScriptImportBindings(ASource, ACopy: TNexusScriptCompiledDefinition);

implementation

uses Generics.Collections, tpNexusScript;

type
  TNexusScriptValuePair = TPair<TNexusScriptCompiledValue, TNexusScriptCompiledValue>;

  TNexusScriptImportCloner = class
  private
    FContext: TNexusScriptImportContext;
    FLocal: TDictionary<TObject, Boolean>;
    FDefinitions: TDictionary<TNexusScriptCompiledDefinition, TNexusScriptCompiledDefinition>;
    FProperties: TDictionary<TNexusScriptCompiledProperty, TNexusScriptCompiledProperty>;
    FValues: TDictionary<TNexusScriptCompiledValue, TNexusScriptCompiledValue>;
    FPending: TList<TNexusScriptValuePair>;
    procedure CollectDefinition(ADefinition: TNexusScriptCompiledDefinition);
    procedure CollectValue(AValue: TNexusScriptCompiledValue);
    function CopyDefinition(ASource: TNexusScriptCompiledDefinition): TNexusScriptCompiledDefinition;
    function CopyProperty(ASource: TNexusScriptCompiledProperty): TNexusScriptCompiledProperty;
    function CopyValue(ASource: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
    function ExternalTarget(ATarget: TObject): Boolean;
    procedure PreserveDefinition(ASource, ACopy: TNexusScriptCompiledDefinition);
    procedure PreserveValue(ASource, ACopy: TNexusScriptCompiledValue);
    procedure RemapReferences;
  public
    constructor Create(AContext: TNexusScriptImportContext);
    destructor Destroy; override;
    procedure Preserve(ASource, ACopy: TNexusScriptCompiledDefinition);
  end;

constructor TNexusScriptImportCloner.Create(AContext: TNexusScriptImportContext);
begin
  inherited Create;
  FContext := AContext;
  FLocal := TDictionary<TObject, Boolean>.Create;
  FDefinitions := TDictionary<TNexusScriptCompiledDefinition, TNexusScriptCompiledDefinition>.Create;
  FProperties := TDictionary<TNexusScriptCompiledProperty, TNexusScriptCompiledProperty>.Create;
  FValues := TDictionary<TNexusScriptCompiledValue, TNexusScriptCompiledValue>.Create;
  FPending := TList<TNexusScriptValuePair>.Create;
end;

destructor TNexusScriptImportCloner.Destroy;
begin
  FPending.Free;
  FValues.Free;
  FProperties.Free;
  FDefinitions.Free;
  FLocal.Free;
  inherited Destroy;
end;

procedure TNexusScriptImportCloner.CollectDefinition(ADefinition: TNexusScriptCompiledDefinition);
var
  lProperty: TNexusScriptCompiledProperty;
  lChild: TNexusScriptCompiledDefinition;
begin
  if ADefinition = nil then Exit;
  FLocal.AddOrSetValue(ADefinition, True);
  for lProperty in ADefinition.Properties do
  begin
    FLocal.AddOrSetValue(lProperty, True);
    CollectValue(lProperty.Value);
  end;
  for lChild in ADefinition.Children do CollectDefinition(lChild);
end;

procedure TNexusScriptImportCloner.CollectValue(AValue: TNexusScriptCompiledValue);
var
  lItem: TNexusScriptCompiledValue;
begin
  if AValue = nil then Exit;
  FLocal.AddOrSetValue(AValue, True);
  CollectDefinition(AValue.StructuralDefinition);
  CollectValue(AValue.EffectiveValue);
  for lItem in AValue.Items do CollectValue(lItem);
  for lItem in AValue.CompositionContributors do CollectValue(lItem);
end;

function TNexusScriptImportCloner.CopyDefinition(
  ASource: TNexusScriptCompiledDefinition): TNexusScriptCompiledDefinition;
var
  lProperty: TNexusScriptCompiledProperty;
  lChild, lCopy: TNexusScriptCompiledDefinition;
  lPropertyCopy: TNexusScriptCompiledProperty;
begin
  if ASource = nil then Exit(nil);
  if FDefinitions.TryGetValue(ASource, Result) then Exit;
  Result := TNexusScriptCompiledDefinition.Create(ASource.Kind, ASource.Name, ASource.SourceRange);
  FDefinitions.Add(ASource, Result);
  FContext.Definitions.Add(Result);
  Result.ImportedRoot := ASource.ImportedRoot;
  Result.Composed := ASource.Composed;
  Result.Targets.Assign(ASource.Targets);
  for lProperty in ASource.Properties do
  begin
    lPropertyCopy := CopyProperty(lProperty);
    FContext.Properties.Extract(lPropertyCopy);
    Result.Properties.Add(lPropertyCopy);
  end;
  for lChild in ASource.Children do
  begin
    lCopy := CopyDefinition(lChild);
    FContext.Definitions.Extract(lCopy);
    lCopy.Parent := Result;
    Result.Children.Add(lCopy);
  end;
end;

function TNexusScriptImportCloner.CopyProperty(
  ASource: TNexusScriptCompiledProperty): TNexusScriptCompiledProperty;
var
  lValue: TNexusScriptCompiledValue;
begin
  if ASource = nil then Exit(nil);
  if FProperties.TryGetValue(ASource, Result) then Exit;
  lValue := CopyValue(ASource.Value);
  FContext.Values.Extract(lValue);
  Result := TNexusScriptCompiledProperty.Create(ASource.Name, lValue, ASource.SourceRange);
  Result.ContributorRanges.Clear;
  Result.ContributorRanges.AddRange(ASource.ContributorRanges);
  FProperties.Add(ASource, Result);
  FContext.Properties.Add(Result);
end;

function TNexusScriptImportCloner.CopyValue(
  ASource: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
var
  lItem, lCopy: TNexusScriptCompiledValue;
  lDefinition: TNexusScriptCompiledDefinition;
begin
  if ASource = nil then Exit(nil);
  if FValues.TryGetValue(ASource, Result) then Exit;
  Result := TNexusScriptCompiledValue.Create(ASource.Kind, ASource.SourceRange);
  FValues.Add(ASource, Result);
  FContext.Values.Add(Result);
  FPending.Add(TNexusScriptValuePair.Create(ASource, Result));
  Result.SourceText := ASource.SourceText;
  Result.ReferenceRanges.AddRange(ASource.ReferenceRanges);
  Result.EntryName := ASource.EntryName;
  Result.EffectiveName := ASource.EffectiveName;
  Result.OriginalDefinitionName := ASource.OriginalDefinitionName;
  Result.EffectiveText := ASource.EffectiveText;
  Result.HasEffectiveText := ASource.HasEffectiveText;
  Result.EvaluationState := ASource.EvaluationState;
  Result.ArrayPreparationState := ASource.ArrayPreparationState;
  lDefinition := CopyDefinition(ASource.StructuralDefinition);
  if lDefinition <> nil then FContext.Definitions.Extract(lDefinition);
  Result.StructuralDefinition := lDefinition;
  lCopy := CopyValue(ASource.EffectiveValue);
  if lCopy <> nil then FContext.Values.Extract(lCopy);
  Result.EffectiveValue := lCopy;
  for lItem in ASource.Items do
  begin
    lCopy := CopyValue(lItem);
    FContext.Values.Extract(lCopy);
    Result.Items.Add(lCopy);
  end;
  for lItem in ASource.CompositionContributors do
  begin
    lCopy := CopyValue(lItem);
    FContext.Values.Extract(lCopy);
    Result.CompositionContributors.Add(lCopy);
  end;
end;

function TNexusScriptImportCloner.ExternalTarget(ATarget: TObject): Boolean;
begin
  Result := (ATarget <> nil) and not FLocal.ContainsKey(ATarget);
end;

procedure TNexusScriptImportCloner.PreserveValue(ASource, ACopy: TNexusScriptCompiledValue);
var
  lIndex: Integer;
begin
  if ASource.ImportBinding <> nil then
    ACopy.ImportBinding := CopyValue(ASource.ImportBinding)
  else if (ASource.Kind = nsvReference) and
    (ExternalTarget(ASource.ResolvedDefinition) or
     ExternalTarget(ASource.ResolvedProperty) or ExternalTarget(ASource.ResolvedValue)) then
    ACopy.ImportBinding := CopyValue(ASource);
  if (ASource.Kind = nsvDefinition) and (ASource.StructuralDefinition <> nil) then
    PreserveDefinition(ASource.StructuralDefinition, ACopy.StructuralDefinition);
  for lIndex := 0 to ASource.Items.Count - 1 do
    PreserveValue(ASource.Items[lIndex], ACopy.Items[lIndex]);
  for lIndex := 0 to ASource.CompositionContributors.Count - 1 do
    PreserveValue(ASource.CompositionContributors[lIndex], ACopy.CompositionContributors[lIndex]);
end;

procedure TNexusScriptImportCloner.PreserveDefinition(ASource, ACopy: TNexusScriptCompiledDefinition);
var
  lIndex: Integer;
begin
  for lIndex := 0 to ASource.Properties.Count - 1 do
    PreserveValue(ASource.Properties[lIndex].Value, ACopy.Properties[lIndex].Value);
  for lIndex := 0 to ASource.Children.Count - 1 do
    PreserveDefinition(ASource.Children[lIndex], ACopy.Children[lIndex]);
end;

procedure TNexusScriptImportCloner.RemapReferences;
var
  lIndex: Integer;
  lPair: TNexusScriptValuePair;
begin
  // Owned structure is registered before following reference edges. The map also
  // closes cycles and ensures shared dependency targets have one owned copy.
  lIndex := 0;
  while lIndex < FPending.Count do
  begin
    lPair := FPending[lIndex];
    lPair.Value.ResolvedDefinition := CopyDefinition(lPair.Key.ResolvedDefinition);
    lPair.Value.ResolvedProperty := CopyProperty(lPair.Key.ResolvedProperty);
    lPair.Value.ResolvedValue := CopyValue(lPair.Key.ResolvedValue);
    lPair.Value.ImportBinding := CopyValue(lPair.Key.ImportBinding);
    Inc(lIndex);
  end;
end;

procedure TNexusScriptImportCloner.Preserve(ASource, ACopy: TNexusScriptCompiledDefinition);
begin
  CollectDefinition(ASource);
  PreserveDefinition(ASource, ACopy);
  RemapReferences;
end;

procedure PreserveNexusScriptImportBindings(ASource, ACopy: TNexusScriptCompiledDefinition);
var
  lCloner: TNexusScriptImportCloner;
begin
  ACopy.ImportContext := TNexusScriptImportContext.Create;
  lCloner := TNexusScriptImportCloner.Create(ACopy.ImportContext);
  try
    lCloner.Preserve(ASource, ACopy);
  finally
    lCloner.Free;
  end;
end;

end.

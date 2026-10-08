(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptDefinitionView;

{$mode delphi}{$H+}

interface

uses Classes, Generics.Collections, obNexusScriptModel;

type
  { Borrows compiled definitions. The compilation session outlives the view. }
  TNexusScriptDefinitionView = class
  private
    FDocuments: TStringList;
    FRoots: TNexusScriptCompiledDefinitionList;
    FDefinitions: TNexusScriptCompiledDefinitionList;
    FRootNames: TStringList;
    FMemberNames: TStringList;
    procedure CollectDefinition(ADefinition: TNexusScriptCompiledDefinition;
      const AScope: string);
    procedure CollectValue(AValue: TNexusScriptCompiledValue;
      const AScope: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddDocument(ADocument: TNexusScriptCompiledDocument);
    property Roots: TNexusScriptCompiledDefinitionList read FRoots;
    property Definitions: TNexusScriptCompiledDefinitionList read FDefinitions;
    property ScopedNames: TStringList read FMemberNames;
  end;

implementation

uses SysUtils, tpNexusScript;

constructor TNexusScriptDefinitionView.Create;
begin
  inherited Create;
  FDocuments := TStringList.Create;
  FDocuments.CaseSensitive := False;
  FRoots := TNexusScriptCompiledDefinitionList.Create(False);
  FDefinitions := TNexusScriptCompiledDefinitionList.Create(False);
  FRootNames := TStringList.Create;
  FRootNames.CaseSensitive := False;
  FMemberNames := TStringList.Create;
  FMemberNames.CaseSensitive := False;
end;

destructor TNexusScriptDefinitionView.Destroy;
begin
  FMemberNames.Free;
  FRootNames.Free;
  FDefinitions.Free;
  FRoots.Free;
  FDocuments.Free;
  inherited Destroy;
end;

procedure TNexusScriptDefinitionView.CollectValue(
  AValue: TNexusScriptCompiledValue; const AScope: string);
var
  lItem, lValue: TNexusScriptCompiledValue;
begin
  { References retain their original targets; they are not new contributions. }
  if AValue.Kind = nsvReference then Exit;
  lValue := AValue;
  while lValue.EffectiveValue <> nil do lValue := lValue.EffectiveValue;
  if lValue.StructuralDefinition <> nil then
    CollectDefinition(lValue.StructuralDefinition, AScope)
  else if lValue.Kind = nsvArray then
    for lItem in lValue.Items do CollectValue(lItem, AScope);
end;

procedure TNexusScriptDefinitionView.CollectDefinition(
  ADefinition: TNexusScriptCompiledDefinition; const AScope: string);
var
  lKey, lScope: string;
  lIndex: Integer;
  lPrevious, lChild: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
begin
  if FDefinitions.IndexOf(ADefinition) >= 0 then Exit;
  lScope := AScope;
  lKey := lScope + '/' + ADefinition.Kind + ':' + ADefinition.Name;
  lIndex := FMemberNames.IndexOf(lKey);
  if lIndex >= 0 then
  begin
    lPrevious := FDefinitions[lIndex];
    raise Exception.CreateFmt('Conflicting definition %s (%s): %s and %s.',
      [ADefinition.Name, ADefinition.Kind, lPrevious.SourceRange.SourceName,
       ADefinition.SourceRange.SourceName]);
  end;
  FMemberNames.Add(lKey);
  FDefinitions.Add(ADefinition);
  { Collection membership does not change a definition's lexical identity. }
  lScope := lKey;
  for lChild in ADefinition.Children do
    CollectDefinition(lChild, lScope);
  for lProperty in ADefinition.Properties do
    CollectValue(lProperty.Value, lScope);
end;

procedure TNexusScriptDefinitionView.AddDocument(
  ADocument: TNexusScriptCompiledDocument);
var
  lDefinition: TNexusScriptCompiledDefinition;
  lIncluded: TNexusScriptCompiledDocument;
begin
  if FDocuments.IndexOf(ADocument.SourceName) >= 0 then Exit;
  FDocuments.Add(ADocument.SourceName);
  for lDefinition in ADocument.Definitions do
    if not lDefinition.ImportedRoot then
    begin
      if FRootNames.IndexOf(lDefinition.Name) >= 0 then
        raise Exception.CreateFmt('Duplicate artifact root name %s.', [lDefinition.Name]);
      FRootNames.Add(lDefinition.Name);
      FRoots.Add(lDefinition);
      CollectDefinition(lDefinition, '');
    end;
  for lIncluded in ADocument.IncludedDocuments do AddDocument(lIncluded);
end;

end.

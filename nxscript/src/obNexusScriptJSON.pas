(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptJSON;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  fpjson,
  tpNexusScript,
  obNexusScriptModel,
  obNexusScriptDefinitionView,
  obNexusScriptArtifactModel,
  obNexusScriptEmitter;

type
  ENexusScriptJSON = class(Exception);

  TNexusScriptJSONEmitter = class(TNexusScriptEmitter)
  private
    FRoot: TJSONObject;
    FMetadata: TJSONObject;
    FRootNames: TStringList;
    FCollectedNames: TStringList;
    FCollections: TJSONObject;
    FProjectedDefinitions: TList<TNexusScriptCompiledDefinition>;
    function IsScalarProjection(AValue: TNexusScriptCompiledValue): Boolean;
    function DefinitionMetadata(
      ADefinition: TNexusScriptCompiledDefinition;
      AReferenceValue: TNexusScriptCompiledValue):
      TNexusScriptArtifactMetadata;
    function DefinitionJSON(
      ADefinition: TNexusScriptCompiledDefinition;
      AReferenceValue: TNexusScriptCompiledValue = nil;
      AProjection: Boolean = False): TJSONObject;
    function ValueJSON(AValue: TNexusScriptCompiledValue;
      AArrayItem: Boolean): TJSONData;
    function ArrayJSON(AValue: TNexusScriptCompiledValue): TJSONArray;
    function ArrayItemJSON(AValue: TNexusScriptCompiledValue): TJSONData;
    function NamedValueJSON(const AName: string;
      AValue: TJSONData): TJSONObject;
  public
    constructor Create; override;
    destructor Destroy; override;
    class function GetFactoryName: string; override;
    procedure AddDocument(
      ADocument: TNexusScriptCompiledDocument); override;
    procedure WriteArtifact(AStream: TStream); overload; override;
    function RenderDefinition(ADefinition: TNexusScriptCompiledDefinition;
      ADocument: TNexusScriptCompiledDocument): string;
    function JSON: string;
  end;

implementation

uses
  DateUtils,
  obNXClassFactory;

procedure WriteText(AStream: TStream; const AValue: string);
var
  lBytes: RawByteString;
begin
  lBytes := UTF8Encode(AValue);
  if Length(lBytes) > 0 then
    AStream.WriteBuffer(Pointer(lBytes)^, Length(lBytes));
end;

class function TNexusScriptJSONEmitter.GetFactoryName: string;
begin
  Result := 'json';
end;

function TNexusScriptJSONEmitter.RenderDefinition(
  ADefinition: TNexusScriptCompiledDefinition;
  ADocument: TNexusScriptCompiledDocument): string;
var
  lData: TJSONObject;
begin
  lData := DefinitionJSON(ADefinition);
  try
    lData.Objects['_nx'].Add('CompiledAt', DateToISO8601(ADocument.CompiledAt));
    Result := lData.AsJSON;
  finally
    lData.Free;
  end;
end;

function TNexusScriptJSONEmitter.DefinitionMetadata(
  ADefinition: TNexusScriptCompiledDefinition;
  AReferenceValue: TNexusScriptCompiledValue):
  TNexusScriptArtifactMetadata;
var
  lIsReference: Boolean;
  lTarget: TNexusScriptTarget;
  lArtifactTarget: TNexusScriptArtifactTarget;
  lValue: string;
begin
  Result := TNexusScriptArtifactMetadata.Create;
  try
    Result.Kind.Value := ADefinition.Kind;
    Result.Name.Value := ADefinition.Name;
    lIsReference := (AReferenceValue <> nil) and
      (AReferenceValue.Kind = nsvReference);
    Result.IsReference.Value := lIsReference;
    Result.SourceRange.SourceName.Value := ADefinition.SourceRange.SourceName;
    Result.SourceRange.StartPosition.Offset.Value :=
      ADefinition.SourceRange.StartPosition.Offset;
    Result.SourceRange.StartPosition.Line.Value :=
      ADefinition.SourceRange.StartPosition.Line;
    Result.SourceRange.StartPosition.Column.Value :=
      ADefinition.SourceRange.StartPosition.Column;
    Result.SourceRange.EndPosition.Offset.Value :=
      ADefinition.SourceRange.EndPosition.Offset;
    Result.SourceRange.EndPosition.Line.Value :=
      ADefinition.SourceRange.EndPosition.Line;
    Result.SourceRange.EndPosition.Column.Value :=
      ADefinition.SourceRange.EndPosition.Column;
    if lIsReference then
    begin
      Result.Name.Value := AReferenceValue.EffectiveName;
      if AReferenceValue.OriginalDefinitionName = '' then
        raise ENexusScriptJSON.CreateFmt(
          'Structural reference %s has no resolved target name.',
          [AReferenceValue.SourceText]);
      Result.Reference.Kind.Value := ADefinition.Kind;
      Result.Reference.Name.Value := AReferenceValue.OriginalDefinitionName;
    end;
    for lTarget in ADefinition.Targets do
    begin
      lArtifactTarget := Result.Targets.AddTarget;
      lArtifactTarget.Name.Value := lTarget.Name;
      for lValue in lTarget.Values do
        lArtifactTarget.Values.AddString(lValue);
    end;
  except
    Result.Free;
    raise;
  end;
end;

constructor TNexusScriptJSONEmitter.Create;
begin
  inherited Create;
  FRoot := TJSONObject.Create;
  FRootNames := TStringList.Create;
  FRootNames.CaseSensitive := False;
  FCollectedNames := TStringList.Create;
  FCollectedNames.CaseSensitive := False;
  FMetadata := TJSONObject.Create;
  FRoot.Add('_nx', FMetadata);
  FCollections := TJSONObject.Create;
  FMetadata.Add('Collections', FCollections);
  FProjectedDefinitions := TList<TNexusScriptCompiledDefinition>.Create;
end;

destructor TNexusScriptJSONEmitter.Destroy;
begin
  FProjectedDefinitions.Free;
  FCollectedNames.Free;
  FRootNames.Free;
  FRoot.Free;
  inherited Destroy;
end;

function TNexusScriptJSONEmitter.NamedValueJSON(const AName: string;
  AValue: TJSONData): TJSONObject;
var
  lMetaData: TNexusScriptArtifactNamedValueMetadata;
begin
  Result := TJSONObject.Create;
  lMetaData := TNexusScriptArtifactNamedValueMetadata.Create;
  try
    try
      lMetaData.Name.Value := AName;
      Result.Add('_nx', lMetaData.ToJSONData);
    finally
      lMetaData.Free;
    end;
    Result.Add('Value', AValue);
  except
    Result.Free;
    raise;
  end;
end;

function TNexusScriptJSONEmitter.ArrayItemJSON(
  AValue: TNexusScriptCompiledValue): TJSONData;
var
  lValue: TNexusScriptCompiledValue;
begin
  lValue := AValue.ArtifactValue;
  Result := ValueJSON(AValue, True);
  if (AValue.EffectiveName <> '') and
    (lValue.ArtifactKind in [nsavText, nsavArray]) then
    Result := NamedValueJSON(AValue.EffectiveName, Result);
end;

function TNexusScriptJSONEmitter.ArrayJSON(
  AValue: TNexusScriptCompiledValue): TJSONArray;
var
  lItem: TNexusScriptCompiledValue;
begin
  Result := TJSONArray.Create;
  try
    for lItem in AValue.Items do
      Result.Add(ArrayItemJSON(lItem));
  except
    Result.Free;
    raise;
  end;
end;

function TNexusScriptJSONEmitter.ValueJSON(
  AValue: TNexusScriptCompiledValue; AArrayItem: Boolean): TJSONData;
var
  lValue: TNexusScriptCompiledValue;
begin
  lValue := AValue.ArtifactValue;
  case lValue.ArtifactKind of
    nsavText:
      Result := TJSONString.Create(lValue.EffectiveText);
    nsavArray:
      Result := ArrayJSON(lValue);
    nsavDefinition:
      Result := DefinitionJSON(lValue.DefinitionValue, AValue);
  else
    if AArrayItem then
      raise ENexusScriptJSON.Create(
        'Array item has no completed artifact value.')
    else
      raise ENexusScriptJSON.Create(
        'Property has no completed artifact value.');
  end;
end;

function TNexusScriptJSONEmitter.IsScalarProjection(
  AValue: TNexusScriptCompiledValue): Boolean;
var
  lValue, lItem: TNexusScriptCompiledValue;
begin
  lValue := AValue.SemanticValue;
  if lValue.DefinitionValue <> nil then Exit(False);
  if lValue.Kind = nsvArray then
    for lItem in lValue.Items do
      if not IsScalarProjection(lItem) then Exit(False);
  Result := True;
end;

function TNexusScriptJSONEmitter.DefinitionJSON(
  ADefinition: TNexusScriptCompiledDefinition;
  AReferenceValue: TNexusScriptCompiledValue;
  AProjection: Boolean): TJSONObject;
var
  lMetaData: TNexusScriptArtifactMetadata;
  lProperty: TNexusScriptCompiledProperty;
  lChild: TNexusScriptCompiledDefinition;
  lProjection: Boolean;
begin
  lProjection := AProjection or ((AReferenceValue <> nil) and
    (AReferenceValue.Kind = nsvReference));
  if lProjection then
  begin
    if FProjectedDefinitions.IndexOf(ADefinition) >= 0 then
      raise ENexusScriptJSON.CreateFmt(
        'Recursive JSON reference projection at %s (%s:%d).',
        [ADefinition.Name, ADefinition.SourceRange.SourceName,
         ADefinition.SourceRange.StartPosition.Line]);
    FProjectedDefinitions.Add(ADefinition);
  end;
  try
    if (ADefinition.FindProperty('_nx') <> nil) or
      (ADefinition.FindChild('_nx') <> nil) then
      raise ENexusScriptJSON.CreateFmt(
        'Definition %s uses reserved member _nx.', [ADefinition.Name]);
    Result := TJSONObject.Create;
    lMetaData := nil;
    try
      lMetaData := DefinitionMetadata(ADefinition, AReferenceValue);
      Result.Add('_nx', lMetaData.ToJSONData);
      FreeAndNil(lMetaData);
      for lProperty in ADefinition.Properties do
      begin
        if lProjection and (lProperty.Value.SemanticValue.Kind = nsvArray) and
          not IsScalarProjection(lProperty.Value) then Continue;
        Result.Add(lProperty.Name, ValueJSON(lProperty.Value, False));
      end;
      for lChild in ADefinition.Children do
        Result.Add(lChild.Name, DefinitionJSON(lChild, nil, lProjection));
    except
      lMetaData.Free;
      Result.Free;
      raise;
    end;
  finally
    if lProjection then
      FProjectedDefinitions.Delete(FProjectedDefinitions.Count - 1);
  end;
end;

procedure TNexusScriptJSONEmitter.AddDocument(
  ADocument: TNexusScriptCompiledDocument);
var
  lDefinition: TNexusScriptCompiledDefinition;
  lView: TNexusScriptDefinitionView;
  lRoots, lDefinitions: TJSONObject;
  lCollection: TJSONArray;
  lIndex, lExisting: Integer;
  lKey, lName: string;
begin
  lView := TNexusScriptDefinitionView.Create;
  lRoots := TJSONObject.Create;
  lDefinitions := TJSONObject.Create;
  try
    try
      lView.AddDocument(ADocument);
    except
      on E: Exception do raise ENexusScriptJSON.Create(E.Message);
    end;
    for lDefinition in lView.Roots do
    begin
      if SameText(lDefinition.Name, '_nx') then
        raise ENexusScriptJSON.Create('Artifact root uses reserved name _nx.');
      lExisting := FRootNames.IndexOfName(lDefinition.Name);
      if lExisting >= 0 then
      begin
        if FRootNames.ValueFromIndex[lExisting] = lDefinition.SourceRange.SourceName then
          Continue;
        raise ENexusScriptJSON.CreateFmt('Duplicate artifact root name %s.',
          [lDefinition.Name]);
      end;
      lRoots.Add(lDefinition.Name, DefinitionJSON(lDefinition));
    end;
    for lIndex := 0 to lView.Definitions.Count - 1 do
    begin
      lDefinition := lView.Definitions[lIndex];
      lKey := lView.ScopedNames[lIndex];
      if FCollectedNames.IndexOf(lKey) < 0 then
        lDefinitions.Add(lKey, DefinitionJSON(lDefinition));
    end;
    { Commit copied JSON only after all rendering succeeds. The caller may
      release or recompile its documents after this method returns. }
    if FMetadata.Find('CompiledAt') = nil then
      FMetadata.Add('CompiledAt', DateToISO8601(ADocument.CompiledAt));
    while lRoots.Count > 0 do
    begin
      lName := lRoots.Names[0];
      FRoot.Add(lName, lRoots.Extract(0));
    end;
    for lDefinition in lView.Roots do
      if FRootNames.IndexOfName(lDefinition.Name) < 0 then
        FRootNames.Add(lDefinition.Name + '=' + lDefinition.SourceRange.SourceName);
    for lIndex := 0 to lView.Definitions.Count - 1 do
    begin
      lKey := lView.ScopedNames[lIndex];
      lExisting := lDefinitions.IndexOfName(lKey);
      if lExisting < 0 then Continue;
      lDefinition := lView.Definitions[lIndex];
      if not FCollections.Find(lDefinition.Kind, lCollection) then
      begin
        lCollection := TJSONArray.Create;
        FCollections.Add(lDefinition.Kind, lCollection);
      end;
      lCollection.Add(lDefinitions.Extract(lExisting));
      FCollectedNames.Add(lKey);
    end;
  finally
    lDefinitions.Free;
    lRoots.Free;
    lView.Free;
  end;
end;

function TNexusScriptJSONEmitter.JSON: string;
begin
  Result := FRoot.FormatJSON;
end;

procedure TNexusScriptJSONEmitter.WriteArtifact(AStream: TStream);
begin
  if AStream = nil then
    raise ENexusScriptJSON.Create('JSON output stream is required.');
  WriteText(AStream, JSON);
end;

initialization
  TNXClassFactory.RegisterClass(TNexusScriptJSONEmitter);

end.

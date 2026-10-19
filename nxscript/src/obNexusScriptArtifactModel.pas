(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptArtifactModel;

{$mode delphi}{$H+}

interface

uses
  Generics.Collections,
  tpNexusScript,
  obNXJSONValues,
  obNexusScriptModel;

type
  TNexusScriptArtifactPosition = class(TNXJSONObject)
  private
    FOffset: TNXJSONInteger;
    FLine: TNXJSONInteger;
    FColumn: TNXJSONInteger;
  published
    property Offset: TNXJSONInteger read FOffset write FOffset;
    property Line: TNXJSONInteger read FLine write FLine;
    property Column: TNXJSONInteger read FColumn write FColumn;
  end;

  TNexusScriptArtifactSourceRange = class(TNXJSONObject)
  private
    FSourceName: TNXJSONString;
    FStartPosition: TNexusScriptArtifactPosition;
    FEndPosition: TNexusScriptArtifactPosition;
  published
    property SourceName: TNXJSONString read FSourceName write FSourceName;
    property StartPosition: TNexusScriptArtifactPosition read FStartPosition
      write FStartPosition;
    property EndPosition: TNexusScriptArtifactPosition read FEndPosition
      write FEndPosition;
  end;

  TNexusScriptArtifactReference = class(TNXJSONObject)
  private
    FKind: TNXJSONString;
    FName: TNXJSONString;
  published
    property Kind: TNXJSONString read FKind write FKind;
    property Name: TNXJSONString read FName write FName;
  end;

  TNexusScriptArtifactTarget = class(TNXJSONObject)
  private
    FName: TNXJSONString;
    FValues: TNXJSONArray;
  published
    property Name: TNXJSONString read FName write FName;
    property Values: TNXJSONArray read FValues write FValues;
  end;

  TNexusScriptArtifactTargetArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONValueClass; override;
    function AddTarget: TNexusScriptArtifactTarget;
  end;

  TNexusScriptArtifactMetadata = class(TNXJSONObject)
  private
    FKind: TNXJSONString;
    FName: TNXJSONString;
    FIsReference: TNXJSONBoolean;
    FSourceRange: TNexusScriptArtifactSourceRange;
    FReference: TNexusScriptArtifactReference;
    FTargets: TNexusScriptArtifactTargetArray;
    FType: TNXJSONString;
    FSource: TNXJSONString;
  published
    property Kind: TNXJSONString read FKind write FKind;
    property Name: TNXJSONString read FName write FName;
    property IsReference: TNXJSONBoolean read FIsReference write FIsReference;
    property SourceRange: TNexusScriptArtifactSourceRange read FSourceRange
      write FSourceRange;
    property Reference: TNexusScriptArtifactReference read FReference
      write FReference;
    property Targets: TNexusScriptArtifactTargetArray read FTargets
      write FTargets;
    property &Type: TNXJSONString read FType write FType;
    property Source: TNXJSONString read FSource write FSource;
  end;

  TNexusScriptArtifactNamedValueMetadata = class(TNXJSONObject)
  private
    FName: TNXJSONString;
  published
    property Name: TNXJSONString read FName write FName;
  end;

  TNexusScriptArtifactValueKind = (
    nsavInvalid,
    nsavText,
    nsavArray,
    nsavDefinition
  );

  TNexusScriptCompiledValueArtifactHelper = class helper for TNexusScriptCompiledValue
  private
    function GetArtifactKind: TNexusScriptArtifactValueKind;
    function GetArtifactValue: TNexusScriptCompiledValue;
  public
    property ArtifactKind: TNexusScriptArtifactValueKind read GetArtifactKind;
    property ArtifactValue: TNexusScriptCompiledValue read GetArtifactValue;
  end;

  TNexusScriptExternalSource = class
  private
    FName: string;
    FDeclaredPath: string;
    FFileName: string;
    FSourceType: string;
    FDeclaringDocument: string;
    FSourceRange: TNexusScriptRange;
  public
    constructor Create(const AName, ADeclaredPath, AFileName,
      ASourceType, ADeclaringDocument: string;
      const ASourceRange: TNexusScriptRange);
    property Name: string read FName;
    property DeclaredPath: string read FDeclaredPath;
    property FileName: string read FFileName;
    property SourceType: string read FSourceType;
    property DeclaringDocument: string read FDeclaringDocument;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNexusScriptExternalSourceList = TObjectList<TNexusScriptExternalSource>;

  TNexusScriptArtifactDocument = class
  private
    FSourceDocument: TNexusScriptSourceDocument;
    FCompiledDocument: TNexusScriptCompiledDocument;
  public
    constructor Create(ASourceDocument: TNexusScriptSourceDocument;
      ACompiledDocument: TNexusScriptCompiledDocument);
    property SourceDocument: TNexusScriptSourceDocument read FSourceDocument;
    property CompiledDocument: TNexusScriptCompiledDocument
      read FCompiledDocument;
  end;

  TNexusScriptArtifactDocumentList = TObjectList<TNexusScriptArtifactDocument>;

procedure RequireMaterializedNexusScriptDocument(ADocument: TNexusScriptCompiledDocument);

implementation

uses SysUtils, obNexusScriptDefinitionView;

procedure RequireMaterializedNexusScriptDocument(ADocument: TNexusScriptCompiledDocument);
var
  lView: TNexusScriptDefinitionView;
  lDefinitions: TList<TNexusScriptCompiledDefinition>;
  lValues: TList<TNexusScriptCompiledValue>;
  lRoot: TNexusScriptCompiledDefinition;

  procedure CheckDefinition(ADefinition: TNexusScriptCompiledDefinition); forward;

  procedure CheckValue(AValue: TNexusScriptCompiledValue);
  var
    lValue, lItem: TNexusScriptCompiledValue;
  begin
    if lValues.IndexOf(AValue) >= 0 then Exit;
    lValues.Add(AValue);
    if AValue.RequiresContext then
      raise Exception.CreateFmt('%s(%d,%d): External expressions require Live evaluation before artifact materialization.',
        [AValue.SourceRange.SourceName, AValue.SourceRange.StartPosition.Line,
         AValue.SourceRange.StartPosition.Column]);
    lValue := AValue.SemanticValue;
    if lValue.DefinitionValue <> nil then
      CheckDefinition(lValue.DefinitionValue)
    else if lValue.Kind = nsvArray then
      for lItem in lValue.Items do CheckValue(lItem);
  end;

  procedure CheckDefinition(ADefinition: TNexusScriptCompiledDefinition);
  var
    lProperty: TNexusScriptCompiledProperty;
    lChild: TNexusScriptCompiledDefinition;
  begin
    if lDefinitions.IndexOf(ADefinition) >= 0 then Exit;
    lDefinitions.Add(ADefinition);
    for lProperty in ADefinition.Properties do
    begin
      if lProperty.IsExternal then
        raise Exception.CreateFmt('%s(%d,%d): External assignment $%s requires processor-specific artifact lowering.',
          [lProperty.SourceRange.SourceName, lProperty.SourceRange.StartPosition.Line,
           lProperty.SourceRange.StartPosition.Column, lProperty.Name]);
      CheckValue(lProperty.Value);
    end;
    for lChild in ADefinition.Children do CheckDefinition(lChild);
  end;
begin
  lView := TNexusScriptDefinitionView.Create;
  lDefinitions := TList<TNexusScriptCompiledDefinition>.Create;
  lValues := TList<TNexusScriptCompiledValue>.Create;
  try
    lView.AddDocument(ADocument);
    for lRoot in lView.Roots do CheckDefinition(lRoot);
  finally
    lValues.Free;
    lDefinitions.Free;
    lView.Free;
  end;
end;


class function TNexusScriptArtifactTargetArray.ItemClass: TNXJSONValueClass;
begin
  Result := TNexusScriptArtifactTarget;
end;

function TNexusScriptArtifactTargetArray.AddTarget:
  TNexusScriptArtifactTarget;
begin
  Result := TNexusScriptArtifactTarget(AddObject(
    TNexusScriptArtifactTarget));
end;

function TNexusScriptCompiledValueArtifactHelper.GetArtifactValue:
  TNexusScriptCompiledValue;
begin
  Result := SemanticValue;
end;

function TNexusScriptCompiledValueArtifactHelper.GetArtifactKind:
  TNexusScriptArtifactValueKind;
var
  lValue: TNexusScriptCompiledValue;
begin
  lValue := GetArtifactValue;
  if lValue.DefinitionValue <> nil then
    Result := nsavDefinition
  else if lValue.Kind = nsvArray then
    Result := nsavArray
  else if lValue.HasEffectiveText then
    Result := nsavText
  else
    Result := nsavInvalid;
end;

constructor TNexusScriptExternalSource.Create(const AName, ADeclaredPath,
  AFileName, ASourceType, ADeclaringDocument: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FName := AName;
  FDeclaredPath := ADeclaredPath;
  FFileName := AFileName;
  FSourceType := ASourceType;
  FDeclaringDocument := ADeclaringDocument;
  FSourceRange := ASourceRange;
end;

constructor TNexusScriptArtifactDocument.Create(
  ASourceDocument: TNexusScriptSourceDocument;
  ACompiledDocument: TNexusScriptCompiledDocument);
begin
  inherited Create;
  FSourceDocument := ASourceDocument;
  FCompiledDocument := ACompiledDocument;
end;

end.

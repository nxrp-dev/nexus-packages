(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptModel;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  tpNexusScript;

type
  TNexusScriptDiagnostic = class
  private
    FCode: string;
    FMessageText: string;
    FSourceRange: TNexusScriptRange;
  public
    constructor Create(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    property Code: string read FCode;
    property MessageText: string read FMessageText;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
  end;

  TNexusScriptSourceValue = class;
  TNexusScriptSourceDefinition = class;
  TNexusScriptImportContext = class;
  TNexusScriptCompiledValue = class;
  TNexusScriptCompiledDefinition = class;
  TNexusScriptCompiledProperty = class;
  TNexusScriptTarget = class;
  TNexusScriptSelectedTarget = class;

  TNexusScriptSourceValueList = TObjectList<TNexusScriptSourceValue>;
  TNexusScriptSourceDefinitionList = TObjectList<TNexusScriptSourceDefinition>;
  TNexusScriptCompiledValueList = TObjectList<TNexusScriptCompiledValue>;
  TNexusScriptCompiledDefinitionList = TObjectList<TNexusScriptCompiledDefinition>;
  TNexusScriptCompiledPropertyList = TObjectList<TNexusScriptCompiledProperty>;
  TNexusScriptDiagnosticList = TObjectList<TNexusScriptDiagnostic>;
  TNexusScriptRangeList = TList<TNexusScriptRange>;

  TNexusScriptTarget = class
  private
    FName: string;
    FValues: TStringList;
    FSourceRange: TNexusScriptRange;
    FNameRange: TNexusScriptRange;
    FValueRanges: TNexusScriptRangeList;
  public
    constructor Create(const AName: string;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function Clone: TNexusScriptTarget;
    function HasValue(const AValue: string): Boolean;
    property Name: string read FName;
    property Values: TStringList read FValues;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property NameRange: TNexusScriptRange read FNameRange write FNameRange;
    property ValueRanges: TNexusScriptRangeList read FValueRanges;
  end;

  TNexusScriptTargetList = class(TObjectList<TNexusScriptTarget>)
  public
    function Find(const AName: string): TNexusScriptTarget;
    procedure Assign(ASource: TNexusScriptTargetList);
  end;

  TNexusScriptSelectedTarget = class
  private
    FName: string;
    FValue: string;
  public
    constructor Create(const AName, AValue: string);
    property Name: string read FName;
    property Value: string read FValue;
  end;

  TNexusScriptTargetSelection = class
  private
    FItems: TObjectList<TNexusScriptSelectedTarget>;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TNexusScriptSelectedTarget;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName, AValue: string);
    procedure Assign(ASource: TNexusScriptTargetSelection);
    function Find(const AName: string): TNexusScriptSelectedTarget;
    procedure SetValue(const AName, AValue: string);
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TNexusScriptSelectedTarget read GetItem;
      default;
  end;

  TNexusScriptSourceValue = class
  private
    FKind: TNexusScriptValueKind;
    FText: string;
    FItems: TNexusScriptSourceValueList;
    FSourceRange: TNexusScriptRange;
    FEntryName: string;
    FEntryNameRange: TNexusScriptRange;
    FInlineDefinition: TNexusScriptSourceDefinition;
    FReferenceRanges: TNexusScriptRangeList;
  public
    constructor Create(AKind: TNexusScriptValueKind;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindNamedItem(const AName: string): TNexusScriptSourceValue;
    property Kind: TNexusScriptValueKind read FKind;
    property Text: string read FText write FText;
    property Items: TNexusScriptSourceValueList read FItems;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property EntryName: string read FEntryName write FEntryName;
    property EntryNameRange: TNexusScriptRange read FEntryNameRange write FEntryNameRange;
    property InlineDefinition: TNexusScriptSourceDefinition
      read FInlineDefinition write FInlineDefinition;
    property ReferenceRanges: TNexusScriptRangeList read FReferenceRanges;
  end;

  TNexusScriptSourceProperty = class
  private
    FName: string;
    FValue: TNexusScriptSourceValue;
    FSourceRange: TNexusScriptRange;
    FNameRange: TNexusScriptRange;
    FValueRange: TNexusScriptRange;
  public
    constructor Create(const AName: string; AValue: TNexusScriptSourceValue;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Name: string read FName;
    property Value: TNexusScriptSourceValue read FValue;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property NameRange: TNexusScriptRange read FNameRange write FNameRange;
    property ValueRange: TNexusScriptRange read FValueRange write FValueRange;
  end;

  TNexusScriptSourcePropertyList = TObjectList<TNexusScriptSourceProperty>;

  TNexusScriptSourceDefinition = class
  private
    FKind: string;
    FName: string;
    FProperties: TNexusScriptSourcePropertyList;
    FChildren: TNexusScriptSourceDefinitionList;
    FCompositionSelectors: TStringList;
    FTargets: TNexusScriptTargetList;
    FParent: TNexusScriptSourceDefinition;
    FSourceRange: TNexusScriptRange;
    FKindRange: TNexusScriptRange;
    FNameRange: TNexusScriptRange;
    FCompositionSelectorRanges: TNexusScriptRangeList;
    FCompositionTargetRanges: TNexusScriptRangeList;
    FBodyEndRange: TNexusScriptRange;
  public
    constructor Create(const AKind, AName: string;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindProperty(const AName: string): TNexusScriptSourceProperty;
    function FindChild(const AName: string): TNexusScriptSourceDefinition;
    property Kind: string read FKind;
    property Name: string read FName;
    property Properties: TNexusScriptSourcePropertyList read FProperties;
    property Children: TNexusScriptSourceDefinitionList read FChildren;
    property CompositionSelectors: TStringList read FCompositionSelectors;
    property Targets: TNexusScriptTargetList read FTargets;
    property Parent: TNexusScriptSourceDefinition read FParent write FParent;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property KindRange: TNexusScriptRange read FKindRange write FKindRange;
    property NameRange: TNexusScriptRange read FNameRange write FNameRange;
    property CompositionSelectorRanges: TNexusScriptRangeList
      read FCompositionSelectorRanges;
    property CompositionTargetRanges: TNexusScriptRangeList
      read FCompositionTargetRanges;
    property BodyEndRange: TNexusScriptRange read FBodyEndRange
      write FBodyEndRange;
  end;

  TNexusScriptSourceModule = class
  private
    FRootSelector: string;
    FPath: string;
    FRecursive: Boolean;
    FSourceRange: TNexusScriptRange;
    FAliasRange: TNexusScriptRange;
    FPathRange: TNexusScriptRange;
    FRootSelectorRange: TNexusScriptRange;
  public
    property RootSelector: string read FRootSelector write FRootSelector;
    property Path: string read FPath write FPath;
    property Recursive: Boolean read FRecursive write FRecursive;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property AliasRange: TNexusScriptRange read FAliasRange write FAliasRange;
    property PathRange: TNexusScriptRange read FPathRange write FPathRange;
    property RootSelectorRange: TNexusScriptRange read FRootSelectorRange
      write FRootSelectorRange;
  end;

  TNexusScriptSourceModuleList = TObjectList<TNexusScriptSourceModule>;

  TNexusScriptSourceDialect = class
  private
    FPath: string;
    FSourceRange: TNexusScriptRange;
    FPathRange: TNexusScriptRange;
  public
    property Path: string read FPath write FPath;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property PathRange: TNexusScriptRange read FPathRange write FPathRange;
  end;

  TNexusScriptSourceInclude = class
  private
    FPath: string;
    FRecursive: Boolean;
    FSourceRange: TNexusScriptRange;
    FPathRange: TNexusScriptRange;
  public
    property Path: string read FPath write FPath;
    property Recursive: Boolean read FRecursive write FRecursive;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
    property PathRange: TNexusScriptRange read FPathRange write FPathRange;
  end;

  TNexusScriptSourceIncludeList = TObjectList<TNexusScriptSourceInclude>;

  TNexusScriptSourceData = class
  private
    FName: string;
    FPath: string;
    FSourceRange: TNexusScriptRange;
  public
    property Name: string read FName write FName;
    property Path: string read FPath write FPath;
    property SourceRange: TNexusScriptRange read FSourceRange write FSourceRange;
  end;

  TNexusScriptSourceDataList = TObjectList<TNexusScriptSourceData>;

  TNexusScriptSourceDocument = class
  private
    FSourceName: string;
    FDefinitions: TNexusScriptSourceDefinitionList;
    FModules: TNexusScriptSourceModuleList;
    FIncludes: TNexusScriptSourceIncludeList;
    FDataSources: TNexusScriptSourceDataList;
    FDialect: TNexusScriptSourceDialect;
    procedure SetDialect(AValue: TNexusScriptSourceDialect);
  public
    constructor Create(const ASourceName: string);
    destructor Destroy; override;
    function FindDefinition(const AName: string): TNexusScriptSourceDefinition;
    function FindDataSource(const AName: string): TNexusScriptSourceData;
    property SourceName: string read FSourceName;
    property Definitions: TNexusScriptSourceDefinitionList read FDefinitions;
    property Modules: TNexusScriptSourceModuleList read FModules;
    property Includes: TNexusScriptSourceIncludeList read FIncludes;
    property DataSources: TNexusScriptSourceDataList read FDataSources;
    property Dialect: TNexusScriptSourceDialect read FDialect write SetDialect;
  end;

  TNexusScriptCompiledValue = class
  private
    // Borrowed from the imported root's owned ImportContext.
    FImportBinding: TNexusScriptCompiledValue;
    FKind: TNexusScriptValueKind;
    FSourceText: string;
    FItems: TNexusScriptCompiledValueList;
    FSourceRange: TNexusScriptRange;
    FResolvedDefinition: TNexusScriptCompiledDefinition;
    FResolvedProperty: TNexusScriptCompiledProperty;
    FEffectiveText: string;
    FHasEffectiveText: Boolean;
    FStructuralDefinition: TNexusScriptCompiledDefinition;
    FEntryName: string;
    FEffectiveName: string;
    FOriginalDefinitionName: string;
    FInlineSourceDefinition: TNexusScriptSourceDefinition;
    FResolvedValue: TNexusScriptCompiledValue;
    FEffectiveValue: TNexusScriptCompiledValue;
    FCompositionContributors: TNexusScriptCompiledValueList;
    FEvaluationState: TNexusScriptValueEvaluationState;
    FArrayPreparationState: TNexusScriptArrayPreparationState;
    FReferenceRanges: TNexusScriptRangeList;
  public
    constructor Create(AKind: TNexusScriptValueKind;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindNamedItem(const AName: string): TNexusScriptCompiledValue;
    function SemanticValue: TNexusScriptCompiledValue;
    function DefinitionValue: TNexusScriptCompiledDefinition;
    property ImportBinding: TNexusScriptCompiledValue read FImportBinding write FImportBinding;
    property Kind: TNexusScriptValueKind read FKind write FKind;
    property SourceText: string read FSourceText write FSourceText;
    property Items: TNexusScriptCompiledValueList read FItems;
    property SourceRange: TNexusScriptRange read FSourceRange;
    property ResolvedDefinition: TNexusScriptCompiledDefinition
      read FResolvedDefinition write FResolvedDefinition;
    property ResolvedProperty: TNexusScriptCompiledProperty
      read FResolvedProperty write FResolvedProperty;
    property EffectiveText: string read FEffectiveText write FEffectiveText;
    property HasEffectiveText: Boolean read FHasEffectiveText write FHasEffectiveText;
    property StructuralDefinition: TNexusScriptCompiledDefinition
      read FStructuralDefinition write FStructuralDefinition;
    property EntryName: string read FEntryName write FEntryName;
    property EffectiveName: string read FEffectiveName write FEffectiveName;
    property OriginalDefinitionName: string read FOriginalDefinitionName
      write FOriginalDefinitionName;
    property InlineSourceDefinition: TNexusScriptSourceDefinition
      read FInlineSourceDefinition write FInlineSourceDefinition;
    property ResolvedValue: TNexusScriptCompiledValue
      read FResolvedValue write FResolvedValue;
    property EffectiveValue: TNexusScriptCompiledValue
      read FEffectiveValue write FEffectiveValue;
    property CompositionContributors: TNexusScriptCompiledValueList
      read FCompositionContributors;
    property EvaluationState: TNexusScriptValueEvaluationState
      read FEvaluationState write FEvaluationState;
    property ArrayPreparationState: TNexusScriptArrayPreparationState
      read FArrayPreparationState write FArrayPreparationState;
    property ReferenceRanges: TNexusScriptRangeList read FReferenceRanges;
  end;

  TNexusScriptCompiledProperty = class
  private
    FName: string;
    FValue: TNexusScriptCompiledValue;
    FSourceRange: TNexusScriptRange;
    FContributorRanges: TNexusScriptRangeList;
    FResolving: Boolean;
  public
    constructor Create(const AName: string; AValue: TNexusScriptCompiledValue;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Name: string read FName;
    property Value: TNexusScriptCompiledValue read FValue;
    property SourceRange: TNexusScriptRange read FSourceRange;
    property ContributorRanges: TNexusScriptRangeList read FContributorRanges;
    property Resolving: Boolean read FResolving write FResolving;
  end;

  TNexusScriptCompiledDefinition = class
  private
    FImportContext: TNexusScriptImportContext;
    FKind: string;
    FName: string;
    FProperties: TNexusScriptCompiledPropertyList;
    FChildren: TNexusScriptCompiledDefinitionList;
    FTargets: TNexusScriptTargetList;
    FSourceDefinition: TNexusScriptSourceDefinition;
    FParent: TNexusScriptCompiledDefinition;
    FSourceRange: TNexusScriptRange;
    FComposing: Boolean;
    FComposed: Boolean;
    FImportedRoot: Boolean;
  public
    constructor Create(const AKind, AName: string;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    function FindProperty(const AName: string): TNexusScriptCompiledProperty;
    function FindChild(const AName: string): TNexusScriptCompiledDefinition;
    property ImportContext: TNexusScriptImportContext read FImportContext write FImportContext;
    property Kind: string read FKind;
    property Name: string read FName write FName;
    property Properties: TNexusScriptCompiledPropertyList read FProperties;
    property Children: TNexusScriptCompiledDefinitionList read FChildren;
    property Targets: TNexusScriptTargetList read FTargets;
    property SourceDefinition: TNexusScriptSourceDefinition
      read FSourceDefinition write FSourceDefinition;
    property Parent: TNexusScriptCompiledDefinition read FParent write FParent;
    property SourceRange: TNexusScriptRange read FSourceRange;
    property Composing: Boolean read FComposing write FComposing;
    property Composed: Boolean read FComposed write FComposed;
    property ImportedRoot: Boolean read FImportedRoot write FImportedRoot;
  end;

  // Owns private imported binding data; never part of the public definition view.
  TNexusScriptImportContext = class
  private
    FDefinitions: TNexusScriptCompiledDefinitionList;
    FProperties: TNexusScriptCompiledPropertyList;
    FValues: TNexusScriptCompiledValueList;
  public
    constructor Create;
    destructor Destroy; override;
    property Definitions: TNexusScriptCompiledDefinitionList read FDefinitions;
    property Properties: TNexusScriptCompiledPropertyList read FProperties;
    property Values: TNexusScriptCompiledValueList read FValues;
  end;

  TNexusScriptCompiledDocument = class
  private
    FIncludedDocuments: TList<TNexusScriptCompiledDocument>;
    FSourceName: string;
    FCompiledAt: TDateTime;
    FDefinitions: TNexusScriptCompiledDefinitionList;
    FDialectPath: string;
    FDialectSourceRange: TNexusScriptRange;
    FDialectSourceName: string;
    FDialectDocument: TNexusScriptCompiledDocument;
  public
    constructor Create(const ASourceName: string; ACompiledAt: TDateTime);
    destructor Destroy; override;
    function FindDefinition(const AName: string): TNexusScriptCompiledDefinition;
    procedure SetDialect(const APath, ASourceName: string;
      const ASourceRange: TNexusScriptRange;
      ADocument: TNexusScriptCompiledDocument);
    property SourceName: string read FSourceName;
    // UTC start time, captured once for this document compilation.
    property CompiledAt: TDateTime read FCompiledAt;
    property Definitions: TNexusScriptCompiledDefinitionList read FDefinitions;
    property IncludedDocuments: TList<TNexusScriptCompiledDocument> read FIncludedDocuments;
    property DialectPath: string read FDialectPath;
    property DialectSourceRange: TNexusScriptRange read FDialectSourceRange;
    property DialectSourceName: string read FDialectSourceName;
    property DialectDocument: TNexusScriptCompiledDocument read FDialectDocument;
  end;

implementation

constructor TNexusScriptTarget.Create(const AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FName := AName;
  FSourceRange := ASourceRange;
  FNameRange := ASourceRange;
  FValues := TStringList.Create;
  FValues.CaseSensitive := True;
  FValueRanges := TNexusScriptRangeList.Create;
end;

destructor TNexusScriptTarget.Destroy;
begin
  FValueRanges.Free;
  FValues.Free;
  inherited Destroy;
end;

function TNexusScriptTarget.Clone: TNexusScriptTarget;
begin
  Result := TNexusScriptTarget.Create(FName, FSourceRange);
  Result.Values.AddStrings(FValues);
  Result.FNameRange := FNameRange;
  Result.FValueRanges.AddRange(FValueRanges);
end;

function TNexusScriptTarget.HasValue(const AValue: string): Boolean;
begin
  Result := FValues.IndexOf(AValue) >= 0;
end;

function TNexusScriptTargetList.Find(
  const AName: string): TNexusScriptTarget;
var
  lTarget: TNexusScriptTarget;
begin
  Result := nil;
  for lTarget in Self do
    if lTarget.Name = AName then
      Exit(lTarget);
end;

procedure TNexusScriptTargetList.Assign(ASource: TNexusScriptTargetList);
var
  lTarget: TNexusScriptTarget;
begin
  Clear;
  for lTarget in ASource do
    Add(lTarget.Clone);
end;

constructor TNexusScriptSelectedTarget.Create(
  const AName, AValue: string);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
end;

constructor TNexusScriptTargetSelection.Create;
begin
  inherited Create;
  FItems := TObjectList<TNexusScriptSelectedTarget>.Create(True);
end;

destructor TNexusScriptTargetSelection.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TNexusScriptTargetSelection.Add(const AName, AValue: string);
begin
  if Find(AName) <> nil then
    raise EArgumentException.CreateFmt(
      'Target kind %s already has a selected value.', [AName]);
  FItems.Add(TNexusScriptSelectedTarget.Create(AName, AValue));
end;

procedure TNexusScriptTargetSelection.Assign(
  ASource: TNexusScriptTargetSelection);
var
  lTarget: TNexusScriptSelectedTarget;
begin
  FItems.Clear;
  if ASource = nil then
    Exit;
  for lTarget in ASource.FItems do
    FItems.Add(TNexusScriptSelectedTarget.Create(lTarget.Name,
      lTarget.Value));
end;

function TNexusScriptTargetSelection.Find(
  const AName: string): TNexusScriptSelectedTarget;
var
  lTarget: TNexusScriptSelectedTarget;
begin
  Result := nil;
  for lTarget in FItems do
    if lTarget.Name = AName then
      Exit(lTarget);
end;

procedure TNexusScriptTargetSelection.SetValue(
  const AName, AValue: string);
var
  lTarget: TNexusScriptSelectedTarget;
begin
  lTarget := Find(AName);
  if lTarget = nil then
    FItems.Add(TNexusScriptSelectedTarget.Create(AName, AValue))
  else
    lTarget.FValue := AValue;
end;

function TNexusScriptTargetSelection.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TNexusScriptTargetSelection.GetItem(
  AIndex: Integer): TNexusScriptSelectedTarget;
begin
  Result := FItems[AIndex];
end;

constructor TNexusScriptDiagnostic.Create(const ACode, AMessageText: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FCode := ACode;
  FMessageText := AMessageText;
  FSourceRange := ASourceRange;
end;

constructor TNexusScriptSourceValue.Create(AKind: TNexusScriptValueKind;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FKind := AKind;
  FSourceRange := ASourceRange;
  FItems := TNexusScriptSourceValueList.Create(True);
  FReferenceRanges := TNexusScriptRangeList.Create;
end;

destructor TNexusScriptSourceValue.Destroy;
begin
  FReferenceRanges.Free;
  FInlineDefinition.Free;
  FItems.Free;
  inherited Destroy;
end;

function TNexusScriptSourceValue.FindNamedItem(
  const AName: string): TNexusScriptSourceValue;
var
  lItem: TNexusScriptSourceValue;
begin
  Result := nil;
  for lItem in FItems do
    if SameText(lItem.EntryName, AName) then
      Exit(lItem);
end;

constructor TNexusScriptSourceProperty.Create(const AName: string;
  AValue: TNexusScriptSourceValue; const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
  FSourceRange := ASourceRange;
end;

destructor TNexusScriptSourceProperty.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

constructor TNexusScriptSourceDefinition.Create(const AKind, AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FKind := AKind;
  FName := AName;
  FSourceRange := ASourceRange;
  FProperties := TNexusScriptSourcePropertyList.Create(True);
  FChildren := TNexusScriptSourceDefinitionList.Create(True);
  FCompositionSelectors := TStringList.Create;
  FCompositionSelectorRanges := TNexusScriptRangeList.Create;
  FCompositionTargetRanges := TNexusScriptRangeList.Create;
  FTargets := TNexusScriptTargetList.Create(True);
end;

destructor TNexusScriptSourceDefinition.Destroy;
begin
  FCompositionTargetRanges.Free;
  FCompositionSelectorRanges.Free;
  FTargets.Free;
  FCompositionSelectors.Free;
  FChildren.Free;
  FProperties.Free;
  inherited Destroy;
end;

function TNexusScriptSourceDefinition.FindProperty(
  const AName: string): TNexusScriptSourceProperty;
var
  lProperty: TNexusScriptSourceProperty;
begin
  Result := nil;
  for lProperty in FProperties do
    if SameText(lProperty.Name, AName) then
      Exit(lProperty);
end;

function TNexusScriptSourceDefinition.FindChild(
  const AName: string): TNexusScriptSourceDefinition;
var
  lDefinition: TNexusScriptSourceDefinition;
begin
  Result := nil;
  for lDefinition in FChildren do
    if SameText(lDefinition.Name, AName) then
      Exit(lDefinition);
end;

constructor TNexusScriptSourceDocument.Create(const ASourceName: string);
begin
  inherited Create;
  FSourceName := ASourceName;
  FDefinitions := TNexusScriptSourceDefinitionList.Create(True);
  FModules := TNexusScriptSourceModuleList.Create(True);
  FIncludes := TNexusScriptSourceIncludeList.Create(True);
  FDataSources := TNexusScriptSourceDataList.Create(True);
end;

destructor TNexusScriptSourceDocument.Destroy;
begin
  FDialect.Free;
  FDataSources.Free;
  FIncludes.Free;
  FModules.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

procedure TNexusScriptSourceDocument.SetDialect(
  AValue: TNexusScriptSourceDialect);
begin
  if FDialect = AValue then Exit;
  FDialect.Free;
  FDialect := AValue;
end;

function TNexusScriptSourceDocument.FindDefinition(
  const AName: string): TNexusScriptSourceDefinition;
var
  lDefinition: TNexusScriptSourceDefinition;
begin
  Result := nil;
  for lDefinition in FDefinitions do
    if SameText(lDefinition.Name, AName) then
      Exit(lDefinition);
end;

function TNexusScriptSourceDocument.FindDataSource(
  const AName: string): TNexusScriptSourceData;
var
  lDataSource: TNexusScriptSourceData;
begin
  Result := nil;
  for lDataSource in FDataSources do
    if SameText(lDataSource.Name, AName) then
      Exit(lDataSource);
end;

constructor TNexusScriptCompiledValue.Create(AKind: TNexusScriptValueKind;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FKind := AKind;
  FSourceRange := ASourceRange;
  FItems := TNexusScriptCompiledValueList.Create(True);
  FCompositionContributors := TNexusScriptCompiledValueList.Create(True);
  FReferenceRanges := TNexusScriptRangeList.Create;
end;

destructor TNexusScriptCompiledValue.Destroy;
begin
  FReferenceRanges.Free;
  FEffectiveValue.Free;
  FCompositionContributors.Free;
  FStructuralDefinition.Free;
  FItems.Free;
  inherited Destroy;
end;

function TNexusScriptCompiledValue.FindNamedItem(
  const AName: string): TNexusScriptCompiledValue;
var
  lItem: TNexusScriptCompiledValue;
begin
  Result := nil;
  for lItem in FItems do
    if SameText(lItem.EffectiveName, AName) then
      Exit(lItem);
end;

function TNexusScriptCompiledValue.SemanticValue: TNexusScriptCompiledValue;
begin
  Result := Self;
  while True do
    if (Result.Kind = nsvReference) and (Result.ResolvedValue <> nil) then
      Result := Result.ResolvedValue
    else if (Result.Kind = nsvReference) and (Result.ResolvedProperty <> nil) then
      Result := Result.ResolvedProperty.Value
    else if Result.EffectiveValue <> nil then
      Result := Result.EffectiveValue
    else
      Exit;
end;

function TNexusScriptCompiledValue.DefinitionValue: TNexusScriptCompiledDefinition;
var
  lValue: TNexusScriptCompiledValue;
begin
  lValue := SemanticValue;
  Result := lValue.StructuralDefinition;
  if Result = nil then Result := lValue.ResolvedDefinition;
end;

constructor TNexusScriptCompiledProperty.Create(const AName: string;
  AValue: TNexusScriptCompiledValue; const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
  FSourceRange := ASourceRange;
  FContributorRanges := TNexusScriptRangeList.Create;
  if ASourceRange.SourceName <> '' then
    FContributorRanges.Add(ASourceRange);
end;

destructor TNexusScriptCompiledProperty.Destroy;
begin
  FContributorRanges.Free;
  FValue.Free;
  inherited Destroy;
end;

constructor TNexusScriptCompiledDefinition.Create(const AKind, AName: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FKind := AKind;
  FName := AName;
  FSourceRange := ASourceRange;
  FProperties := TNexusScriptCompiledPropertyList.Create(True);
  FChildren := TNexusScriptCompiledDefinitionList.Create(True);
  FTargets := TNexusScriptTargetList.Create(True);
end;

destructor TNexusScriptCompiledDefinition.Destroy;
begin
  FImportContext.Free;
  FTargets.Free;
  FChildren.Free;
  FProperties.Free;
  inherited Destroy;
end;

function TNexusScriptCompiledDefinition.FindProperty(
  const AName: string): TNexusScriptCompiledProperty;
var
  lProperty: TNexusScriptCompiledProperty;
begin
  Result := nil;
  for lProperty in FProperties do
    if SameText(lProperty.Name, AName) then
      Exit(lProperty);
end;

function TNexusScriptCompiledDefinition.FindChild(
  const AName: string): TNexusScriptCompiledDefinition;
var
  lDefinition: TNexusScriptCompiledDefinition;
begin
  Result := nil;
  for lDefinition in FChildren do
    if SameText(lDefinition.Name, AName) then
      Exit(lDefinition);
end;

constructor TNexusScriptImportContext.Create;
begin
  inherited Create;
  FDefinitions := TNexusScriptCompiledDefinitionList.Create(True);
  FProperties := TNexusScriptCompiledPropertyList.Create(True);
  FValues := TNexusScriptCompiledValueList.Create(True);
end;

destructor TNexusScriptImportContext.Destroy;
begin
  FValues.Free;
  FProperties.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

constructor TNexusScriptCompiledDocument.Create(const ASourceName: string;
  ACompiledAt: TDateTime);
begin
  inherited Create;
  FSourceName := ASourceName;
  FCompiledAt := ACompiledAt;
  FDefinitions := TNexusScriptCompiledDefinitionList.Create(True);
  FIncludedDocuments := TList<TNexusScriptCompiledDocument>.Create;
end;

destructor TNexusScriptCompiledDocument.Destroy;
begin
  FIncludedDocuments.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

function TNexusScriptCompiledDocument.FindDefinition(
  const AName: string): TNexusScriptCompiledDefinition;
var
  lDefinition: TNexusScriptCompiledDefinition;
begin
  Result := nil;
  for lDefinition in FDefinitions do
    if SameText(lDefinition.Name, AName) then
      Exit(lDefinition);
end;

procedure TNexusScriptCompiledDocument.SetDialect(const APath,
  ASourceName: string; const ASourceRange: TNexusScriptRange;
  ADocument: TNexusScriptCompiledDocument);
begin
  FDialectPath := APath;
  FDialectSourceRange := ASourceRange;
  FDialectSourceName := ASourceName;
  FDialectDocument := ADocument;
end;

end.

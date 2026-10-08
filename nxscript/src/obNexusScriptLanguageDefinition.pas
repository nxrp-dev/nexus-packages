(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptLanguageDefinition;

{$mode delphi}{$H+}

interface

uses
  Classes, Generics.Collections, tpNexusScript, obNexusScriptModel,
  obNexusScriptDefinitionView;

const
  cNexusScriptUnbounded = -1;

type
  TNSUnknownPolicy = (nupAllow, nupReject);
  TNSNamePolicy = (nnpOptional, nnpRequired, nnpForbidden);
  TNSSourceForm = (nsfText, nsfArray, nsfReference,
    nsfTextComposition, nsfInlineDefinition);
  TNSSourceForms = set of TNSSourceForm;
  TNSEffectiveCategory = (necText, necArray, necDefinition);
  TNSEffectiveCategories = set of TNSEffectiveCategory;
  TNSScalarKind = (nskNone, nskText, nskInteger, nskBoolean);
  TNSReferenceTarget = (nrtProperty, nrtDefinition);
  TNSReferenceTargets = set of TNSReferenceTarget;

  TNSLanguageDiagnostic = class
  private
    FCode: string;
    FMessageText: string;
    FSourceRange: TNexusScriptRange;
  public
    constructor Create(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    property Code: string read FCode;
    property MessageText: string read FMessageText;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNSArrayRule = class
  private
    FMinimum, FMaximum: Integer;
    FNamePolicy: TNSNamePolicy;
    FEntrySourceForms: TNSSourceForms;
    FHasEntrySourceForms: Boolean;
    FEntryCategories: TNSEffectiveCategories;
    FHasEntryCategories: Boolean;
    FDefinitionKinds, FAllowedValues: TStringList;
    FMixed: Boolean;
    function GetDefinitionKindCount: Integer;
    function GetDefinitionKind(AIndex: Integer): string;
    function GetAllowedValueCount: Integer;
    function GetAllowedValue(AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function HasDefinitionKind(const AKind: string): Boolean;
    function HasAllowedValue(const AValue: string): Boolean;
    property Minimum: Integer read FMinimum;
    property Maximum: Integer read FMaximum;
    property NamePolicy: TNSNamePolicy read FNamePolicy;
    property EntrySourceForms: TNSSourceForms read FEntrySourceForms;
    property HasEntrySourceForms: Boolean read FHasEntrySourceForms;
    property EntryCategories: TNSEffectiveCategories read FEntryCategories;
    property HasEntryCategories: Boolean read FHasEntryCategories;
    property DefinitionKindCount: Integer read GetDefinitionKindCount;
    property DefinitionKinds[AIndex: Integer]: string read GetDefinitionKind;
    property AllowedValueCount: Integer read GetAllowedValueCount;
    property AllowedValues[AIndex: Integer]: string read GetAllowedValue;
    property Mixed: Boolean read FMixed;
  end;

  TNSReferenceRule = class
  private
    FTargets: TNSReferenceTargets;
    FDefinitionKinds: TStringList;
    function GetDefinitionKindCount: Integer;
    function GetDefinitionKind(AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function HasDefinitionKind(const AKind: string): Boolean;
    property Targets: TNSReferenceTargets read FTargets;
    property DefinitionKindCount: Integer read GetDefinitionKindCount;
    property DefinitionKinds[AIndex: Integer]: string read GetDefinitionKind;
  end;

  TNSValueRule = class
  private
    FSourceForms: TNSSourceForms;
    FHasSourceForms: Boolean;
    FEffectiveCategories: TNSEffectiveCategories;
    FHasEffectiveCategories: Boolean;
    FScalarKind: TNSScalarKind;
    FAllowedValues: TStringList;
    FArrayRule: TNSArrayRule;
    FReferenceRule: TNSReferenceRule;
    function GetAllowedValueCount: Integer;
    function GetAllowedValue(AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function HasAllowedValue(const AValue: string): Boolean;
    property SourceForms: TNSSourceForms read FSourceForms;
    property HasSourceForms: Boolean read FHasSourceForms;
    property EffectiveCategories: TNSEffectiveCategories read FEffectiveCategories;
    property HasEffectiveCategories: Boolean read FHasEffectiveCategories;
    property ScalarKind: TNSScalarKind read FScalarKind;
    property AllowedValueCount: Integer read GetAllowedValueCount;
    property AllowedValues[AIndex: Integer]: string read GetAllowedValue;
    property ArrayRule: TNSArrayRule read FArrayRule;
    property ReferenceRule: TNSReferenceRule read FReferenceRule;
  end;

  TNSPropertyRule = class
  private
    FName: string;
    FRequired: Boolean;
    FValueRule: TNSValueRule;
    FSourceRange: TNexusScriptRange;
  public
    destructor Destroy; override;
    property Name: string read FName;
    property Required: Boolean read FRequired;
    property ValueRule: TNSValueRule read FValueRule;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNSChildRule = class
  private
    FName: string;
    FKinds: TStringList;
    FMinimum, FMaximum: Integer;
    FSourceRange: TNexusScriptRange;
    function GetKindCount: Integer;
    function GetKind(AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function HasKind(const AKind: string): Boolean;
    property Name: string read FName;
    property KindCount: Integer read GetKindCount;
    property Kinds[AIndex: Integer]: string read GetKind;
    property Minimum: Integer read FMinimum;
    property Maximum: Integer read FMaximum;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNSDefinitionRule = class
  private
    FKindName: string;
    FRootAllowed: Boolean;
    FParents: TStringList;
    FUnknownProperties, FUnknownChildren: TNSUnknownPolicy;
    FHasUnknownChildren, FHasChildren: Boolean;
    FPropertyRules: TObjectList<TNSPropertyRule>;
    FChildRules: TObjectList<TNSChildRule>;
    FSourceRange: TNexusScriptRange;
    function GetParentCount: Integer;
    function GetParent(AIndex: Integer): string;
    function GetPropertyRuleCount: Integer;
    function GetPropertyRule(AIndex: Integer): TNSPropertyRule;
    function GetChildRuleCount: Integer;
    function GetChildRule(AIndex: Integer): TNSChildRule;
  public
    constructor Create;
    destructor Destroy; override;
    function HasParent(const AKind: string): Boolean;
    function FindPropertyRule(const AName: string): TNSPropertyRule;
    function FindChildRule(const AKind: string): TNSChildRule;
    property KindName: string read FKindName;
    property RootAllowed: Boolean read FRootAllowed;
    property ParentCount: Integer read GetParentCount;
    property Parents[AIndex: Integer]: string read GetParent;
    property UnknownProperties: TNSUnknownPolicy read FUnknownProperties;
    property UnknownChildren: TNSUnknownPolicy read FUnknownChildren;
    property HasUnknownChildren: Boolean read FHasUnknownChildren;
    property HasChildren: Boolean read FHasChildren;
    property PropertyRuleCount: Integer read GetPropertyRuleCount;
    property PropertyRules[AIndex: Integer]: TNSPropertyRule read GetPropertyRule;
    property ChildRuleCount: Integer read GetChildRuleCount;
    property ChildRules[AIndex: Integer]: TNSChildRule read GetChildRule;
    property SourceRange: TNexusScriptRange read FSourceRange;
  end;

  TNexusScriptLanguageDefinition = class
  private
    FUnknownDefinitions: TNSUnknownPolicy;
    FDefinitionRules: TObjectList<TNSDefinitionRule>;
    FDiagnostics: TObjectList<TNSLanguageDiagnostic>;
    procedure AddDiagnostic(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    function NormalizeDefinition(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSDefinitionRule): Boolean;
    function NormalizeProperty(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSPropertyRule): Boolean;
    function NormalizeChild(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSChildRule): Boolean;
    function NormalizeValue(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSValueRule): Boolean;
    function NormalizeArray(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSArrayRule): Boolean;
    function NormalizeReference(ADefinition: TNexusScriptCompiledDefinition;
      out ARule: TNSReferenceRule): Boolean;
    function FindPropertyRule(ARule: TNSDefinitionRule;
      const AName: string): TNSPropertyRule;
    function FindChildRule(ARule: TNSDefinitionRule;
      const AKind: string): TNSChildRule;
    function GetDefinitionRuleCount: Integer;
    function GetDefinitionRule(AIndex: Integer): TNSDefinitionRule;
    function GetDiagnosticCount: Integer;
    function GetDiagnostic(AIndex: Integer): TNSLanguageDiagnostic;
  public
    constructor Create;
    destructor Destroy; override;
    function Normalize(ADocument: TNexusScriptCompiledDocument): Boolean;
    function FindDefinitionRule(const AKind: string): TNSDefinitionRule;
    property UnknownDefinitions: TNSUnknownPolicy read FUnknownDefinitions;
    property DefinitionRuleCount: Integer read GetDefinitionRuleCount;
    property DefinitionRules[AIndex: Integer]: TNSDefinitionRule
      read GetDefinitionRule;
    property DiagnosticCount: Integer read GetDiagnosticCount;
    property Diagnostics[AIndex: Integer]: TNSLanguageDiagnostic
      read GetDiagnostic;
  end;

implementation

uses
  SysUtils;

constructor TNSLanguageDiagnostic.Create(const ACode, AMessageText: string;
  const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FCode := ACode;
  FMessageText := AMessageText;
  FSourceRange := ASourceRange;
end;

constructor TNSArrayRule.Create;
begin
  inherited Create;
  FMaximum := cNexusScriptUnbounded;
  FNamePolicy := nnpOptional;
  FMixed := True;
  FDefinitionKinds := TStringList.Create;
  FDefinitionKinds.CaseSensitive := False;
  FAllowedValues := TStringList.Create;
  FAllowedValues.CaseSensitive := False;
end;

destructor TNSArrayRule.Destroy;
begin
  FAllowedValues.Free;
  FDefinitionKinds.Free;
  inherited Destroy;
end;

function TNSArrayRule.GetDefinitionKindCount: Integer;
begin
  Result := FDefinitionKinds.Count;
end;

function TNSArrayRule.GetDefinitionKind(AIndex: Integer): string;
begin
  Result := FDefinitionKinds[AIndex];
end;

function TNSArrayRule.GetAllowedValueCount: Integer;
begin
  Result := FAllowedValues.Count;
end;

function TNSArrayRule.GetAllowedValue(AIndex: Integer): string;
begin
  Result := FAllowedValues[AIndex];
end;

function TNSArrayRule.HasDefinitionKind(const AKind: string): Boolean;
begin
  Result := FDefinitionKinds.IndexOf(AKind) >= 0;
end;

function TNSArrayRule.HasAllowedValue(const AValue: string): Boolean;
begin
  Result := FAllowedValues.IndexOf(AValue) >= 0;
end;

constructor TNSReferenceRule.Create;
begin
  inherited Create;
  FDefinitionKinds := TStringList.Create;
  FDefinitionKinds.CaseSensitive := False;
end;

destructor TNSReferenceRule.Destroy;
begin
  FDefinitionKinds.Free;
  inherited Destroy;
end;

function TNSReferenceRule.GetDefinitionKindCount: Integer;
begin
  Result := FDefinitionKinds.Count;
end;

function TNSReferenceRule.GetDefinitionKind(AIndex: Integer): string;
begin
  Result := FDefinitionKinds[AIndex];
end;

function TNSReferenceRule.HasDefinitionKind(const AKind: string): Boolean;
begin
  Result := FDefinitionKinds.IndexOf(AKind) >= 0;
end;

constructor TNSValueRule.Create;
begin
  inherited Create;
  FAllowedValues := TStringList.Create;
  FAllowedValues.CaseSensitive := False;
end;

destructor TNSValueRule.Destroy;
begin
  FReferenceRule.Free;
  FArrayRule.Free;
  FAllowedValues.Free;
  inherited Destroy;
end;

function TNSValueRule.GetAllowedValueCount: Integer;
begin
  Result := FAllowedValues.Count;
end;

function TNSValueRule.GetAllowedValue(AIndex: Integer): string;
begin
  Result := FAllowedValues[AIndex];
end;

function TNSValueRule.HasAllowedValue(const AValue: string): Boolean;
begin
  Result := FAllowedValues.IndexOf(AValue) >= 0;
end;

destructor TNSPropertyRule.Destroy;
begin
  FValueRule.Free;
  inherited Destroy;
end;

constructor TNSChildRule.Create;
begin
  inherited Create;
  FMaximum := cNexusScriptUnbounded;
  FKinds := TStringList.Create;
  FKinds.CaseSensitive := False;
end;

destructor TNSChildRule.Destroy;
begin
  FKinds.Free;
  inherited Destroy;
end;

function TNSChildRule.GetKindCount: Integer;
begin
  Result := FKinds.Count;
end;

function TNSChildRule.GetKind(AIndex: Integer): string;
begin
  Result := FKinds[AIndex];
end;

function TNSChildRule.HasKind(const AKind: string): Boolean;
begin
  Result := FKinds.IndexOf(AKind) >= 0;
end;

constructor TNSDefinitionRule.Create;
begin
  inherited Create;
  FParents := TStringList.Create;
  FParents.CaseSensitive := False;
  FUnknownProperties := nupReject;
  FUnknownChildren := nupAllow;
  FPropertyRules := TObjectList<TNSPropertyRule>.Create(True);
  FChildRules := TObjectList<TNSChildRule>.Create(True);
end;

destructor TNSDefinitionRule.Destroy;
begin
  FChildRules.Free;
  FPropertyRules.Free;
  FParents.Free;
  inherited Destroy;
end;

function TNSDefinitionRule.GetParentCount: Integer;
begin
  Result := FParents.Count;
end;

function TNSDefinitionRule.GetParent(AIndex: Integer): string;
begin
  Result := FParents[AIndex];
end;

function TNSDefinitionRule.GetPropertyRuleCount: Integer;
begin
  Result := FPropertyRules.Count;
end;

function TNSDefinitionRule.GetPropertyRule(AIndex: Integer): TNSPropertyRule;
begin
  Result := FPropertyRules[AIndex];
end;

function TNSDefinitionRule.GetChildRuleCount: Integer;
begin
  Result := FChildRules.Count;
end;

function TNSDefinitionRule.GetChildRule(AIndex: Integer): TNSChildRule;
begin
  Result := FChildRules[AIndex];
end;

function TNSDefinitionRule.HasParent(const AKind: string): Boolean;
begin
  Result := FParents.IndexOf(AKind) >= 0;
end;

function TNSDefinitionRule.FindPropertyRule(const AName: string): TNSPropertyRule;
var
  lRule: TNSPropertyRule;
begin
  Result := nil;
  for lRule in FPropertyRules do
    if SameText(lRule.Name, AName) then Exit(lRule);
end;

function TNSDefinitionRule.FindChildRule(const AKind: string): TNSChildRule;
var
  lRule: TNSChildRule;
begin
  Result := nil;
  for lRule in FChildRules do
    if lRule.HasKind(AKind) then Exit(lRule);
end;

constructor TNexusScriptLanguageDefinition.Create;
begin
  inherited Create;
  FUnknownDefinitions := nupReject;
  FDefinitionRules := TObjectList<TNSDefinitionRule>.Create(True);
  FDiagnostics := TObjectList<TNSLanguageDiagnostic>.Create(True);
end;

destructor TNexusScriptLanguageDefinition.Destroy;
begin
  FDiagnostics.Free;
  FDefinitionRules.Free;
  inherited Destroy;
end;

procedure TNexusScriptLanguageDefinition.AddDiagnostic(const ACode,
  AMessageText: string; const ASourceRange: TNexusScriptRange);
begin
  FDiagnostics.Add(TNSLanguageDiagnostic.Create(ACode, AMessageText,
    ASourceRange));
end;

function TNexusScriptLanguageDefinition.GetDefinitionRuleCount: Integer;
begin
  Result := FDefinitionRules.Count;
end;

function TNexusScriptLanguageDefinition.GetDefinitionRule(
  AIndex: Integer): TNSDefinitionRule;
begin
  Result := FDefinitionRules[AIndex];
end;

function TNexusScriptLanguageDefinition.GetDiagnosticCount: Integer;
begin
  Result := FDiagnostics.Count;
end;

function TNexusScriptLanguageDefinition.GetDiagnostic(
  AIndex: Integer): TNSLanguageDiagnostic;
begin
  Result := FDiagnostics[AIndex];
end;

function EffectiveValue(AValue: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
begin
  Result := AValue;
  if (AValue <> nil) and (AValue.EffectiveValue <> nil) then
    Result := AValue.EffectiveValue;
end;

function PropertyText(ADefinition: TNexusScriptCompiledDefinition;
  const AName: string; out AText: string): Boolean;
var
  lProperty: TNexusScriptCompiledProperty;
  lValue: TNexusScriptCompiledValue;
begin
  Result := False;
  AText := '';
  lProperty := ADefinition.FindProperty(AName);
  if lProperty = nil then
    Exit;
  lValue := EffectiveValue(lProperty.Value);
  if not lValue.HasEffectiveText then
    Exit;
  AText := lValue.EffectiveText;
  Result := True;
end;

function PropertyArray(ADefinition: TNexusScriptCompiledDefinition;
  const AName: string): TNexusScriptCompiledValue;
var
  lProperty: TNexusScriptCompiledProperty;
begin
  Result := nil;
  lProperty := ADefinition.FindProperty(AName);
  if lProperty = nil then
    Exit;
  Result := EffectiveValue(lProperty.Value);
  if (Result = nil) or (Result.Kind <> nsvArray) then
    Result := nil;
end;

function ParseBoolean(const AText: string; out AValue: Boolean): Boolean;
begin
  Result := True;
  if SameText(AText, 'True') then
    AValue := True
  else if SameText(AText, 'False') then
    AValue := False
  else
    Result := False;
end;

function ParseNonNegativeInteger(const AText: string;
  out AValue: Integer): Boolean;
var
  lCode: Integer;
begin
  Val(AText, AValue, lCode);
  Result := (lCode = 0) and (AValue >= 0) and (IntToStr(AValue) = AText);
end;

function ParseInteger(const AText: string; out AValue: Integer): Boolean;
var
  lCode: Integer;
begin
  Val(AText, AValue, lCode);
  Result := (lCode = 0) and ((IntToStr(AValue) = AText) or
    ((AValue = 0) and (AText = '-0')));
end;

function NameIsAllowed(const AName, AAllowedNames: string): Boolean;
var
  lNames: TStringList;
begin
  lNames := TStringList.Create;
  try
    lNames.Delimiter := '|';
    lNames.StrictDelimiter := True;
    lNames.DelimitedText := AAllowedNames;
    lNames.CaseSensitive := False;
    Result := lNames.IndexOf(AName) >= 0;
  finally
    lNames.Free;
  end;
end;

function HasOnlyMembers(ADefinition: TNexusScriptCompiledDefinition;
  const AProperties, AChildren: string): Boolean;
var
  lProperty: TNexusScriptCompiledProperty;
  lChild: TNexusScriptCompiledDefinition;
begin
  for lProperty in ADefinition.Properties do
    if not NameIsAllowed(lProperty.Name, AProperties) then Exit(False);
  for lChild in ADefinition.Children do
    if not NameIsAllowed(lChild.Name, AChildren) then Exit(False);
  Result := True;
end;

function ParseUnknownPolicy(const AText: string;
  out AValue: TNSUnknownPolicy): Boolean;
begin
  Result := True;
  if SameText(AText, 'Allow') then
    AValue := nupAllow
  else if SameText(AText, 'Reject') then
    AValue := nupReject
  else
    Result := False;
end;

function AddTextItems(AValue: TNexusScriptCompiledValue;
  ATarget: TStringList): Boolean;
var
  lItem: TNexusScriptCompiledValue;
  lValue: TNexusScriptCompiledValue;
begin
  Result := AValue <> nil;
  if not Result then
    Exit;
  for lItem in AValue.Items do
  begin
    lValue := EffectiveValue(lItem);
    if not lValue.HasEffectiveText then
      Exit(False);
    if ATarget.IndexOf(lValue.EffectiveText) < 0 then
      ATarget.Add(lValue.EffectiveText);
  end;
end;

function SourceFormOf(AValue: TNexusScriptCompiledValue): TNSSourceForm;
begin
  case AValue.Kind of
    nsvArray: Result := nsfArray;
    nsvReference: Result := nsfReference;
    nsvTextComposition: Result := nsfTextComposition;
    nsvDefinition: Result := nsfInlineDefinition;
  else
    Result := nsfText;
  end;
end;

function EffectiveCategoryOf(
  AValue: TNexusScriptCompiledValue): TNSEffectiveCategory;
var
  lValue: TNexusScriptCompiledValue;
begin
  if AValue.StructuralDefinition <> nil then
    Exit(necDefinition);
  lValue := EffectiveValue(AValue);
  if lValue.StructuralDefinition <> nil then
    Exit(necDefinition);
  if lValue.Kind = nsvArray then
    Exit(necArray);
  if (AValue.ResolvedDefinition <> nil) and not AValue.HasEffectiveText then
    Exit(necDefinition);
  Result := necText;
end;

function ParseSourceForms(AValue: TNexusScriptCompiledValue;
  out AForms: TNSSourceForms): Boolean;
var
  lItem: TNexusScriptCompiledValue;
  lText: string;
begin
  AForms := [];
  Result := AValue <> nil;
  if not Result then
    Exit;
  for lItem in AValue.Items do
  begin
    if not EffectiveValue(lItem).HasEffectiveText then
      Exit(False);
    lText := EffectiveValue(lItem).EffectiveText;
    if SameText(lText, 'Text') then Include(AForms, nsfText)
    else if SameText(lText, 'Array') then Include(AForms, nsfArray)
    else if SameText(lText, 'Reference') then Include(AForms, nsfReference)
    else if SameText(lText, 'TextComposition') then Include(AForms, nsfTextComposition)
    else if SameText(lText, 'InlineDefinition') then Include(AForms, nsfInlineDefinition)
    else Exit(False);
  end;
  Result := AForms <> [];
end;

function ParseCategories(AValue: TNexusScriptCompiledValue;
  out ACategories: TNSEffectiveCategories): Boolean;
var
  lItem: TNexusScriptCompiledValue;
  lText: string;
begin
  ACategories := [];
  Result := AValue <> nil;
  if not Result then
    Exit;
  for lItem in AValue.Items do
  begin
    if not EffectiveValue(lItem).HasEffectiveText then
      Exit(False);
    lText := EffectiveValue(lItem).EffectiveText;
    if SameText(lText, 'Text') then Include(ACategories, necText)
    else if SameText(lText, 'Array') then Include(ACategories, necArray)
    else if SameText(lText, 'Definition') then Include(ACategories, necDefinition)
    else Exit(False);
  end;
  Result := ACategories <> [];
end;

function StructuralDefinition(AValue: TNexusScriptCompiledValue):
  TNexusScriptCompiledDefinition;
begin
  Result := AValue.DefinitionValue;
end;

function TNexusScriptLanguageDefinition.NormalizeArray(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSArrayRule): Boolean;
var
  lText: string;
  lValue: Integer;
  lBoolean: Boolean;
begin
  Result := False;
  ARule := TNSArrayRule.Create;
  if not HasOnlyMembers(ADefinition,
    'Minimum|Maximum|Names|EntrySourceForms|EntryEffectiveCategories|DefinitionKinds|AllowedValues|Mixed',
    '') then Exit;
  if PropertyText(ADefinition, 'Minimum', lText) then
  begin
    if not ParseNonNegativeInteger(lText, lValue) then
      Exit;
    ARule.FMinimum := lValue;
  end;
  if PropertyText(ADefinition, 'Maximum', lText) then
  begin
    if SameText(lText, 'Unbounded') then
      ARule.FMaximum := cNexusScriptUnbounded
    else
    begin
      if not ParseNonNegativeInteger(lText, lValue) then
        Exit;
      ARule.FMaximum := lValue;
    end;
  end;
  if (ARule.FMaximum <> cNexusScriptUnbounded) and (ARule.FMinimum > ARule.FMaximum) then
    Exit;
  if PropertyText(ADefinition, 'Names', lText) then
  begin
    if SameText(lText, 'Required') then ARule.FNamePolicy := nnpRequired
    else if SameText(lText, 'Optional') then ARule.FNamePolicy := nnpOptional
    else if SameText(lText, 'Forbidden') then ARule.FNamePolicy := nnpForbidden
    else Exit;
  end;
  if ADefinition.FindProperty('EntrySourceForms') <> nil then
  begin
    ARule.FHasEntrySourceForms := ParseSourceForms(
      PropertyArray(ADefinition, 'EntrySourceForms'), ARule.FEntrySourceForms);
    if not ARule.FHasEntrySourceForms then Exit;
  end;
  if ADefinition.FindProperty('EntryEffectiveCategories') <> nil then
  begin
    ARule.FHasEntryCategories := ParseCategories(
      PropertyArray(ADefinition, 'EntryEffectiveCategories'),
      ARule.FEntryCategories);
    if not ARule.FHasEntryCategories then Exit;
  end;
  if ADefinition.FindProperty('DefinitionKinds') <> nil then
    if not AddTextItems(PropertyArray(ADefinition, 'DefinitionKinds'),
      ARule.FDefinitionKinds) then Exit;
  if ADefinition.FindProperty('AllowedValues') <> nil then
  begin
    if not AddTextItems(PropertyArray(ADefinition, 'AllowedValues'),
      ARule.FAllowedValues) then Exit;
    if ARule.FAllowedValues.Count = 0 then Exit;
  end;
  if PropertyText(ADefinition, 'Mixed', lText) then
  begin
    if not ParseBoolean(lText, lBoolean) then Exit;
    ARule.FMixed := lBoolean;
  end;
  Result := True;
end;

function TNexusScriptLanguageDefinition.NormalizeReference(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSReferenceRule): Boolean;
var
  lArray: TNexusScriptCompiledValue;
  lItem: TNexusScriptCompiledValue;
  lText: string;
begin
  Result := False;
  ARule := TNSReferenceRule.Create;
  if not HasOnlyMembers(ADefinition, 'Targets|DefinitionKinds', '') then Exit;
  lArray := PropertyArray(ADefinition, 'Targets');
  if lArray = nil then Exit;
  for lItem in lArray.Items do
  begin
    if not EffectiveValue(lItem).HasEffectiveText then Exit;
    lText := EffectiveValue(lItem).EffectiveText;
    if SameText(lText, 'Property') then Include(ARule.FTargets, nrtProperty)
    else if SameText(lText, 'Definition') then Include(ARule.FTargets, nrtDefinition)
    else Exit;
  end;
  if ARule.FTargets = [] then Exit;
  if ADefinition.FindProperty('DefinitionKinds') <> nil then
    if not AddTextItems(PropertyArray(ADefinition, 'DefinitionKinds'),
      ARule.FDefinitionKinds) then Exit;
  Result := True;
end;

function TNexusScriptLanguageDefinition.NormalizeValue(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSValueRule): Boolean;
var
  lText: string;
begin
  Result := False;
  ARule := TNSValueRule.Create;
  if not HasOnlyMembers(ADefinition,
    'SourceForms|EffectiveCategories|Scalar|AllowedValues',
    'Array|Reference') then Exit;
  if (ADefinition.FindChild('Array') <> nil) and
    not SameText(ADefinition.FindChild('Array').Kind, 'Array') then Exit;
  if (ADefinition.FindChild('Reference') <> nil) and
    not SameText(ADefinition.FindChild('Reference').Kind, 'Reference') then Exit;
  if ADefinition.FindProperty('SourceForms') <> nil then
  begin
    ARule.FHasSourceForms := ParseSourceForms(
      PropertyArray(ADefinition, 'SourceForms'), ARule.FSourceForms);
    if not ARule.FHasSourceForms then Exit;
  end;
  if ADefinition.FindProperty('EffectiveCategories') <> nil then
  begin
    ARule.FHasEffectiveCategories := ParseCategories(
      PropertyArray(ADefinition, 'EffectiveCategories'),
      ARule.FEffectiveCategories);
    if not ARule.FHasEffectiveCategories then Exit;
  end;
  if PropertyText(ADefinition, 'Scalar', lText) then
  begin
    if SameText(lText, 'Text') then ARule.FScalarKind := nskText
    else if SameText(lText, 'Integer') then ARule.FScalarKind := nskInteger
    else if SameText(lText, 'Boolean') then ARule.FScalarKind := nskBoolean
    else Exit;
  end;
  if ADefinition.FindProperty('AllowedValues') <> nil then
  begin
    if not AddTextItems(PropertyArray(ADefinition, 'AllowedValues'),
      ARule.FAllowedValues) then Exit;
    if ARule.FAllowedValues.Count = 0 then Exit;
  end;
  if ADefinition.FindChild('Array') <> nil then
    if not NormalizeArray(ADefinition.FindChild('Array'), ARule.FArrayRule) then Exit;
  if ADefinition.FindChild('Reference') <> nil then
    if not NormalizeReference(ADefinition.FindChild('Reference'),
      ARule.FReferenceRule) then Exit;
  Result := True;
end;

function TNexusScriptLanguageDefinition.NormalizeProperty(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSPropertyRule): Boolean;
var
  lText: string;
  lBoolean: Boolean;
begin
  Result := False;
  ARule := TNSPropertyRule.Create;
  if not HasOnlyMembers(ADefinition, 'Required', 'Value') then Exit;
  if (ADefinition.FindChild('Value') <> nil) and
    not SameText(ADefinition.FindChild('Value').Kind, 'Value') then Exit;
  ARule.FName := ADefinition.Name;
  ARule.FSourceRange := ADefinition.SourceRange;
  if PropertyText(ADefinition, 'Required', lText) then
  begin
    if not ParseBoolean(lText, lBoolean) then Exit;
    ARule.FRequired := lBoolean;
  end;
  if ADefinition.FindChild('Value') <> nil then
    if not NormalizeValue(ADefinition.FindChild('Value'), ARule.FValueRule) then Exit;
  Result := True;
end;

function TNexusScriptLanguageDefinition.NormalizeChild(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSChildRule): Boolean;
var
  lText: string;
  lValue: Integer;
begin
  Result := False;
  ARule := TNSChildRule.Create;
  if not HasOnlyMembers(ADefinition, 'Kinds|Minimum|Maximum', '') then Exit;
  ARule.FName := ADefinition.Name;
  ARule.FSourceRange := ADefinition.SourceRange;
  if not AddTextItems(PropertyArray(ADefinition, 'Kinds'), ARule.FKinds) or
    (ARule.FKinds.Count = 0) then Exit;
  if PropertyText(ADefinition, 'Minimum', lText) then
  begin
    if not ParseNonNegativeInteger(lText, lValue) then Exit;
    ARule.FMinimum := lValue;
  end;
  if PropertyText(ADefinition, 'Maximum', lText) then
  begin
    if SameText(lText, 'Unbounded') then ARule.FMaximum := cNexusScriptUnbounded
    else begin
      if not ParseNonNegativeInteger(lText, lValue) then Exit;
      ARule.FMaximum := lValue;
    end;
  end;
  if (ARule.FMaximum <> cNexusScriptUnbounded) and (ARule.FMinimum > ARule.FMaximum) then Exit;
  Result := True;
end;

function TNexusScriptLanguageDefinition.NormalizeDefinition(
  ADefinition: TNexusScriptCompiledDefinition;
  out ARule: TNSDefinitionRule): Boolean;
var
  lText: string;
  lBoolean: Boolean;
  lArray: TNexusScriptCompiledValue;
  lItem: TNexusScriptCompiledValue;
  lDefinition: TNexusScriptCompiledDefinition;
  lPropertyRule: TNSPropertyRule;
  lChildRule: TNSChildRule;
  lIndex: Integer;
  lOtherIndex: Integer;
  lEffectiveName: string;
begin
  Result := False;
  ARule := TNSDefinitionRule.Create;
  if not HasOnlyMembers(ADefinition,
    'Root|Parents|UnknownProperties|UnknownChildren|Properties|Children', '') then Exit;
  ARule.FKindName := ADefinition.Name;
  ARule.FSourceRange := ADefinition.SourceRange;
  if PropertyText(ADefinition, 'Root', lText) then
  begin
    if not ParseBoolean(lText, lBoolean) then Exit;
    ARule.FRootAllowed := lBoolean;
  end;
  if ADefinition.FindProperty('Parents') <> nil then
    if not AddTextItems(PropertyArray(ADefinition, 'Parents'), ARule.FParents) then Exit;
  if PropertyText(ADefinition, 'UnknownProperties', lText) then
    if not ParseUnknownPolicy(lText, ARule.FUnknownProperties) then Exit;
  if PropertyText(ADefinition, 'UnknownChildren', lText) then
  begin
    ARule.FHasUnknownChildren := True;
    if not ParseUnknownPolicy(lText, ARule.FUnknownChildren) then Exit;
  end;
  lArray := PropertyArray(ADefinition, 'Properties');
  if lArray <> nil then
    for lItem in lArray.Items do
    begin
      lDefinition := StructuralDefinition(lItem);
      if (lDefinition = nil) or not SameText(lDefinition.Kind, 'Property') then Exit;
      lPropertyRule := nil;
      if not NormalizeProperty(lDefinition, lPropertyRule) then
      begin
        lPropertyRule.Free;
        Exit;
      end;
      lEffectiveName := lItem.EffectiveName;
      if lEffectiveName <> '' then lPropertyRule.FName := lEffectiveName;
      if FindPropertyRule(ARule, lPropertyRule.FName) <> nil then
      begin
        lPropertyRule.Free;
        Exit;
      end;
      ARule.FPropertyRules.Add(lPropertyRule);
    end;
  lArray := PropertyArray(ADefinition, 'Children');
  ARule.FHasChildren := lArray <> nil;
  if ARule.FHasChildren and not ARule.FHasUnknownChildren then
    ARule.FUnknownChildren := nupReject;
  if lArray <> nil then
    for lItem in lArray.Items do
    begin
      lDefinition := StructuralDefinition(lItem);
      if (lDefinition = nil) or not SameText(lDefinition.Kind, 'Child') then Exit;
      lChildRule := nil;
      if not NormalizeChild(lDefinition, lChildRule) then
      begin
        lChildRule.Free;
        Exit;
      end;
      lEffectiveName := lItem.EffectiveName;
      if lEffectiveName <> '' then lChildRule.FName := lEffectiveName;
      for lIndex := 0 to ARule.FChildRules.Count - 1 do
        for lOtherIndex := 0 to lChildRule.FKinds.Count - 1 do
          if ARule.FChildRules[lIndex].FKinds.IndexOf(
            lChildRule.FKinds[lOtherIndex]) >= 0 then
          begin
            lChildRule.Free;
            Exit;
          end;
      ARule.FChildRules.Add(lChildRule);
    end;
  Result := True;
end;

function TNexusScriptLanguageDefinition.Normalize(
  ADocument: TNexusScriptCompiledDocument): Boolean;
var
  lLanguageDefinition: TNexusScriptCompiledDefinition;
  lDefinition: TNexusScriptCompiledDefinition;
  lArray: TNexusScriptCompiledValue;
  lItem: TNexusScriptCompiledValue;
  lRule: TNSDefinitionRule;
  lChildRule: TNSChildRule;
  lPropertyRule: TNSPropertyRule;
  lText: string;
  lIndex: Integer;
  lRuleName: string;
  lView: TNexusScriptDefinitionView;
  lPolicy: TNSUnknownPolicy;
begin
  Result := False;
  FDiagnostics.Clear;
  FDefinitionRules.Clear;
  FUnknownDefinitions := nupReject;
  lView := TNexusScriptDefinitionView.Create;
  try
  if (ADocument = nil) or (ADocument.Definitions.Count <> 1) then
  begin
    AddDiagnostic('NSV1001', 'Language definition must contain exactly one root Language definition.',
      Default(TNexusScriptRange));
    Exit;
  end;
  try
    lView.AddDocument(ADocument);
  except
    on E: Exception do
    begin
      AddDiagnostic('NSV1006', E.Message, Default(TNexusScriptRange));
      Exit;
    end;
  end;
  for lLanguageDefinition in lView.Roots do
  begin
  if not SameText(lLanguageDefinition.Kind, 'Language') then
  begin
    AddDiagnostic('NSV1002', 'Language definition root must have kind Language.',
      lLanguageDefinition.SourceRange);
    Exit;
  end;
  if not HasOnlyMembers(lLanguageDefinition,
    'UnknownDefinitions|Definitions', '') then
  begin
    AddDiagnostic('NSV1010', 'Language contains an unknown member.',
      lLanguageDefinition.SourceRange);
    Exit;
  end;
  if PropertyText(lLanguageDefinition, 'UnknownDefinitions', lText) then
  begin
    if not ParseUnknownPolicy(lText, lPolicy) then
    begin
      AddDiagnostic('NSV1003', 'UnknownDefinitions must be Allow or Reject.',
        lLanguageDefinition.FindProperty('UnknownDefinitions').SourceRange);
      Exit;
    end;
    if lLanguageDefinition = ADocument.Definitions[0] then
      FUnknownDefinitions := lPolicy
    else if lPolicy <> FUnknownDefinitions then
    begin
      AddDiagnostic('NSV1003', 'Included language policy conflicts with the declared language.',
        lLanguageDefinition.FindProperty('UnknownDefinitions').SourceRange);
      Exit;
    end;
  end;
  lArray := PropertyArray(lLanguageDefinition, 'Definitions');
  if lArray = nil then
  begin
    AddDiagnostic('NSV1004', 'Language requires a Definitions array.',
      lLanguageDefinition.SourceRange);
    Exit;
  end;
  for lItem in lArray.Items do
  begin
    lDefinition := StructuralDefinition(lItem);
    if (lDefinition = nil) or not SameText(lDefinition.Kind, 'Definition') then
    begin
      AddDiagnostic('NSV1005', 'Definitions entries must be Definition values.',
        lItem.SourceRange);
      Exit;
    end;
    lRuleName := lItem.EffectiveName;
    if lRuleName = '' then lRuleName := lDefinition.Name;
    if FindDefinitionRule(lRuleName) <> nil then
    begin
      AddDiagnostic('NSV1006', 'Duplicate definition rule ' + lRuleName + '.',
        lDefinition.SourceRange);
      Exit;
    end;
    lRule := nil;
    if not NormalizeDefinition(lDefinition, lRule) then
    begin
      lRule.Free;
      AddDiagnostic('NSV1007', 'Invalid definition rule ' + lDefinition.Name + '.',
        lDefinition.SourceRange);
      Exit;
    end;
    lRule.FKindName := lRuleName;
    FDefinitionRules.Add(lRule);
  end;
  end;
  for lRule in FDefinitionRules do
  begin
    for lIndex := 0 to lRule.FParents.Count - 1 do
      if FindDefinitionRule(lRule.FParents[lIndex]) = nil then
      begin
        AddDiagnostic('NSV1008', 'Unknown parent kind ' + lRule.FParents[lIndex] + '.',
          lRule.FSourceRange);
        Exit;
      end;
    for lChildRule in lRule.FChildRules do
      for lIndex := 0 to lChildRule.FKinds.Count - 1 do
        if FindDefinitionRule(lChildRule.FKinds[lIndex]) = nil then
        begin
          AddDiagnostic('NSV1011', 'Unknown child kind ' +
            lChildRule.FKinds[lIndex] + '.', lChildRule.FSourceRange);
          Exit;
        end;
    for lPropertyRule in lRule.FPropertyRules do
    begin
      if (lPropertyRule.FValueRule <> nil) and
        (lPropertyRule.FValueRule.FArrayRule <> nil) then
        for lIndex := 0 to
          lPropertyRule.FValueRule.FArrayRule.FDefinitionKinds.Count - 1 do
          if FindDefinitionRule(
            lPropertyRule.FValueRule.FArrayRule.FDefinitionKinds[lIndex]) = nil then
          begin
            AddDiagnostic('NSV1012', 'Unknown array definition kind ' +
              lPropertyRule.FValueRule.FArrayRule.FDefinitionKinds[lIndex] + '.',
              lPropertyRule.FSourceRange);
            Exit;
          end;
      if (lPropertyRule.FValueRule <> nil) and
        (lPropertyRule.FValueRule.FReferenceRule <> nil) then
        for lIndex := 0 to
          lPropertyRule.FValueRule.FReferenceRule.FDefinitionKinds.Count - 1 do
          if FindDefinitionRule(
            lPropertyRule.FValueRule.FReferenceRule.FDefinitionKinds[lIndex]) = nil then
          begin
            AddDiagnostic('NSV1013', 'Unknown reference definition kind ' +
              lPropertyRule.FValueRule.FReferenceRule.FDefinitionKinds[lIndex] + '.',
              lPropertyRule.FSourceRange);
            Exit;
          end;
    end;
  end;
    Result := True;
  finally
    lView.Free;
    if not Result then
    begin
      FDefinitionRules.Clear;
      FUnknownDefinitions := nupReject;
    end;
  end;
end;

function TNexusScriptLanguageDefinition.FindDefinitionRule(
  const AKind: string): TNSDefinitionRule;
var
  lRule: TNSDefinitionRule;
begin
  Result := nil;
  for lRule in FDefinitionRules do
    if SameText(lRule.FKindName, AKind) then Exit(lRule);
end;

function TNexusScriptLanguageDefinition.FindPropertyRule(ARule: TNSDefinitionRule;
  const AName: string): TNSPropertyRule;
var
  lRule: TNSPropertyRule;
begin
  Result := nil;
  for lRule in ARule.FPropertyRules do
    if SameText(lRule.FName, AName) then Exit(lRule);
end;

function TNexusScriptLanguageDefinition.FindChildRule(ARule: TNSDefinitionRule;
  const AKind: string): TNSChildRule;
var
  lRule: TNSChildRule;
begin
  Result := nil;
  for lRule in ARule.FChildRules do
    if lRule.FKinds.IndexOf(AKind) >= 0 then Exit(lRule);
end;

end.

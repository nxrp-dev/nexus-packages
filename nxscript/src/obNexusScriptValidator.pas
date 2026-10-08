(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptValidator;

{$mode delphi}{$H+}

interface

uses
  Generics.Collections,
  tpNexusScript,
  obNexusScriptModel,
  obNexusScriptLanguageDefinition;

type
  TNexusScriptValidationSeverity = (nvsError);

  TNexusScriptValidationDiagnostic = class
  private
    FSeverity: TNexusScriptValidationSeverity;
    FCode: string;
    FMessageText: string;
    FSourceRange: TNexusScriptRange;
    FRelatedRanges: TList<TNexusScriptRange>;
  public
    constructor Create(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    destructor Destroy; override;
    property Code: string read FCode;
    property Severity: TNexusScriptValidationSeverity read FSeverity;
    property MessageText: string read FMessageText;
    property SourceRange: TNexusScriptRange read FSourceRange;
    property RelatedRanges: TList<TNexusScriptRange> read FRelatedRanges;
  end;

  TNexusScriptValidationDiagnosticList =
    TObjectList<TNexusScriptValidationDiagnostic>;

  TNexusScriptValidator = class
  private
    FDiagnostics: TNexusScriptValidationDiagnosticList;
  public
    constructor Create;
    destructor Destroy; override;
    function Validate(ASubject,
      ALanguageDefinition: TNexusScriptCompiledDocument): Boolean;
    property Diagnostics: TNexusScriptValidationDiagnosticList
      read FDiagnostics;
  end;

implementation

uses
  Classes,
  SysUtils,
  obNexusScriptDefinitionView;

type
  TNSValidatorEngine = class
  private
    FDiagnostics: TNexusScriptValidationDiagnosticList;
    FLanguage: TNexusScriptLanguageDefinition;
    FVisited: TList<TNexusScriptCompiledDefinition>;
    procedure AddDiagnostic(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    procedure ValidateDefinition(ADefinition: TNexusScriptCompiledDefinition;
      AParent: TNexusScriptCompiledDefinition; AIsRoot: Boolean);
    procedure ValidateProperty(AProperty: TNexusScriptCompiledProperty;
      ARule: TNSPropertyRule);
    procedure ValidateValue(AValue: TNexusScriptCompiledValue;
      ARule: TNSValueRule);
    procedure ValidateArray(AValue: TNexusScriptCompiledValue;
      ARule: TNSArrayRule);
    procedure ValidateReference(AValue: TNexusScriptCompiledValue;
      ARule: TNSReferenceRule);
  public
    constructor Create(ADiagnostics: TNexusScriptValidationDiagnosticList);
    destructor Destroy; override;
    function Execute(ASubject,
      ALanguageDefinition: TNexusScriptCompiledDocument): Boolean;
  end;

constructor TNexusScriptValidationDiagnostic.Create(const ACode,
  AMessageText: string; const ASourceRange: TNexusScriptRange);
begin
  inherited Create;
  FSeverity := nvsError;
  FCode := ACode;
  FMessageText := AMessageText;
  FSourceRange := ASourceRange;
  FRelatedRanges := TList<TNexusScriptRange>.Create;
end;

destructor TNexusScriptValidationDiagnostic.Destroy;
begin
  FRelatedRanges.Free;
  inherited Destroy;
end;

constructor TNexusScriptValidator.Create;
begin
  inherited Create;
  FDiagnostics := TNexusScriptValidationDiagnosticList.Create(True);
end;

destructor TNexusScriptValidator.Destroy;
begin
  FDiagnostics.Free;
  inherited Destroy;
end;

function TNexusScriptValidator.Validate(ASubject,
  ALanguageDefinition: TNexusScriptCompiledDocument): Boolean;
var
  lEngine: TNSValidatorEngine;
begin
  FDiagnostics.Clear;
  lEngine := TNSValidatorEngine.Create(FDiagnostics);
  try
    Result := lEngine.Execute(ASubject, ALanguageDefinition);
  finally
    lEngine.Free;
  end;
end;

constructor TNSValidatorEngine.Create(
  ADiagnostics: TNexusScriptValidationDiagnosticList);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
  FVisited := TList<TNexusScriptCompiledDefinition>.Create;
end;

destructor TNSValidatorEngine.Destroy;
begin
  FVisited.Free;
  FLanguage.Free;
  inherited Destroy;
end;

procedure TNSValidatorEngine.AddDiagnostic(const ACode, AMessageText: string;
  const ASourceRange: TNexusScriptRange);
begin
  FDiagnostics.Add(TNexusScriptValidationDiagnostic.Create(ACode,
    AMessageText, ASourceRange));
end;

function EffectiveValue(AValue: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
begin
  Result := AValue;
  if (AValue <> nil) and (AValue.EffectiveValue <> nil) then
    Result := AValue.EffectiveValue;
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

function ParseInteger(const AText: string; out AValue: Integer): Boolean;
var
  lCode: Integer;
begin
  Val(AText, AValue, lCode);
  Result := (lCode = 0) and ((IntToStr(AValue) = AText) or
    ((AValue = 0) and (AText = '-0')));
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

function StructuralDefinition(AValue: TNexusScriptCompiledValue):
  TNexusScriptCompiledDefinition;
begin
  Result := AValue.DefinitionValue;
end;

procedure TNSValidatorEngine.ValidateReference(AValue: TNexusScriptCompiledValue;
  ARule: TNSReferenceRule);
begin
  if (AValue.ResolvedProperty <> nil) and not (nrtProperty in ARule.Targets) then
    AddDiagnostic('NSV3001', 'Reference target must not be a property.',
      AValue.SourceRange)
  else if (AValue.ResolvedDefinition <> nil) and
    not (nrtDefinition in ARule.Targets) then
    AddDiagnostic('NSV3002', 'Reference target must not be a definition.',
      AValue.SourceRange)
  else if (AValue.ResolvedDefinition <> nil) and
    (ARule.DefinitionKindCount > 0) and
    (not ARule.HasDefinitionKind(AValue.ResolvedDefinition.Kind)) then
    AddDiagnostic('NSV3003', 'Referenced definition kind ' +
      AValue.ResolvedDefinition.Kind + ' is not allowed.', AValue.SourceRange);
end;

procedure TNSValidatorEngine.ValidateArray(AValue: TNexusScriptCompiledValue;
  ARule: TNSArrayRule);
var
  lArray: TNexusScriptCompiledValue;
  lItem: TNexusScriptCompiledValue;
  lCategory: TNSEffectiveCategory;
  lFirstCategory: TNSEffectiveCategory;
  lHasFirstCategory: Boolean;
  lDefinition: TNexusScriptCompiledDefinition;
begin
  lArray := EffectiveValue(AValue);
  if (lArray = nil) or (lArray.Kind <> nsvArray) then Exit;
  if lArray.Items.Count < ARule.Minimum then
    AddDiagnostic('NSV2401', 'Array has fewer than ' + IntToStr(ARule.Minimum) +
      ' entries.', AValue.SourceRange);
  if (ARule.Maximum <> cNexusScriptUnbounded) and
    (lArray.Items.Count > ARule.Maximum) then
    AddDiagnostic('NSV2402', 'Array has more than ' + IntToStr(ARule.Maximum) +
      ' entries.', AValue.SourceRange);
  lHasFirstCategory := False;
  for lItem in lArray.Items do
  begin
    if (ARule.NamePolicy = nnpRequired) and (lItem.EffectiveName = '') then
      AddDiagnostic('NSV2403', 'Array entry requires an effective name.',
        lItem.SourceRange);
    if (ARule.NamePolicy = nnpForbidden) and (lItem.EffectiveName <> '') then
      AddDiagnostic('NSV2404', 'Array entry must be unnamed.', lItem.SourceRange);
    if ARule.HasEntrySourceForms and
      not (SourceFormOf(lItem) in ARule.EntrySourceForms) then
      AddDiagnostic('NSV2405', 'Array entry source form is not allowed.',
        lItem.SourceRange);
    lCategory := EffectiveCategoryOf(lItem);
    if ARule.HasEntryCategories and not (lCategory in ARule.EntryCategories) then
      AddDiagnostic('NSV2406', 'Array entry effective category is not allowed.',
        lItem.SourceRange);
    if ARule.AllowedValueCount > 0 then
    begin
      if not EffectiveValue(lItem).HasEffectiveText then
        AddDiagnostic('NSV2409', 'Array entry must have an allowed scalar value.',
          lItem.SourceRange)
      else if not ARule.HasAllowedValue(EffectiveValue(lItem).EffectiveText) then
        AddDiagnostic('NSV2409', 'Array entry value ' +
          EffectiveValue(lItem).EffectiveText + ' is not allowed.',
          lItem.SourceRange);
    end;
    if not ARule.Mixed then
    begin
      if not lHasFirstCategory then
      begin
        lFirstCategory := lCategory;
        lHasFirstCategory := True;
      end
      else if lCategory <> lFirstCategory then
        AddDiagnostic('NSV2407', 'Mixed array entry categories are not allowed.',
          lItem.SourceRange);
    end;
    lDefinition := StructuralDefinition(lItem);
    if (lDefinition <> nil) and (ARule.DefinitionKindCount > 0) and
      (not ARule.HasDefinitionKind(lDefinition.Kind)) then
      AddDiagnostic('NSV2408', 'Array definition kind ' + lDefinition.Kind +
        ' is not allowed.', lItem.SourceRange);
  end;
end;

procedure TNSValidatorEngine.ValidateValue(AValue: TNexusScriptCompiledValue;
  ARule: TNSValueRule);
var
  lText: string;
  lInteger: Integer;
  lBoolean: Boolean;
begin
  if ARule.HasSourceForms and not (SourceFormOf(AValue) in ARule.SourceForms) then
    AddDiagnostic('NSV2301', 'Value source form is not allowed.', AValue.SourceRange);
  if ARule.HasEffectiveCategories and
    not (EffectiveCategoryOf(AValue) in ARule.EffectiveCategories) then
    AddDiagnostic('NSV2302', 'Value effective category is not allowed.',
      AValue.SourceRange);
  if ARule.ScalarKind <> nskNone then
  begin
    if not EffectiveValue(AValue).HasEffectiveText then
      AddDiagnostic('NSV2303', 'Value must have effective text.', AValue.SourceRange)
    else
    begin
      lText := EffectiveValue(AValue).EffectiveText;
      if (ARule.ScalarKind = nskInteger) and
        not ParseInteger(lText, lInteger) then
        AddDiagnostic('NSV2304', 'Value must be an Integer.', AValue.SourceRange)
      else if (ARule.ScalarKind = nskBoolean) and
        not ParseBoolean(lText, lBoolean) then
        AddDiagnostic('NSV2305', 'Value must be True or False.', AValue.SourceRange);
    end;
  end;
  if ARule.AllowedValueCount > 0 then
  begin
    if not EffectiveValue(AValue).HasEffectiveText then
      AddDiagnostic('NSV2306', 'Value must have an allowed scalar value.',
        AValue.SourceRange)
    else if not ARule.HasAllowedValue(EffectiveValue(AValue).EffectiveText) then
      AddDiagnostic('NSV2306', 'Value ' + EffectiveValue(AValue).EffectiveText +
        ' is not allowed.', AValue.SourceRange);
  end;
  if ARule.ArrayRule <> nil then ValidateArray(AValue, ARule.ArrayRule);
  if (ARule.ReferenceRule <> nil) and (AValue.Kind = nsvReference) then
    ValidateReference(AValue, ARule.ReferenceRule);
end;

procedure TNSValidatorEngine.ValidateProperty(
  AProperty: TNexusScriptCompiledProperty; ARule: TNSPropertyRule);
begin
  if ARule.ValueRule <> nil then ValidateValue(AProperty.Value, ARule.ValueRule);
end;

procedure TNSValidatorEngine.ValidateDefinition(
  ADefinition: TNexusScriptCompiledDefinition;
  AParent: TNexusScriptCompiledDefinition; AIsRoot: Boolean);
var
  lRule: TNSDefinitionRule;
  lParentRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lProperty: TNexusScriptCompiledProperty;
  lChildRule: TNSChildRule;
  lChild: TNexusScriptCompiledDefinition;
  lItem: TNexusScriptCompiledValue;
  lArray: TNexusScriptCompiledValue;
  lContained: TList<TNexusScriptCompiledDefinition>;
  lCount: Integer;
  lIndex: Integer;
begin
  if FVisited.IndexOf(ADefinition) >= 0 then Exit;
  FVisited.Add(ADefinition);
  lRule := FLanguage.FindDefinitionRule(ADefinition.Kind);
  if lRule = nil then
  begin
    if FLanguage.UnknownDefinitions = nupReject then
      AddDiagnostic('NSV2001', 'Unknown definition kind ' + ADefinition.Kind + '.',
        ADefinition.SourceRange);
    Exit;
  end;
  if AIsRoot and not lRule.RootAllowed then
    AddDiagnostic('NSV2002', 'Definition kind ' + ADefinition.Kind +
      ' is not allowed at document root.', ADefinition.SourceRange);
  if (AParent <> nil) and (lRule.ParentCount > 0) and
    (not lRule.HasParent(AParent.Kind)) then
    AddDiagnostic('NSV2003', 'Definition kind ' + ADefinition.Kind +
      ' is not allowed under ' + AParent.Kind + '.', ADefinition.SourceRange);
  if AParent <> nil then
  begin
    lParentRule := FLanguage.FindDefinitionRule(AParent.Kind);
    if lParentRule <> nil then
    begin
      lChildRule := lParentRule.FindChildRule(ADefinition.Kind);
      if (lChildRule = nil) and
        (lParentRule.HasChildren or lParentRule.HasUnknownChildren) and
        (lParentRule.UnknownChildren = nupReject) then
        AddDiagnostic('NSV2004', 'Parent kind ' + AParent.Kind +
          ' does not allow child kind ' + ADefinition.Kind + '.',
          ADefinition.SourceRange);
    end;
  end;
  for lIndex := 0 to lRule.PropertyRuleCount - 1 do
  begin
    lPropertyRule := lRule.PropertyRules[lIndex];
    if lPropertyRule.Required and
      (ADefinition.FindProperty(lPropertyRule.Name) = nil) then
      AddDiagnostic('NSV2101', 'Missing required property ' +
        lPropertyRule.Name + '.', ADefinition.SourceRange);
  end;
  for lProperty in ADefinition.Properties do
  begin
    lPropertyRule := lRule.FindPropertyRule(lProperty.Name);
    if lPropertyRule = nil then
    begin
      if lRule.UnknownProperties = nupReject then
        AddDiagnostic('NSV2102', 'Unknown property ' + lProperty.Name + '.',
          lProperty.SourceRange);
    end
    else
      ValidateProperty(lProperty, lPropertyRule);
  end;
  lContained := TList<TNexusScriptCompiledDefinition>.Create;
  try
    for lChild in ADefinition.Children do lContained.Add(lChild);
    for lProperty in ADefinition.Properties do
    begin
      lArray := EffectiveValue(lProperty.Value);
      if (lArray <> nil) and (lArray.Kind = nsvArray) then
        for lItem in lArray.Items do
        begin
          { A reference projects a target; it does not declare a child here. }
          if lItem.Kind = nsvReference then Continue;
          lChild := StructuralDefinition(lItem);
          if (lChild <> nil) and (lContained.IndexOf(lChild) < 0) then
            lContained.Add(lChild);
        end;
    end;
    for lIndex := 0 to lRule.ChildRuleCount - 1 do
    begin
      lChildRule := lRule.ChildRules[lIndex];
      lCount := 0;
      for lChild in lContained do
        if lChildRule.HasKind(lChild.Kind) then Inc(lCount);
      if lCount < lChildRule.Minimum then
        AddDiagnostic('NSV2201', 'Child rule ' + lChildRule.Name +
          ' requires at least ' + IntToStr(lChildRule.Minimum) + '.',
          ADefinition.SourceRange);
      if (lChildRule.Maximum <> cNexusScriptUnbounded) and (lCount > lChildRule.Maximum) then
        AddDiagnostic('NSV2202', 'Child rule ' + lChildRule.Name +
          ' allows at most ' + IntToStr(lChildRule.Maximum) + '.',
          ADefinition.SourceRange);
    end;
    for lChild in lContained do ValidateDefinition(lChild, ADefinition, False);
  finally
    lContained.Free;
  end;
end;

function TNSValidatorEngine.Execute(ASubject,
  ALanguageDefinition: TNexusScriptCompiledDocument): Boolean;
var
  lDefinition: TNexusScriptCompiledDefinition;
  lDiagnostic: TNSLanguageDiagnostic;
  lIndex: Integer;
  lView: TNexusScriptDefinitionView;
begin
  FLanguage.Free;
  FLanguage := TNexusScriptLanguageDefinition.Create;
  Result := FLanguage.Normalize(ALanguageDefinition);
  if not Result then
  begin
    for lIndex := 0 to FLanguage.DiagnosticCount - 1 do
    begin
      lDiagnostic := FLanguage.Diagnostics[lIndex];
      AddDiagnostic(lDiagnostic.Code, lDiagnostic.MessageText,
        lDiagnostic.SourceRange);
    end;
    Exit;
  end;
  if ASubject = nil then
  begin
    AddDiagnostic('NSV1009', 'Subject document is required.',
      Default(TNexusScriptRange));
    Exit(False);
  end;
  FVisited.Clear;
  lView := TNexusScriptDefinitionView.Create;
  try
    try
      lView.AddDocument(ASubject);
    except
      on E: Exception do
      begin
        AddDiagnostic('NSV2000', E.Message, Default(TNexusScriptRange));
        Exit(False);
      end;
    end;
    for lDefinition in lView.Roots do
      ValidateDefinition(lDefinition, nil, True);
  finally
    lView.Free;
  end;
  Result := FDiagnostics.Count = 0;
end;

end.

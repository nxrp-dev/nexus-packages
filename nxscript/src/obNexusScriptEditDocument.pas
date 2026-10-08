(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptEditDocument;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, tpNexusScript, obNexusScriptModel,
  obNexusScriptSourceProvider, obNexusScriptAnalysis, obNexusScriptCompiler,
  obNexusScriptLanguageDefinition;

type
  { Owns the source buffer and its analysis. Model objects and rules are borrowed
    until the next successful edit/load. Offsets always address the current
    revision, and only the entry file is writable. }
  TNexusScriptEditDocument = class
  private
    FAnalysis: TNexusScriptAnalysis;
    FSourceName, FSourceText, FSavedText: string;
    FDiagnostics, FUndo, FRedo: TStringList;
    FRevision: Integer;
    FValid: Boolean;
    FOnChanging, FOnChanged: TNotifyEvent;
    function Analyze(const AText: string): TNexusScriptAnalysis;
    function CheckAnalysis(AAnalysis: TNexusScriptAnalysis): Boolean;
    procedure Adopt(AAnalysis: TNexusScriptAnalysis; const AText: string);
    function Replace(AStart, AEnd: Integer; const AText: string): Boolean;
    function Reject(const AMessage: string): Boolean;
    function ParseFragment(const AText: string): TNexusScriptCompiler;
    function CheckValueSyntax(const AText: string; AArrayEntry: Boolean = False): Boolean;
    function CompiledDefinition(AOffset: Integer): TNexusScriptCompiledDefinition;
    function CountChildren(ADefinition: TNexusScriptCompiledDefinition;
      ARule: TNSChildRule): Integer;
  protected
    function GetSourceDocument: TNexusScriptSourceDocument;
    function GetLanguage: TNexusScriptLanguageDefinition;
    function GetDirty: Boolean;
    function GetCanUndo: Boolean;
    function GetCanRedo: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadSource(const ASourceName, AText: string);
    procedure LoadFile(const AFileName: string);
    procedure Save;
    function FindDefinition(AOffset: Integer): TNexusScriptSourceDefinition;
    function FindValue(AOffset: Integer): TNexusScriptSourceValue;
    function PropertyRule(AOwnerOffset: Integer; const AName: string): TNSPropertyRule;
    function SourceSlice(const ARange: TNexusScriptRange): string;
    function ValueRange(AValue: TNexusScriptSourceValue): TNexusScriptRange;
    function EntryRange(AValue: TNexusScriptSourceValue): TNexusScriptRange;
    class function QuoteText(const AText: string): string; static;
    procedure GetPropertyNames(AOwnerOffset: Integer; AResult: TStrings);
    procedure GetDefinitionKinds(AParentOffset: Integer; AResult: TStrings);
    procedure GetReferenceChoices(AOwnerOffset: Integer; ARule: TNSReferenceRule;
      AArrayRule: TNSArrayRule; AResult: TStrings);
    function CanRemoveProperty(AOwnerOffset: Integer; const AName: string): Boolean;
    function CanRemoveDefinition(AOffset: Integer): Boolean;
    function SetProperty(AOwnerOffset: Integer; const AName, ASourceValue: string): Boolean;
    function ReplaceValue(AOffset: Integer; const ASourceValue: string): Boolean;
    function RenameDefinition(AOffset: Integer; const AName: string): Boolean;
    function AddDefinition(AParentOffset: Integer;
      const AKind, AName, ABody: string): Boolean;
    function RemoveProperty(AOwnerOffset: Integer; const AName: string): Boolean;
    function RemoveDefinition(AOffset: Integer): Boolean;
    function AddArrayItem(AArrayOffset: Integer;
      const ASourceValue: string; const AEntryName: string = ''): Boolean;
    function RemoveArrayItem(AArrayOffset, AIndex: Integer): Boolean;
    function RenameArrayEntry(AArrayOffset, AIndex: Integer; const AName: string): Boolean;
    function Undo: Boolean;
    function Redo: Boolean;
    property SourceName: string read FSourceName;
    property SourceText: string read FSourceText;
    property SourceDocument: TNexusScriptSourceDocument read GetSourceDocument;
    property Language: TNexusScriptLanguageDefinition read GetLanguage;
    property Diagnostics: TStringList read FDiagnostics;
    property Revision: Integer read FRevision;
    property Valid: Boolean read FValid;
    property Dirty: Boolean read GetDirty;
    property CanUndo: Boolean read GetCanUndo;
    property CanRedo: Boolean read GetCanRedo;
    property OnChanging: TNotifyEvent read FOnChanging write FOnChanging;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

uses
  Generics.Collections, obNexusScriptValidator,
  obNexusScriptDefinitionView;

type
  TEditSourceProvider = class(TNexusScriptFileSourceProvider)
  private
    FEntryName, FEntryText: string;
  public
    constructor Create(const AName, AText: string);
    function Exists(const ASourceName: string): Boolean; override;
    function ReadSource(const ASourceName: string; out AText: string;
      out AVersion: Integer): Boolean; override;
  end;

  TEditAnalysis = class(TNexusScriptAnalysis)
  private
    FProvider: TEditSourceProvider;
  public
    constructor Create(const AName, AText: string; ARevision: Integer);
    destructor Destroy; override;
  end;

constructor TEditAnalysis.Create(const AName, AText: string; ARevision: Integer);
begin
  FProvider := TEditSourceProvider.Create(AName, AText);
  inherited Create(AName, ARevision, FProvider);
end;

destructor TEditAnalysis.Destroy;
begin
  inherited Destroy;
  FProvider.Free;
end;

constructor TEditSourceProvider.Create(const AName, AText: string);
begin
  inherited Create;
  FEntryName := CanonicalName(AName);
  FEntryText := AText;
end;

function TEditSourceProvider.Exists(const ASourceName: string): Boolean;
begin
  Result := SameIdentity(ASourceName, FEntryName) or inherited Exists(ASourceName);
end;

function TEditSourceProvider.ReadSource(const ASourceName: string;
  out AText: string; out AVersion: Integer): Boolean;
begin
  if SameIdentity(ASourceName, FEntryName) then
  begin
    AText := FEntryText;
    AVersion := 1;
    Exit(True);
  end;
  Result := inherited ReadSource(ASourceName, AText, AVersion);
end;

function IsName(const AName: string): Boolean;
var
  lCharacter: Char;
begin
  Result := False;
  if (AName = '') or (Pos('//', AName) > 0) or (Pos('/*', AName) > 0) then Exit;
  for lCharacter in AName do
    if (lCharacter <= ' ') or
      (lCharacter in ['{', '}', ':', ';', '(', ')', ',', '[', ']', '@', '.', '+', '"']) then Exit;
  Result := True;
end;

constructor TNexusScriptEditDocument.Create;
begin
  inherited Create;
  FDiagnostics := TStringList.Create;
  FUndo := TStringList.Create;
  FRedo := TStringList.Create;
end;

destructor TNexusScriptEditDocument.Destroy;
begin
  FAnalysis.Free;
  FDiagnostics.Free;
  FUndo.Free;
  FRedo.Free;
  inherited Destroy;
end;

function TNexusScriptEditDocument.Analyze(const AText: string): TNexusScriptAnalysis;
begin
  Result := TEditAnalysis.Create(FSourceName, AText, FRevision + 1);
  try
    Result.Execute;
  except
    Result.Free;
    raise;
  end;
end;

function TNexusScriptEditDocument.CheckAnalysis(AAnalysis: TNexusScriptAnalysis): Boolean;
var
  lCompiler: TNexusScriptCompiler;
  lDiagnostic: TNexusScriptDiagnostic;
  lValidation: TNexusScriptValidationDiagnostic;
  lIndex: Integer;
begin
  FDiagnostics.Clear;
  for lDiagnostic in AAnalysis.Session.Diagnostics do
    FDiagnostics.Add(lDiagnostic.Code + ': ' + lDiagnostic.MessageText);
  for lIndex := 0 to AAnalysis.Session.AttemptedCompilerCount - 1 do
  begin
    lCompiler := AAnalysis.Session.AttemptedCompilers[lIndex];
    for lDiagnostic in lCompiler.Diagnostics do
      FDiagnostics.Add(lDiagnostic.Code + ': ' + lDiagnostic.MessageText);
  end;
  if not AAnalysis.Succeeded then
  begin
    if FDiagnostics.Count = 0 then FDiagnostics.Add(AAnalysis.Session.LastError);
    Exit(False);
  end;
  if AAnalysis.EntryCompiler.CompiledDocument.DialectDocument = nil then
    FDiagnostics.Add('A dialect declaration is required for structured editing.');
  for lIndex := 0 to AAnalysis.Language.DiagnosticCount - 1 do
    FDiagnostics.Add(AAnalysis.Language.Diagnostics[lIndex].Code + ': ' +
      AAnalysis.Language.Diagnostics[lIndex].MessageText);
  for lValidation in AAnalysis.Validator.Diagnostics do
    FDiagnostics.Add(lValidation.Code + ': ' + lValidation.MessageText);
  Result := FDiagnostics.Count = 0;
end;

procedure TNexusScriptEditDocument.Adopt(AAnalysis: TNexusScriptAnalysis;
  const AText: string);
begin
  if Assigned(FOnChanging) then FOnChanging(Self);
  FAnalysis.Free;
  FAnalysis := AAnalysis;
  FSourceText := AText;
  Inc(FRevision);
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TNexusScriptEditDocument.LoadSource(const ASourceName, AText: string);
var
  lAnalysis: TNexusScriptAnalysis;
begin
  FSourceName := ExpandFileName(ASourceName);
  lAnalysis := Analyze(AText);
  FValid := CheckAnalysis(lAnalysis);
  FUndo.Clear;
  FRedo.Clear;
  FSavedText := AText;
  Adopt(lAnalysis, AText);
end;

procedure TNexusScriptEditDocument.LoadFile(const AFileName: string);
var
  lFile: TFileStream;
  lText: string;
begin
  lFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(lText, lFile.Size);
    if lText <> '' then lFile.ReadBuffer(lText[1], Length(lText));
  finally
    lFile.Free;
  end;
  LoadSource(AFileName, lText);
end;

procedure TNexusScriptEditDocument.Save;
var
  lFile: TFileStream;
begin
  if FSourceName = '' then raise EInvalidOperation.Create('No document is open.');
  lFile := TFileStream.Create(FSourceName, fmCreate);
  try
    if FSourceText <> '' then lFile.WriteBuffer(FSourceText[1], Length(FSourceText));
  finally
    lFile.Free;
  end;
  FSavedText := FSourceText;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

function TNexusScriptEditDocument.GetSourceDocument: TNexusScriptSourceDocument;
begin
  Result := nil;
  if (FAnalysis <> nil) and (FAnalysis.EntrySourceCompiler <> nil) then
    Result := FAnalysis.EntrySourceCompiler.SourceDocument;
end;

function TNexusScriptEditDocument.GetLanguage: TNexusScriptLanguageDefinition;
begin
  Result := nil;
  if FAnalysis <> nil then Result := FAnalysis.Language;
end;

function TNexusScriptEditDocument.GetDirty: Boolean;
begin
  Result := FSourceText <> FSavedText;
end;

function TNexusScriptEditDocument.GetCanUndo: Boolean;
begin
  Result := FUndo.Count > 0;
end;

function TNexusScriptEditDocument.GetCanRedo: Boolean;
begin
  Result := FRedo.Count > 0;
end;

function TNexusScriptEditDocument.Reject(const AMessage: string): Boolean;
begin
  FDiagnostics.Clear;
  FDiagnostics.Add(AMessage);
  Result := False;
end;

function TNexusScriptEditDocument.ParseFragment(const AText: string): TNexusScriptCompiler;
var
  lCompiler: TNexusScriptCompiler;
  lDiagnostic: TNexusScriptDiagnostic;
  lSource: TNexusScriptSourceDocument;
begin
  lCompiler := TNexusScriptCompiler.Create;
  try
    { Use the real parser. Unresolved references in this isolated fragment are
      checked later in the complete candidate document. }
    lCompiler.CompileText(FSourceName, AText);
    for lDiagnostic in lCompiler.Diagnostics do
      if (Copy(lDiagnostic.Code, 1, 4) = 'NXS1') or
        (Copy(lDiagnostic.Code, 1, 4) = 'NXS2') or
        (Copy(lDiagnostic.Code, 1, 4) = 'NXS3') then
      begin
        Reject(lDiagnostic.Code + ': ' + lDiagnostic.MessageText);
        Exit(nil);
      end;
    lSource := lCompiler.SourceDocument;
    if not ((lSource <> nil) and (lSource.Definitions.Count = 1) and
      (lSource.Modules.Count = 0) and (lSource.Includes.Count = 0) and
      (lSource.Dialect = nil) and (lSource.DataSources.Count = 0)) then
    begin
      Reject('An edit cannot introduce additional roots or file directives.');
      Exit(nil);
    end;
    Result := lCompiler;
    lCompiler := nil;
  finally
    lCompiler.Free;
  end;
end;

function TNexusScriptEditDocument.CheckValueSyntax(const AText: string;
  AArrayEntry: Boolean): Boolean;
var
  lText: string;
  lCompiler: TNexusScriptCompiler;
  lDefinition: TNexusScriptSourceDefinition;
begin
  lText := AText;
  if AArrayEntry then lText := '[' + lText + ']';
  lCompiler := ParseFragment('Value Editor { Value: ' + lText + '; }');
  if lCompiler = nil then Exit(False);
  try
    lDefinition := lCompiler.SourceDocument.Definitions[0];
    Result := (lDefinition.Properties.Count = 1) and (lDefinition.Children.Count = 0);
    if Result and AArrayEntry then
      Result := (lDefinition.Properties[0].Value.Kind = nsvArray) and
        (lDefinition.Properties[0].Value.Items.Count = 1);
    if not Result then Reject('Enter one value, not additional entries or properties.');
  finally
    lCompiler.Free;
  end;
end;

function TNexusScriptEditDocument.Replace(AStart, AEnd: Integer;
  const AText: string): Boolean;
var
  lText: string;
  lAnalysis: TNexusScriptAnalysis;
begin
  if (AStart < 0) or (AEnd < AStart) or (AEnd > Length(FSourceText)) then
    raise EArgumentException.Create('Edit range is outside the entry source.');
  lText := Copy(FSourceText, 1, AStart) + AText +
    Copy(FSourceText, AEnd + 1, MaxInt);
  if lText = FSourceText then Exit(True);
  lAnalysis := Analyze(lText);
  if not CheckAnalysis(lAnalysis) then
  begin
    lAnalysis.Free;
    Exit(False);
  end;
  FUndo.Add(FSourceText);
  FRedo.Clear;
  FValid := True;
  Adopt(lAnalysis, lText);
  Result := True;
end;

function FindSourceDefinition(ADefinitions: TNexusScriptSourceDefinitionList;
  AOffset: Integer): TNexusScriptSourceDefinition; forward;

function FindInlineDefinition(AValue: TNexusScriptSourceValue;
  AOffset: Integer): TNexusScriptSourceDefinition;
var
  lItem: TNexusScriptSourceValue;
  lProperty: TNexusScriptSourceProperty;
begin
  Result := AValue.InlineDefinition;
  if Result <> nil then
  begin
    if Result.SourceRange.StartPosition.Offset = AOffset then Exit;
    for lProperty in Result.Properties do
    begin
      Result := FindInlineDefinition(lProperty.Value, AOffset);
      if Result <> nil then Exit;
    end;
    Result := FindSourceDefinition(AValue.InlineDefinition.Children, AOffset);
    if Result <> nil then Exit;
  end;
  for lItem in AValue.Items do
  begin
    Result := FindInlineDefinition(lItem, AOffset);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

function FindSourceDefinition(ADefinitions: TNexusScriptSourceDefinitionList;
  AOffset: Integer): TNexusScriptSourceDefinition;
var
  lDefinition: TNexusScriptSourceDefinition;
  lProperty: TNexusScriptSourceProperty;
begin
  for lDefinition in ADefinitions do
  begin
    if lDefinition.SourceRange.StartPosition.Offset = AOffset then Exit(lDefinition);
    Result := FindSourceDefinition(lDefinition.Children, AOffset);
    if Result <> nil then Exit;
    for lProperty in lDefinition.Properties do
    begin
      Result := FindInlineDefinition(lProperty.Value, AOffset);
      if Result <> nil then Exit;
    end;
  end;
  Result := nil;
end;

function TNexusScriptEditDocument.FindDefinition(AOffset: Integer): TNexusScriptSourceDefinition;
begin
  Result := nil;
  if SourceDocument <> nil then
    Result := FindSourceDefinition(SourceDocument.Definitions, AOffset);
end;

function FindDefinitionValue(ADefinition: TNexusScriptSourceDefinition;
  AOffset: Integer): TNexusScriptSourceValue; forward;

function FindSourceValue(AValue: TNexusScriptSourceValue;
  AOffset: Integer): TNexusScriptSourceValue;
var
  lItem: TNexusScriptSourceValue;
begin
  if AValue.SourceRange.StartPosition.Offset = AOffset then Exit(AValue);
  for lItem in AValue.Items do
  begin
    Result := FindSourceValue(lItem, AOffset);
    if Result <> nil then Exit;
  end;
  if AValue.InlineDefinition <> nil then
    Exit(FindDefinitionValue(AValue.InlineDefinition, AOffset));
  Result := nil;
end;

function FindDefinitionValue(ADefinition: TNexusScriptSourceDefinition;
  AOffset: Integer): TNexusScriptSourceValue;
var
  lProperty: TNexusScriptSourceProperty;
  lChild: TNexusScriptSourceDefinition;
begin
  for lProperty in ADefinition.Properties do
  begin
    Result := FindSourceValue(lProperty.Value, AOffset);
    if Result <> nil then Exit;
  end;
  for lChild in ADefinition.Children do
  begin
    Result := FindDefinitionValue(lChild, AOffset);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

function TNexusScriptEditDocument.FindValue(AOffset: Integer): TNexusScriptSourceValue;
var
  lDefinition: TNexusScriptSourceDefinition;
begin
  if SourceDocument <> nil then
    for lDefinition in SourceDocument.Definitions do
    begin
      Result := FindDefinitionValue(lDefinition, AOffset);
      if Result <> nil then Exit;
    end;
  Result := nil;
end;

function TNexusScriptEditDocument.PropertyRule(AOwnerOffset: Integer;
  const AName: string): TNSPropertyRule;
var
  lDefinition: TNexusScriptSourceDefinition;
  lRule: TNSDefinitionRule;
begin
  Result := nil;
  lDefinition := FindDefinition(AOwnerOffset);
  if (lDefinition = nil) or (Language = nil) then Exit;
  lRule := Language.FindDefinitionRule(lDefinition.Kind);
  if lRule <> nil then Result := lRule.FindPropertyRule(AName);
end;

function TNexusScriptEditDocument.SourceSlice(const ARange: TNexusScriptRange): string;
begin
  Result := Copy(FSourceText, ARange.StartPosition.Offset + 1,
    ARange.EndPosition.Offset - ARange.StartPosition.Offset);
end;

function TNexusScriptEditDocument.ValueRange(AValue: TNexusScriptSourceValue): TNexusScriptRange;
begin
  Result := AValue.SourceRange;
  if AValue.InlineDefinition <> nil then Result := AValue.InlineDefinition.SourceRange;
end;

function TNexusScriptEditDocument.EntryRange(AValue: TNexusScriptSourceValue): TNexusScriptRange;
begin
  Result := ValueRange(AValue);
  if AValue.EntryName <> '' then Result.StartPosition := AValue.EntryNameRange.StartPosition;
end;

class function TNexusScriptEditDocument.QuoteText(const AText: string): string;
var
  lCharacter: Char;
begin
  Result := '"';
  for lCharacter in AText do
    case lCharacter of
      '^': Result := Result + '^^';
      '"': Result := Result + '^"';
      #10: Result := Result + '^n';
      #13: Result := Result + '^r';
      #9: Result := Result + '^t';
    else
      Result := Result + lCharacter;
    end;
  Result := Result + '"';
end;

procedure TNexusScriptEditDocument.GetPropertyNames(AOwnerOffset: Integer; AResult: TStrings);
var
  lDefinition: TNexusScriptSourceDefinition;
  lRule: TNSDefinitionRule;
  lIndex: Integer;
begin
  AResult.Clear;
  lDefinition := FindDefinition(AOwnerOffset);
  if (lDefinition = nil) or (Language = nil) then Exit;
  lRule := Language.FindDefinitionRule(lDefinition.Kind);
  if lRule = nil then Exit;
  for lIndex := 0 to lRule.PropertyRuleCount - 1 do
    if lDefinition.FindProperty(lRule.PropertyRules[lIndex].Name) = nil then
      AResult.Add(lRule.PropertyRules[lIndex].Name);
end;

function TNexusScriptEditDocument.CompiledDefinition(AOffset: Integer): TNexusScriptCompiledDefinition;
var
  lView: TNexusScriptDefinitionView;
  lDefinition: TNexusScriptCompiledDefinition;
  lSource: TNexusScriptSourceDefinition;
begin
  Result := nil;
  lSource := FindDefinition(AOffset);
  if (lSource = nil) or (FAnalysis.EntryCompiler = nil) then Exit;
  lView := TNexusScriptDefinitionView.Create;
  try
    lView.AddDocument(FAnalysis.EntryCompiler.CompiledDocument);
    for lDefinition in lView.Definitions do
      if lDefinition.SourceDefinition = lSource then Exit(lDefinition);
  finally
    lView.Free;
  end;
end;

function TNexusScriptEditDocument.CountChildren(ADefinition: TNexusScriptCompiledDefinition;
  ARule: TNSChildRule): Integer;
var
  lChild: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
  lValue, lItem, lEffectiveItem: TNexusScriptCompiledValue;
  lContained: TList<TNexusScriptCompiledDefinition>;
begin
  Result := 0;
  if ADefinition = nil then Exit;
  lContained := TList<TNexusScriptCompiledDefinition>.Create;
  try
    for lChild in ADefinition.Children do lContained.Add(lChild);
    for lProperty in ADefinition.Properties do
    begin
      lValue := lProperty.Value;
      if lValue.EffectiveValue <> nil then lValue := lValue.EffectiveValue;
      if lValue.Kind <> nsvArray then Continue;
      for lItem in lValue.Items do
      begin
        if lItem.Kind = nsvReference then Continue;
        lEffectiveItem := lItem;
        if lItem.EffectiveValue <> nil then lEffectiveItem := lItem.EffectiveValue;
        lChild := lEffectiveItem.StructuralDefinition;
        if (lChild <> nil) and (lContained.IndexOf(lChild) < 0) then lContained.Add(lChild);
      end;
    end;
    for lChild in lContained do
      if ARule.HasKind(lChild.Kind) then Inc(Result);
  finally
    lContained.Free;
  end;
end;

procedure TNexusScriptEditDocument.GetDefinitionKinds(AParentOffset: Integer; AResult: TStrings);
var
  lParent: TNexusScriptSourceDefinition;
  lParentRule, lRule: TNSDefinitionRule;
  lChildRule: TNSChildRule;
  lCompiled: TNexusScriptCompiledDefinition;
  lIndex: Integer;
begin
  AResult.Clear;
  if Language = nil then Exit;
  lParent := FindDefinition(AParentOffset);
  lParentRule := nil;
  lCompiled := nil;
  if lParent <> nil then
  begin
    lParentRule := Language.FindDefinitionRule(lParent.Kind);
    lCompiled := CompiledDefinition(AParentOffset);
  end
  else if AParentOffset <> -1 then Exit;
  for lIndex := 0 to Language.DefinitionRuleCount - 1 do
  begin
    lRule := Language.DefinitionRules[lIndex];
    if lParent = nil then
    begin
      if lRule.RootAllowed then AResult.Add(lRule.KindName);
      Continue;
    end;
    if (lRule.ParentCount > 0) and not lRule.HasParent(lParent.Kind) then Continue;
    if lParentRule <> nil then
    begin
      lChildRule := lParentRule.FindChildRule(lRule.KindName);
      if lChildRule = nil then
      begin
        if (lParentRule.HasChildren or lParentRule.HasUnknownChildren) and
          (lParentRule.UnknownChildren = nupReject) then Continue;
      end
      else if (lChildRule.Maximum <> cNexusScriptUnbounded) and
        (CountChildren(lCompiled, lChildRule) >= lChildRule.Maximum) then Continue;
    end;
    AResult.Add(lRule.KindName);
  end;
end;

procedure TNexusScriptEditDocument.GetReferenceChoices(AOwnerOffset: Integer;
  ARule: TNSReferenceRule; AArrayRule: TNSArrayRule; AResult: TStrings);
var
  lOwner, lRoot, lDefinition: TNexusScriptCompiledDefinition;

  function AllowsDefinition(ADefinition: TNexusScriptCompiledDefinition): Boolean;
  var
    lRule: TNSDefinitionRule;
    lScope: TNexusScriptCompiledDefinition;
  begin
    Result := False;
    if (ARule <> nil) and (not (nrtDefinition in ARule.Targets) or
      ((ARule.DefinitionKindCount > 0) and not ARule.HasDefinitionKind(ADefinition.Kind))) then Exit;
    if AArrayRule <> nil then
    begin
      if AArrayRule.HasEntryCategories and not (necDefinition in AArrayRule.EntryCategories) then Exit;
      if (AArrayRule.DefinitionKindCount > 0) and
        not AArrayRule.HasDefinitionKind(ADefinition.Kind) then Exit;
    end;
    { Prefer the existing lexical owner of a target kind over foreign scopes. }
    lRule := Language.FindDefinitionRule(ADefinition.Kind);
    lScope := lOwner;
    if (lRule <> nil) and (lRule.ParentCount > 0) then
      while lScope <> nil do
      begin
        if lRule.HasParent(lScope.Kind) then Exit(ADefinition.Parent = lScope);
        lScope := lScope.Parent;
      end;
    Result := True;
  end;

  function AllowsProperties: Boolean;
  begin
    Result := (ARule = nil) or (nrtProperty in ARule.Targets);
    if AArrayRule <> nil then
      Result := Result and ((AArrayRule.DefinitionKindCount = 0) and
        (not AArrayRule.HasEntryCategories or
        (necText in AArrayRule.EntryCategories) or (necArray in AArrayRule.EntryCategories)));
  end;

  procedure Collect(ADefinition: TNexusScriptCompiledDefinition; const APath: string);
  var
    lChild: TNexusScriptCompiledDefinition;
    lProperty: TNexusScriptCompiledProperty;
  begin
    if AllowsDefinition(ADefinition) then AResult.Add('@' + APath);
    for lProperty in ADefinition.Properties do
      if AllowsProperties then
        AResult.Add('@' + APath + '.' + lProperty.Name);
    for lChild in ADefinition.Children do Collect(lChild, APath + '.' + lChild.Name);
  end;

begin
  AResult.Clear;
  if (FAnalysis = nil) or (FAnalysis.EntryCompiler = nil) then Exit;
  lOwner := CompiledDefinition(AOwnerOffset);
  lRoot := lOwner;
  while (lRoot <> nil) and (lRoot.Parent <> nil) do lRoot := lRoot.Parent;
  for lDefinition in FAnalysis.EntryCompiler.CompiledDocument.Definitions do
    if lDefinition.ImportedRoot or (lDefinition = lRoot) then
      Collect(lDefinition, lDefinition.Name);
end;

function TNexusScriptEditDocument.CanRemoveProperty(AOwnerOffset: Integer;
  const AName: string): Boolean;
var
  lDefinition: TNexusScriptSourceDefinition;
  lRule: TNSPropertyRule;
begin
  lDefinition := FindDefinition(AOwnerOffset);
  Result := (lDefinition <> nil) and (lDefinition.FindProperty(AName) <> nil);
  if not Result then Exit;
  lRule := PropertyRule(AOwnerOffset, AName);
  Result := (lRule = nil) or not lRule.Required;
end;

function TNexusScriptEditDocument.CanRemoveDefinition(AOffset: Integer): Boolean;
var
  lDefinition: TNexusScriptSourceDefinition;
  lParent: TNexusScriptCompiledDefinition;
  lRule: TNSDefinitionRule;
  lChildRule: TNSChildRule;
begin
  lDefinition := FindDefinition(AOffset);
  Result := lDefinition <> nil;
  if not Result or (lDefinition.Parent = nil) then Exit;
  lRule := Language.FindDefinitionRule(lDefinition.Parent.Kind);
  if lRule = nil then Exit;
  lChildRule := lRule.FindChildRule(lDefinition.Kind);
  if lChildRule = nil then Exit;
  lParent := CompiledDefinition(lDefinition.Parent.SourceRange.StartPosition.Offset);
  Result := CountChildren(lParent, lChildRule) > lChildRule.Minimum;
end;

function TNexusScriptEditDocument.SetProperty(AOwnerOffset: Integer;
  const AName, ASourceValue: string): Boolean;
var
  lDefinition: TNexusScriptSourceDefinition;
  lProperty: TNexusScriptSourceProperty;
begin
  lDefinition := FindDefinition(AOwnerOffset);
  if lDefinition = nil then Exit(Reject('Definition was not found.'));
  if not IsName(AName) then Exit(Reject('A property name must be one unquoted word.'));
  if not CheckValueSyntax(ASourceValue) then Exit(False);
  lProperty := lDefinition.FindProperty(AName);
  if lProperty <> nil then
    Exit(ReplaceValue(lProperty.Value.SourceRange.StartPosition.Offset, ASourceValue));
  Result := Replace(lDefinition.BodyEndRange.StartPosition.Offset,
    lDefinition.BodyEndRange.StartPosition.Offset, LineEnding + '  ' +
    AName + ': ' + ASourceValue + ';' + LineEnding);
end;

function TNexusScriptEditDocument.ReplaceValue(AOffset: Integer;
  const ASourceValue: string): Boolean;
var
  lValue: TNexusScriptSourceValue;
  lRange: TNexusScriptRange;
begin
  lValue := FindValue(AOffset);
  if lValue = nil then Exit(Reject('Value was not found.'));
  if not CheckValueSyntax(ASourceValue, lValue.InlineDefinition <> nil) then Exit(False);
  lRange := ValueRange(lValue);
  Result := Replace(lRange.StartPosition.Offset, lRange.EndPosition.Offset, ASourceValue);
end;

function TNexusScriptEditDocument.RenameDefinition(AOffset: Integer;
  const AName: string): Boolean;
var
  lDefinition: TNexusScriptSourceDefinition;
begin
  lDefinition := FindDefinition(AOffset);
  if lDefinition = nil then Exit(Reject('Definition was not found.'));
  if not IsName(AName) then Exit(Reject('A definition name must be one unquoted word.'));
  Result := Replace(lDefinition.NameRange.StartPosition.Offset,
    lDefinition.NameRange.EndPosition.Offset, AName);
end;

function TNexusScriptEditDocument.AddDefinition(AParentOffset: Integer;
  const AKind, AName, ABody: string): Boolean;
var
  lDefinition: TNexusScriptSourceDefinition;
  lKinds: TStringList;
  lOffset: Integer;
  lFragment: TNexusScriptCompiler;
begin
  if not IsName(AKind) or not IsName(AName) then
    Exit(Reject('Definition kind and name must each be one unquoted word.'));
  lFragment := ParseFragment(AKind + ' ' + AName + ' {' + ABody + '}');
  if lFragment = nil then Exit(False);
  lFragment.Free;
  lKinds := TStringList.Create;
  try
    GetDefinitionKinds(AParentOffset, lKinds);
    if lKinds.IndexOf(AKind) < 0 then Exit(Reject('Definition kind is not allowed here.'));
  finally
    lKinds.Free;
  end;
  lDefinition := FindDefinition(AParentOffset);
  lOffset := Length(FSourceText);
  if lDefinition <> nil then lOffset := lDefinition.BodyEndRange.StartPosition.Offset;
  Result := Replace(lOffset, lOffset, LineEnding + AKind + ' ' + AName +
    ' {' + LineEnding + ABody + LineEnding + '}' + LineEnding);
end;

function TNexusScriptEditDocument.RemoveProperty(AOwnerOffset: Integer;
  const AName: string): Boolean;
var
  lRange: TNexusScriptRange;
begin
  if not CanRemoveProperty(AOwnerOffset, AName) then
    Exit(Reject('This property is required or is not present.'));
  lRange := FindDefinition(AOwnerOffset).FindProperty(AName).SourceRange;
  Result := Replace(lRange.StartPosition.Offset, lRange.EndPosition.Offset, '');
end;

function TNexusScriptEditDocument.RemoveDefinition(AOffset: Integer): Boolean;
var
  lRange: TNexusScriptRange;
begin
  if not CanRemoveDefinition(AOffset) then
    Exit(Reject('This definition is required or is not present.'));
  lRange := FindDefinition(AOffset).SourceRange;
  Result := Replace(lRange.StartPosition.Offset, lRange.EndPosition.Offset, '');
end;

function TNexusScriptEditDocument.AddArrayItem(AArrayOffset: Integer;
  const ASourceValue, AEntryName: string): Boolean;
var
  lArray: TNexusScriptSourceValue;
  lOffset: Integer;
  lText: string;
begin
  lArray := FindValue(AArrayOffset);
  if (lArray = nil) or (lArray.Kind <> nsvArray) then Exit(Reject('A source array is required.'));
  if (AEntryName <> '') and not IsName(AEntryName) then
    Exit(Reject('An array entry name must be one unquoted word.'));
  { Wrapping an entry also checks named and inline-definition array syntax. }
  lText := ASourceValue;
  if AEntryName <> '' then lText := AEntryName + ': ' + lText;
  if not CheckValueSyntax(lText, True) then Exit(False);
  lOffset := lArray.SourceRange.StartPosition.Offset + 1;
  if lArray.Items.Count > 0 then
  begin
    lOffset := ValueRange(lArray.Items[lArray.Items.Count - 1]).EndPosition.Offset;
    lText := ', ' + lText;
  end;
  Result := Replace(lOffset, lOffset, lText);
end;

function TNexusScriptEditDocument.RemoveArrayItem(AArrayOffset, AIndex: Integer): Boolean;
var
  lArray: TNexusScriptSourceValue;
  lRange: TNexusScriptRange;
  lStart, lEnd: Integer;
begin
  lArray := FindValue(AArrayOffset);
  if (lArray = nil) or (lArray.Kind <> nsvArray) or
    (AIndex < 0) or (AIndex >= lArray.Items.Count) then Exit(Reject('Array item was not found.'));
  lRange := EntryRange(lArray.Items[AIndex]);
  lStart := lRange.StartPosition.Offset;
  lEnd := lRange.EndPosition.Offset;
  if lArray.Items.Count = 1 then
  begin
    lStart := lArray.SourceRange.StartPosition.Offset + 1;
    lEnd := lArray.SourceRange.EndPosition.Offset - 1;
  end
  else if AIndex = 0 then lEnd := EntryRange(lArray.Items[1]).StartPosition.Offset
  else lStart := ValueRange(lArray.Items[AIndex - 1]).EndPosition.Offset;
  Result := Replace(lStart, lEnd, '');
end;

function TNexusScriptEditDocument.RenameArrayEntry(AArrayOffset, AIndex: Integer;
  const AName: string): Boolean;
var
  lArray, lItem: TNexusScriptSourceValue;
  lStart, lEnd: Integer;
  lText: string;
begin
  lArray := FindValue(AArrayOffset);
  if (lArray = nil) or (lArray.Kind <> nsvArray) or (AIndex < 0) or
    (AIndex >= lArray.Items.Count) then Exit(Reject('Array item was not found.'));
  if (AName <> '') and not IsName(AName) then
    Exit(Reject('An array entry name must be one unquoted word.'));
  lItem := lArray.Items[AIndex];
  if lItem.EntryName = AName then Exit(True);
  lStart := ValueRange(lItem).StartPosition.Offset;
  lEnd := lStart;
  lText := '';
  if lItem.EntryName <> '' then
  begin
    lStart := lItem.EntryNameRange.StartPosition.Offset;
    if AName <> '' then lEnd := lItem.EntryNameRange.EndPosition.Offset;
  end;
  if AName <> '' then
  begin
    lText := AName;
    if lItem.EntryName = '' then lText := lText + ': ';
  end;
  Result := Replace(lStart, lEnd, lText);
end;

function TNexusScriptEditDocument.Undo: Boolean;
var
  lText: string;
  lAnalysis: TNexusScriptAnalysis;
begin
  if not CanUndo then Exit(False);
  lText := FUndo[FUndo.Count - 1];
  lAnalysis := Analyze(lText);
  FValid := CheckAnalysis(lAnalysis);
  FRedo.Add(FSourceText);
  FUndo.Delete(FUndo.Count - 1);
  Adopt(lAnalysis, lText);
  Result := True;
end;

function TNexusScriptEditDocument.Redo: Boolean;
var
  lText: string;
  lAnalysis: TNexusScriptAnalysis;
begin
  if not CanRedo then Exit(False);
  lText := FRedo[FRedo.Count - 1];
  lAnalysis := Analyze(lText);
  FValid := CheckAnalysis(lAnalysis);
  FUndo.Add(FSourceText);
  FRedo.Delete(FRedo.Count - 1);
  Adopt(lAnalysis, lText);
  Result := True;
end;

end.

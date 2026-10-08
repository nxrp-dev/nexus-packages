(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptSQLite;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  SQLite3Dyn,
  obNexusScriptModel,
  obNexusScriptDefinitionView,
  obNexusScriptLanguageDefinition,
  obNexusScriptEmitter;

type
  ENexusScriptSQLite = class(Exception);

  TNexusScriptSQLiteEmitter = class(TNexusScriptEmitter)
  private
    FView: TNexusScriptDefinitionView;
    FSQLiteLibrary: string;
    FLanguage: TNexusScriptLanguageDefinition;
    FHasDocument: Boolean;
    FHasDialect: Boolean;
    function QuoteIdentifier(const AValue: string): string;
    function SQLText(const AValue: string): string;
    function EffectiveValue(AValue: TNexusScriptCompiledValue):
      TNexusScriptCompiledValue;
    function DefinitionID(
      ADefinition: TNexusScriptCompiledDefinition): Integer;
    function ReferenceTarget(AValue: TNexusScriptCompiledValue):
      TNexusScriptCompiledDefinition;
    function ReferenceTable(const ATableName, APropertyName: string): string;
    function IsScalarArrayRule(APropertyRule: TNSPropertyRule): Boolean;
    function IsDefinitionArrayRule(APropertyRule: TNSPropertyRule): Boolean;
    function IsScalarArrayProperty(
      ADefinition: TNexusScriptCompiledDefinition;
      AProperty: TNexusScriptCompiledProperty): Boolean;
    function FindDefinitionStorage(
      ADefinition: TNexusScriptCompiledDefinition;
      out ATableName, AOwnerTableName: string;
      out AOrdinal: Integer): Boolean;
    function CreateSchemaSQL: string;
    function CreateDefinitionTableSQL(const ATableName: string): string;
    function CreateScalarArrayTableSQL(const ATableName: string): string;
    procedure ExecuteSQL(ADatabase: Psqlite3; const ASQL: string);
    procedure InsertScalarArray(ADatabase: Psqlite3;
      ADefinition: TNexusScriptCompiledDefinition;
      AProperty: TNexusScriptCompiledProperty);
    procedure InsertDefinitions(ADatabase: Psqlite3);
    procedure Initialize(const ASQLiteLibrary: string);
    procedure PopulateDatabase(ADatabase: Psqlite3);
  public
    constructor Create; overload; override;
    constructor Create(const ASQLiteLibrary: string); reintroduce; overload;
    destructor Destroy; override;
    class function GetFactoryName: string; override;
    procedure AddDocument(
      ADocument: TNexusScriptCompiledDocument); override;
    procedure WriteArtifact(AStream: TStream); overload; override;
    procedure WriteDatabase(const AFileName: string);
  end;

implementation

uses
  ctypes,
  tpNexusScript,
  obNXClassFactory;

class function TNexusScriptSQLiteEmitter.GetFactoryName: string;
begin
  Result := 'sqlite';
end;

function TNexusScriptSQLiteEmitter.QuoteIdentifier(
  const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
end;

function TNexusScriptSQLiteEmitter.SQLText(const AValue: string): string;
begin
  Result := QuotedStr(AValue);
end;

function TNexusScriptSQLiteEmitter.EffectiveValue(
  AValue: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
begin
  Result := AValue;
  while (Result <> nil) and (Result.EffectiveValue <> nil) do
    Result := Result.EffectiveValue;
end;

function TNexusScriptSQLiteEmitter.DefinitionID(
  ADefinition: TNexusScriptCompiledDefinition): Integer;
begin
  Result := FView.Definitions.IndexOf(ADefinition) + 1;
  if Result <= 0 then
    raise ENexusScriptSQLite.CreateFmt(
      'Definition %s is not part of the consumer artifact.',
      [ADefinition.Name]);
end;

function TNexusScriptSQLiteEmitter.ReferenceTarget(
  AValue: TNexusScriptCompiledValue): TNexusScriptCompiledDefinition;
var
  lTarget, lCandidate: TNexusScriptCompiledDefinition;
begin
  Result := nil;
  if (AValue = nil) or (AValue.Kind <> nsvReference) then Exit;
  lTarget := AValue.DefinitionValue;
  if lTarget = nil then Exit;
  if FView.Definitions.IndexOf(lTarget) >= 0 then Exit(lTarget);

  { Imported copies refer to the same authored definition as an included row. }
  for lCandidate in FView.Definitions do
    if (lTarget.SourceRange.SourceName <> '') and
      (lCandidate.SourceRange.SourceName = lTarget.SourceRange.SourceName) and
      (lCandidate.SourceRange.StartPosition.Offset =
        lTarget.SourceRange.StartPosition.Offset) and
      (lCandidate.SourceRange.EndPosition.Offset =
        lTarget.SourceRange.EndPosition.Offset) and
      SameText(lCandidate.Kind, lTarget.Kind) and
      SameText(lCandidate.Name, lTarget.Name) then
    begin
      if Result <> nil then
        raise ENexusScriptSQLite.CreateFmt(
          'Reference @%s has more than one matching authored row.',
          [AValue.SourceText]);
      Result := lCandidate;
    end;
  if Result = nil then
    raise ENexusScriptSQLite.CreateFmt(
      'Reference @%s targets definition %s outside the SQLite artifact.',
      [AValue.SourceText, lTarget.Name]);
end;

function TNexusScriptSQLiteEmitter.ReferenceTable(
  const ATableName, APropertyName: string): string;
var
  lDefinition, lTarget: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
  lStorageTable, lOwnerTable, lTargetTable: string;
  lOrdinal: Integer;
begin
  Result := '';
  for lDefinition in FView.Definitions do
  begin
    lProperty := lDefinition.FindProperty(APropertyName);
    if lProperty = nil then Continue;
    if not FindDefinitionStorage(lDefinition, lStorageTable, lOwnerTable,
      lOrdinal) or not SameText(lStorageTable, ATableName) then Continue;
    lTarget := ReferenceTarget(lProperty.Value);
    if lTarget = nil then Continue;
    if not FindDefinitionStorage(lTarget, lTargetTable, lOwnerTable,
      lOrdinal) then
      raise ENexusScriptSQLite.CreateFmt(
        'Cannot determine SQLite table for reference @%s.',
        [lProperty.Value.SourceText]);
    if (Result <> '') and not SameText(Result, lTargetTable) then
      raise ENexusScriptSQLite.CreateFmt(
        'Reference property %s.%s targets both %s and %s tables.',
        [ATableName, APropertyName, Result, lTargetTable]);
    Result := lTargetTable;
  end;
end;

function TNexusScriptSQLiteEmitter.IsScalarArrayRule(
  APropertyRule: TNSPropertyRule): Boolean;
var
  lValueRule: TNSValueRule;
  lArrayRule: TNSArrayRule;
begin
  lValueRule := APropertyRule.ValueRule;
  lArrayRule := lValueRule.ArrayRule;
  Result := (lArrayRule <> nil) and lArrayRule.HasEntryCategories and
    (lArrayRule.EntryCategories = [necText]);
end;

function TNexusScriptSQLiteEmitter.IsDefinitionArrayRule(
  APropertyRule: TNSPropertyRule): Boolean;
var
  lArrayRule: TNSArrayRule;
begin
  lArrayRule := APropertyRule.ValueRule.ArrayRule;
  Result := (lArrayRule <> nil) and lArrayRule.HasEntryCategories and
    (lArrayRule.EntryCategories = [necDefinition]) and
    (lArrayRule.DefinitionKindCount > 0);
end;

function TNexusScriptSQLiteEmitter.IsScalarArrayProperty(
  ADefinition: TNexusScriptCompiledDefinition;
  AProperty: TNexusScriptCompiledProperty): Boolean;
var
  lDefinitionRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lArrayValue, lItemValue: TNexusScriptCompiledValue;
  lItemIndex: Integer;
begin
  Result := False;
  lArrayValue := EffectiveValue(AProperty.Value);
  if (lArrayValue = nil) or (lArrayValue.Kind <> nsvArray) then
    Exit;
  if FHasDialect then
  begin
    lDefinitionRule := FLanguage.FindDefinitionRule(ADefinition.Kind);
    if lDefinitionRule <> nil then
    begin
      lPropertyRule := lDefinitionRule.FindPropertyRule(AProperty.Name);
      if lPropertyRule <> nil then
        Exit(IsScalarArrayRule(lPropertyRule));
    end;
  end;
  if lArrayValue.Items.Count = 0 then
    Exit;
  Result := True;
  for lItemIndex := 0 to lArrayValue.Items.Count - 1 do
  begin
    lItemValue := EffectiveValue(lArrayValue.Items[lItemIndex]);
    if (lItemValue = nil) or
      (lItemValue.StructuralDefinition <> nil) or
      not lItemValue.HasEffectiveText then
      Exit(False);
  end;
end;

function TNexusScriptSQLiteEmitter.FindDefinitionStorage(
  ADefinition: TNexusScriptCompiledDefinition;
  out ATableName, AOwnerTableName: string;
  out AOrdinal: Integer): Boolean;
var
  lCandidateOwner: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
  lArrayValue, lItemValue: TNexusScriptCompiledValue;
  lChildIndex, lItemIndex, lOwnerOrdinal: Integer;
  lUnusedOwnerTable: string;
begin
  Result := False;
  ATableName := '';
  AOwnerTableName := '';
  AOrdinal := -1;
  if FView.Roots.IndexOf(ADefinition) >= 0 then
  begin
    ATableName := ADefinition.Name;
    Exit(True);
  end;
  for lCandidateOwner in FView.Definitions do
  begin
    for lChildIndex := 0 to lCandidateOwner.Children.Count - 1 do
      if lCandidateOwner.Children[lChildIndex] = ADefinition then
      begin
        ATableName := ADefinition.Name;
        if not FindDefinitionStorage(lCandidateOwner, AOwnerTableName,
          lUnusedOwnerTable, lOwnerOrdinal) then
          raise ENexusScriptSQLite.CreateFmt(
            'Cannot determine storage for owner %s.',
            [lCandidateOwner.Name]);
        Exit(True);
      end;
    for lProperty in lCandidateOwner.Properties do
    begin
      if lProperty.Value.Kind = nsvReference then
        Continue;
      lArrayValue := EffectiveValue(lProperty.Value);
      if lArrayValue = nil then
        Continue;
      if lArrayValue.StructuralDefinition = ADefinition then
      begin
        ATableName := lProperty.Name;
        if not FindDefinitionStorage(lCandidateOwner, AOwnerTableName,
          lUnusedOwnerTable, lOwnerOrdinal) then
          raise ENexusScriptSQLite.CreateFmt(
            'Cannot determine storage for owner %s.',
            [lCandidateOwner.Name]);
        Exit(True);
      end;
      if lArrayValue.Kind <> nsvArray then
        Continue;
      for lItemIndex := 0 to lArrayValue.Items.Count - 1 do
      begin
        if lArrayValue.Items[lItemIndex].Kind = nsvReference then
          Continue;
        lItemValue := EffectiveValue(lArrayValue.Items[lItemIndex]);
        if lItemValue.StructuralDefinition = ADefinition then
        begin
          ATableName := lProperty.Name;
          if not FindDefinitionStorage(lCandidateOwner, AOwnerTableName,
            lUnusedOwnerTable, lOwnerOrdinal) then
            raise ENexusScriptSQLite.CreateFmt(
              'Cannot determine storage for owner %s.',
              [lCandidateOwner.Name]);
          AOrdinal := lItemIndex;
          Exit(True);
        end;
      end;
    end;
  end;
end;

function TNexusScriptSQLiteEmitter.CreateSchemaSQL: string;
var
  lDefinition: TNexusScriptCompiledDefinition;
  lDefinitionRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lProperty: TNexusScriptCompiledProperty;
  lDefinitionTables, lScalarArrayTables, lDropTables: TStringList;
  lTableName, lOwnerTableName: string;
  lIndex, lPropertyIndex, lOrdinal: Integer;

  procedure AddName(AList: TStringList; const AName: string);
  begin
    if (AName <> '') and (AList.IndexOf(AName) < 0) then
      AList.Add(AName);
  end;
begin
  lDefinitionTables := TStringList.Create;
  lScalarArrayTables := TStringList.Create;
  lDropTables := TStringList.Create;
  try
    lDefinitionTables.CaseSensitive := False;
    lScalarArrayTables.CaseSensitive := False;
    lDropTables.CaseSensitive := False;
    for lDefinition in FView.Definitions do
    begin
      if not FindDefinitionStorage(lDefinition, lTableName,
        lOwnerTableName, lOrdinal) then
        raise ENexusScriptSQLite.CreateFmt(
          'Cannot determine SQLite table for definition %s.',
          [lDefinition.Name]);
      AddName(lDefinitionTables, lTableName);
      lDefinitionRule := nil;
      if FHasDialect then
        lDefinitionRule := FLanguage.FindDefinitionRule(lDefinition.Kind);
      if lDefinitionRule <> nil then
      begin
        for lPropertyIndex := 0 to
          lDefinitionRule.PropertyRuleCount - 1 do
        begin
          lPropertyRule := lDefinitionRule.PropertyRules[lPropertyIndex];
          if IsScalarArrayRule(lPropertyRule) then
            AddName(lScalarArrayTables, lPropertyRule.Name)
          else if IsDefinitionArrayRule(lPropertyRule) then
            AddName(lDefinitionTables, lPropertyRule.Name);
        end;
      end;
      for lProperty in lDefinition.Properties do
        if IsScalarArrayProperty(lDefinition, lProperty) then
          AddName(lScalarArrayTables, lProperty.Name);
    end;

    for lIndex := 0 to lDefinitionTables.Count - 1 do
      if lScalarArrayTables.IndexOf(lDefinitionTables[lIndex]) >= 0 then
        raise ENexusScriptSQLite.CreateFmt(
          'SQLite table %s is both definition-valued and scalar-valued.',
          [lDefinitionTables[lIndex]]);
    for lIndex := 0 to lDefinitionTables.Count - 1 do
      AddName(lDropTables, lDefinitionTables[lIndex]);
    for lIndex := 0 to lScalarArrayTables.Count - 1 do
      AddName(lDropTables, lScalarArrayTables[lIndex]);
    if FHasDialect then
      for lIndex := 0 to FLanguage.DefinitionRuleCount - 1 do
        AddName(lDropTables, FLanguage.DefinitionRules[lIndex].KindName);

    Result := 'BEGIN IMMEDIATE;' + LineEnding;
    for lIndex := lDropTables.Count - 1 downto 0 do
      Result := Result + 'DROP TABLE IF EXISTS ' +
        QuoteIdentifier(lDropTables[lIndex]) + ';' + LineEnding;
    for lIndex := 0 to lDefinitionTables.Count - 1 do
      Result := Result + CreateDefinitionTableSQL(
        lDefinitionTables[lIndex]) + LineEnding;
    for lIndex := 0 to lScalarArrayTables.Count - 1 do
      Result := Result + CreateScalarArrayTableSQL(
        lScalarArrayTables[lIndex]) +
        LineEnding;
  finally
    lDropTables.Free;
    lScalarArrayTables.Free;
    lDefinitionTables.Free;
  end;
end;

function TNexusScriptSQLiteEmitter.CreateDefinitionTableSQL(
  const ATableName: string): string;
var
  lDefinition: TNexusScriptCompiledDefinition;
  lDefinitionRule, lAllowedRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lProperty: TNexusScriptCompiledProperty;
  lValue: TNexusScriptCompiledValue;
  lArrayRule: TNSArrayRule;
  lOwnerTables, lKinds, lColumns, lReferences: TStringList;
  lStorageTable, lOwnerTable, lColumnName: string;
  lDefinitionIndex, lPropertyIndex, lKindIndex, lOrdinal: Integer;
  lHasOrdinal: Boolean;

  procedure AddName(AList: TStringList; const AName: string);
  begin
    if (AName <> '') and (AList.IndexOf(AName) < 0) then
      AList.Add(AName);
  end;
begin
  lOwnerTables := TStringList.Create;
  lKinds := TStringList.Create;
  lColumns := TStringList.Create;
  lReferences := TStringList.Create;
  try
    lOwnerTables.CaseSensitive := False;
    lKinds.CaseSensitive := False;
    lColumns.CaseSensitive := False;
    lReferences.CaseSensitive := False;
    lHasOrdinal := False;
    for lDefinition in FView.Definitions do
    begin
      if not FindDefinitionStorage(lDefinition, lStorageTable,
        lOwnerTable, lOrdinal) or not SameText(lStorageTable, ATableName) then
        Continue;
      AddName(lOwnerTables, lOwnerTable);
      AddName(lKinds, lDefinition.Kind);
      lHasOrdinal := lHasOrdinal or (lOrdinal >= 0);
      for lProperty in lDefinition.Properties do
        if ReferenceTarget(lProperty.Value) <> nil then
          AddName(lReferences, lProperty.Name);
      if not FHasDialect then
        for lProperty in lDefinition.Properties do
        begin
          lValue := EffectiveValue(lProperty.Value);
          if (lValue <> nil) and (lValue.Kind <> nsvArray) and
            (lValue.StructuralDefinition = nil) and
            lValue.HasEffectiveText then
          begin
            if SameText(lProperty.Name, 'Name') then
              raise ENexusScriptSQLite.CreateFmt(
                'Definition %s declares reserved property Name.',
                [lDefinition.Name]);
            AddName(lColumns, lProperty.Name);
          end;
        end;
    end;
    if FHasDialect then
      for lDefinition in FView.Definitions do
      begin
        if not FindDefinitionStorage(lDefinition, lStorageTable,
          lOwnerTable, lOrdinal) then
          Continue;
        lDefinitionRule := FLanguage.FindDefinitionRule(lDefinition.Kind);
        if lDefinitionRule = nil then
          Continue;
        lPropertyRule := lDefinitionRule.FindPropertyRule(ATableName);
        if (lPropertyRule = nil) or
          not IsDefinitionArrayRule(lPropertyRule) then
          Continue;
        AddName(lOwnerTables, lStorageTable);
        lHasOrdinal := True;
        lArrayRule := lPropertyRule.ValueRule.ArrayRule;
        for lKindIndex := 0 to lArrayRule.DefinitionKindCount - 1 do
          AddName(lKinds, lArrayRule.DefinitionKinds[lKindIndex]);
      end;
    if FHasDialect then
      for lKindIndex := 0 to lKinds.Count - 1 do
      begin
        lAllowedRule := FLanguage.FindDefinitionRule(lKinds[lKindIndex]);
        if lAllowedRule = nil then
          Continue;
        for lPropertyIndex := 0 to lAllowedRule.PropertyRuleCount - 1 do
        begin
          lPropertyRule := lAllowedRule.PropertyRules[lPropertyIndex];
          if lPropertyRule.ValueRule.ScalarKind = nskNone then
            Continue;
          if SameText(lPropertyRule.Name, 'Name') then
            raise ENexusScriptSQLite.CreateFmt(
              'Dialect definition %s declares reserved property Name.',
              [lAllowedRule.KindName]);
          AddName(lColumns, lPropertyRule.Name);
        end;
      end;

    Result := 'CREATE TABLE ' + QuoteIdentifier(ATableName) + ' (' +
      QuoteIdentifier('nx_id') + ' INTEGER PRIMARY KEY NOT NULL, ' +
      QuoteIdentifier('Name') + ' TEXT NOT NULL';
    for lDefinitionIndex := 0 to lOwnerTables.Count - 1 do
    begin
      lColumnName := 'nx_' + LowerCase(lOwnerTables[lDefinitionIndex]) +
        '_id';
      Result := Result + ', ' + QuoteIdentifier(lColumnName) +
        ' INTEGER REFERENCES ' +
        QuoteIdentifier(lOwnerTables[lDefinitionIndex]) + ' (' +
        QuoteIdentifier('nx_id') + ')';
    end;
    if lHasOrdinal then
      Result := Result + ', ' + QuoteIdentifier('nx_ordinal') + ' INTEGER';
    for lPropertyIndex := 0 to lColumns.Count - 1 do
    begin
      Result := Result + ', ' + QuoteIdentifier(lColumns[lPropertyIndex]) +
        ' TEXT';
      if FHasDialect and (lKinds.Count = 1) then
      begin
        lAllowedRule := FLanguage.FindDefinitionRule(lKinds[0]);
        if lAllowedRule <> nil then
        begin
          lPropertyRule := lAllowedRule.FindPropertyRule(
            lColumns[lPropertyIndex]);
          if (lPropertyRule <> nil) and lPropertyRule.Required then
            Result := Result + ' NOT NULL';
        end;
      end;
    end;
    for lPropertyIndex := 0 to lReferences.Count - 1 do
    begin
      lColumnName := lReferences[lPropertyIndex] + '_id';
      Result := Result + ', ' + QuoteIdentifier(lColumnName) +
        ' INTEGER REFERENCES ' + QuoteIdentifier(ReferenceTable(
          ATableName, lReferences[lPropertyIndex])) +
        ' (' + QuoteIdentifier('nx_id') + ') DEFERRABLE INITIALLY DEFERRED';
    end;
    Result := Result + ');';
  finally
    lReferences.Free;
    lColumns.Free;
    lKinds.Free;
    lOwnerTables.Free;
  end;
end;

function TNexusScriptSQLiteEmitter.CreateScalarArrayTableSQL(
  const ATableName: string): string;
var
  lDefinition: TNexusScriptCompiledDefinition;
  lDefinitionRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lProperty: TNexusScriptCompiledProperty;
  lOwnerTables: TStringList;
  lStorageTable, lOwnerTable, lColumnName: string;
  lOwnerIndex, lOrdinal: Integer;

  procedure AddOwner(const AName: string);
  begin
    if (AName <> '') and (lOwnerTables.IndexOf(AName) < 0) then
      lOwnerTables.Add(AName);
  end;
begin
  lOwnerTables := TStringList.Create;
  try
    lOwnerTables.CaseSensitive := False;
    for lDefinition in FView.Definitions do
    begin
      if not FindDefinitionStorage(lDefinition, lStorageTable,
        lOwnerTable, lOrdinal) then
        Continue;
      for lProperty in lDefinition.Properties do
        if SameText(lProperty.Name, ATableName) and
          IsScalarArrayProperty(lDefinition, lProperty) then
          AddOwner(lStorageTable);
      if FHasDialect then
      begin
        lDefinitionRule := FLanguage.FindDefinitionRule(lDefinition.Kind);
        if lDefinitionRule <> nil then
        begin
          lPropertyRule := lDefinitionRule.FindPropertyRule(ATableName);
          if (lPropertyRule <> nil) and
            IsScalarArrayRule(lPropertyRule) then
            AddOwner(lStorageTable);
        end;
      end;
    end;
    Result := 'CREATE TABLE ' + QuoteIdentifier(ATableName) + ' (' +
      QuoteIdentifier('nx_id') + ' INTEGER PRIMARY KEY NOT NULL';
    for lOwnerIndex := 0 to lOwnerTables.Count - 1 do
    begin
      lColumnName := 'nx_' + LowerCase(lOwnerTables[lOwnerIndex]) + '_id';
      Result := Result + ', ' + QuoteIdentifier(lColumnName) +
        ' INTEGER REFERENCES ' + QuoteIdentifier(lOwnerTables[lOwnerIndex]) +
        ' (' + QuoteIdentifier('nx_id') + ')';
    end;
    Result := Result + ', ' + QuoteIdentifier('nx_ordinal') +
      ' INTEGER NOT NULL, ' + QuoteIdentifier('nx_value') +
      ' TEXT NOT NULL);';
  finally
    lOwnerTables.Free;
  end;
end;

procedure TNexusScriptSQLiteEmitter.ExecuteSQL(ADatabase: Psqlite3;
  const ASQL: string);
var
  lError: PAnsiChar;
  lCode: cint;
  lSQL: UTF8String;
begin
  lError := nil;
  lSQL := UTF8String(ASQL);
  lCode := sqlite3_exec(ADatabase, PAnsiChar(lSQL), nil, nil, @lError);
  if lCode <> SQLITE_OK then
  begin
    if lError <> nil then
    begin
      try
        raise ENexusScriptSQLite.Create(UTF8Decode(StrPas(lError)));
      finally
        sqlite3_free(lError);
      end;
    end;
    raise ENexusScriptSQLite.CreateFmt('SQLite error %d: %s',
      [lCode, UTF8Decode(StrPas(sqlite3_errmsg(ADatabase)))]);
  end;
end;

procedure TNexusScriptSQLiteEmitter.InsertScalarArray(ADatabase: Psqlite3;
  ADefinition: TNexusScriptCompiledDefinition;
  AProperty: TNexusScriptCompiledProperty);
var
  lArrayValue, lItem, lItemValue: TNexusScriptCompiledValue;
  lItemIndex, lOwnerOrdinal: Integer;
  lOwnerTable, lUnusedOwnerTable, lSQL: string;
begin
  lArrayValue := EffectiveValue(AProperty.Value);
  if lArrayValue.Kind <> nsvArray then
    raise ENexusScriptSQLite.CreateFmt(
      'Property %s on %s must be an array.',
      [AProperty.Name, ADefinition.Name]);
  if not FindDefinitionStorage(ADefinition, lOwnerTable,
    lUnusedOwnerTable, lOwnerOrdinal) then
    raise ENexusScriptSQLite.CreateFmt(
      'Cannot determine SQLite table for definition %s.',
      [ADefinition.Name]);

  for lItemIndex := 0 to lArrayValue.Items.Count - 1 do
  begin
    lItem := lArrayValue.Items[lItemIndex];
    lItemValue := EffectiveValue(lItem);
    if not lItemValue.HasEffectiveText then
      raise ENexusScriptSQLite.CreateFmt(
        'Scalar array %s on %s contains a non-text item.',
        [AProperty.Name, ADefinition.Name]);
    lSQL := 'INSERT INTO ' + QuoteIdentifier(AProperty.Name) + ' (' +
      QuoteIdentifier('nx_' + LowerCase(lOwnerTable) + '_id') + ', ' +
      QuoteIdentifier('nx_ordinal') + ', ' + QuoteIdentifier('nx_value') +
      ') VALUES (' + IntToStr(DefinitionID(ADefinition)) + ', ' +
      IntToStr(lItemIndex) + ', ' + SQLText(lItemValue.EffectiveText) + ');';
    ExecuteSQL(ADatabase, lSQL);
  end;
end;

procedure TNexusScriptSQLiteEmitter.InsertDefinitions(ADatabase: Psqlite3);
var
  lDefinition, lTarget: TNexusScriptCompiledDefinition;
  lDefinitionRule: TNSDefinitionRule;
  lPropertyRule: TNSPropertyRule;
  lProperty: TNexusScriptCompiledProperty;
  lValue: TNexusScriptCompiledValue;
  lColumns, lValues, lSQL: string;
  lTableName, lOwnerTableName: string;
  lPropertyIndex, lOrdinal: Integer;
begin
  for lDefinition in FView.Definitions do
  begin
    if not FindDefinitionStorage(lDefinition, lTableName,
      lOwnerTableName, lOrdinal) then
      raise ENexusScriptSQLite.CreateFmt(
        'Cannot determine SQLite table for definition %s.',
        [lDefinition.Name]);
    lColumns := QuoteIdentifier('nx_id') + ', ' + QuoteIdentifier('Name');
    lValues := IntToStr(DefinitionID(lDefinition)) + ', ' +
      SQLText(lDefinition.Name);
    if lOwnerTableName <> '' then
    begin
      lColumns := lColumns + ', ' +
        QuoteIdentifier('nx_' + LowerCase(lOwnerTableName) + '_id');
      lValues := lValues + ', ' + IntToStr(DefinitionID(lDefinition.Parent));
    end;
    if lOrdinal >= 0 then
    begin
      lColumns := lColumns + ', ' + QuoteIdentifier('nx_ordinal');
      lValues := lValues + ', ' + IntToStr(lOrdinal);
    end;

    lDefinitionRule := nil;
    if FHasDialect then
      lDefinitionRule := FLanguage.FindDefinitionRule(lDefinition.Kind);
    if lDefinitionRule <> nil then
    begin
      for lPropertyIndex := 0 to
        lDefinitionRule.PropertyRuleCount - 1 do
      begin
        lPropertyRule := lDefinitionRule.PropertyRules[lPropertyIndex];
        if lPropertyRule.ValueRule.ScalarKind = nskNone then
          Continue;
        lColumns := lColumns + ', ' + QuoteIdentifier(lPropertyRule.Name);
        lProperty := lDefinition.FindProperty(lPropertyRule.Name);
        if lProperty = nil then
        begin
          if lPropertyRule.Required then
            raise ENexusScriptSQLite.CreateFmt(
              'Definition %s requires property %s.',
              [lDefinition.Name, lPropertyRule.Name]);
          lValues := lValues + ', NULL';
          Continue;
        end;
        lValue := EffectiveValue(lProperty.Value);
        if lValue.HasEffectiveText then
          lValues := lValues + ', ' + SQLText(lValue.EffectiveText)
        else
          lValues := lValues + ', NULL';
      end;
    end
    else
      for lProperty in lDefinition.Properties do
      begin
        lValue := EffectiveValue(lProperty.Value);
        if (lValue = nil) or (lValue.Kind = nsvArray) or
          (lValue.StructuralDefinition <> nil) or
          not lValue.HasEffectiveText then
          Continue;
        lColumns := lColumns + ', ' + QuoteIdentifier(lProperty.Name);
        lValues := lValues + ', ' + SQLText(lValue.EffectiveText);
      end;

    for lProperty in lDefinition.Properties do
    begin
      lTarget := ReferenceTarget(lProperty.Value);
      if lTarget = nil then Continue;
      lColumns := lColumns + ', ' + QuoteIdentifier(lProperty.Name + '_id');
      lValues := lValues + ', ' + IntToStr(DefinitionID(lTarget));
    end;

    lSQL := 'INSERT INTO ' + QuoteIdentifier(lTableName) + ' (' +
      lColumns + ') VALUES (' + lValues + ');';
    ExecuteSQL(ADatabase, lSQL);
  end;

  for lDefinition in FView.Definitions do
    for lProperty in lDefinition.Properties do
      if IsScalarArrayProperty(lDefinition, lProperty) then
        InsertScalarArray(ADatabase, lDefinition, lProperty);
end;

procedure TNexusScriptSQLiteEmitter.Initialize(const ASQLiteLibrary: string);
begin
  FSQLiteLibrary := ASQLiteLibrary;
  FView := TNexusScriptDefinitionView.Create;
  FLanguage := TNexusScriptLanguageDefinition.Create;
end;

constructor TNexusScriptSQLiteEmitter.Create;
begin
  inherited Create;
  Initialize('');
end;

constructor TNexusScriptSQLiteEmitter.Create(const ASQLiteLibrary: string);
begin
  inherited Create;
  Initialize(ASQLiteLibrary);
end;

destructor TNexusScriptSQLiteEmitter.Destroy;
begin
  FLanguage.Free;
  FView.Free;
  inherited Destroy;
end;

procedure TNexusScriptSQLiteEmitter.AddDocument(
  ADocument: TNexusScriptCompiledDocument);
var
  lDiagnostic: TNSLanguageDiagnostic;
  lIndex: Integer;
  lMessage: string;
begin
  if ADocument = nil then
    raise ENexusScriptSQLite.Create('SQLite projection requires a document.');
  if not FHasDocument then
  begin
    FHasDialect := ADocument.DialectDocument <> nil;
    if FHasDialect and not FLanguage.Normalize(ADocument.DialectDocument) then
    begin
      lMessage := 'Cannot normalize document dialect';
      for lIndex := 0 to FLanguage.DiagnosticCount - 1 do
      begin
        lDiagnostic := FLanguage.Diagnostics[lIndex];
        lMessage := lMessage + LineEnding + lDiagnostic.Code + ': ' +
          lDiagnostic.MessageText;
      end;
      raise ENexusScriptSQLite.Create(lMessage);
    end;
    FHasDocument := True;
  end
  else if FHasDialect <> (ADocument.DialectDocument <> nil) then
  begin
    raise ENexusScriptSQLite.Create(
      'SQLite projection cannot mix dialect and dialectless documents.');
  end;
  try
    FView.AddDocument(ADocument);
  except
    on E: Exception do
      raise ENexusScriptSQLite.Create(E.Message);
  end;
end;

procedure TNexusScriptSQLiteEmitter.WriteDatabase(const AFileName: string);
var
  lDatabase: Psqlite3;
  lFileName: UTF8String;
  lFullFileName: string;
  lCode: cint;
  lOwnSQLiteLibrary: Boolean;
begin
  if not FHasDocument then
    raise ENexusScriptSQLite.Create('No compiled document was added.');
  if AFileName = '' then
    raise ENexusScriptSQLite.Create('SQLite output file name is required.');
  lFullFileName := ExpandFileName(AFileName);
  if not ForceDirectories(ExtractFileDir(lFullFileName)) then
    raise ENexusScriptSQLite.CreateFmt(
      'Cannot create SQLite output directory for %s.', [AFileName]);
  lFileName := UTF8String(lFullFileName);
  lOwnSQLiteLibrary := not SQLite3IsLoaded;
  if lOwnSQLiteLibrary and not LoadSQLite3(FSQLiteLibrary) then
    raise ENexusScriptSQLite.Create(SQLite3LoadError);
  lDatabase := nil;
  try
    lCode := sqlite3_open_v2(PAnsiChar(lFileName), @lDatabase,
      SQLITE_OPEN_READWRITE or SQLITE_OPEN_CREATE, nil);
    if lCode <> SQLITE_OK then
    begin
      if lDatabase <> nil then
        raise ENexusScriptSQLite.Create(UTF8Decode(StrPas(
          sqlite3_errmsg(lDatabase))));
      raise ENexusScriptSQLite.CreateFmt('SQLite error %d opening %s.',
        [lCode, AFileName]);
    end;
    PopulateDatabase(lDatabase);
  finally
    if lDatabase <> nil then
      sqlite3_close(lDatabase);
    if lOwnSQLiteLibrary then
      UnloadSQLite3;
  end;
end;

procedure TNexusScriptSQLiteEmitter.PopulateDatabase(ADatabase: Psqlite3);
begin
  try
    ExecuteSQL(ADatabase, CreateSchemaSQL);
    InsertDefinitions(ADatabase);
    ExecuteSQL(ADatabase, 'COMMIT;');
  except
    sqlite3_exec(ADatabase, 'ROLLBACK;', nil, nil, nil);
    raise;
  end;
end;

procedure TNexusScriptSQLiteEmitter.WriteArtifact(AStream: TStream);
const
  cWriteChunkSize = 1024 * 1024;
var
  lDatabase: Psqlite3;
  lBuffer, lPosition: PByte;
  lSize, lRemaining: sqlite3_int64;
  lChunkSize: LongInt;
  lCode: cint;
  lOwnSQLiteLibrary: Boolean;
begin
  if not FHasDocument then
    raise ENexusScriptSQLite.Create('No compiled document was added.');
  if AStream = nil then
    raise ENexusScriptSQLite.Create('SQLite output stream is required.');
  lOwnSQLiteLibrary := not SQLite3IsLoaded;
  if lOwnSQLiteLibrary and not LoadSQLite3(FSQLiteLibrary) then
    raise ENexusScriptSQLite.Create(SQLite3LoadError);
  lDatabase := nil;
  try
    lCode := sqlite3_open_v2(':memory:', @lDatabase,
      SQLITE_OPEN_READWRITE or SQLITE_OPEN_CREATE, nil);
    if lCode <> SQLITE_OK then
    begin
      if lDatabase <> nil then
        raise ENexusScriptSQLite.Create(UTF8Decode(StrPas(
          sqlite3_errmsg(lDatabase))));
      raise ENexusScriptSQLite.CreateFmt(
        'SQLite error %d opening in-memory database.', [lCode]);
    end;
    PopulateDatabase(lDatabase);
    if not Assigned(sqlite3_serialize) or not Assigned(sqlite3_free) then
      raise ENexusScriptSQLite.Create(
        'The SQLite runtime does not support database serialization.');
    lSize := 0;
    lBuffer := sqlite3_serialize(lDatabase, 'main', @lSize, 0);
    if lBuffer = nil then
      raise ENexusScriptSQLite.Create(
        'SQLite could not serialize the generated database.');
    try
      lPosition := lBuffer;
      lRemaining := lSize;
      while lRemaining > 0 do
      begin
        if lRemaining > cWriteChunkSize then
          lChunkSize := cWriteChunkSize
        else
          lChunkSize := lRemaining;
        AStream.WriteBuffer(lPosition^, lChunkSize);
        Inc(lPosition, lChunkSize);
        Dec(lRemaining, lChunkSize);
      end;
    finally
      sqlite3_free(lBuffer);
    end;
  finally
    if lDatabase <> nil then
      sqlite3_close(lDatabase);
    if lOwnSQLiteLibrary then
      UnloadSQLite3;
  end;
end;

initialization
  TNXClassFactory.RegisterClass(TNexusScriptSQLiteEmitter);

end.

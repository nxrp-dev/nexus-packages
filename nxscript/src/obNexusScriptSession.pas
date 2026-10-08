(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptSession;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  tpNexusScript,
  obNexusScriptModel,
  obNexusScriptCompiler,
  obNexusScriptSourceProvider;

type
  TNexusScriptCompilationSession = class
  private
    FDialectRoot: string;
    FSelectedTargets: TNexusScriptTargetSelection;
    FSourceProvider: TNexusScriptSourceProvider;
    FOwnsSourceProvider: Boolean;
    FCompilers: TStringList;
    FAttemptedCompilers: TObjectList<TNexusScriptCompiler>;
    FAttemptedVersions: TList<Integer>;
    FDiagnostics: TNexusScriptDiagnosticList;
    FActiveFiles: TStringList;
    FEntryCompiler: TNexusScriptCompiler;
    FEntryAttemptCompiler: TNexusScriptCompiler;
    FLastError: string;
    function CompileDocument(const AFileName: string): TNexusScriptCompiler;
    function ExpandPatterns(ADocument: TNexusScriptSourceDocument): Boolean;
    function SelectMatchingFiles(const ASourceName, APattern: string;
      ARecursive: Boolean; const ASourceRange: TNexusScriptRange): TStringList;
    procedure AddDiagnostic(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    function SelectDefinition(ACompiler: TNexusScriptCompiler;
      const ASelector: string): TNexusScriptCompiledDefinition;
    function GetCompilerCount: Integer;
    function GetCompiler(AIndex: Integer): TNexusScriptCompiler;
    function GetAttemptedCompilerCount: Integer;
    function GetAttemptedCompiler(AIndex: Integer): TNexusScriptCompiler;
    function GetAttemptedVersion(AIndex: Integer): Integer;
    function FindName(AList: TStringList; const AName: string): Integer;
  public
    constructor Create(ASelectedTargets: TNexusScriptTargetSelection = nil;
      ASourceProvider: TNexusScriptSourceProvider = nil);
    destructor Destroy; override;
    function CompileFile(const AFileName: string): Boolean;
    function ResolveDependencyPath(const ASourceName,
      ADeclaredPath: string): string;
    function ResolveDialectPath(const ASourceName,
      ADeclaredPath: string): string;
    property EntryCompiler: TNexusScriptCompiler read FEntryCompiler;
    property EntryAttemptCompiler: TNexusScriptCompiler read FEntryAttemptCompiler;
    function FindCompiler(const AFileName: string): TNexusScriptCompiler;
    property CompilerCount: Integer read GetCompilerCount;
    property Compilers[AIndex: Integer]: TNexusScriptCompiler read GetCompiler;
    property AttemptedCompilerCount: Integer read GetAttemptedCompilerCount;
    property AttemptedCompilers[AIndex: Integer]: TNexusScriptCompiler
      read GetAttemptedCompiler;
    property AttemptedVersions[AIndex: Integer]: Integer read GetAttemptedVersion;
    property Diagnostics: TNexusScriptDiagnosticList read FDiagnostics;
    property DialectRoot: string read FDialectRoot write FDialectRoot;
    property LastError: string read FLastError;
    property SourceProvider: TNexusScriptSourceProvider read FSourceProvider;
  end;

implementation

constructor TNexusScriptCompilationSession.Create(
  ASelectedTargets: TNexusScriptTargetSelection;
  ASourceProvider: TNexusScriptSourceProvider);
begin
  inherited Create;
  FSourceProvider := ASourceProvider;
  FOwnsSourceProvider := FSourceProvider = nil;
  if FOwnsSourceProvider then
    FSourceProvider := TNexusScriptFileSourceProvider.Create;
  FSelectedTargets := TNexusScriptTargetSelection.Create;
  FSelectedTargets.Assign(ASelectedTargets);
  FCompilers := TStringList.Create;
  FAttemptedCompilers := TObjectList<TNexusScriptCompiler>.Create(True);
  FAttemptedVersions := TList<Integer>.Create;
  FDiagnostics := TNexusScriptDiagnosticList.Create(True);
  FActiveFiles := TStringList.Create;
end;

destructor TNexusScriptCompilationSession.Destroy;
begin
  FActiveFiles.Free;
  FCompilers.Free;
  FDiagnostics.Free;
  FAttemptedVersions.Free;
  FAttemptedCompilers.Free;
  FSelectedTargets.Free;
  if FOwnsSourceProvider then
    FSourceProvider.Free;
  inherited Destroy;
end;

procedure TNexusScriptCompilationSession.AddDiagnostic(const ACode,
  AMessageText: string; const ASourceRange: TNexusScriptRange);
begin
  FDiagnostics.Add(TNexusScriptDiagnostic.Create(ACode, AMessageText,
    ASourceRange));
end;

function TNexusScriptCompilationSession.FindName(AList: TStringList;
  const AName: string): Integer;
var
  lIndex: Integer;
begin
  for lIndex := 0 to AList.Count - 1 do
    if FSourceProvider.SameIdentity(AList[lIndex], AName) then
      Exit(lIndex);
  Result := -1;
end;

function TNexusScriptCompilationSession.ResolveDependencyPath(
  const ASourceName, ADeclaredPath: string): string;
begin
  if (ExtractFileDrive(ADeclaredPath) <> '') or
    ((ADeclaredPath <> '') and IsPathDelimiter(ADeclaredPath, 1)) then
    Result := FSourceProvider.CanonicalName(ADeclaredPath)
  else if not FSourceProvider.SupportsRelativePaths(ASourceName) then
    Result := ''
  else
    Result := FSourceProvider.CanonicalName(IncludeTrailingPathDelimiter(
      ExtractFileDir(ASourceName)) + ADeclaredPath);
end;

function TNexusScriptCompilationSession.ResolveDialectPath(
  const ASourceName, ADeclaredPath: string): string;
var
  lLocalName: string;
begin
  lLocalName := ResolveDependencyPath(ASourceName, ADeclaredPath);
  if ((lLocalName <> '') and FSourceProvider.Exists(lLocalName)) or
    (FDialectRoot = '') or
    (ExtractFileDrive(ADeclaredPath) <> '') or
    ((ADeclaredPath <> '') and IsPathDelimiter(ADeclaredPath, 1)) then
    Exit(lLocalName);
  Result := FSourceProvider.CanonicalName(IncludeTrailingPathDelimiter(
    FDialectRoot) + ADeclaredPath);
end;

function TNexusScriptCompilationSession.SelectMatchingFiles(
  const ASourceName, APattern: string;
  ARecursive: Boolean; const ASourceRange: TNexusScriptRange): TStringList;
var
  lFolderName: string;
  lDeclaredFolder: string;
  lFileNamePattern: string;
  lIndex: Integer;

begin
  Result := TStringList.Create;
  lDeclaredFolder := ExtractFileDir(APattern);
  if lDeclaredFolder = '' then
    lDeclaredFolder := '.';
  lFileNamePattern := ExtractFileName(APattern);
  lFolderName := ResolveDependencyPath(ASourceName, lDeclaredFolder);
  if (lFolderName = '') or not FSourceProvider.FolderExists(lFolderName) then
  begin
    FLastError := 'Unable to select files for ' + ASourceName +
      ': folder not found: ' + lDeclaredFolder;
    AddDiagnostic('dependency-folder-not-found', FLastError, ASourceRange);
    FreeAndNil(Result);
    Exit;
  end;
  try
    Result.Free;
    Result := FSourceProvider.SelectFiles(lFolderName, lFileNamePattern,
      ARecursive);
    lIndex := Result.Count - 1;
    while lIndex >= 0 do
    begin
      if FSourceProvider.SameIdentity(Result[lIndex], ASourceName) or
        (FindName(Result, Result[lIndex]) <> lIndex) then
        Result.Delete(lIndex);
      Dec(lIndex);
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Unable to select files in ' + lDeclaredFolder +
        ' for ' + ASourceName + ': ' + E.Message;
      AddDiagnostic('dependency-selection-failed', FLastError, ASourceRange);
      FreeAndNil(Result);
    end;
  end;
end;

function TNexusScriptCompilationSession.ExpandPatterns(
  ADocument: TNexusScriptSourceDocument): Boolean;
var
  lIndex: Integer;
  lPathIndex: Integer;
  lPaths: TStringList;
  lModule: TNexusScriptSourceModule;
  lInclude: TNexusScriptSourceInclude;
  lNewModule: TNexusScriptSourceModule;
  lNewInclude: TNexusScriptSourceInclude;
  lRange: TNexusScriptRange;
  lPathRange: TNexusScriptRange;
begin
  Result := False;
  lIndex := 0;
  while lIndex < ADocument.Modules.Count do
  begin
    lModule := ADocument.Modules[lIndex];
    if not lModule.Recursive and (Pos('*', lModule.Path) = 0) and
      (Pos('?', lModule.Path) = 0) then
    begin
      Inc(lIndex);
      Continue;
    end;
    lPaths := SelectMatchingFiles(ADocument.SourceName, lModule.Path,
      lModule.Recursive, lModule.PathRange);
    if lPaths = nil then
      Exit;
    try
      lRange := lModule.SourceRange;
      lPathRange := lModule.PathRange;
      ADocument.Modules.Delete(lIndex);
      for lPathIndex := 0 to lPaths.Count - 1 do
      begin
        lNewModule := TNexusScriptSourceModule.Create;
        lNewModule.Path := lPaths[lPathIndex];
        lNewModule.SourceRange := lRange;
        lNewModule.PathRange := lPathRange;
        ADocument.Modules.Insert(lIndex, lNewModule);
        Inc(lIndex);
      end;
    finally
      lPaths.Free;
    end;
  end;
  lIndex := 0;
  while lIndex < ADocument.Includes.Count do
  begin
    lInclude := ADocument.Includes[lIndex];
    if not lInclude.Recursive and (Pos('*', lInclude.Path) = 0) and
      (Pos('?', lInclude.Path) = 0) then
    begin
      Inc(lIndex);
      Continue;
    end;
    lPaths := SelectMatchingFiles(ADocument.SourceName, lInclude.Path,
      lInclude.Recursive, lInclude.PathRange);
    if lPaths = nil then
      Exit;
    try
      lRange := lInclude.SourceRange;
      lPathRange := lInclude.PathRange;
      ADocument.Includes.Delete(lIndex);
      for lPathIndex := 0 to lPaths.Count - 1 do
      begin
        lNewInclude := TNexusScriptSourceInclude.Create;
        lNewInclude.Path := lPaths[lPathIndex];
        lNewInclude.SourceRange := lRange;
        lNewInclude.PathRange := lPathRange;
        ADocument.Includes.Insert(lIndex, lNewInclude);
        Inc(lIndex);
      end;
    finally
      lPaths.Free;
    end;
  end;
  Result := True;
end;

function TNexusScriptCompilationSession.SelectDefinition(
  ACompiler: TNexusScriptCompiler;
  const ASelector: string): TNexusScriptCompiledDefinition;
begin
  Result := nil;
  if ACompiler.CompiledDocument = nil then
    Exit;
  Result := ACompiler.CompiledDocument.FindDefinition(ASelector);
end;

function TNexusScriptCompilationSession.CompileDocument(
  const AFileName: string): TNexusScriptCompiler;
var
  lCanonicalName: string;
  lIndex: Integer;
  lCompiler: TNexusScriptCompiler;
  lModule: TNexusScriptSourceModule;
  lImportedCompiler: TNexusScriptCompiler;
  lImportedDefinition: TNexusScriptCompiledDefinition;
  lImportedName: string;
  lDialect: TNexusScriptSourceDialect;
  lDialectCompiler: TNexusScriptCompiler;
  lDialectSourceName: string;
  lDeclaredDialectPath: string;
  lDialectRange: TNexusScriptRange;
  lInclude: TNexusScriptSourceInclude;
  lIncludedCompiler: TNexusScriptCompiler;
  lIncludedName: string;
  lSourceText: string;
  lSourceVersion: Integer;
begin
  Result := nil;
  lCanonicalName := FSourceProvider.CanonicalName(AFileName);
  lIndex := FindName(FCompilers, lCanonicalName);
  if lIndex >= 0 then
    Exit(TNexusScriptCompiler(FCompilers.Objects[lIndex]));
  if FindName(FActiveFiles, lCanonicalName) >= 0 then
  begin
    FLastError := 'Document dependency cycle at ' + lCanonicalName;
    Exit;
  end;
  if not FSourceProvider.ReadSource(lCanonicalName, lSourceText,
    lSourceVersion) then
  begin
    FLastError := 'Document file not found: ' + lCanonicalName;
    Exit;
  end;
  FActiveFiles.Add(lCanonicalName);
  lCompiler := TNexusScriptCompiler.Create(FSelectedTargets);
  FAttemptedCompilers.Add(lCompiler);
  FAttemptedVersions.Add(lSourceVersion);
  try
    lCompiler.CompileText(lCanonicalName, lSourceText);
    lCompiler.ClearImports;
    if not ExpandPatterns(lCompiler.SourceDocument) then
      Exit;
    lDialect := lCompiler.SourceDocument.Dialect;
    lDialectCompiler := nil;
    lDialectSourceName := '';
    lDeclaredDialectPath := '';
    if lDialect <> nil then
    begin
      lDeclaredDialectPath := lDialect.Path;
      lDialectRange := lDialect.SourceRange;
      lDialectSourceName := ResolveDialectPath(lCanonicalName,
        lDeclaredDialectPath);
      lDialectCompiler := CompileDocument(lDialectSourceName);
      if lDialectCompiler = nil then
      begin
        FLastError := 'Unable to load dialect for ' + lCanonicalName +
          ': ' + FLastError;
        AddDiagnostic('dialect-load-failed', FLastError,
          lDialect.PathRange);
        Exit;
      end;
    end;
    for lModule in lCompiler.SourceDocument.Modules do
    begin
      lImportedName := ResolveDependencyPath(lCanonicalName, lModule.Path);
      if lImportedName = '' then
      begin
        FLastError := 'Relative module path requires a filesystem source: ' +
          lModule.Path;
        AddDiagnostic('module-load-failed', FLastError, lModule.PathRange);
        Exit;
      end;
      lImportedCompiler := CompileDocument(lImportedName);
      if lImportedCompiler = nil then
      begin
        AddDiagnostic('module-load-failed', FLastError, lModule.PathRange);
        Exit;
      end;
      if lModule.RootSelector = '' then
        lCompiler.AddImportedDocument(lImportedCompiler.CompiledDocument)
      else
      begin
        lImportedDefinition := SelectDefinition(lImportedCompiler,
          lModule.RootSelector);
        if lImportedDefinition = nil then
        begin
          FLastError := 'Module root selector not found: ' +
            lModule.RootSelector + ' in ' + lImportedName;
          AddDiagnostic('module-selector-not-found', FLastError,
            lModule.RootSelectorRange);
          Exit;
        end;
        lCompiler.AddImportedDefinition(lImportedDefinition);
      end;
    end;
    for lInclude in lCompiler.SourceDocument.Includes do
    begin
      lIncludedName := ResolveDependencyPath(lCanonicalName, lInclude.Path);
      if lIncludedName = '' then
      begin
        FLastError := 'Relative include path requires a filesystem source: ' +
          lInclude.Path;
        AddDiagnostic('include-load-failed', FLastError,
          lInclude.PathRange);
        Exit;
      end;
      lIncludedCompiler := CompileDocument(lIncludedName);
      if lIncludedCompiler = nil then
      begin
        FLastError := 'Unable to load include ' + lInclude.Path + ' for ' +
          lCanonicalName + ': ' + FLastError;
        AddDiagnostic('include-load-failed', FLastError,
          lInclude.PathRange);
        Exit;
      end;
    end;
    if not FSourceProvider.ReadSource(lCanonicalName, lSourceText,
      lSourceVersion) then
    begin
      FLastError := 'Document file not found: ' + lCanonicalName;
      Exit;
    end;
    // The dependency-discovery pass and binding pass are one document compilation.
    if not lCompiler.CompileText(lCanonicalName, lSourceText,
      lCompiler.CompiledDocument.CompiledAt) then
    begin
      FLastError := 'Compilation failed: ' + lCanonicalName;
      if lCompiler.Diagnostics.Count > 0 then
        FLastError := FLastError + ': ' +
          lCompiler.Diagnostics[0].MessageText;
      Exit;
    end;
    if not ExpandPatterns(lCompiler.SourceDocument) then
      Exit;
    if lDeclaredDialectPath <> '' then
      lCompiler.CompiledDocument.SetDialect(lDeclaredDialectPath,
        lDialectSourceName, lDialectRange,
        lDialectCompiler.CompiledDocument);
    for lInclude in lCompiler.SourceDocument.Includes do
    begin
      lIncludedName := ResolveDependencyPath(lCanonicalName, lInclude.Path);
      lIncludedCompiler := FindCompiler(lIncludedName);
      lCompiler.CompiledDocument.IncludedDocuments.Add(
        lIncludedCompiler.CompiledDocument);
    end;
    FCompilers.AddObject(lCanonicalName, lCompiler);
    Result := lCompiler;
  finally
    FActiveFiles.Delete(FindName(FActiveFiles, lCanonicalName));
  end;
end;

function TNexusScriptCompilationSession.CompileFile(
  const AFileName: string): Boolean;
var
  lAttemptStart: Integer;
begin
  FLastError := '';
  FDiagnostics.Clear;
  FEntryCompiler := nil;
  FEntryAttemptCompiler := nil;
  lAttemptStart := FAttemptedCompilers.Count;
  FEntryCompiler := CompileDocument(AFileName);
  if FAttemptedCompilers.Count > lAttemptStart then
    FEntryAttemptCompiler := FAttemptedCompilers[lAttemptStart]
  else
    FEntryAttemptCompiler := FEntryCompiler;
  Result := FEntryCompiler <> nil;
end;

function TNexusScriptCompilationSession.GetCompilerCount: Integer;
begin
  Result := FCompilers.Count;
end;

function TNexusScriptCompilationSession.GetCompiler(
  AIndex: Integer): TNexusScriptCompiler;
begin
  Result := TNexusScriptCompiler(FCompilers.Objects[AIndex]);
end;

function TNexusScriptCompilationSession.GetAttemptedCompilerCount: Integer;
begin
  Result := FAttemptedCompilers.Count;
end;

function TNexusScriptCompilationSession.GetAttemptedCompiler(
  AIndex: Integer): TNexusScriptCompiler;
begin
  Result := FAttemptedCompilers[AIndex];
end;

function TNexusScriptCompilationSession.GetAttemptedVersion(
  AIndex: Integer): Integer;
begin
  Result := FAttemptedVersions[AIndex];
end;

function TNexusScriptCompilationSession.FindCompiler(
  const AFileName: string): TNexusScriptCompiler;
var
  lIndex: Integer;
begin
  Result := nil;
  lIndex := FindName(FCompilers, FSourceProvider.CanonicalName(AFileName));
  if lIndex >= 0 then
    Result := TNexusScriptCompiler(FCompilers.Objects[lIndex]);
end;

end.

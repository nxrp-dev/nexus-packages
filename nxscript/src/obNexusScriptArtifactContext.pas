(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptArtifactContext;

{$mode delphi}{$H+}

interface

uses
  Classes,
  obNexusScriptCompiler,
  obNexusScriptSession,
  obNexusScriptArtifactModel;

type
  TNexusScriptArtifactContext = class
  private
    FSession: TNexusScriptCompilationSession;
    FArtifactDocuments: TNexusScriptArtifactDocumentList;
    FExternalSources: TNexusScriptExternalSourceList;
    function ResolvePath(const ASourceName, ADeclaredPath: string): string;
    procedure AddArtifactDocument(ACompiler: TNexusScriptCompiler;
      ASeen: TStringList);
    procedure AddExternalSources(ACompiler: TNexusScriptCompiler;
      ASeenDocuments, ASourceNames: TStringList);
  public
    constructor Create(ASession: TNexusScriptCompilationSession);
    destructor Destroy; override;
    procedure Build;
    property Session: TNexusScriptCompilationSession read FSession;
    property ArtifactDocuments: TNexusScriptArtifactDocumentList
      read FArtifactDocuments;
    property ExternalSources: TNexusScriptExternalSourceList
      read FExternalSources;
  end;

implementation

uses
  SysUtils,
  obNexusScriptModel;

constructor TNexusScriptArtifactContext.Create(
  ASession: TNexusScriptCompilationSession);
begin
  inherited Create;
  if ASession = nil then
    raise Exception.Create('Compilation session is required.');
  FSession := ASession;
  FArtifactDocuments := TNexusScriptArtifactDocumentList.Create(True);
  FExternalSources := TNexusScriptExternalSourceList.Create(True);
end;

destructor TNexusScriptArtifactContext.Destroy;
begin
  FExternalSources.Free;
  FArtifactDocuments.Free;
  inherited Destroy;
end;

function TNexusScriptArtifactContext.ResolvePath(const ASourceName,
  ADeclaredPath: string): string;
begin
  if (ExtractFileDrive(ADeclaredPath) <> '') or
    ((ADeclaredPath <> '') and IsPathDelimiter(ADeclaredPath, 1)) then
    Result := ExpandFileName(ADeclaredPath)
  else
    Result := ExpandFileName(IncludeTrailingPathDelimiter(
      ExtractFileDir(ASourceName)) + ADeclaredPath);
end;

procedure TNexusScriptArtifactContext.AddArtifactDocument(
  ACompiler: TNexusScriptCompiler; ASeen: TStringList);
var
  lCanonicalName: string;
  lInclude: TNexusScriptSourceInclude;
  lIncludedName: string;
  lIncludedCompiler: TNexusScriptCompiler;
begin
  lCanonicalName := ExpandFileName(ACompiler.CompiledDocument.SourceName);
  if ASeen.IndexOf(lCanonicalName) >= 0 then
    Exit;
  ASeen.Add(lCanonicalName);
  FArtifactDocuments.Add(TNexusScriptArtifactDocument.Create(
    ACompiler.SourceDocument, ACompiler.CompiledDocument));
  for lInclude in ACompiler.SourceDocument.Includes do
  begin
    lIncludedName := ResolvePath(ACompiler.SourceDocument.SourceName,
      lInclude.Path);
    lIncludedCompiler := FSession.FindCompiler(lIncludedName);
    if lIncludedCompiler = nil then
      raise Exception.CreateFmt('Compiled include is unavailable: %s',
        [lIncludedName]);
    AddArtifactDocument(lIncludedCompiler, ASeen);
  end;
end;

procedure TNexusScriptArtifactContext.AddExternalSources(
  ACompiler: TNexusScriptCompiler; ASeenDocuments,
  ASourceNames: TStringList);
var
  lCanonicalDocument: string;
  lDataSource: TNexusScriptSourceData;
  lFileName: string;
  lExistingFileName: string;
  lSourceType: string;
  lExtension: string;
  lInclude: TNexusScriptSourceInclude;
  lModule: TNexusScriptSourceModule;
  lDependencyName: string;
  lDependencyCompiler: TNexusScriptCompiler;
  lIndex: Integer;
begin
  lCanonicalDocument := ExpandFileName(ACompiler.SourceDocument.SourceName);
  if ASeenDocuments.IndexOf(lCanonicalDocument) >= 0 then
    Exit;
  ASeenDocuments.Add(lCanonicalDocument);
  for lDataSource in ACompiler.SourceDocument.DataSources do
  begin
    lFileName := ResolvePath(lCanonicalDocument, lDataSource.Path);
    lIndex := ASourceNames.IndexOfName(lDataSource.Name);
    if lIndex >= 0 then
    begin
      lExistingFileName := ASourceNames.ValueFromIndex[lIndex];
      if SameFileName(lExistingFileName, lFileName) then
        Continue;
      raise Exception.CreateFmt(
        'External data source %s resolves to both %s and %s',
        [lDataSource.Name, lExistingFileName, lFileName]);
    end;
    ASourceNames.Add(lDataSource.Name + '=' + lFileName);
    lExtension := ExtractFileExt(lFileName);
    if lExtension <> '' then
      Delete(lExtension, 1, 1);
    lSourceType := LowerCase(lExtension);
    FExternalSources.Add(TNexusScriptExternalSource.Create(
      lDataSource.Name, lDataSource.Path, lFileName, lSourceType,
      lCanonicalDocument, lDataSource.SourceRange));
  end;
  for lInclude in ACompiler.SourceDocument.Includes do
  begin
    lDependencyName := ResolvePath(lCanonicalDocument, lInclude.Path);
    lDependencyCompiler := FSession.FindCompiler(lDependencyName);
    if lDependencyCompiler = nil then
      raise Exception.CreateFmt('Compiled include is unavailable: %s',
        [lDependencyName]);
    AddExternalSources(lDependencyCompiler, ASeenDocuments, ASourceNames);
  end;
  for lModule in ACompiler.SourceDocument.Modules do
  begin
    lDependencyName := ResolvePath(lCanonicalDocument, lModule.Path);
    lDependencyCompiler := FSession.FindCompiler(lDependencyName);
    if lDependencyCompiler = nil then
      raise Exception.CreateFmt('Compiled module is unavailable: %s',
        [lDependencyName]);
    AddExternalSources(lDependencyCompiler, ASeenDocuments, ASourceNames);
  end;
end;

procedure TNexusScriptArtifactContext.Build;
var
  lSeen: TStringList;
  lSourceNames: TStringList;
begin
  FArtifactDocuments.Clear;
  FExternalSources.Clear;
  if FSession.EntryCompiler = nil then
    Exit;
  lSeen := TStringList.Create;
  lSourceNames := TStringList.Create;
  try
    lSeen.CaseSensitive := False;
    lSeen.Sorted := True;
    lSeen.Duplicates := dupIgnore;
    AddArtifactDocument(FSession.EntryCompiler, lSeen);
    lSeen.Clear;
    lSourceNames.CaseSensitive := False;
    lSourceNames.NameValueSeparator := '=';
    AddExternalSources(FSession.EntryCompiler, lSeen, lSourceNames);
  finally
    lSourceNames.Free;
    lSeen.Free;
  end;
end;

end.

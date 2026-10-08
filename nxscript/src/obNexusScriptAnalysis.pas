(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptAnalysis;

{$mode delphi}{$H+}

interface

uses
  obNexusScriptSourceProvider,
  obNexusScriptModel,
  obNexusScriptCompiler,
  obNexusScriptSession,
  obNexusScriptLanguageDefinition,
  obNexusScriptValidator;

type
  TNexusScriptAnalysis = class
  private
    FRevision: Integer;
    FEntryName: string;
    FSucceeded: Boolean;
    FSession: TNexusScriptCompilationSession;
    FLanguage: TNexusScriptLanguageDefinition;
    FValidator: TNexusScriptValidator;
  public
    constructor Create(const AEntryName: string; ARevision: Integer;
      ASourceProvider: TNexusScriptSourceProvider;
      ASelectedTargets: TNexusScriptTargetSelection = nil);
    destructor Destroy; override;
    procedure Execute(const ADialectRoot: string = '');
    function EntryCompiler: TNexusScriptCompiler;
    function EntrySourceCompiler: TNexusScriptCompiler;
    property Revision: Integer read FRevision;
    property EntryName: string read FEntryName;
    property Succeeded: Boolean read FSucceeded;
    property Session: TNexusScriptCompilationSession read FSession;
    property Language: TNexusScriptLanguageDefinition read FLanguage;
    property Validator: TNexusScriptValidator read FValidator;
  end;

implementation

constructor TNexusScriptAnalysis.Create(const AEntryName: string;
  ARevision: Integer; ASourceProvider: TNexusScriptSourceProvider;
  ASelectedTargets: TNexusScriptTargetSelection);
begin
  inherited Create;
  FEntryName := AEntryName;
  FRevision := ARevision;
  FSession := TNexusScriptCompilationSession.Create(ASelectedTargets,
    ASourceProvider);
  FLanguage := TNexusScriptLanguageDefinition.Create;
  FValidator := TNexusScriptValidator.Create;
end;

destructor TNexusScriptAnalysis.Destroy;
begin
  FValidator.Free;
  FLanguage.Free;
  FSession.Free;
  inherited Destroy;
end;

procedure TNexusScriptAnalysis.Execute(const ADialectRoot: string);
var
  lDocument: TNexusScriptCompiledDocument;
begin
  FSession.DialectRoot := ADialectRoot;
  FSucceeded := FSession.CompileFile(FEntryName);
  if not FSucceeded then
    Exit;
  lDocument := FSession.EntryCompiler.CompiledDocument;
  if lDocument.DialectDocument = nil then
    Exit;
  FLanguage.Normalize(lDocument.DialectDocument);
  if FLanguage.DiagnosticCount = 0 then
    FValidator.Validate(lDocument, lDocument.DialectDocument);
end;

function TNexusScriptAnalysis.EntryCompiler: TNexusScriptCompiler;
begin
  Result := FSession.EntryCompiler;
end;

function TNexusScriptAnalysis.EntrySourceCompiler: TNexusScriptCompiler;
begin
  Result := FSession.EntryAttemptCompiler;
end;

end.

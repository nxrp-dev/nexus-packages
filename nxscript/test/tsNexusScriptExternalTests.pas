(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNexusScriptExternalTests;

{$mode delphi}{$H+}

interface
uses obNXTestRegistry;
procedure RegisterNexusScriptExternalTests(ARegistry: TNXTestRegistry);

implementation
uses Classes, SysUtils, obNXTestContext, obNXTestSuite, tpNexusScript,
  tpNexusScriptLive, obNexusScriptCompiler, obNexusScriptModel,
  obNexusScriptLive, obNexusScriptValidator, obNexusScriptJSON, obNexusScriptSQLite;

type
  TExternalProvider = class
  public
    Value: string;
    Reads, Results: Integer;
    LastPath, LastValue: string;
    Handled: Boolean;
    Reenter: TNexusScriptLiveValue;
    procedure ReadExternal(const APath: string; out AValue: string; out AHandled: Boolean);
    procedure ReceiveResult(const APath, AValue: string; out AHandled: Boolean);
  end;

procedure TExternalProvider.ReadExternal(const APath: string;
  out AValue: string; out AHandled: Boolean);
begin
  Inc(Reads);
  LastPath := APath;
  AValue := Value;
  AHandled := Handled;
  if Reenter <> nil then AValue := Reenter.AsText;
end;

procedure TExternalProvider.ReceiveResult(const APath, AValue: string;
  out AHandled: Boolean);
begin
  Inc(Results);
  LastPath := APath;
  LastValue := AValue;
  AHandled := Handled;
end;

function CompileLive(AContext: TNXTestContext; const ASource: string;
  ATargets: TNexusScriptTargetSelection = nil): TNexusScriptLiveDocument;
var
  lCompiler: TNexusScriptCompiler;
  lMessage: string;
  lDiagnostic: TNexusScriptDiagnostic;
begin
  lCompiler := TNexusScriptCompiler.Create(ATargets);
  try
    if not lCompiler.CompileText('external.nxscript', ASource) then
    begin
      lMessage := '';
      for lDiagnostic in lCompiler.Diagnostics do
        lMessage := lMessage + lDiagnostic.Code + ': ' + lDiagnostic.MessageText + LineEnding;
      AContext.AssertTrue(False, 'External script compiles: ' + lMessage);
    end;
    Result := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
  finally
    lCompiler.Free;
  end;
end;

procedure TestGenericTargets(AContext: TNXTestContext);
var
  lTargets: TNexusScriptTargetSelection;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
begin
  lTargets := TNexusScriptTargetSelection.Create;
  lProvider := TExternalProvider.Create;
  lLive := nil;
  try
    lTargets.Add('TargetOS', 'linux');
    lTargets.Add('TargetCPU', 'aarch64');
    lTargets.Add('Flavor', 'Preview');
    lTargets.Add('Empty', '');
    lLive := CompileLive(AContext,
      'Thing Root { Path: "/output/" + $TargetOS + "/" + $TargetCPU + "/" + $Flavor; ' +
      'Empty: $Empty; Literal: "$TargetOS"; }', lTargets);
    lTargets.SetValue('Flavor', 'Changed');
    FreeAndNil(lTargets);
    lLive.OnReadExternal := lProvider.ReadExternal;
    AContext.AssertEquals('/output/linux/aarch64/Preview',
      lLive.FindDefinition('Root').FindProperty('Path').Value.AsText,
      'Every selection name resolves from the immutable compilation selection.');
    AContext.AssertEquals('', lLive.FindDefinition('Root').FindProperty('Empty').Value.AsText,
      'A selected empty value is resolved.');
    AContext.AssertEquals('$TargetOS', lLive.FindDefinition('Root').FindProperty('Literal').Value.AsText,
      'Quoted dollar syntax stays literal.');
    AContext.AssertEquals(0, lProvider.Reads, 'The extension event does not override selections.');
    AContext.AssertTrue(lLive.FindExternal('Flavor').IsSelectedTarget, 'Generic selected identity is read-only.');
  finally
    lLive.Free;
    lProvider.Free;
    lTargets.Free;
  end;
end;

procedure TestDeferredReadAndIdentity(AContext: TNXTestContext);
var
  lLive: TNexusScriptLiveDocument;
  lRoot: TNexusScriptLiveDefinition;
  lProvider: TExternalProvider;
  lValue, lOther: TNexusScriptLiveValue;
begin
  lProvider := TExternalProvider.Create;
  lLive := nil;
  try
    lProvider.Handled := True;
    lProvider.Value := 'first';
    lLive := CompileLive(AContext, 'Thing Root { Value: $Server.Options.Name; ' +
      'Other: $Server.Options.Name; Alias: @Value; Combined: @Alias + "!"; ' +
      'Items: [Entry: $Server.Options.Name, @Combined]; }');
    lLive.OnReadExternal := lProvider.ReadExternal;
    lLive.OnExternalResult := lProvider.ReceiveResult;
    lRoot := lLive.FindDefinition('Root');
    lValue := lRoot.FindProperty('Value').Value;
    lOther := lRoot.FindProperty('Other').Value;
    AContext.AssertEquals(0, lProvider.Reads, 'Emission performs no external reads.');
    AContext.AssertTrue(lValue.External = lOther.External, 'Every use shares one external identity.');
    AContext.AssertTrue(lValue.External.Parent.Name = 'Options', 'Qualification is a real namespace tree.');
    AContext.AssertTrue(lValue.Reference.Kind = nslrExternal, 'External reference kind is retained.');
    AContext.AssertTrue(lValue.Reference.Target = lValue.External, 'Reference edge targets the external identity.');
    AContext.AssertEquals(3, lValue.ReferenceRanges.Count, 'Each qualified name segment retains its source range.');
    AContext.AssertEquals('first!', lRoot.FindProperty('Combined').Value.AsText, 'Internal aliases evaluate external expressions.');
    lProvider.Value := 'second';
    AContext.AssertEquals('second!', lRoot.FindProperty('Items').Value.Items[1].AsText,
      'Later access observes the current provider value, including array aliases.');
    AContext.AssertEquals('second', lRoot.FindProperty('Items').Value.FindItem('Entry').AsText,
      'Named array entries retain deferred expressions.');
    AContext.AssertEquals(0, lProvider.Results, 'Reading never delivers desired state.');
  finally
    lLive.Free;
    lProvider.Free;
  end;
end;

procedure TestMissingEmptyAndCase(AContext: TNXTestContext);
var
  lLive: TNexusScriptLiveDocument;
  lTargets: TNexusScriptTargetSelection;
  lProvider: TExternalProvider;
  lValue: TNexusScriptLiveValue;
  lError: string;
begin
  lTargets := TNexusScriptTargetSelection.Create;
  lProvider := TExternalProvider.Create;
  lLive := nil;
  try
    lTargets.Add('Name', 'selected');
    lLive := CompileLive(AContext, 'Thing Root { Missing: $name; }', lTargets);
    lValue := lLive.FindDefinition('Root').FindProperty('Missing').Value;
    lError := '';
    try lValue.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('Unresolved external reference $name', lError) > 0, 'Case-sensitive misses fail on demand.');
    AContext.AssertTrue(Pos('external.nxscript(1,', lError) > 0, 'Error identifies the reference use site.');
    lLive.OnReadExternal := lProvider.ReadExternal;
    lProvider.Handled := True;
    AContext.AssertEquals('', lValue.AsText, 'A successful empty string is not unresolved.');
    lProvider.Handled := False;
    lError := '';
    try lValue.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('$name', lError) > 0, 'A later unresolved result is not hidden by a cached empty value.');
  finally
    lLive.Free;
    lProvider.Free;
    lTargets.Free;
  end;
end;

procedure TestDesiredValues(AContext: TNXTestContext);
var
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
  lResults: TNexusScriptExternalResultList;
  lRoot: TNexusScriptLiveDefinition;
begin
  lLive := nil;
  lResults := nil;
  lProvider := TExternalProvider.Create;
  try
    lProvider.Value := '/current';
    lProvider.Handled := True;
    lLive := CompileLive(AContext, 'Setup Root { Path: "/nexus/bin"; $Path: $Path + ":" + @Path; }');
    lLive.OnReadExternal := lProvider.ReadExternal;
    lLive.OnExternalResult := lProvider.ReceiveResult;
    lRoot := lLive.FindDefinition('Root');
    AContext.AssertEquals(1, lRoot.Properties.Count, 'External assignments are not ordinary output properties.');
    AContext.AssertEquals(1, lRoot.ExternalAssignments.Count, 'Desired state has its own semantic namespace.');
    AContext.AssertEquals('/nexus/bin', lRoot.FindProperty('Path').Value.AsText, 'Internal identity remains distinct.');
    AContext.AssertEquals('/current:/nexus/bin', lRoot.FindExternalAssignment('Path').Value.AsText,
      'The right-hand external reference reads current state, not its desired assignment.');
    AContext.AssertEquals(0, lProvider.Results, 'Inspecting the desired value causes no delivery.');
    lResults := lLive.EvaluateExternalAssignments;
    AContext.AssertEquals('/current:/nexus/bin', lResults[0].Value, 'Processors can inspect an owned result batch.');
    AContext.AssertEquals(0, lProvider.Results, 'Preparing a batch has no delivery side effect.');
    lLive.PublishExternalAssignments;
    AContext.AssertEquals(1, lProvider.Results, 'Explicit publication calls the result event once.');
    AContext.AssertEquals('Path', lProvider.LastPath, 'The event receives the exact identity.');
    AContext.AssertEquals('/current:/nexus/bin', lProvider.LastValue, 'The processor receives desired text.');
    FreeAndNil(lLive);
    AContext.AssertEquals('Path', lResults[0].Path, 'A prepared result owns its data after the document is released.');
  finally
    lResults.Free;
    lLive.Free;
    lProvider.Free;
  end;
end;

procedure TestAssignmentRejections(AContext: TNXTestContext);
var
  lCompiler: TNexusScriptCompiler;
  lTargets: TNexusScriptTargetSelection;
  lLive: TNexusScriptLiveDocument;
  lRejected: Boolean;
begin
  lTargets := TNexusScriptTargetSelection.Create;
  lTargets.Add('Flavor', 'Debug');
  lCompiler := TNexusScriptCompiler.Create(lTargets);
  lLive := nil;
  try
    AContext.AssertTrue(not lCompiler.CompileText('readonly.nxscript', 'Thing Root { $Flavor: Release; }'),
      'Selected Target assignment fails during binding.');
    AContext.AssertEquals('NXS5010', lCompiler.Diagnostics[0].Code, 'Read-only error is explicit.');
    AContext.AssertTrue(not lCompiler.CompileText('duplicate.nxscript', 'Thing Root { $Path: one; $Path: two; }'),
      'Duplicate assignments within one definition are rejected.');
    AContext.AssertTrue(not lCompiler.CompileText('array.nxscript', 'Thing Root { $Path: [one, two]; }'),
      'String-centric external assignment rejects structural values.');
    AContext.AssertTrue(lCompiler.CompileText('conflict.nxscript',
      'Thing One { $Path: one; } Thing Two { $Path: two; }'), 'Conflicts across public contributions bind independently.');
    lRejected := False;
    try lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    except on E: ENexusScriptLive do lRejected := Pos('Conflicting external assignments for $Path', E.Message)>0; end;
    AContext.AssertTrue(lRejected and (lLive=nil), 'Live rejects surviving conflicts before any delivery.');
    AContext.AssertTrue(lCompiler.CompileText('case.nxscript', 'Thing Root { $Path: one; $path: two; }'),
      'External identity is case-sensitive.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    AContext.AssertEquals(2, lLive.ExternalAssignments.Count, 'Differently cased names remain separate identities.');
  finally
    lLive.Free;
    lCompiler.Free;
    lTargets.Free;
  end;
end;

procedure TestFilteringAndComposition(AContext: TNXTestContext);
var
  lTargets: TNexusScriptTargetSelection;
  lCompiler, lConsumer: TNexusScriptCompiler;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
begin
  lTargets := TNexusScriptTargetSelection.Create;
  lTargets.Add('TargetOS', 'linux');
  lCompiler := TNexusScriptCompiler.Create(lTargets);
  lConsumer := TNexusScriptCompiler.Create(lTargets);
  lProvider := TExternalProvider.Create;
  lProvider.Handled := True;
  lProvider.Value := 'observed';
  lLive := nil;
  try
    AContext.AssertTrue(lCompiler.CompileText('base.nxscript',
      'Thing Base { Suffix: base; $Path: $Path + @Suffix; }'), 'Base compiles.');
    lConsumer.AddImportedDefinition(lCompiler.CompiledDocument.FindDefinition('Base'));
    AContext.AssertTrue(lConsumer.CompileText('consumer.nxscript',
      'Thing Root(Base) TargetOS[linux] { Suffix: local; $Path: $Path + ":" + @Suffix; } ' +
      'Thing Root TargetOS[win64] { $Path: excluded; }'), 'Selected composition compiles.');
    FreeAndNil(lCompiler);
    lLive := TNexusScriptLiveEmitter.Emit(lConsumer.CompiledDocument);
    FreeAndNil(lConsumer);
    lLive.OnReadExternal := lProvider.ReadExternal;
    AContext.AssertEquals(1, lLive.ExternalAssignments.Count, 'Composition reduces to one surviving local assignment.');
    AContext.AssertEquals('observed:local', lLive.ExternalAssignments[0].Value.AsText,
      'Composition uses local internal values and current external values.');
    AContext.AssertEquals(2, lLive.ExternalAssignments[0].ContributorRanges.Count,
      'Composition retains both contributing declarations.');
  finally
    lLive.Free;
    lProvider.Free;
    lConsumer.Free;
    lCompiler.Free;
    lTargets.Free;
  end;
end;

procedure TestImportedExpressionLifetime(AContext: TNXTestContext);
var
  lDependency, lProducer, lConsumer: TNexusScriptCompiler;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
begin
  lDependency := TNexusScriptCompiler.Create;
  lProducer := TNexusScriptCompiler.Create;
  lConsumer := TNexusScriptCompiler.Create;
  lLive := nil;
  lProvider := TExternalProvider.Create;
  lProvider.Handled := True;
  lProvider.Value := 'external';
  try
    AContext.AssertTrue(lDependency.CompileText('dependency.nxscript',
      'Thing Dependency { Value: $Context + "-original"; }'), 'Dependency compiles.');
    lProducer.AddImportedDefinition(lDependency.CompiledDocument.FindDefinition('Dependency'));
    FreeAndNil(lDependency);
    AContext.AssertTrue(lProducer.CompileText('producer.nxscript',
      'Thing Export { Value: @Dependency.Value; }'), 'Producer compiles.');
    lConsumer.AddImportedDefinition(lProducer.CompiledDocument.FindDefinition('Export'));
    FreeAndNil(lProducer);
    AContext.AssertTrue(lConsumer.CompileText('consumer.nxscript',
      'Thing Dependency { Value: wrong; } Thing Root { Value: @Export.Value; }'), 'Consumer compiles without producer lifetime.');
    lLive := TNexusScriptLiveEmitter.Emit(lConsumer.CompiledDocument);
    FreeAndNil(lConsumer);
    lLive.OnReadExternal := lProvider.ReadExternal;
    AContext.AssertEquals('external-original', lLive.FindDefinition('Root').FindProperty('Value').Value.AsText,
      'Deferred private import binding cannot be captured by a same-named local definition.');
  finally
    lProvider.Free;
    lLive.Free;
    lConsumer.Free;
    lProducer.Free;
    lDependency.Free;
  end;
end;

procedure TestReentrancyAndBatchFailure(AContext: TNXTestContext);
var
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
  lError: string;
begin
  lProvider := TExternalProvider.Create;
  lLive := nil;
  try
    lLive := CompileLive(AContext, 'Thing Root { Value: $Name; $First: fixed; $Second: $Missing; }');
    lLive.OnReadExternal := lProvider.ReadExternal;
    lLive.OnExternalResult := lProvider.ReceiveResult;
    lProvider.Handled := True;
    lProvider.Reenter := lLive.FindDefinition('Root').FindProperty('Value').Value;
    lError := '';
    try lProvider.Reenter.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('dependency cycle', lError)>0, 'Reentrant evaluation reports a cycle.');
    lProvider.Reenter := nil;
    lProvider.Handled := False;
    lError := '';
    try lLive.PublishExternalAssignments; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('$Missing', lError)>0, 'Unresolved desired state fails the batch.');
    AContext.AssertEquals(0, lProvider.Results, 'No result is delivered before all values evaluate.');
    lProvider.Handled := True;
    lProvider.Value := 'recovered';
    AContext.AssertEquals('recovered', lLive.FindDefinition('Root').FindProperty('Value').Value.AsText,
      'Failed evaluation resets the cycle guard for a later valid access.');
  finally
    lLive.Free;
    lProvider.Free;
  end;
end;

procedure TestDeferredValidation(AContext: TNXTestContext);
var
  lCompiler, lSchema: TNexusScriptCompiler;
  lValidator: TNexusScriptValidator;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
  lRoot: TNexusScriptLiveDefinition;
  lValue: TNexusScriptLiveValue;
  lError: string;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lSchema := TNexusScriptCompiler.Create;
  lValidator := TNexusScriptValidator.Create;
  lProvider := TExternalProvider.Create;
  lProvider.Handled := True;
  lLive := nil;
  try
    AContext.AssertTrue(lSchema.CompileText('external-language.nxscript',
      'Language Test { UnknownDefinitions: Reject; Definitions: [' +
      'Definition Thing { Root: True; UnknownProperties: Reject; Properties: [' +
      'Property Enabled { Value Value { SourceForms: [ExternalReference]; Scalar: Boolean; } },' +
      'Property Count { Value Value { Scalar: Integer; } },' +
      'Property Mode { Value Value { AllowedValues: [Debug, Release]; } },' +
      'Property Items { Value Value { EffectiveCategories: [Array]; Array Array {' +
      'EntrySourceForms: [ExternalReference]; AllowedValues: [Debug, Release]; } } }' +
      ']; }]; }'), 'External-aware dialect compiles.');
    AContext.AssertTrue(lCompiler.CompileText('constrained.nxscript',
      'Thing Root { Enabled: $Enabled; Count: $Count; Mode: $Mode; Items: [$Mode]; $Destination: desired; }'),
      'Context-independent binding succeeds before values exist.');
    AContext.AssertTrue(lValidator.Validate(lCompiler.CompiledDocument, lSchema.CompiledDocument),
      'Structural validation records text constraints for Live evaluation.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    FreeAndNil(lCompiler);
    FreeAndNil(lSchema);
    FreeAndNil(lValidator);
    lLive.OnReadExternal := lProvider.ReadExternal;
    lRoot := lLive.FindDefinition('Root');
    lValue := lRoot.FindProperty('Enabled').Value;
    lProvider.Value := 'True';
    AContext.AssertEquals('True', lValue.AsText, 'Valid booleans pass after validator lifetime ends.');
    lProvider.Value := 'not-a-boolean';
    lError := '';
    try lValue.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('NSV2305', lError)>0, 'Deferred Boolean errors retain dialect diagnostic codes.');
    AContext.AssertTrue(Pos('constrained.nxscript(', lError)>0, 'Deferred constraint errors identify the use site.');
    lValue := lRoot.FindProperty('Count').Value;
    lProvider.Value := '42';
    AContext.AssertEquals('42', lValue.AsText, 'Valid integers pass.');
    lProvider.Value := '042';
    lError := '';
    try lValue.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('NSV2304', lError)>0, 'Deferred integers follow the existing canonical integer rule.');
    lProvider.Value := 'release';
    AContext.AssertEquals('release', lRoot.FindProperty('Mode').Value.AsText, 'Allowed values retain existing case rules.');
    lProvider.Value := 'other';
    lError := '';
    try lRoot.FindProperty('Mode').Value.AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('NSV2306', lError)>0, 'Scalar allowed-value constraints remain enforced.');
    lError := '';
    try lRoot.FindProperty('Items').Value.Items[0].AsText; except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('NSV2409', lError)>0, 'Array allowed-value constraints remain enforced.');
  finally
    lLive.Free;
    lProvider.Free;
    lValidator.Free;
    lSchema.Free;
    lCompiler.Free;
  end;
end;

procedure TestExternalSourceForm(AContext: TNXTestContext);
var
  lCompiler, lSchema: TNexusScriptCompiler;
  lValidator: TNexusScriptValidator;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lSchema := TNexusScriptCompiler.Create;
  lValidator := TNexusScriptValidator.Create;
  try
    AContext.AssertTrue(lSchema.CompileText('internal-only.nxscript',
      'Language Test { Definitions: [Definition Thing { Root: True; Properties: [' +
      'Property Link { Value Value { SourceForms: [Reference]; Reference Reference { Targets: [Definition]; } } }]; }]; }'),
      'Internal-reference dialect compiles.');
    AContext.AssertTrue(lCompiler.CompileText('external.nxscript', 'Thing Root { Link: $Definition; }'), 'External source binds.');
    AContext.AssertTrue(not lValidator.Validate(lCompiler.CompiledDocument, lSchema.CompiledDocument),
      'An external scalar cannot masquerade as an internal definition reference.');
    AContext.AssertEquals('NSV2301', lValidator.Diagnostics[0].Code, 'Source-form restriction remains effective.');
  finally
    lValidator.Free;
    lSchema.Free;
    lCompiler.Free;
  end;
end;

procedure TestArtifactBoundary(AContext: TNXTestContext);
const
  cSources: array[0..2] of string = (
    'Thing Root { Value: $Name; }',
    'Thing Root { Values: [one, [$Name]]; }',
    'Thing Root { $Name: desired; }');
var
  lCompiler: TNexusScriptCompiler;
  lJSON: TNexusScriptJSONEmitter;
  lSQLite: TNexusScriptSQLiteEmitter;
  lError: string;
  lSource: string;
begin
  lCompiler := TNexusScriptCompiler.Create;
  try
    for lSource in cSources do
    begin
      AContext.AssertTrue(lCompiler.CompileText('artifact.nxscript', lSource), 'Artifact-boundary fixture compiles.');
      lJSON := TNexusScriptJSONEmitter.Create;
      lSQLite := TNexusScriptSQLiteEmitter.Create;
      try
        lError := '';
        try lJSON.AddDocument(lCompiler.CompiledDocument);
        except on E: ENexusScriptJSON do lError := E.Message; end;
        AContext.AssertTrue(Pos('External', lError)>0, 'JSON rejects unmaterialized external semantics explicitly.');
        lError := '';
        try lSQLite.AddDocument(lCompiler.CompiledDocument);
        except on E: ENexusScriptSQLite do lError := E.Message; end;
        AContext.AssertTrue(Pos('External', lError)>0, 'SQLite cannot silently omit external expressions or assignments.');
      finally
        lSQLite.Free;
        lJSON.Free;
      end;
    end;
  finally
    lCompiler.Free;
  end;
end;

procedure TestArrayAliasConstraints(AContext: TNXTestContext);
var
  lCompiler, lSchema: TNexusScriptCompiler;
  lValidator: TNexusScriptValidator;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
  lError: string;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lSchema := TNexusScriptCompiler.Create;
  lValidator := TNexusScriptValidator.Create;
  lProvider := TExternalProvider.Create;
  lProvider.Handled := True;
  lProvider.Value := 'invalid';
  lLive := nil;
  try
    AContext.AssertTrue(lSchema.CompileText('array-alias-language.nxscript',
      'Language Test { Definitions: [Definition Thing { Root: True; UnknownProperties: Allow; Properties: [' +
      'Property Alias { Value Value { Array Array { AllowedValues: [valid]; } } }]; }]; }'), 'Alias language compiles.');
    AContext.AssertTrue(lCompiler.CompileText('array-alias.nxscript',
      'Thing Root { Values: [$Input]; Alias: @Values; }'), 'Alias fixture compiles.');
    AContext.AssertTrue(lValidator.Validate(lCompiler.CompiledDocument, lSchema.CompiledDocument), 'Alias shape validates.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    lLive.OnReadExternal := lProvider.ReadExternal;
    lError := '';
    try lLive.FindDefinition('Root').FindProperty('Alias').Value.Items[0].AsText;
    except on E: ENexusScriptLive do lError := E.Message; end;
    AContext.AssertTrue(Pos('NSV2409', lError)>0, 'An array alias must retain its deferred entry constraints.');
  finally
    lLive.Free;
    lProvider.Free;
    lValidator.Free;
    lSchema.Free;
    lCompiler.Free;
  end;
end;

procedure TestValidationReplacement(AContext: TNXTestContext);
var
  lCompiler, lSchema: TNexusScriptCompiler;
  lValidator: TNexusScriptValidator;
  lLive: TNexusScriptLiveDocument;
  lProvider: TExternalProvider;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lSchema := TNexusScriptCompiler.Create;
  lValidator := TNexusScriptValidator.Create;
  lProvider := TExternalProvider.Create;
  lProvider.Handled := True;
  lProvider.Value := 'now-text';
  lLive := nil;
  try
    AContext.AssertTrue(lCompiler.CompileText('revalidate.nxscript', 'Thing Root { Value: $Input; }'), 'Fixture compiles.');
    AContext.AssertTrue(lSchema.CompileText('language.nxscript',
      'Language Test { Definitions: [Definition Thing { Root: True; Properties: [' +
      'Property Value { Value Value { Scalar: Integer; } }]; }]; }'), 'First language compiles.');
    AContext.AssertTrue(lValidator.Validate(lCompiler.CompiledDocument, lSchema.CompiledDocument), 'First validation defers integer check.');
    AContext.AssertTrue(lSchema.CompileText('language.nxscript',
      'Language Test { Definitions: [Definition Thing { Root: True; UnknownProperties: Allow; }]; }'), 'Replacement language compiles.');
    AContext.AssertTrue(lValidator.Validate(lCompiler.CompiledDocument, lSchema.CompiledDocument), 'Second validation replaces earlier checks.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    lLive.OnReadExternal := lProvider.ReadExternal;
    AContext.AssertEquals('now-text', lLive.FindDefinition('Root').FindProperty('Value').Value.AsText,
      'Revalidation must not retain stale constraints from the earlier dialect.');
  finally
    lLive.Free;
    lProvider.Free;
    lValidator.Free;
    lSchema.Free;
    lCompiler.Free;
  end;
end;

procedure RegisterNexusScriptExternalTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NexusScript.External');
  lSuite.AddTest('ArrayAliasConstraints', TestArrayAliasConstraints);
  lSuite.AddTest('ValidationReplacement', TestValidationReplacement);
  lSuite.AddTest('DeferredValidation', TestDeferredValidation);
  lSuite.AddTest('ExternalSourceForm', TestExternalSourceForm);
  lSuite.AddTest('ArtifactBoundary', TestArtifactBoundary);
  lSuite.AddTest('GenericTargets', TestGenericTargets);
  lSuite.AddTest('DeferredReadAndIdentity', TestDeferredReadAndIdentity);
  lSuite.AddTest('MissingEmptyAndCase', TestMissingEmptyAndCase);
  lSuite.AddTest('DesiredValues', TestDesiredValues);
  lSuite.AddTest('AssignmentRejections', TestAssignmentRejections);
  lSuite.AddTest('FilteringAndComposition', TestFilteringAndComposition);
  lSuite.AddTest('ImportedExpressionLifetime', TestImportedExpressionLifetime);
  lSuite.AddTest('ReentrancyAndBatchFailure', TestReentrancyAndBatchFailure);
end;
end.

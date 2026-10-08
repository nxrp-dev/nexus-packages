(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNexusScriptLiveTests;

{$mode delphi}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterNexusScriptLiveTests(ARegistry: TNXTestRegistry);

implementation

uses SysUtils, obNXTestContext, obNXTestSuite, obNexusScriptCompiler,
  obNexusScriptSession, obNexusScriptModel, obNexusScriptLive, tpNexusScript;

procedure TestGraphAndLifetime(AContext: TNXTestContext);
var
  lCompiler: TNexusScriptCompiler;
  lLive, lOther: TNexusScriptLiveDocument;
  lRoot, lLeft, lRight: TNexusScriptLiveDefinition;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lLive := nil;
  lOther := nil;
  try
    AContext.AssertTrue(lCompiler.CompileText('live-cycle.nxscript',
      'Thing Root { Thing Left { Text: left; Other: @Root.Right; Self: @Root.Left; } ' +
      'Thing Right { Other: @Root.Left; Links: [@Root.Left, @Root.Right]; } ' +
      'First: @Root.Left; Second: @Root.Left; Alias: @First; }'), 'Graph source compiles.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    lOther := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    FreeAndNil(lCompiler);
    lRoot := lLive.FindDefinition('Root');
    lLeft := lRoot.FindChild('Left');
    lRight := lRoot.FindChild('Right');
    AContext.AssertTrue(lLeft.FindProperty('Other').Value.AsDefinition = lRight,
      'A forward reference points to the actual right object.');
    AContext.AssertTrue(lRight.FindProperty('Other').Value.AsDefinition = lLeft,
      'A backward reference closes the cycle.');
    AContext.AssertTrue(lLeft.FindProperty('Self').Value.Reference.Target = lLeft,
      'Reference.Target preserves a self-link.');
    AContext.AssertTrue(lRoot.FindProperty('First').Value.AsDefinition =
      lRoot.FindProperty('Second').Value.AsDefinition, 'Repeated references share one target.');
    AContext.AssertTrue(lRoot.FindProperty('Alias').Value.Reference.Target =
      lRoot.FindProperty('First'), 'A property alias retains its immediate target.');
    AContext.AssertTrue(lRoot.FindProperty('Alias').Value.AsDefinition = lLeft,
      'The same alias exposes its effective definition.');
    AContext.AssertEquals(2, lRight.FindProperty('Links').Value.Items.Count,
      'Reference arrays remain complete.');
    AContext.AssertTrue(lRight.FindProperty('Links').Value.Items[0].AsDefinition = lLeft,
      'Array references share the existing object.');
    AContext.AssertEquals('left', lLeft.FindProperty('Text').Value.AsText,
      'Values remain readable after releasing the compiler.');
    AContext.AssertTrue(lLeft.Parent = lRoot, 'Owned parent navigation is retained.');
    AContext.AssertTrue(lOther.FindDefinition('Root').FindChild('Left') <> lLeft,
      'Two emissions own independent snapshots.');
    AContext.AssertEquals('live-cycle.nxscript', lLeft.SourceRange.SourceName,
      'Source provenance survives compiler destruction.');
  finally
    lOther.Free;
    lLive.Free;
    lCompiler.Free;
  end;
end;

procedure TestArraysAndAliases(AContext: TNXTestContext);
var
  lCompiler: TNexusScriptCompiler;
  lLive: TNexusScriptLiveDocument;
  lRoot: TNexusScriptLiveDefinition;
  lItems: TNexusScriptLiveValue;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lLive := nil;
  try
    AContext.AssertTrue(lCompiler.CompileText('live-arrays.nxscript',
      'Thing Root { Text: original; ScalarAlias: @Text; Items: [' +
      'Label: one, Item: Node Declared { Self: @Root.Items.Item; }, Nested: [two, three]]; ' +
      'Alias: @Items; Entry: @Items.Item; }'), 'Array source compiles.');
    lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    AContext.AssertTrue(lCompiler.CompileText('replacement.nxscript', 'Thing Replacement {}'),
      'Recompiling the producer is permitted.');
    lRoot := lLive.FindDefinition('Root');
    lItems := lRoot.FindProperty('Items').Value;
    AContext.AssertEquals('original', lRoot.FindProperty('ScalarAlias').Value.AsText,
      'Scalar aliases expose effective text.');
    AContext.AssertTrue(lRoot.FindProperty('ScalarAlias').Value.Reference.Target =
      lRoot.FindProperty('Text'), 'Scalar aliases retain the property relationship.');
    AContext.AssertTrue(lRoot.FindProperty('Alias').Value.Items[1] = lItems.Items[1],
      'Whole-array aliases share original entry identities.');
    AContext.AssertTrue(lRoot.FindProperty('Entry').Value.Reference.Target = lItems.Items[1],
      'Named-entry lookup retains the actual entry.');
    AContext.AssertEquals('Declared', lRoot.FindProperty('Entry').Value.OriginalDefinitionName,
      'Original declaration provenance survives alongside effective entry names.');
    AContext.AssertTrue(lItems.Items[1].AsDefinition.FindProperty('Self').Value.AsDefinition =
      lItems.Items[1].AsDefinition, 'Inline entries may refer to themselves.');
    AContext.AssertEquals('one', lItems.FindItem('Label').AsText, 'Named scalar lookup works.');
    AContext.AssertEquals(2, lItems.FindItem('Nested').Items.Count, 'Nested arrays are retained.');
    AContext.AssertTrue(lRoot.FindProperty('Text').ContributorRanges.Count > 0,
      'Property attribution is retained.');
  finally
    lLive.Free;
    lCompiler.Free;
  end;
end;

procedure TestImportedTargets(AContext: TNXTestContext);
var
  lSession: TNexusScriptCompilationSession;
  lLive: TNexusScriptLiveDocument;
  lMiddle, lDependency: TNexusScriptLiveDefinition;
begin
  lSession := TNexusScriptCompilationSession.Create;
  lLive := nil;
  try
    AContext.AssertTrue(lSession.CompileFile(ExpandFileName(
      'packages/nexus-packages/nxscript/test/fixtures/modules/selected-dependency/selected.nxscript')),
      'Selected module compilation succeeds: ' + lSession.LastError);
    lLive := TNexusScriptLiveEmitter.Emit(lSession.EntryCompiler.CompiledDocument);
    FreeAndNil(lSession);
    AContext.AssertEquals(1, lLive.Roots.Count, 'Module-only targets do not become public roots.');
    lMiddle := lLive.FindDefinition('Entry').FindProperty('Link').Value.AsDefinition;
    lDependency := lMiddle.FindProperty('Link').Value.AsDefinition;
    AContext.AssertEquals('Dependency', lDependency.Name, 'Private transitive target remains reachable.');
    AContext.AssertTrue(lLive.FindDefinition('Dependency') = nil,
      'Reachability does not change public contribution membership.');
  finally
    lLive.Free;
    lSession.Free;
  end;
end;

procedure TestFailureCleanup(AContext: TNXTestContext);
var
  lCompiler: TNexusScriptCompiler;
  lLive: TNexusScriptLiveDocument;
  lRejected: Boolean;
begin
  lCompiler := TNexusScriptCompiler.Create;
  lLive := nil;
  try
    AContext.AssertTrue(lCompiler.CompileText('live-failure.nxscript',
      'Thing Root { First: valid; Second: unfinished; }'), 'Fixture compiles.');
    lCompiler.CompiledDocument.FindDefinition('Root').FindProperty('Second').Value.
      EvaluationState := nsvesFailed;
    lRejected := False;
    try
      lLive := TNexusScriptLiveEmitter.Emit(lCompiler.CompiledDocument);
    except
      on E: ENexusScriptLive do lRejected := True;
    end;
    AContext.AssertTrue(lRejected and (lLive = nil), 'A partial snapshot is not returned.');
  finally
    lLive.Free;
    lCompiler.Free;
  end;
end;

procedure RegisterNexusScriptLiveTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NexusScript.Live');
  lSuite.AddTest('GraphAndLifetime', TestGraphAndLifetime);
  lSuite.AddTest('ArraysAndAliases', TestArraysAndAliases);
  lSuite.AddTest('ImportedTargets', TestImportedTargets);
  lSuite.AddTest('FailureCleanup', TestFailureCleanup);
end;

end.

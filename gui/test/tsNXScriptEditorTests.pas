(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXScriptEditorTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterNXScriptEditorTests(ARegistry: TNXTestRegistry);

implementation

uses Classes, SysUtils, obNXTestSuite, obNXTestContext,
  obNexusScriptEditDocument, obNexusScriptModel, obNXScriptEditor,
  tpVTV, fpg_base, obNexusScriptLanguageDefinition;

const
  cSampleFile = 'packages2/nexus-packages/gui/examples/nxscript-editor/Demo.nxscript';

type
  TTestEditor = class(TNXScriptEditor)
  public
    procedure Choices(ANode: PVirtualNode; AResult: TStrings);
    procedure Pending(const AText: string);
    procedure Key(AKey: Word; AShift: TShiftState = []);
  end;

procedure TTestEditor.Choices(ANode: PVirtualNode; AResult: TStrings);
begin
  GetEditChoices(ANode, 1, AResult);
end;

procedure TTestEditor.Pending(const AText: string);
begin
  SetPendingEditText(AText);
end;

procedure TTestEditor.Key(AKey: Word; AShift: TShiftState);
var
  lConsumed: Boolean;
begin
  lConsumed := False;
  HandleKeyPress(AKey, AShift, lConsumed);
end;

procedure TestConstruction(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
begin
  lEditor := TTestEditor.Create(nil);
  try
    AContext.AssertEquals(3, lEditor.Header.Columns.Count);
    AContext.AssertTrue(lEditor.Document <> nil);
    AContext.AssertTrue(lEditor.GetFirst = nil);
  finally
    lEditor.Free;
  end;
end;

function FindNode(AEditor: TNXScriptEditor; const ACaption: string): PVirtualNode;
begin
  Result := AEditor.GetFirst;
  while Result <> nil do
  begin
    if AEditor.Text[Result, 0] = ACaption then Exit;
    Result := AEditor.GetNext(Result);
  end;
end;

procedure LoadDocument(ADocument: TNexusScriptEditDocument; AContext: TNXTestContext);
begin
  ADocument.LoadFile(cSampleFile);
  AContext.AssertTrue(ADocument.Valid, ADocument.Diagnostics.Text);
end;

function RootOffset(ADocument: TNexusScriptEditDocument): Integer;
begin
  Result := ADocument.SourceDocument.Definitions[0].SourceRange.StartPosition.Offset;
end;

function ArrayOffset(ADocument: TNexusScriptEditDocument; const AName: string): Integer;
begin
  Result := ADocument.SourceDocument.Definitions[0].FindProperty(AName).
    Value.SourceRange.StartPosition.Offset;
end;

procedure TestSourcePreservation(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lOriginal, lExpected, lText: string;
begin
  lDocument := TNexusScriptEditDocument.Create;
  try
    LoadDocument(lDocument, AContext);
    lOriginal := lDocument.SourceText;
    lText := 'Quoted "text", caret ^ and line' + #10 + 'two';
    lExpected := StringReplace(lOriginal, 'Title: "NexusScript tree editor";',
      'Title: ' + lDocument.QuoteText(lText) + ';', []);
    AContext.AssertTrue(lDocument.SetProperty(RootOffset(lDocument), 'Title',
      lDocument.QuoteText(lText)), lDocument.Diagnostics.Text);
    AContext.AssertEquals(lExpected, lDocument.SourceText);
    AContext.AssertEquals(lText, lDocument.SourceDocument.Definitions[0].FindProperty('Title').Value.Text);
    AContext.AssertTrue(Pos('Link: @Sample.Title;', lDocument.SourceText) > 0);
    AContext.AssertTrue(lDocument.Dirty);
    AContext.AssertTrue(lDocument.Undo);
    AContext.AssertEquals(lOriginal, lDocument.SourceText);
    AContext.AssertFalse(lDocument.Dirty);
    AContext.AssertTrue(lDocument.Redo);
    AContext.AssertEquals(lExpected, lDocument.SourceText);
  finally
    lDocument.Free;
  end;
end;

procedure TestRejectedEdits(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lOriginal: string;
  lRevision: Integer;
begin
  lDocument := TNexusScriptEditDocument.Create;
  try
    LoadDocument(lDocument, AContext);
    lOriginal := lDocument.SourceText;
    lRevision := lDocument.Revision;
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Enabled', 'maybe'));
    AContext.AssertTrue(Pos('NSV2305', lDocument.Diagnostics.Text) > 0);
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Count', '3.5'));
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Mode', 'Other'));
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Bogus', '"value"'));
    AContext.AssertFalse(lDocument.RemoveProperty(RootOffset(lDocument), 'Title'));
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Count', '4; Mode: Dark'));
    AContext.AssertEquals(lOriginal, lDocument.SourceText);
    AContext.AssertEquals(lRevision, lDocument.Revision);
    AContext.AssertFalse(lDocument.Dirty);
    AContext.AssertFalse(lDocument.CanUndo);
  finally
    lDocument.Free;
  end;
end;

procedure TestPropertyAndDefinitionRules(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lChoices: TStringList;
  lChildOffset: Integer;
begin
  lDocument := TNexusScriptEditDocument.Create;
  lChoices := TStringList.Create;
  try
    LoadDocument(lDocument, AContext);
    lDocument.GetDefinitionKinds(-1, lChoices);
    AContext.AssertEquals(1, lChoices.Count);
    AContext.AssertEquals('Demo', lChoices[0]);
    lDocument.GetDefinitionKinds(RootOffset(lDocument), lChoices);
    AContext.AssertEquals(0, lChoices.Count, 'Inline and ordinary children both count toward maximum.');
    AContext.AssertFalse(lDocument.AddDefinition(-1, 'Leaf', 'Wrong', 'Caption: "wrong";'));
    lChildOffset := lDocument.SourceDocument.Definitions[0].Children[0].SourceRange.StartPosition.Offset;
    AContext.AssertTrue(lDocument.RemoveDefinition(lChildOffset));
    lDocument.GetDefinitionKinds(RootOffset(lDocument), lChoices);
    AContext.AssertEquals('Leaf', lChoices[0]);
    AContext.AssertFalse(lDocument.AddDefinition(RootOffset(lDocument), 'Leaf', 'Missing', ''));
    AContext.AssertTrue(lDocument.AddDefinition(RootOffset(lDocument), 'Leaf', 'New',
      'Caption: "created";'), lDocument.Diagnostics.Text);
    AContext.AssertTrue(lDocument.RemoveProperty(RootOffset(lDocument), 'Mode'));
    lDocument.GetPropertyNames(RootOffset(lDocument), lChoices);
    AContext.AssertEquals(1, lChoices.Count);
    AContext.AssertEquals('Mode', lChoices[0]);
    AContext.AssertTrue(lDocument.SetProperty(RootOffset(lDocument), 'Mode', 'Dark'));
  finally
    lChoices.Free;
    lDocument.Free;
  end;
end;

procedure TestArrays(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lValue: TNexusScriptSourceValue;
  lBefore: string;
begin
  lDocument := TNexusScriptEditDocument.Create;
  try
    LoadDocument(lDocument, AContext);
    AContext.AssertTrue(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Items'), '"green"'));
    lBefore := lDocument.SourceText;
    AContext.AssertFalse(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Items'), '"red"'));
    AContext.AssertEquals(lBefore, lDocument.SourceText);
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Items'), 1));
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Items'), 0));
    AContext.AssertFalse(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Items'), 0));
    lValue := lDocument.FindValue(ArrayOffset(lDocument, 'Named'));
    AContext.AssertEquals('first: "red"', lDocument.SourceSlice(lDocument.EntryRange(lValue.Items[0])));
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Named'), 0));
    lValue := lDocument.FindValue(ArrayOffset(lDocument, 'Named'));
    AContext.AssertEquals('second', lValue.Items[0].EntryName);
    AContext.AssertEquals('blue', lValue.Items[0].Text);
    AContext.AssertFalse(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Named'), '"green"'));
    AContext.AssertTrue(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Named'), '"green"', 'third'));
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Named'), 1));
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Named'), 0));
    AContext.AssertTrue(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Named'), '"red"', 'new'));
  finally
    lDocument.Free;
  end;
end;

procedure TestInlineDefinitions(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lArray: TNexusScriptSourceValue;
  lInlineOffset: Integer;
begin
  lDocument := TNexusScriptEditDocument.Create;
  try
    LoadDocument(lDocument, AContext);
    lArray := lDocument.FindValue(ArrayOffset(lDocument, 'Leaves'));
    AContext.AssertEquals('Leaf Inline { Caption: "An inline definition"; }',
      lDocument.SourceSlice(lDocument.ValueRange(lArray.Items[0])));
    lInlineOffset := lArray.Items[0].InlineDefinition.SourceRange.StartPosition.Offset;
    AContext.AssertTrue(lDocument.SetProperty(lInlineOffset, 'Caption', '"edited inline"'));
    AContext.AssertTrue(lDocument.RemoveArrayItem(ArrayOffset(lDocument, 'Leaves'), 0));
    AContext.AssertTrue(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Leaves'),
      'Leaf Added { Caption: "added"; }'), lDocument.Diagnostics.Text);
    AContext.AssertFalse(lDocument.AddArrayItem(ArrayOffset(lDocument, 'Leaves'),
      'Leaf TooMany { Caption: "over maximum"; }'));
    AContext.AssertTrue(lDocument.Valid);
  finally
    lDocument.Free;
  end;
end;

procedure TestReferences(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lChoices: TStringList;
  lRule: TNSPropertyRule;
  lOriginal: string;
begin
  lDocument := TNexusScriptEditDocument.Create;
  lChoices := TStringList.Create;
  try
    LoadDocument(lDocument, AContext);
    lRule := lDocument.PropertyRule(RootOffset(lDocument), 'Link');
    lDocument.GetReferenceChoices(RootOffset(lDocument), lRule.ValueRule.ReferenceRule, nil, lChoices);
    AContext.AssertTrue(lChoices.IndexOf('@Sample.Title') >= 0);
    AContext.AssertTrue(lChoices.IndexOf('@Sample') < 0);
    AContext.AssertTrue(lDocument.SetProperty(RootOffset(lDocument), 'Link', '@Sample.Mode'));
    lOriginal := lDocument.SourceText;
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Link', '@Sample.Missing'));
    AContext.AssertFalse(lDocument.SetProperty(RootOffset(lDocument), 'Link', '@Sample.Link'));
    AContext.AssertEquals(lOriginal, lDocument.SourceText);
    AContext.AssertTrue(lDocument.SetProperty(RootOffset(lDocument), 'Title', '"prefix " + @Sample.Mode'));
    AContext.AssertTrue(Pos('"prefix " + @Sample.Mode', lDocument.SourceText) > 0);
    AContext.AssertFalse(lDocument.RenameDefinition(RootOffset(lDocument), 'Renamed'),
      'A rename that breaks existing references is rejected, not silently rewritten.');
  finally
    lChoices.Free;
    lDocument.Free;
  end;
end;

procedure TestTreeProjectionAndChoices(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
  lChoices: TStringList;
  lNode: PVirtualNode;
begin
  lEditor := TTestEditor.Create(nil);
  lChoices := TStringList.Create;
  try
    lEditor.LoadFile(cSampleFile);
    AContext.AssertTrue(lEditor.Document.Valid, lEditor.Document.Diagnostics.Text);
    AContext.AssertEquals('Demo', lEditor.Text[lEditor.GetFirst, 0]);
    AContext.AssertEquals('Sample', lEditor.Text[lEditor.GetFirst, 1]);
    lNode := FindNode(lEditor, 'Link');
    AContext.AssertEquals('@Sample.Title', lEditor.Text[lNode, 1]);
    lEditor.Choices(FindNode(lEditor, 'Enabled'), lChoices);
    AContext.AssertEquals(2, lChoices.Count);
    AContext.AssertTrue(lChoices.IndexOf('True') >= 0);
    lEditor.Choices(FindNode(lEditor, 'Mode'), lChoices);
    AContext.AssertEquals('Light', lChoices[0]);
    AContext.AssertEquals('Dark', lChoices[1]);
    lEditor.GetSourceForms(FindNode(lEditor, 'Enabled'), lChoices);
    AContext.AssertEquals(1, lChoices.Count);
    AContext.AssertEquals('Literal', lChoices[0]);
    AContext.AssertFalse(lEditor.CanRemove(FindNode(lEditor, 'Title')));
    AContext.AssertTrue(lEditor.CanRemove(FindNode(lEditor, 'Mode')));
    lNode := FindNode(lEditor, 'Items');
    lEditor.Choices(lNode^.FirstChild, lChoices);
    AContext.AssertEquals(3, lChoices.Count);
    lNode := FindNode(lEditor, 'Leaves')^.FirstChild;
    AContext.AssertTrue(lNode <> nil);
    lEditor.GetSourceForms(lNode, lChoices);
    AContext.AssertEquals(1, lChoices.Count);
    AContext.AssertEquals('Inline definition', lChoices[0]);
    AContext.AssertTrue(lEditor.SetNodeSource(lNode,
      'Leaf Replacement { Caption: "A replacement inline definition"; }'),
      lEditor.Document.Diagnostics.Text);
    lNode := FindNode(lEditor, 'Leaves')^.FirstChild;
    AContext.AssertEquals('Replacement', lEditor.Text[lNode, 1]);
    AContext.AssertFalse(lEditor.SetNodeSource(lNode,
      'Leaf Replacement { Caption: "first"; }, Leaf Extra { Caption: "extra"; }'),
      'Replacing one entry cannot insert a second entry.');
    AContext.AssertTrue(lEditor.TotalCount > 12);
  finally
    lChoices.Free;
    lEditor.Free;
  end;
end;

procedure TestCellCommitCancelAndRejection(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
  lNode: PVirtualNode;
  lSource: string;
begin
  lEditor := TTestEditor.Create(nil);
  try
    lEditor.Width := 1000;
    lEditor.Height := 800;
    lEditor.LoadFile(cSampleFile);
    lNode := FindNode(lEditor, 'Enabled');
    lEditor.FocusedNode := lNode;
    AContext.AssertTrue(lEditor.EditNode(lNode, 1));
    lEditor.Pending('False');
    AContext.AssertTrue(lEditor.EndEditNode);
    AContext.AssertEquals('False', lEditor.Text[FindNode(lEditor, 'Enabled'), 1]);
    AContext.AssertEquals('Enabled', lEditor.Text[lEditor.FocusedNode, 0]);
    lNode := FindNode(lEditor, 'Mode');
    AContext.AssertTrue(lEditor.EditNode(lNode, 1));
    lEditor.Pending('Dark');
    lEditor.CancelEditNode;
    AContext.AssertEquals('Light', lEditor.Text[FindNode(lEditor, 'Mode'), 1]);
    lNode := FindNode(lEditor, 'Count');
    AContext.AssertTrue(lEditor.EditNode(lNode, 1));
    lEditor.Pending('not an integer');
    lSource := lEditor.Document.SourceText;
    AContext.AssertFalse(lEditor.EndEditNode, 'Invalid Integer must reject the cell commit.');
    AContext.AssertEquals(lSource, lEditor.Document.SourceText);
    lEditor.Pending('7');
    AContext.AssertTrue(lEditor.EndEditNode);
    AContext.AssertEquals('7', lEditor.Text[FindNode(lEditor, 'Count'), 1]);
    AContext.AssertFalse(lEditor.EditNode(FindNode(lEditor, 'Items'), 1), 'Arrays must not use a scalar cell editor.');
    AContext.AssertFalse(lEditor.EditNode(FindNode(lEditor, 'Count'), 0), 'The property-name column is not editable.');
    lEditor.Key(keyZ, [ssCtrl]);
    AContext.AssertEquals('3', lEditor.Text[FindNode(lEditor, 'Count'), 1]);
    lEditor.Key(keyY, [ssCtrl]);
    AContext.AssertEquals('7', lEditor.Text[FindNode(lEditor, 'Count'), 1]);
  finally
    lEditor.Free;
  end;
end;

procedure TestReloadAndInvalidSource(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
  lNode: PVirtualNode;
begin
  lEditor := TTestEditor.Create(nil);
  try
    lEditor.LoadFile(cSampleFile);
    lNode := FindNode(lEditor, 'Title');
    lEditor.FocusedNode := lNode;
    lEditor.Selected[lNode] := True;
    AContext.AssertTrue(lEditor.SetNodeValue(lNode, 'A replacement caption'));
    lEditor.LoadSource('output/NexusScriptEditorTests/broken.nxscript', 'Not valid {');
    AContext.AssertFalse(lEditor.Document.Valid);
    AContext.AssertTrue(lEditor.Document.Diagnostics.Count > 0);
    lEditor.LoadFile(cSampleFile);
    AContext.AssertTrue(lEditor.Document.Valid);
    AContext.AssertEquals('NexusScript tree editor', lEditor.Text[FindNode(lEditor, 'Title'), 1]);
    AContext.AssertFalse(lEditor.Document.CanUndo);
  finally
    lEditor.Free;
  end;
end;

procedure TestNamedEntryEditing(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
  lArray: PVirtualNode;
begin
  lEditor := TTestEditor.Create(nil);
  try
    lEditor.Width := 1000;
    lEditor.Height := 800;
    lEditor.LoadFile(cSampleFile);
    lArray := FindNode(lEditor, 'Named');
    AContext.AssertTrue(lEditor.EditNode(lArray^.FirstChild, 0));
    lEditor.Pending('renamed');
    AContext.AssertTrue(lEditor.EndEditNode);
    lArray := FindNode(lEditor, 'Named');
    AContext.AssertEquals('renamed', lEditor.Text[lArray^.FirstChild, 0]);
    AContext.AssertEquals('red', lEditor.Text[lArray^.FirstChild, 1]);
    AContext.AssertTrue(lEditor.EditNode(lArray^.FirstChild, 0));
    lEditor.Pending('');
    AContext.AssertFalse(lEditor.EndEditNode, 'A required array name cannot be erased.');
    lEditor.CancelEditNode;
    AContext.AssertFalse(lEditor.EditNode(FindNode(lEditor, 'Items')^.FirstChild, 0),
      'Forbidden array names cannot be edited.');
  finally
    lEditor.Free;
  end;
end;

function ReadBytes(const AFileName: string): string;
var
  lFile: TFileStream;
begin
  lFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, lFile.Size);
    if Result <> '' then lFile.ReadBuffer(Result[1], Length(Result));
  finally
    lFile.Free;
  end;
end;

procedure TestSaveBytes(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lSource, lPath: string;
begin
  lDocument := TNexusScriptEditDocument.Create;
  try
    lSource := ReadBytes(cSampleFile);
    lSource := StringReplace(lSource, '"Editor.Language.nxscript"',
      lDocument.QuoteText(ExpandFileName('packages2/nexus-packages/gui/examples/nxscript-editor/Editor.Language.nxscript')), []);
    lPath := ExpandFileName('output/NexusScriptEditorTests/roundtrip/saved.nxscript');
    ForceDirectories(ExtractFilePath(lPath));
    lDocument.LoadSource(lPath, lSource);
    AContext.AssertTrue(lDocument.Valid, lDocument.Diagnostics.Text);
    AContext.AssertTrue(lDocument.SetProperty(RootOffset(lDocument), 'Count', '8'));
    lDocument.Save;
    AContext.AssertEquals(lDocument.SourceText, ReadBytes(lPath));
    AContext.AssertFalse(lDocument.Dirty);
    lDocument.LoadFile(lPath);
    AContext.AssertTrue(lDocument.Valid);
    AContext.AssertEquals('8', lDocument.SourceDocument.Definitions[0].FindProperty('Count').Value.Text);
  finally
    lDocument.Free;
  end;
end;

function ReferenceSource(const ABody: string; AImport: Boolean = False): string;
begin
  Result := 'dialect ' + TNexusScriptEditDocument.QuoteText(
    ExpandFileName('packages2/nexus-packages/gui/test/fixtures/Reference.Language.nxscript')) + ';' + LineEnding;
  if AImport then Result := Result + 'module Imported ' + TNexusScriptEditDocument.QuoteText(
    ExpandFileName('packages2/nexus-packages/gui/test/fixtures/ReferenceTarget.nxscript')) + ';' + LineEnding;
  Result := Result + ABody;
end;

procedure TestReferenceContainment(AContext: TNXTestContext);
var
  lDocument: TNexusScriptEditDocument;
  lChoices: TStringList;
begin
  lDocument := TNexusScriptEditDocument.Create;
  lChoices := TStringList.Create;
  try
    lDocument.LoadSource(cSampleFile,
      ReferenceSource('Host Current { Record Target {} Links: [@Current.Target]; }'));
    AContext.AssertTrue(lDocument.Valid, lDocument.Diagnostics.Text);
    lDocument.GetDefinitionKinds(RootOffset(lDocument), lChoices);
    AContext.AssertEquals(1, lChoices.Count, 'The reference does not consume the second child slot.');
    AContext.AssertTrue(lDocument.AddDefinition(RootOffset(lDocument), 'Record', 'Second', ''));
    lDocument.GetDefinitionKinds(RootOffset(lDocument), lChoices);
    AContext.AssertEquals(0, lChoices.Count);
    AContext.AssertFalse(lDocument.AddDefinition(RootOffset(lDocument), 'Record', 'Third', ''));

    lDocument.LoadSource(cSampleFile,
      ReferenceSource('Host Current { Links: [@Imported.Foreign]; }', True));
    AContext.AssertFalse(lDocument.Valid, 'A reference cannot satisfy the required owned-child minimum.');
    AContext.AssertTrue(Pos('NSV2201', lDocument.Diagnostics.Text) > 0, lDocument.Diagnostics.Text);

    lDocument.LoadSource(cSampleFile,
      ReferenceSource('Host Current { Items: [Record Inline {}]; Links: [@Current.Items.Inline]; }'));
    AContext.AssertTrue(lDocument.Valid, lDocument.Diagnostics.Text);
    lDocument.GetDefinitionKinds(RootOffset(lDocument), lChoices);
    AContext.AssertEquals(1, lChoices.Count, 'The inline definition counts once; its reference counts zero.');
    AContext.AssertTrue(lDocument.AddDefinition(RootOffset(lDocument), 'Record', 'Second', ''));
    AContext.AssertFalse(lDocument.AddDefinition(RootOffset(lDocument), 'Record', 'Third', ''));
  finally
    lChoices.Free;
    lDocument.Free;
  end;
end;

procedure TestScopedReferenceChoices(AContext: TNXTestContext);
var
  lEditor: TTestEditor;
  lChoices: TStringList;
begin
  lEditor := TTestEditor.Create(nil);
  lChoices := TStringList.Create;
  try
    lEditor.LoadSource(cSampleFile, ReferenceSource(
      'Host Current { Record First {} Record Second { Link: @Current.First; } Links: [@Current.First]; } ' +
      'Host Unrelated { Record Other {} }', True));
    AContext.AssertTrue(lEditor.Document.Valid, lEditor.Document.Diagnostics.Text);
    lEditor.Choices(FindNode(lEditor, '[0]'), lChoices);
    AContext.AssertEquals(2, lChoices.Count);
    AContext.AssertTrue(lChoices.IndexOf('@Current.First') >= 0);
    AContext.AssertTrue(lChoices.IndexOf('@Current.Second') >= 0);
    AContext.AssertTrue(lChoices.IndexOf('@Unrelated.Other') < 0);
    AContext.AssertTrue(lChoices.IndexOf('@Imported.Foreign') < 0);
    lEditor.Choices(FindNode(lEditor, 'Link'), lChoices);
    AContext.AssertEquals(2, lChoices.Count);
    AContext.AssertTrue(lChoices.IndexOf('@Current.First') >= 0);
    AContext.AssertTrue(lChoices.IndexOf('@Imported.Foreign') < 0);
  finally
    lChoices.Free;
    lEditor.Free;
  end;
end;

procedure RegisterNXScriptEditorTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NXScriptEditor');
  lSuite.AddTest('Construction', @TestConstruction);
  lSuite.AddTest('SourcePreservationAndUndoRedo', @TestSourcePreservation);
  lSuite.AddTest('RejectedEditsAreAtomic', @TestRejectedEdits);
  lSuite.AddTest('PropertyAndDefinitionRules', @TestPropertyAndDefinitionRules);
  lSuite.AddTest('ArraysAndNamedEntries', @TestArrays);
  lSuite.AddTest('InlineDefinitions', @TestInlineDefinitions);
  lSuite.AddTest('ReferencesAndCompositions', @TestReferences);
  lSuite.AddTest('TreeProjectionAndChoices', @TestTreeProjectionAndChoices);
  lSuite.AddTest('CellCommitCancelAndRejection', @TestCellCommitCancelAndRejection);
  lSuite.AddTest('ReloadAndInvalidSource', @TestReloadAndInvalidSource);
  lSuite.AddTest('NamedEntryEditing', @TestNamedEntryEditing);
  lSuite.AddTest('SavePreservesSourceBytes', @TestSaveBytes);
  lSuite.AddTest('ReferenceContainment', @TestReferenceContainment);
  lSuite.AddTest('ScopedReferenceChoices', @TestScopedReferenceChoices);
end;

end.

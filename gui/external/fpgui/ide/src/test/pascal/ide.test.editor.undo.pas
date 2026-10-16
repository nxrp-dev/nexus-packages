{
    fpGUI IDE — Undo/Redo System Tests

    Tests for TUndoManager and the concrete TUndoAction subclasses.
    These tests verify the undo system in isolation from the text editor
    widget, operating directly on a TStringList as the text model.
}
unit ide.test.editor.undo;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.editor.undo;

type

  { TTestUndoManager }

  TTestUndoManager = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestInitialState;
    procedure TestCanUndoAfterAction;
    procedure TestCanRedoAfterUndo;
    procedure TestRedoClearedAfterNewAction;
    procedure TestUndoRestoresState;
    procedure TestRedoReappliesState;
    procedure TestMultipleUndoRedo;
    procedure TestUndoOnEmptyStackDoesNothing;
    procedure TestRedoOnEmptyStackDoesNothing;
    procedure TestMaxUndoLevels;
    procedure TestClear;
  end;

  { TTestInsertTextAction }

  TTestInsertTextAction = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestInsertSingleChar;
    procedure TestInsertAtMiddleOfLine;
    procedure TestInsertAtEndOfLine;
    procedure TestInsertIntoEmptyLine;
    procedure TestUndoInsertRemovesText;
    procedure TestRedoInsertRestoresText;
    procedure TestInsertMultiByteUTF8;
  end;

  { TTestDeleteTextAction }

  TTestDeleteTextAction = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestDeleteSingleChar;
    procedure TestDeleteAtStartOfLine;
    procedure TestUndoDeleteRestoresChar;
    procedure TestRedoDeleteRemovesAgain;
    procedure TestDeleteSelection;
    procedure TestUndoDeleteSelectionRestoresText;
  end;

  { TTestSplitLineAction }

  TTestSplitLineAction = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestSplitAtMiddle;
    procedure TestSplitAtStart;
    procedure TestSplitAtEnd;
    procedure TestSplitWithAutoIndent;
    procedure TestUndoSplitRejoinsLine;
    procedure TestRedoSplitSplitsAgain;
  end;

  { TTestJoinLinesAction }

  TTestJoinLinesAction = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestJoinWithPreviousLine;
    procedure TestJoinWithNextLine;
    procedure TestUndoJoinRestoresTwoLines;
    procedure TestRedoJoinMergesAgain;
  end;

  { TTestCompoundAction }

  TTestCompoundAction = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestCompoundUndoesAllAtOnce;
    procedure TestCompoundRedoesAllAtOnce;
    procedure TestEmptyCompoundIsNoOp;
  end;

  { TTestActionMerging }

  TTestActionMerging = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestConsecutiveInsertsAtSamePositionMerge;
    procedure TestInsertAfterPauseDoesNotMerge;
    procedure TestDeletesDoNotMergeWithInserts;
    procedure TestConsecutiveBackspacesAtSamePositionMerge;
  end;

  { TTestUTF8Actions — verify all actions with multi-byte codepoints }

  TTestUTF8Actions = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLines: TStringList;
    FManager: TUndoManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestInsertAfterMultiByte;
    procedure TestDeleteMultiByteCodepoint;
    procedure TestDeleteAfterMultiByte;
    procedure TestSplitLineWithMultiByte;
    procedure TestJoinLinesWithMultiByte;
    procedure TestConsecutiveMultiByteInsertsMerge;
    procedure TestBackspaceMultiByteCodepointsMerge;
  end;


procedure RegisteridetesteditorundoTests(ARegistry: TNXTestRegistry);

implementation

{ =========================================================================
    TTestUndoManager
  ========================================================================= }

procedure TTestUndoManager.SetUp;
begin
  
  FManager := TUndoManager.Create;
end;

procedure TTestUndoManager.TearDown;
begin
  FManager.Free;
  
end;

procedure TTestUndoManager.TestInitialState;
begin
  FContext.AssertTrue(not (FManager.CanUndo), 'New manager should not be able to undo');
  FContext.AssertTrue(not (FManager.CanRedo), 'New manager should not be able to redo');
  FContext.AssertTrue((0)=(FManager.UndoCount), 'Undo count should be 0');
  FContext.AssertTrue((0)=(FManager.RedoCount), 'Redo count should be 0');
end;

procedure TTestUndoManager.TestCanUndoAfterAction;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FContext.AssertTrue(FManager.CanUndo, 'Should be able to undo after action');
    FContext.AssertTrue((1)=(FManager.UndoCount), 'Undo count should be 1');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestCanRedoAfterUndo;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FManager.Undo;
    FContext.AssertTrue(FManager.CanRedo, 'Should be able to redo after undo');
    FContext.AssertTrue((1)=(FManager.RedoCount), 'Redo count should be 1');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestRedoClearedAfterNewAction;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FManager.Undo;
    FContext.AssertTrue(FManager.CanRedo, 'Should have redo available');
    { Now perform a new action — redo stack should be cleared }
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'Y'));
    FContext.AssertTrue(not (FManager.CanRedo), 'Redo should be cleared after new action');
    FContext.AssertTrue((0)=(FManager.RedoCount), 'Redo count should be 0');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestUndoRestoresState;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FContext.AssertTrue(('helloX')=(Lines[0]), 'After execute');
    FManager.Undo;
    FContext.AssertTrue(('hello')=(Lines[0]), 'After undo');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestRedoReappliesState;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FManager.Undo;
    FManager.Redo;
    FContext.AssertTrue(('helloX')=(Lines[0]), 'After redo');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestMultipleUndoRedo;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('abc');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 3, 'D'));
    FManager.BreakMerge;
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 4, 'E'));
    FContext.AssertTrue(('abcDE')=(Lines[0]), 'After two inserts');
    FContext.AssertTrue((2)=(FManager.UndoCount), 'Undo count should be 2');

    FManager.Undo;
    FContext.AssertTrue(('abcD')=(Lines[0]), 'After first undo');

    FManager.Undo;
    FContext.AssertTrue(('abc')=(Lines[0]), 'After second undo');

    FManager.Redo;
    FContext.AssertTrue(('abcD')=(Lines[0]), 'After first redo');

    FManager.Redo;
    FContext.AssertTrue(('abcDE')=(Lines[0]), 'After second redo');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestUndoOnEmptyStackDoesNothing;
begin
  { Should not raise an exception }
  FManager.Undo;
  FContext.AssertTrue(not (FManager.CanUndo), 'Still cannot undo');
end;

procedure TTestUndoManager.TestRedoOnEmptyStackDoesNothing;
begin
  { Should not raise an exception }
  FManager.Redo;
  FContext.AssertTrue(not (FManager.CanRedo), 'Still cannot redo');
end;

procedure TTestUndoManager.TestMaxUndoLevels;
var
  Lines: TStringList;
  i: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('');
    FManager.MaxUndoLevels := 5;
    for i := 1 to 10 do
    begin
      FManager.BreakMerge;
      FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, i - 1, Chr(Ord('A') + i - 1)));
    end;
    FContext.AssertTrue((5)=(FManager.UndoCount), 'Should be capped at max levels');
    { The oldest 5 actions should have been discarded }
    for i := 1 to 5 do
      FManager.Undo;
    FContext.AssertTrue(not (FManager.CanUndo), 'Should not be able to undo beyond max');
  finally
    Lines.Free;
  end;
end;

procedure TTestUndoManager.TestClear;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('hello');
    FManager.ExecuteAction(TInsertTextAction.Create(Lines, 0, 5, 'X'));
    FManager.Undo;
    FContext.AssertTrue(FManager.CanUndo or FManager.CanRedo, 'Should have undo');
    FManager.Clear;
    FContext.AssertTrue(not (FManager.CanUndo), 'After clear, no undo');
    FContext.AssertTrue(not (FManager.CanRedo), 'After clear, no redo');
  finally
    Lines.Free;
  end;
end;


{ =========================================================================
    TTestInsertTextAction
  ========================================================================= }

procedure TTestInsertTextAction.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestInsertTextAction.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestInsertTextAction.TestInsertSingleChar;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 5, 'X'));
  FContext.AssertTrue(('helloX')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestInsertAtMiddleOfLine;
begin
  FLines.Add('helo');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 2, 'l'));
  FContext.AssertTrue(('hello')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestInsertAtEndOfLine;
begin
  FLines.Add('abc');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 3, 'def'));
  FContext.AssertTrue(('abcdef')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestInsertIntoEmptyLine;
begin
  FLines.Add('');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 0, 'A'));
  FContext.AssertTrue(('A')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestUndoInsertRemovesText;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 5, ' world'));
  FContext.AssertTrue(('hello world')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('hello')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestRedoInsertRestoresText;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 5, ' world'));
  FManager.Undo;
  FManager.Redo;
  FContext.AssertTrue(('hello world')=(FLines[0]), '');
end;

procedure TTestInsertTextAction.TestInsertMultiByteUTF8;
begin
  FLines.Add('cafe');
  { Insert a UTF-8 character (e-acute: 2 bytes in UTF-8) }
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 3, #$C3#$A9));
  FContext.AssertTrue(('caf' + #$C3#$A9 + 'e')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('cafe')=(FLines[0]), '');
end;


{ =========================================================================
    TTestDeleteTextAction
  ========================================================================= }

procedure TTestDeleteTextAction.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestDeleteTextAction.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestDeleteTextAction.TestDeleteSingleChar;
begin
  FLines.Add('hello');
  { Delete the character at position 4 (the 'o') }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 4, 1));
  FContext.AssertTrue(('hell')=(FLines[0]), '');
end;

procedure TTestDeleteTextAction.TestDeleteAtStartOfLine;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 0, 1));
  FContext.AssertTrue(('ello')=(FLines[0]), '');
end;

procedure TTestDeleteTextAction.TestUndoDeleteRestoresChar;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 4, 1));
  FContext.AssertTrue(('hell')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('hello')=(FLines[0]), '');
end;

procedure TTestDeleteTextAction.TestRedoDeleteRemovesAgain;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 4, 1));
  FManager.Undo;
  FManager.Redo;
  FContext.AssertTrue(('hell')=(FLines[0]), '');
end;

procedure TTestDeleteTextAction.TestDeleteSelection;
begin
  FLines.Add('hello world');
  { Delete 5 chars starting at position 5 (' worl') }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 5, 5));
  FContext.AssertTrue(('hellod')=(FLines[0]), '');
end;

procedure TTestDeleteTextAction.TestUndoDeleteSelectionRestoresText;
begin
  FLines.Add('hello world');
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 5, 5));
  FContext.AssertTrue(('hellod')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('hello world')=(FLines[0]), '');
end;


{ =========================================================================
    TTestSplitLineAction
  ========================================================================= }

procedure TTestSplitLineAction.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestSplitLineAction.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestSplitLineAction.TestSplitAtMiddle;
begin
  FLines.Add('hello world');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 5));
  FContext.AssertTrue((2)=(FLines.Count), 'Line count after split');
  FContext.AssertTrue(('hello')=(FLines[0]), 'First line');
  FContext.AssertTrue((' world')=(FLines[1]), 'Second line');
end;

procedure TTestSplitLineAction.TestSplitAtStart;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 0));
  FContext.AssertTrue((2)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('')=(FLines[0]), 'First line should be empty');
  FContext.AssertTrue(('hello')=(FLines[1]), 'Second line');
end;

procedure TTestSplitLineAction.TestSplitAtEnd;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 5));
  FContext.AssertTrue((2)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('hello')=(FLines[0]), 'First line');
  FContext.AssertTrue(('')=(FLines[1]), 'Second line should be empty');
end;

procedure TTestSplitLineAction.TestSplitWithAutoIndent;
begin
  FLines.Add('  hello world');
  { Split at position 7 (after 'he'), with 2-space auto-indent }
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 7, '  '));
  FContext.AssertTrue((2)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('  hello')=(FLines[0]), 'First line');
  FContext.AssertTrue(('   world')=(FLines[1]), 'Second line with indent');
end;

procedure TTestSplitLineAction.TestUndoSplitRejoinsLine;
begin
  FLines.Add('hello world');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 5));
  FContext.AssertTrue((2)=(FLines.Count), 'After split');
  FManager.Undo;
  FContext.AssertTrue((1)=(FLines.Count), 'After undo line count');
  FContext.AssertTrue(('hello world')=(FLines[0]), 'After undo content');
end;

procedure TTestSplitLineAction.TestRedoSplitSplitsAgain;
begin
  FLines.Add('hello world');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 5));
  FManager.Undo;
  FManager.Redo;
  FContext.AssertTrue((2)=(FLines.Count), 'After redo line count');
  FContext.AssertTrue(('hello')=(FLines[0]), 'First line');
  FContext.AssertTrue((' world')=(FLines[1]), 'Second line');
end;


{ =========================================================================
    TTestJoinLinesAction
  ========================================================================= }

procedure TTestJoinLinesAction.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestJoinLinesAction.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestJoinLinesAction.TestJoinWithPreviousLine;
begin
  FLines.Add('hello');
  FLines.Add(' world');
  { Join line 1 onto line 0 (backspace at start of line 1) }
  FManager.ExecuteAction(TJoinLinesAction.Create(FLines, 1));
  FContext.AssertTrue((1)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('hello world')=(FLines[0]), 'Joined content');
end;

procedure TTestJoinLinesAction.TestJoinWithNextLine;
begin
  FLines.Add('hello');
  FLines.Add(' world');
  { Join line 1 onto line 0 (delete at end of line 0) — same operation, different trigger }
  FManager.ExecuteAction(TJoinLinesAction.Create(FLines, 1));
  FContext.AssertTrue((1)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('hello world')=(FLines[0]), 'Joined content');
end;

procedure TTestJoinLinesAction.TestUndoJoinRestoresTwoLines;
begin
  FLines.Add('hello');
  FLines.Add(' world');
  FManager.ExecuteAction(TJoinLinesAction.Create(FLines, 1));
  FContext.AssertTrue((1)=(FLines.Count), 'After join');
  FManager.Undo;
  FContext.AssertTrue((2)=(FLines.Count), 'After undo line count');
  FContext.AssertTrue(('hello')=(FLines[0]), 'Line 0');
  FContext.AssertTrue((' world')=(FLines[1]), 'Line 1');
end;

procedure TTestJoinLinesAction.TestRedoJoinMergesAgain;
begin
  FLines.Add('hello');
  FLines.Add(' world');
  FManager.ExecuteAction(TJoinLinesAction.Create(FLines, 1));
  FManager.Undo;
  FManager.Redo;
  FContext.AssertTrue((1)=(FLines.Count), 'After redo line count');
  FContext.AssertTrue(('hello world')=(FLines[0]), 'After redo content');
end;


{ =========================================================================
    TTestCompoundAction
  ========================================================================= }

procedure TTestCompoundAction.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestCompoundAction.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestCompoundAction.TestCompoundUndoesAllAtOnce;
var
  Compound: TCompoundAction;
begin
  FLines.Add('hello world');
  { Simulate paste-replacing-selection: delete selection then insert }
  Compound := TCompoundAction.Create;
  Compound.Add(TDeleteTextAction.Create(FLines, 0, 6, 5)); { delete 'world' }
  Compound.Add(TInsertTextAction.Create(FLines, 0, 6, 'there'));  { insert 'there' }
  FManager.ExecuteAction(Compound);
  FContext.AssertTrue(('hello there')=(FLines[0]), 'After compound');

  { Single undo should revert the entire compound }
  FManager.Undo;
  FContext.AssertTrue(('hello world')=(FLines[0]), 'After undo');
  FContext.AssertTrue((0)=(FManager.UndoCount), 'Only one undo step consumed');
end;

procedure TTestCompoundAction.TestCompoundRedoesAllAtOnce;
var
  Compound: TCompoundAction;
begin
  FLines.Add('hello world');
  Compound := TCompoundAction.Create;
  Compound.Add(TDeleteTextAction.Create(FLines, 0, 6, 5));
  Compound.Add(TInsertTextAction.Create(FLines, 0, 6, 'there'));
  FManager.ExecuteAction(Compound);
  FManager.Undo;
  FManager.Redo;
  FContext.AssertTrue(('hello there')=(FLines[0]), 'After redo');
end;

procedure TTestCompoundAction.TestEmptyCompoundIsNoOp;
var
  Compound: TCompoundAction;
begin
  FLines.Add('hello');
  Compound := TCompoundAction.Create;
  FManager.ExecuteAction(Compound);
  FContext.AssertTrue(('hello')=(FLines[0]), 'Text unchanged');
  { Empty compound should still be on the stack but undo is harmless }
  FManager.Undo;
  FContext.AssertTrue(('hello')=(FLines[0]), 'Still unchanged');
end;


{ =========================================================================
    TTestActionMerging
  ========================================================================= }

procedure TTestActionMerging.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestActionMerging.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestActionMerging.TestConsecutiveInsertsAtSamePositionMerge;
begin
  FLines.Add('');
  { Type 'hello' one character at a time — should merge into one undo step }
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 0, 'h'));
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 1, 'e'));
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 2, 'l'));
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 3, 'l'));
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 4, 'o'));
  FContext.AssertTrue(('hello')=(FLines[0]), 'Text after typing');
  FContext.AssertTrue((1)=(FManager.UndoCount), 'Should merge into 1 undo step');

  FManager.Undo;
  FContext.AssertTrue(('')=(FLines[0]), 'Single undo reverts entire word');
end;

procedure TTestActionMerging.TestInsertAfterPauseDoesNotMerge;
begin
  FLines.Add('');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 0, 'a'));
  { Force a merge break }
  FManager.BreakMerge;
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 1, 'b'));
  FContext.AssertTrue(('ab')=(FLines[0]), 'Text after typing');
  FContext.AssertTrue((2)=(FManager.UndoCount), 'Should be 2 separate undo steps');
end;

procedure TTestActionMerging.TestDeletesDoNotMergeWithInserts;
begin
  FLines.Add('hello');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 5, 'X'));
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 5, 1));
  FContext.AssertTrue(('hello')=(FLines[0]), 'Text unchanged after insert+delete');
  FContext.AssertTrue((2)=(FManager.UndoCount), 'Different action types should not merge');
end;

procedure TTestActionMerging.TestConsecutiveBackspacesAtSamePositionMerge;
begin
  FLines.Add('hello');
  { Backspace from end: delete 'o', then 'l', then 'l' }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 4, 1));  { delete 'o' }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 3, 1));  { delete 'l' }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 2, 1));  { delete 'l' }
  FContext.AssertTrue(('he')=(FLines[0]), 'Text after backspaces');
  FContext.AssertTrue((1)=(FManager.UndoCount), 'Consecutive backspaces should merge');

  FManager.Undo;
  FContext.AssertTrue(('hello')=(FLines[0]), 'Single undo restores all');
end;


{ =========================================================================
    TTestUTF8Actions — verify all actions handle multi-byte codepoints
    correctly (where byte offset ≠ codepoint offset).
  ========================================================================= }

procedure TTestUTF8Actions.SetUp;
begin
  
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestUTF8Actions.TearDown;
begin
  FManager.Free;
  FLines.Free;
  
end;

procedure TTestUTF8Actions.TestInsertAfterMultiByte;
begin
  { Line: 'café' — é is 2 bytes, so byte length = 5, codepoint count = 4 }
  FLines.Add('caf' + #$C3#$A9);
  { Insert 's' at codepoint 4 (after é). Byte-based Insert at pos 4 would
    land inside the é sequence — only codepoint-based insert is correct. }
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 4, 's'));
  FContext.AssertTrue(('caf' + #$C3#$A9 + 's')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('caf' + #$C3#$A9)=(FLines[0]), '');
end;

procedure TTestUTF8Actions.TestDeleteMultiByteCodepoint;
begin
  { Line: 'café' — delete the é at codepoint 3 }
  FLines.Add('caf' + #$C3#$A9);
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 3, 1));
  FContext.AssertTrue(('caf')=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('caf' + #$C3#$A9)=(FLines[0]), '');
end;

procedure TTestUTF8Actions.TestDeleteAfterMultiByte;
begin
  { Line: 'résumé' — r(1) é(2) s(3) u(4) m(5) é(6), 8 bytes total
    Delete 'u' at codepoint 3 (0-based) = codepoint 4 (1-based) }
  FLines.Add('r' + #$C3#$A9 + 'sum' + #$C3#$A9);
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 3, 1));
  FContext.AssertTrue(('r' + #$C3#$A9 + 'sm' + #$C3#$A9)=(FLines[0]), '');
  FManager.Undo;
  FContext.AssertTrue(('r' + #$C3#$A9 + 'sum' + #$C3#$A9)=(FLines[0]), '');
end;

procedure TTestUTF8Actions.TestSplitLineWithMultiByte;
begin
  { Line: 'café latte' — split at codepoint 5 (after the space) }
  FLines.Add('caf' + #$C3#$A9 + ' latte');
  FManager.ExecuteAction(TSplitLineAction.Create(FLines, 0, 5));
  FContext.AssertTrue((2)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('caf' + #$C3#$A9 + ' ')=(FLines[0]), 'First line');
  FContext.AssertTrue(('latte')=(FLines[1]), 'Second line');
  FManager.Undo;
  FContext.AssertTrue((1)=(FLines.Count), 'After undo count');
  FContext.AssertTrue(('caf' + #$C3#$A9 + ' latte')=(FLines[0]), 'After undo');
end;

procedure TTestUTF8Actions.TestJoinLinesWithMultiByte;
begin
  { Two lines with multi-byte chars, join them }
  FLines.Add('caf' + #$C3#$A9);
  FLines.Add(' cr' + #$C3#$A8 + 'me');
  FManager.ExecuteAction(TJoinLinesAction.Create(FLines, 1));
  FContext.AssertTrue((1)=(FLines.Count), 'Line count');
  FContext.AssertTrue(('caf' + #$C3#$A9 + ' cr' + #$C3#$A8 + 'me')=(FLines[0]), 'Joined');
  FManager.Undo;
  FContext.AssertTrue((2)=(FLines.Count), 'After undo count');
  FContext.AssertTrue(('caf' + #$C3#$A9)=(FLines[0]), 'Line 0');
  FContext.AssertTrue((' cr' + #$C3#$A8 + 'me')=(FLines[1]), 'Line 1');
end;

procedure TTestUTF8Actions.TestConsecutiveMultiByteInsertsMerge;
begin
  { Type two multi-byte chars — should merge into one undo step }
  FLines.Add('ab');
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 2, #$C3#$A9));  { é }
  FManager.ExecuteAction(TInsertTextAction.Create(FLines, 0, 3, #$C3#$A8));  { è }
  FContext.AssertTrue(('ab' + #$C3#$A9 + #$C3#$A8)=(FLines[0]), '');
  FContext.AssertTrue((1)=(FManager.UndoCount), 'Should merge');
  FManager.Undo;
  FContext.AssertTrue(('ab')=(FLines[0]), '');
end;

procedure TTestUTF8Actions.TestBackspaceMultiByteCodepointsMerge;
begin
  { Line: 'aéè' — backspace è then é }
  FLines.Add('a' + #$C3#$A9 + #$C3#$A8);
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 2, 1));  { delete è at codepoint 2 }
  FManager.ExecuteAction(TDeleteTextAction.Create(FLines, 0, 1, 1));  { delete é at codepoint 1 }
  FContext.AssertTrue(('a')=(FLines[0]), '');
  FContext.AssertTrue((1)=(FManager.UndoCount), 'Backspaces should merge');
  FManager.Undo;
  FContext.AssertTrue(('a' + #$C3#$A9 + #$C3#$A8)=(FLines[0]), '');
end;



procedure RunTTestUndoManagerTestInitialState(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInitialState';
    lFixture.SetUp;
    try lFixture.TestInitialState; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestCanUndoAfterAction(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCanUndoAfterAction';
    lFixture.SetUp;
    try lFixture.TestCanUndoAfterAction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestCanRedoAfterUndo(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCanRedoAfterUndo';
    lFixture.SetUp;
    try lFixture.TestCanRedoAfterUndo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestRedoClearedAfterNewAction(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoClearedAfterNewAction';
    lFixture.SetUp;
    try lFixture.TestRedoClearedAfterNewAction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestUndoRestoresState(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoRestoresState';
    lFixture.SetUp;
    try lFixture.TestUndoRestoresState; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestRedoReappliesState(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoReappliesState';
    lFixture.SetUp;
    try lFixture.TestRedoReappliesState; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestMultipleUndoRedo(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultipleUndoRedo';
    lFixture.SetUp;
    try lFixture.TestMultipleUndoRedo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestUndoOnEmptyStackDoesNothing(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoOnEmptyStackDoesNothing';
    lFixture.SetUp;
    try lFixture.TestUndoOnEmptyStackDoesNothing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestRedoOnEmptyStackDoesNothing(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoOnEmptyStackDoesNothing';
    lFixture.SetUp;
    try lFixture.TestRedoOnEmptyStackDoesNothing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestMaxUndoLevels(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMaxUndoLevels';
    lFixture.SetUp;
    try lFixture.TestMaxUndoLevels; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUndoManagerTestClear(AContext: TNXTestContext);
var lFixture: TTestUndoManager;
begin
  lFixture:=TTestUndoManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClear';
    lFixture.SetUp;
    try lFixture.TestClear; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestInsertSingleChar(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertSingleChar';
    lFixture.SetUp;
    try lFixture.TestInsertSingleChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestInsertAtMiddleOfLine(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertAtMiddleOfLine';
    lFixture.SetUp;
    try lFixture.TestInsertAtMiddleOfLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestInsertAtEndOfLine(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertAtEndOfLine';
    lFixture.SetUp;
    try lFixture.TestInsertAtEndOfLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestInsertIntoEmptyLine(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertIntoEmptyLine';
    lFixture.SetUp;
    try lFixture.TestInsertIntoEmptyLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestUndoInsertRemovesText(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoInsertRemovesText';
    lFixture.SetUp;
    try lFixture.TestUndoInsertRemovesText; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestRedoInsertRestoresText(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoInsertRestoresText';
    lFixture.SetUp;
    try lFixture.TestRedoInsertRestoresText; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertTextActionTestInsertMultiByteUTF8(AContext: TNXTestContext);
var lFixture: TTestInsertTextAction;
begin
  lFixture:=TTestInsertTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertMultiByteUTF8';
    lFixture.SetUp;
    try lFixture.TestInsertMultiByteUTF8; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestDeleteSingleChar(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteSingleChar';
    lFixture.SetUp;
    try lFixture.TestDeleteSingleChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestDeleteAtStartOfLine(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteAtStartOfLine';
    lFixture.SetUp;
    try lFixture.TestDeleteAtStartOfLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestUndoDeleteRestoresChar(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoDeleteRestoresChar';
    lFixture.SetUp;
    try lFixture.TestUndoDeleteRestoresChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestRedoDeleteRemovesAgain(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoDeleteRemovesAgain';
    lFixture.SetUp;
    try lFixture.TestRedoDeleteRemovesAgain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestDeleteSelection(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteSelection';
    lFixture.SetUp;
    try lFixture.TestDeleteSelection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteTextActionTestUndoDeleteSelectionRestoresText(AContext: TNXTestContext);
var lFixture: TTestDeleteTextAction;
begin
  lFixture:=TTestDeleteTextAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoDeleteSelectionRestoresText';
    lFixture.SetUp;
    try lFixture.TestUndoDeleteSelectionRestoresText; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestSplitAtMiddle(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplitAtMiddle';
    lFixture.SetUp;
    try lFixture.TestSplitAtMiddle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestSplitAtStart(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplitAtStart';
    lFixture.SetUp;
    try lFixture.TestSplitAtStart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestSplitAtEnd(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplitAtEnd';
    lFixture.SetUp;
    try lFixture.TestSplitAtEnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestSplitWithAutoIndent(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplitWithAutoIndent';
    lFixture.SetUp;
    try lFixture.TestSplitWithAutoIndent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestUndoSplitRejoinsLine(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoSplitRejoinsLine';
    lFixture.SetUp;
    try lFixture.TestUndoSplitRejoinsLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSplitLineActionTestRedoSplitSplitsAgain(AContext: TNXTestContext);
var lFixture: TTestSplitLineAction;
begin
  lFixture:=TTestSplitLineAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoSplitSplitsAgain';
    lFixture.SetUp;
    try lFixture.TestRedoSplitSplitsAgain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJoinLinesActionTestJoinWithPreviousLine(AContext: TNXTestContext);
var lFixture: TTestJoinLinesAction;
begin
  lFixture:=TTestJoinLinesAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestJoinWithPreviousLine';
    lFixture.SetUp;
    try lFixture.TestJoinWithPreviousLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJoinLinesActionTestJoinWithNextLine(AContext: TNXTestContext);
var lFixture: TTestJoinLinesAction;
begin
  lFixture:=TTestJoinLinesAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestJoinWithNextLine';
    lFixture.SetUp;
    try lFixture.TestJoinWithNextLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJoinLinesActionTestUndoJoinRestoresTwoLines(AContext: TNXTestContext);
var lFixture: TTestJoinLinesAction;
begin
  lFixture:=TTestJoinLinesAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUndoJoinRestoresTwoLines';
    lFixture.SetUp;
    try lFixture.TestUndoJoinRestoresTwoLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJoinLinesActionTestRedoJoinMergesAgain(AContext: TNXTestContext);
var lFixture: TTestJoinLinesAction;
begin
  lFixture:=TTestJoinLinesAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRedoJoinMergesAgain';
    lFixture.SetUp;
    try lFixture.TestRedoJoinMergesAgain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCompoundActionTestCompoundUndoesAllAtOnce(AContext: TNXTestContext);
var lFixture: TTestCompoundAction;
begin
  lFixture:=TTestCompoundAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCompoundUndoesAllAtOnce';
    lFixture.SetUp;
    try lFixture.TestCompoundUndoesAllAtOnce; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCompoundActionTestCompoundRedoesAllAtOnce(AContext: TNXTestContext);
var lFixture: TTestCompoundAction;
begin
  lFixture:=TTestCompoundAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCompoundRedoesAllAtOnce';
    lFixture.SetUp;
    try lFixture.TestCompoundRedoesAllAtOnce; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCompoundActionTestEmptyCompoundIsNoOp(AContext: TNXTestContext);
var lFixture: TTestCompoundAction;
begin
  lFixture:=TTestCompoundAction.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyCompoundIsNoOp';
    lFixture.SetUp;
    try lFixture.TestEmptyCompoundIsNoOp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestActionMergingTestConsecutiveInsertsAtSamePositionMerge(AContext: TNXTestContext);
var lFixture: TTestActionMerging;
begin
  lFixture:=TTestActionMerging.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConsecutiveInsertsAtSamePositionMerge';
    lFixture.SetUp;
    try lFixture.TestConsecutiveInsertsAtSamePositionMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestActionMergingTestInsertAfterPauseDoesNotMerge(AContext: TNXTestContext);
var lFixture: TTestActionMerging;
begin
  lFixture:=TTestActionMerging.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertAfterPauseDoesNotMerge';
    lFixture.SetUp;
    try lFixture.TestInsertAfterPauseDoesNotMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestActionMergingTestDeletesDoNotMergeWithInserts(AContext: TNXTestContext);
var lFixture: TTestActionMerging;
begin
  lFixture:=TTestActionMerging.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeletesDoNotMergeWithInserts';
    lFixture.SetUp;
    try lFixture.TestDeletesDoNotMergeWithInserts; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestActionMergingTestConsecutiveBackspacesAtSamePositionMerge(AContext: TNXTestContext);
var lFixture: TTestActionMerging;
begin
  lFixture:=TTestActionMerging.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConsecutiveBackspacesAtSamePositionMerge';
    lFixture.SetUp;
    try lFixture.TestConsecutiveBackspacesAtSamePositionMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestInsertAfterMultiByte(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertAfterMultiByte';
    lFixture.SetUp;
    try lFixture.TestInsertAfterMultiByte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestDeleteMultiByteCodepoint(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteMultiByteCodepoint';
    lFixture.SetUp;
    try lFixture.TestDeleteMultiByteCodepoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestDeleteAfterMultiByte(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteAfterMultiByte';
    lFixture.SetUp;
    try lFixture.TestDeleteAfterMultiByte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestSplitLineWithMultiByte(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplitLineWithMultiByte';
    lFixture.SetUp;
    try lFixture.TestSplitLineWithMultiByte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestJoinLinesWithMultiByte(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestJoinLinesWithMultiByte';
    lFixture.SetUp;
    try lFixture.TestJoinLinesWithMultiByte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestConsecutiveMultiByteInsertsMerge(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConsecutiveMultiByteInsertsMerge';
    lFixture.SetUp;
    try lFixture.TestConsecutiveMultiByteInsertsMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUTF8ActionsTestBackspaceMultiByteCodepointsMerge(AContext: TNXTestContext);
var lFixture: TTestUTF8Actions;
begin
  lFixture:=TTestUTF8Actions.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBackspaceMultiByteCodepointsMerge';
    lFixture.SetUp;
    try lFixture.TestBackspaceMultiByteCodepointsMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetesteditorundoTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestUndoManager');
  lSuite.AddTest('TestInitialState', @RunTTestUndoManagerTestInitialState);
  lSuite.AddTest('TestCanUndoAfterAction', @RunTTestUndoManagerTestCanUndoAfterAction);
  lSuite.AddTest('TestCanRedoAfterUndo', @RunTTestUndoManagerTestCanRedoAfterUndo);
  lSuite.AddTest('TestRedoClearedAfterNewAction', @RunTTestUndoManagerTestRedoClearedAfterNewAction);
  lSuite.AddTest('TestUndoRestoresState', @RunTTestUndoManagerTestUndoRestoresState);
  lSuite.AddTest('TestRedoReappliesState', @RunTTestUndoManagerTestRedoReappliesState);
  lSuite.AddTest('TestMultipleUndoRedo', @RunTTestUndoManagerTestMultipleUndoRedo);
  lSuite.AddTest('TestUndoOnEmptyStackDoesNothing', @RunTTestUndoManagerTestUndoOnEmptyStackDoesNothing);
  lSuite.AddTest('TestRedoOnEmptyStackDoesNothing', @RunTTestUndoManagerTestRedoOnEmptyStackDoesNothing);
  lSuite.AddTest('TestMaxUndoLevels', @RunTTestUndoManagerTestMaxUndoLevels);
  lSuite.AddTest('TestClear', @RunTTestUndoManagerTestClear);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestInsertTextAction');
  lSuite.AddTest('TestInsertSingleChar', @RunTTestInsertTextActionTestInsertSingleChar);
  lSuite.AddTest('TestInsertAtMiddleOfLine', @RunTTestInsertTextActionTestInsertAtMiddleOfLine);
  lSuite.AddTest('TestInsertAtEndOfLine', @RunTTestInsertTextActionTestInsertAtEndOfLine);
  lSuite.AddTest('TestInsertIntoEmptyLine', @RunTTestInsertTextActionTestInsertIntoEmptyLine);
  lSuite.AddTest('TestUndoInsertRemovesText', @RunTTestInsertTextActionTestUndoInsertRemovesText);
  lSuite.AddTest('TestRedoInsertRestoresText', @RunTTestInsertTextActionTestRedoInsertRestoresText);
  lSuite.AddTest('TestInsertMultiByteUTF8', @RunTTestInsertTextActionTestInsertMultiByteUTF8);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestDeleteTextAction');
  lSuite.AddTest('TestDeleteSingleChar', @RunTTestDeleteTextActionTestDeleteSingleChar);
  lSuite.AddTest('TestDeleteAtStartOfLine', @RunTTestDeleteTextActionTestDeleteAtStartOfLine);
  lSuite.AddTest('TestUndoDeleteRestoresChar', @RunTTestDeleteTextActionTestUndoDeleteRestoresChar);
  lSuite.AddTest('TestRedoDeleteRemovesAgain', @RunTTestDeleteTextActionTestRedoDeleteRemovesAgain);
  lSuite.AddTest('TestDeleteSelection', @RunTTestDeleteTextActionTestDeleteSelection);
  lSuite.AddTest('TestUndoDeleteSelectionRestoresText', @RunTTestDeleteTextActionTestUndoDeleteSelectionRestoresText);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestSplitLineAction');
  lSuite.AddTest('TestSplitAtMiddle', @RunTTestSplitLineActionTestSplitAtMiddle);
  lSuite.AddTest('TestSplitAtStart', @RunTTestSplitLineActionTestSplitAtStart);
  lSuite.AddTest('TestSplitAtEnd', @RunTTestSplitLineActionTestSplitAtEnd);
  lSuite.AddTest('TestSplitWithAutoIndent', @RunTTestSplitLineActionTestSplitWithAutoIndent);
  lSuite.AddTest('TestUndoSplitRejoinsLine', @RunTTestSplitLineActionTestUndoSplitRejoinsLine);
  lSuite.AddTest('TestRedoSplitSplitsAgain', @RunTTestSplitLineActionTestRedoSplitSplitsAgain);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestJoinLinesAction');
  lSuite.AddTest('TestJoinWithPreviousLine', @RunTTestJoinLinesActionTestJoinWithPreviousLine);
  lSuite.AddTest('TestJoinWithNextLine', @RunTTestJoinLinesActionTestJoinWithNextLine);
  lSuite.AddTest('TestUndoJoinRestoresTwoLines', @RunTTestJoinLinesActionTestUndoJoinRestoresTwoLines);
  lSuite.AddTest('TestRedoJoinMergesAgain', @RunTTestJoinLinesActionTestRedoJoinMergesAgain);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestCompoundAction');
  lSuite.AddTest('TestCompoundUndoesAllAtOnce', @RunTTestCompoundActionTestCompoundUndoesAllAtOnce);
  lSuite.AddTest('TestCompoundRedoesAllAtOnce', @RunTTestCompoundActionTestCompoundRedoesAllAtOnce);
  lSuite.AddTest('TestEmptyCompoundIsNoOp', @RunTTestCompoundActionTestEmptyCompoundIsNoOp);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestActionMerging');
  lSuite.AddTest('TestConsecutiveInsertsAtSamePositionMerge', @RunTTestActionMergingTestConsecutiveInsertsAtSamePositionMerge);
  lSuite.AddTest('TestInsertAfterPauseDoesNotMerge', @RunTTestActionMergingTestInsertAfterPauseDoesNotMerge);
  lSuite.AddTest('TestDeletesDoNotMergeWithInserts', @RunTTestActionMergingTestDeletesDoNotMergeWithInserts);
  lSuite.AddTest('TestConsecutiveBackspacesAtSamePositionMerge', @RunTTestActionMergingTestConsecutiveBackspacesAtSamePositionMerge);
  lSuite:=ARegistry.AddSuite('ide.test.editor.undo.TTestUTF8Actions');
  lSuite.AddTest('TestInsertAfterMultiByte', @RunTTestUTF8ActionsTestInsertAfterMultiByte);
  lSuite.AddTest('TestDeleteMultiByteCodepoint', @RunTTestUTF8ActionsTestDeleteMultiByteCodepoint);
  lSuite.AddTest('TestDeleteAfterMultiByte', @RunTTestUTF8ActionsTestDeleteAfterMultiByte);
  lSuite.AddTest('TestSplitLineWithMultiByte', @RunTTestUTF8ActionsTestSplitLineWithMultiByte);
  lSuite.AddTest('TestJoinLinesWithMultiByte', @RunTTestUTF8ActionsTestJoinLinesWithMultiByte);
  lSuite.AddTest('TestConsecutiveMultiByteInsertsMerge', @RunTTestUTF8ActionsTestConsecutiveMultiByteInsertsMerge);
  lSuite.AddTest('TestBackspaceMultiByteCodepointsMerge', @RunTTestUTF8ActionsTestBackspaceMultiByteCodepointsMerge);
end;

end.

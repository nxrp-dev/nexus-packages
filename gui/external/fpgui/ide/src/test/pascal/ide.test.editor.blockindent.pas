{
    fpGUI IDE — Block Indent/Unindent Tests

    Tests for block indent and unindent operations using TTextBlockAction.
    These tests verify the indent logic in isolation from the text editor
    widget, operating directly on a TStringList as the text model.
}
unit ide.test.editor.blockindent;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.editor.undo;

type

  { TTestBlockIndent }

  TTestBlockIndent = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FLines: TStringList;
    FManager: TUndoManager;
    procedure IndentLines(AStartLine, AEndLine, AIndentSize: Integer);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestIndentSingleLine;
    procedure TestIndentMultipleLines;
    procedure TestIndentPreservesExistingIndent;
    procedure TestIndentEmptyLine;
    procedure TestIndentMixedContentWithEmptyLines;
    procedure TestIndentCustomSize;
    procedure TestIndentUndo;
    procedure TestIndentUndoRedo;
  end;


  { TTestBlockUnindent }

  TTestBlockUnindent = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FLines: TStringList;
    FManager: TUndoManager;
    procedure UnindentLines(AStartLine, AEndLine, AIndentSize: Integer);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestUnindentSingleLine;
    procedure TestUnindentMultipleLines;
    procedure TestUnindentRemovesPartialIndent;
    procedure TestUnindentNoLeadingSpaces;
    procedure TestUnindentEmptyLine;
    procedure TestUnindentMixedIndentLevels;
    procedure TestUnindentWithTabs;
    procedure TestUnindentUndo;
    procedure TestUnindentUndoRedo;
  end;


  { TTestBlockIndentRoundTrip }

  TTestBlockIndentRoundTrip = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FLines: TStringList;
    FManager: TUndoManager;
    procedure IndentLines(AStartLine, AEndLine, AIndentSize: Integer);
    procedure UnindentLines(AStartLine, AEndLine, AIndentSize: Integer);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestIndentThenUnindentRestoresOriginal;
    procedure TestMultipleIndentsThenUnindents;
    procedure TestIndentUndoIsSingleStep;
    procedure TestUnindentUndoIsSingleStep;
  end;


procedure RegisteridetesteditorblockindentTests(ARegistry: TNXTestRegistry);

implementation

{ Helper: indent lines AStartLine..AEndLine by prepending AIndentSize spaces.
  Uses TTextBlockAction for undo support. }
procedure IndentLinesImpl(ALines: TStringList; AManager: TUndoManager;
  AStartLine, AEndLine, AIndentSize: Integer);
var
  Block: TTextBlockAction;
  I: Integer;
  Indent: string;
begin
  Block := TTextBlockAction.Create(ALines, AStartLine);
  Block.SaveBefore(AEndLine);
  Block.CaretBefore := Point(0, AStartLine);

  Indent := StringOfChar(' ', AIndentSize);
  for I := AStartLine to AEndLine do
    ALines[I] := Indent + ALines[I];

  Block.SaveAfter(AEndLine);
  Block.CaretAfter := Point(AIndentSize, AStartLine);
  AManager.ExecuteAction(Block);
end;

{ Helper: unindent lines AStartLine..AEndLine by removing up to AIndentSize
  leading spaces (or one tab). Uses TTextBlockAction for undo support. }
procedure UnindentLinesImpl(ALines: TStringList; AManager: TUndoManager;
  AStartLine, AEndLine, AIndentSize: Integer);
var
  Block: TTextBlockAction;
  I, J, Remove: Integer;
  Line: string;
begin
  Block := TTextBlockAction.Create(ALines, AStartLine);
  Block.SaveBefore(AEndLine);
  Block.CaretBefore := Point(0, AStartLine);

  for I := AStartLine to AEndLine do
  begin
    Line := ALines[I];
    if (Length(Line) > 0) and (Line[1] = #9) then
    begin
      { Remove one leading tab }
      Delete(Line, 1, 1);
      ALines[I] := Line;
    end
    else
    begin
      { Remove up to AIndentSize leading spaces }
      Remove := 0;
      for J := 1 to Length(Line) do
      begin
        if (Remove >= AIndentSize) then
          Break;
        if Line[J] = ' ' then
          Inc(Remove)
        else
          Break;
      end;
      if Remove > 0 then
      begin
        Delete(Line, 1, Remove);
        ALines[I] := Line;
      end;
    end;
  end;

  Block.SaveAfter(AEndLine);
  Block.CaretAfter := Point(0, AStartLine);
  AManager.ExecuteAction(Block);
end;


{ TTestBlockIndent }

procedure TTestBlockIndent.IndentLines(AStartLine, AEndLine, AIndentSize: Integer);
begin
  IndentLinesImpl(FLines, FManager, AStartLine, AEndLine, AIndentSize);
end;

procedure TTestBlockIndent.SetUp;
begin
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestBlockIndent.TearDown;
begin
  FManager.Free;
  FLines.Free;
end;

procedure TTestBlockIndent.TestIndentSingleLine;
begin
  FLines.Add('hello');
  IndentLines(0, 0, 2);
  TestContext.AssertTrue(('  hello')=(FLines[0]), 'Indented line');
end;

procedure TTestBlockIndent.TestIndentMultipleLines;
begin
  FLines.Add('line one');
  FLines.Add('line two');
  FLines.Add('line three');
  IndentLines(0, 2, 2);
  TestContext.AssertTrue(('  line one')=(FLines[0]), 'Line 0');
  TestContext.AssertTrue(('  line two')=(FLines[1]), 'Line 1');
  TestContext.AssertTrue(('  line three')=(FLines[2]), 'Line 2');
end;

procedure TTestBlockIndent.TestIndentPreservesExistingIndent;
begin
  FLines.Add('  already indented');
  IndentLines(0, 0, 2);
  TestContext.AssertTrue(('    already indented')=(FLines[0]), 'Double indented');
end;

procedure TTestBlockIndent.TestIndentEmptyLine;
begin
  FLines.Add('');
  IndentLines(0, 0, 2);
  TestContext.AssertTrue(('  ')=(FLines[0]), 'Indented empty line');
end;

procedure TTestBlockIndent.TestIndentMixedContentWithEmptyLines;
begin
  FLines.Add('first');
  FLines.Add('');
  FLines.Add('third');
  IndentLines(0, 2, 2);
  TestContext.AssertTrue(('  first')=(FLines[0]), 'Line 0');
  TestContext.AssertTrue(('  ')=(FLines[1]), 'Line 1 (empty)');
  TestContext.AssertTrue(('  third')=(FLines[2]), 'Line 2');
end;

procedure TTestBlockIndent.TestIndentCustomSize;
begin
  FLines.Add('hello');
  IndentLines(0, 0, 4);
  TestContext.AssertTrue(('    hello')=(FLines[0]), '4-space indent');
end;

procedure TTestBlockIndent.TestIndentUndo;
begin
  FLines.Add('hello');
  FLines.Add('world');
  IndentLines(0, 1, 2);
  TestContext.AssertTrue(('  hello')=(FLines[0]), 'Before undo line 0');
  TestContext.AssertTrue(('  world')=(FLines[1]), 'Before undo line 1');
  FManager.Undo;
  TestContext.AssertTrue(('hello')=(FLines[0]), 'After undo line 0');
  TestContext.AssertTrue(('world')=(FLines[1]), 'After undo line 1');
end;

procedure TTestBlockIndent.TestIndentUndoRedo;
begin
  FLines.Add('hello');
  IndentLines(0, 0, 2);
  FManager.Undo;
  TestContext.AssertTrue(('hello')=(FLines[0]), 'After undo');
  FManager.Redo;
  TestContext.AssertTrue(('  hello')=(FLines[0]), 'After redo');
end;


{ TTestBlockUnindent }

procedure TTestBlockUnindent.UnindentLines(AStartLine, AEndLine, AIndentSize: Integer);
begin
  UnindentLinesImpl(FLines, FManager, AStartLine, AEndLine, AIndentSize);
end;

procedure TTestBlockUnindent.SetUp;
begin
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestBlockUnindent.TearDown;
begin
  FManager.Free;
  FLines.Free;
end;

procedure TTestBlockUnindent.TestUnindentSingleLine;
begin
  FLines.Add('  hello');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('hello')=(FLines[0]), 'Unindented line');
end;

procedure TTestBlockUnindent.TestUnindentMultipleLines;
begin
  FLines.Add('  line one');
  FLines.Add('  line two');
  FLines.Add('  line three');
  UnindentLines(0, 2, 2);
  TestContext.AssertTrue(('line one')=(FLines[0]), 'Line 0');
  TestContext.AssertTrue(('line two')=(FLines[1]), 'Line 1');
  TestContext.AssertTrue(('line three')=(FLines[2]), 'Line 2');
end;

procedure TTestBlockUnindent.TestUnindentRemovesPartialIndent;
begin
  FLines.Add(' hello');  { only 1 space, indent size is 2 }
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('hello')=(FLines[0]), 'Partial unindent');
end;

procedure TTestBlockUnindent.TestUnindentNoLeadingSpaces;
begin
  FLines.Add('hello');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('hello')=(FLines[0]), 'No change');
end;

procedure TTestBlockUnindent.TestUnindentEmptyLine;
begin
  FLines.Add('');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('')=(FLines[0]), 'Empty stays empty');
end;

procedure TTestBlockUnindent.TestUnindentMixedIndentLevels;
begin
  FLines.Add('    four spaces');
  FLines.Add('  two spaces');
  FLines.Add(' one space');
  FLines.Add('no spaces');
  UnindentLines(0, 3, 2);
  TestContext.AssertTrue(('  four spaces')=(FLines[0]), 'Line 0');
  TestContext.AssertTrue(('two spaces')=(FLines[1]), 'Line 1');
  TestContext.AssertTrue(('one space')=(FLines[2]), 'Line 2');  { only 1 space removed }
  TestContext.AssertTrue(('no spaces')=(FLines[3]), 'Line 3');
end;

procedure TTestBlockUnindent.TestUnindentWithTabs;
begin
  FLines.Add(#9 + 'tabbed line');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('tabbed line')=(FLines[0]), 'Tab removed');
end;

procedure TTestBlockUnindent.TestUnindentUndo;
begin
  FLines.Add('  hello');
  FLines.Add('  world');
  UnindentLines(0, 1, 2);
  TestContext.AssertTrue(('hello')=(FLines[0]), 'Before undo line 0');
  TestContext.AssertTrue(('world')=(FLines[1]), 'Before undo line 1');
  FManager.Undo;
  TestContext.AssertTrue(('  hello')=(FLines[0]), 'After undo line 0');
  TestContext.AssertTrue(('  world')=(FLines[1]), 'After undo line 1');
end;

procedure TTestBlockUnindent.TestUnindentUndoRedo;
begin
  FLines.Add('  hello');
  UnindentLines(0, 0, 2);
  FManager.Undo;
  TestContext.AssertTrue(('  hello')=(FLines[0]), 'After undo');
  FManager.Redo;
  TestContext.AssertTrue(('hello')=(FLines[0]), 'After redo');
end;


{ TTestBlockIndentRoundTrip }

procedure TTestBlockIndentRoundTrip.IndentLines(AStartLine, AEndLine, AIndentSize: Integer);
begin
  IndentLinesImpl(FLines, FManager, AStartLine, AEndLine, AIndentSize);
end;

procedure TTestBlockIndentRoundTrip.UnindentLines(AStartLine, AEndLine, AIndentSize: Integer);
begin
  UnindentLinesImpl(FLines, FManager, AStartLine, AEndLine, AIndentSize);
end;

procedure TTestBlockIndentRoundTrip.SetUp;
begin
  FLines := TStringList.Create;
  FManager := TUndoManager.Create;
end;

procedure TTestBlockIndentRoundTrip.TearDown;
begin
  FManager.Free;
  FLines.Free;
end;

procedure TTestBlockIndentRoundTrip.TestIndentThenUnindentRestoresOriginal;
begin
  FLines.Add('hello');
  FLines.Add('world');
  IndentLines(0, 1, 2);
  UnindentLines(0, 1, 2);
  TestContext.AssertTrue(('hello')=(FLines[0]), 'Line 0 restored');
  TestContext.AssertTrue(('world')=(FLines[1]), 'Line 1 restored');
end;

procedure TTestBlockIndentRoundTrip.TestMultipleIndentsThenUnindents;
begin
  FLines.Add('code');
  IndentLines(0, 0, 2);
  IndentLines(0, 0, 2);
  TestContext.AssertTrue(('    code')=(FLines[0]), 'Double indented');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('  code')=(FLines[0]), 'Single indented');
  UnindentLines(0, 0, 2);
  TestContext.AssertTrue(('code')=(FLines[0]), 'Restored');
end;

procedure TTestBlockIndentRoundTrip.TestIndentUndoIsSingleStep;
begin
  FLines.Add('line one');
  FLines.Add('line two');
  FLines.Add('line three');
  IndentLines(0, 2, 2);
  TestContext.AssertTrue((1)=(FManager.UndoCount), 'Undo count after indent');
  FManager.Undo;
  TestContext.AssertTrue(('line one')=(FLines[0]), 'Line 0 after undo');
  TestContext.AssertTrue(('line two')=(FLines[1]), 'Line 1 after undo');
  TestContext.AssertTrue(('line three')=(FLines[2]), 'Line 2 after undo');
end;

procedure TTestBlockIndentRoundTrip.TestUnindentUndoIsSingleStep;
begin
  FLines.Add('  line one');
  FLines.Add('  line two');
  FLines.Add('  line three');
  UnindentLines(0, 2, 2);
  TestContext.AssertTrue((1)=(FManager.UndoCount), 'Undo count after unindent');
  FManager.Undo;
  TestContext.AssertTrue(('  line one')=(FLines[0]), 'Line 0 after undo');
  TestContext.AssertTrue(('  line two')=(FLines[1]), 'Line 1 after undo');
  TestContext.AssertTrue(('  line three')=(FLines[2]), 'Line 2 after undo');
end;



constructor TTestBlockIndent.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestBlockUnindent.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestBlockIndentRoundTrip.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBlockIndentTestIndentSingleLine(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentSingleLine');
  try
    lFixture.SetUp;
    try lFixture.TestIndentSingleLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentMultipleLines(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentMultipleLines');
  try
    lFixture.SetUp;
    try lFixture.TestIndentMultipleLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentPreservesExistingIndent(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentPreservesExistingIndent');
  try
    lFixture.SetUp;
    try lFixture.TestIndentPreservesExistingIndent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentEmptyLine(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentEmptyLine');
  try
    lFixture.SetUp;
    try lFixture.TestIndentEmptyLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentMixedContentWithEmptyLines(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentMixedContentWithEmptyLines');
  try
    lFixture.SetUp;
    try lFixture.TestIndentMixedContentWithEmptyLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentCustomSize(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentCustomSize');
  try
    lFixture.SetUp;
    try lFixture.TestIndentCustomSize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentUndo(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentUndo');
  try
    lFixture.SetUp;
    try lFixture.TestIndentUndo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentTestIndentUndoRedo(AContext: TNXTestContext);
var lFixture: TTestBlockIndent;
begin
  lFixture:=TTestBlockIndent.Create(AContext, 'TestIndentUndoRedo');
  try
    lFixture.SetUp;
    try lFixture.TestIndentUndoRedo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentSingleLine(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentSingleLine');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentSingleLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentMultipleLines(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentMultipleLines');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentMultipleLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentRemovesPartialIndent(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentRemovesPartialIndent');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentRemovesPartialIndent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentNoLeadingSpaces(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentNoLeadingSpaces');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentNoLeadingSpaces; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentEmptyLine(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentEmptyLine');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentEmptyLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentMixedIndentLevels(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentMixedIndentLevels');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentMixedIndentLevels; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentWithTabs(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentWithTabs');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentWithTabs; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentUndo(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentUndo');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentUndo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockUnindentTestUnindentUndoRedo(AContext: TNXTestContext);
var lFixture: TTestBlockUnindent;
begin
  lFixture:=TTestBlockUnindent.Create(AContext, 'TestUnindentUndoRedo');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentUndoRedo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentRoundTripTestIndentThenUnindentRestoresOriginal(AContext: TNXTestContext);
var lFixture: TTestBlockIndentRoundTrip;
begin
  lFixture:=TTestBlockIndentRoundTrip.Create(AContext, 'TestIndentThenUnindentRestoresOriginal');
  try
    lFixture.SetUp;
    try lFixture.TestIndentThenUnindentRestoresOriginal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentRoundTripTestMultipleIndentsThenUnindents(AContext: TNXTestContext);
var lFixture: TTestBlockIndentRoundTrip;
begin
  lFixture:=TTestBlockIndentRoundTrip.Create(AContext, 'TestMultipleIndentsThenUnindents');
  try
    lFixture.SetUp;
    try lFixture.TestMultipleIndentsThenUnindents; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentRoundTripTestIndentUndoIsSingleStep(AContext: TNXTestContext);
var lFixture: TTestBlockIndentRoundTrip;
begin
  lFixture:=TTestBlockIndentRoundTrip.Create(AContext, 'TestIndentUndoIsSingleStep');
  try
    lFixture.SetUp;
    try lFixture.TestIndentUndoIsSingleStep; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBlockIndentRoundTripTestUnindentUndoIsSingleStep(AContext: TNXTestContext);
var lFixture: TTestBlockIndentRoundTrip;
begin
  lFixture:=TTestBlockIndentRoundTrip.Create(AContext, 'TestUnindentUndoIsSingleStep');
  try
    lFixture.SetUp;
    try lFixture.TestUnindentUndoIsSingleStep; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetesteditorblockindentTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.editor.blockindent.TTestBlockIndent');
  lSuite.AddTest('TestIndentSingleLine', @RunTTestBlockIndentTestIndentSingleLine);
  lSuite.AddTest('TestIndentMultipleLines', @RunTTestBlockIndentTestIndentMultipleLines);
  lSuite.AddTest('TestIndentPreservesExistingIndent', @RunTTestBlockIndentTestIndentPreservesExistingIndent);
  lSuite.AddTest('TestIndentEmptyLine', @RunTTestBlockIndentTestIndentEmptyLine);
  lSuite.AddTest('TestIndentMixedContentWithEmptyLines', @RunTTestBlockIndentTestIndentMixedContentWithEmptyLines);
  lSuite.AddTest('TestIndentCustomSize', @RunTTestBlockIndentTestIndentCustomSize);
  lSuite.AddTest('TestIndentUndo', @RunTTestBlockIndentTestIndentUndo);
  lSuite.AddTest('TestIndentUndoRedo', @RunTTestBlockIndentTestIndentUndoRedo);
  lSuite:=ARegistry.AddSuite('ide.test.editor.blockindent.TTestBlockUnindent');
  lSuite.AddTest('TestUnindentSingleLine', @RunTTestBlockUnindentTestUnindentSingleLine);
  lSuite.AddTest('TestUnindentMultipleLines', @RunTTestBlockUnindentTestUnindentMultipleLines);
  lSuite.AddTest('TestUnindentRemovesPartialIndent', @RunTTestBlockUnindentTestUnindentRemovesPartialIndent);
  lSuite.AddTest('TestUnindentNoLeadingSpaces', @RunTTestBlockUnindentTestUnindentNoLeadingSpaces);
  lSuite.AddTest('TestUnindentEmptyLine', @RunTTestBlockUnindentTestUnindentEmptyLine);
  lSuite.AddTest('TestUnindentMixedIndentLevels', @RunTTestBlockUnindentTestUnindentMixedIndentLevels);
  lSuite.AddTest('TestUnindentWithTabs', @RunTTestBlockUnindentTestUnindentWithTabs);
  lSuite.AddTest('TestUnindentUndo', @RunTTestBlockUnindentTestUnindentUndo);
  lSuite.AddTest('TestUnindentUndoRedo', @RunTTestBlockUnindentTestUnindentUndoRedo);
  lSuite:=ARegistry.AddSuite('ide.test.editor.blockindent.TTestBlockIndentRoundTrip');
  lSuite.AddTest('TestIndentThenUnindentRestoresOriginal', @RunTTestBlockIndentRoundTripTestIndentThenUnindentRestoresOriginal);
  lSuite.AddTest('TestMultipleIndentsThenUnindents', @RunTTestBlockIndentRoundTripTestMultipleIndentsThenUnindents);
  lSuite.AddTest('TestIndentUndoIsSingleStep', @RunTTestBlockIndentRoundTripTestIndentUndoIsSingleStep);
  lSuite.AddTest('TestUnindentUndoIsSingleStep', @RunTTestBlockIndentRoundTripTestUnindentUndoIsSingleStep);
end;

end.

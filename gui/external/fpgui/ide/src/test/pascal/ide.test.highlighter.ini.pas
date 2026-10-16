{
    fpGUI IDE - INI Highlighter Tests

    Tests for TINIHighlighter token positions and categories.
}
unit ide.test.highlighter.ini;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.highlighter,
  ide.highlighter.ini;

type

  { TTestINIHighlighter }

  TTestINIHighlighter = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FHL: TINIHighlighter;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestSectionHeader;
    procedure TestKeyValue;
    procedure TestCommentSemicolon;
    procedure TestCommentHash;
    procedure TestEmptyLines;
    procedure TestKeyOnly;
  end;


procedure RegisteridetesthighlighteriniTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestINIHighlighter.SetUp;
begin
  FHL := TINIHighlighter.Create;
end;

procedure TTestINIHighlighter.TearDown;
begin
  FHL.Free;
end;

procedure TTestINIHighlighter.TestSectionHeader;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('[General]');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Column');
  TestContext.AssertTrue((9)=(tokens[0].Length), 'Length');
  TestContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'Category should be hcKeyword1');
end;

procedure TTestINIHighlighter.TestKeyValue;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('name=John');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((3)=(Length(tokens)), 'Should have 3 tokens (key, =, value)');
  TestContext.AssertTrue((Ord(hcIdentifier))=(Ord(tokens[0].Category)), 'Key should be hcIdentifier');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Key column');
  TestContext.AssertTrue((4)=(tokens[0].Length), 'Key length');
  TestContext.AssertTrue((Ord(hcSymbol))=(Ord(tokens[1].Category)), '= should be hcSymbol');
  TestContext.AssertTrue((Ord(hcString1))=(Ord(tokens[2].Category)), 'Value should be hcString1');
end;

procedure TTestINIHighlighter.TestCommentSemicolon;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('; this is a comment');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Should be hcComment1');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Column');
  TestContext.AssertTrue((19)=(tokens[0].Length), 'Length covers entire line');
end;

procedure TTestINIHighlighter.TestCommentHash;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('# comment');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Should be hcComment1');
end;

procedure TTestINIHighlighter.TestEmptyLines;
begin
  FHL.Tokenise('' + LineEnding + '' + LineEnding + '[Section]');
  TestContext.AssertTrue((0)=(FHL.GetLineTokenCount(0)), 'Line 0 should have no tokens');
  TestContext.AssertTrue((0)=(FHL.GetLineTokenCount(1)), 'Line 1 should have no tokens');
  TestContext.AssertTrue((1)=(FHL.GetLineTokenCount(2)), 'Line 2 should have 1 token');
end;

procedure TTestINIHighlighter.TestKeyOnly;
var
  tokens: THighlightTokenArray;
begin
  { A line with just a key and no = sign }
  FHL.Tokenise('orphankey');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  TestContext.AssertTrue((Ord(hcIdentifier))=(Ord(tokens[0].Category)), 'Should be hcIdentifier');
end;


constructor TTestINIHighlighter.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestINIHighlighterTestSectionHeader(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestSectionHeader');
  try
    lFixture.SetUp;
    try lFixture.TestSectionHeader; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestKeyValue(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestKeyValue');
  try
    lFixture.SetUp;
    try lFixture.TestKeyValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestCommentSemicolon(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestCommentSemicolon');
  try
    lFixture.SetUp;
    try lFixture.TestCommentSemicolon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestCommentHash(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestCommentHash');
  try
    lFixture.SetUp;
    try lFixture.TestCommentHash; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestEmptyLines(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestEmptyLines');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestKeyOnly(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create(AContext, 'TestKeyOnly');
  try
    lFixture.SetUp;
    try lFixture.TestKeyOnly; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetesthighlighteriniTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.highlighter.ini.TTestINIHighlighter');
  lSuite.AddTest('TestSectionHeader', @RunTTestINIHighlighterTestSectionHeader);
  lSuite.AddTest('TestKeyValue', @RunTTestINIHighlighterTestKeyValue);
  lSuite.AddTest('TestCommentSemicolon', @RunTTestINIHighlighterTestCommentSemicolon);
  lSuite.AddTest('TestCommentHash', @RunTTestINIHighlighterTestCommentHash);
  lSuite.AddTest('TestEmptyLines', @RunTTestINIHighlighterTestEmptyLines);
  lSuite.AddTest('TestKeyOnly', @RunTTestINIHighlighterTestKeyOnly);
end;

end.

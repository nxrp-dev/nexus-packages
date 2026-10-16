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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  FContext.AssertTrue((0)=(tokens[0].Column), 'Column');
  FContext.AssertTrue((9)=(tokens[0].Length), 'Length');
  FContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'Category should be hcKeyword1');
end;

procedure TTestINIHighlighter.TestKeyValue;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('name=John');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue((3)=(Length(tokens)), 'Should have 3 tokens (key, =, value)');
  FContext.AssertTrue((Ord(hcIdentifier))=(Ord(tokens[0].Category)), 'Key should be hcIdentifier');
  FContext.AssertTrue((0)=(tokens[0].Column), 'Key column');
  FContext.AssertTrue((4)=(tokens[0].Length), 'Key length');
  FContext.AssertTrue((Ord(hcSymbol))=(Ord(tokens[1].Category)), '= should be hcSymbol');
  FContext.AssertTrue((Ord(hcString1))=(Ord(tokens[2].Category)), 'Value should be hcString1');
end;

procedure TTestINIHighlighter.TestCommentSemicolon;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('; this is a comment');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  FContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Should be hcComment1');
  FContext.AssertTrue((0)=(tokens[0].Column), 'Column');
  FContext.AssertTrue((19)=(tokens[0].Length), 'Length covers entire line');
end;

procedure TTestINIHighlighter.TestCommentHash;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('# comment');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  FContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Should be hcComment1');
end;

procedure TTestINIHighlighter.TestEmptyLines;
begin
  FHL.Tokenise('' + LineEnding + '' + LineEnding + '[Section]');
  FContext.AssertTrue((0)=(FHL.GetLineTokenCount(0)), 'Line 0 should have no tokens');
  FContext.AssertTrue((0)=(FHL.GetLineTokenCount(1)), 'Line 1 should have no tokens');
  FContext.AssertTrue((1)=(FHL.GetLineTokenCount(2)), 'Line 2 should have 1 token');
end;

procedure TTestINIHighlighter.TestKeyOnly;
var
  tokens: THighlightTokenArray;
begin
  { A line with just a key and no = sign }
  FHL.Tokenise('orphankey');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 token');
  FContext.AssertTrue((Ord(hcIdentifier))=(Ord(tokens[0].Category)), 'Should be hcIdentifier');
end;


procedure RunTTestINIHighlighterTestSectionHeader(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSectionHeader';
    lFixture.SetUp;
    try lFixture.TestSectionHeader; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestKeyValue(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeyValue';
    lFixture.SetUp;
    try lFixture.TestKeyValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestCommentSemicolon(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCommentSemicolon';
    lFixture.SetUp;
    try lFixture.TestCommentSemicolon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestCommentHash(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCommentHash';
    lFixture.SetUp;
    try lFixture.TestCommentHash; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestEmptyLines(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyLines';
    lFixture.SetUp;
    try lFixture.TestEmptyLines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestINIHighlighterTestKeyOnly(AContext: TNXTestContext);
var lFixture: TTestINIHighlighter;
begin
  lFixture:=TTestINIHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeyOnly';
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

{
    fpGUI IDE - XML Highlighter Tests

    Tests for TXMLHighlighter token positions and categories.
}
unit ide.test.highlighter.xml;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.highlighter,
  ide.highlighter.xml;

type

  { TTestXMLHighlighter }

  TTestXMLHighlighter = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FHL: TXMLHighlighter;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestSimpleTag;
    procedure TestClosingTag;
    procedure TestSelfClosingTag;
    procedure TestAttribute;
    procedure TestComment;
    procedure TestProcessingInstruction;
    procedure TestEntityReference;
    procedure TestMultiLineComment;
    procedure TestCDATA;
  end;


procedure RegisteridetesthighlighterxmlTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestXMLHighlighter.SetUp;
begin
  FHL := TXMLHighlighter.Create;
end;

procedure TTestXMLHighlighter.TearDown;
begin
  FHL.Free;
end;

procedure TTestXMLHighlighter.TestSimpleTag;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<root>');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue(Length(tokens) >= 2, 'Should have at least 2 tokens (tag name, >)');
  TestContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'Tag name should be hcKeyword1');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Tag starts at column 0');
end;

procedure TTestXMLHighlighter.TestClosingTag;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('</root>');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue(Length(tokens) >= 2, 'Should have at least 2 tokens');
  TestContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'Closing tag should be hcKeyword1');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Starts at column 0');
  { The token should include </root }
  TestContext.AssertTrue(tokens[0].Length >= 6, 'Should include </root');
end;

procedure TTestXMLHighlighter.TestSelfClosingTag;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<br/>');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue(Length(tokens) >= 2, 'Should have at least 2 tokens');
  TestContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'Tag name hcKeyword1');
  { Last token should be /> }
  TestContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[Length(tokens) - 1].Category)), '/> should be hcKeyword1');
end;

procedure TTestXMLHighlighter.TestAttribute;
var
  tokens: THighlightTokenArray;
  i: Integer;
  hasIdent, hasString, hasSymbol: Boolean;
begin
  FHL.Tokenise('<div class="main">');
  tokens := FHL.GetLineTokens(0);
  hasIdent := False;
  hasString := False;
  hasSymbol := False;
  for i := 0 to Length(tokens) - 1 do
  begin
    if tokens[i].Category = hcIdentifier then
      hasIdent := True;
    if tokens[i].Category = hcString1 then
      hasString := True;
    if tokens[i].Category = hcSymbol then
      hasSymbol := True;
  end;
  TestContext.AssertTrue(hasIdent, 'Should have attribute name (hcIdentifier)');
  TestContext.AssertTrue(hasString, 'Should have attribute value (hcString1)');
  TestContext.AssertTrue(hasSymbol, 'Should have = separator (hcSymbol)');
end;

procedure TTestXMLHighlighter.TestComment;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<!-- a comment -->');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 comment token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Should be hcComment1');
  TestContext.AssertTrue((0)=(tokens[0].Column), 'Starts at column 0');
  TestContext.AssertTrue((18)=(tokens[0].Length), 'Covers entire comment');
end;

procedure TTestXMLHighlighter.TestProcessingInstruction;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<?xml version="1.0"?>');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 PI token');
  TestContext.AssertTrue((Ord(hcDirective))=(Ord(tokens[0].Category)), 'Should be hcDirective');
end;

procedure TTestXMLHighlighter.TestEntityReference;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('a &amp; b');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 entity token');
  TestContext.AssertTrue((Ord(hcSymbol))=(Ord(tokens[0].Category)), 'Entity should be hcSymbol');
  TestContext.AssertTrue((2)=(tokens[0].Column), 'Entity starts at column 2');
  TestContext.AssertTrue((5)=(tokens[0].Length), 'Entity length is 5 (&amp;)');
end;

procedure TTestXMLHighlighter.TestMultiLineComment;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<!-- start' + LineEnding + 'middle' + LineEnding + 'end -->');
  { Line 0: partial comment }
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Line 0 should have 1 token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Line 0 should be comment');
  { Line 1: continuation }
  tokens := FHL.GetLineTokens(1);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Line 1 should have 1 token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[1 - 1].Category)), 'Line 1 should be comment');
  { Line 2: closing }
  tokens := FHL.GetLineTokens(2);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Line 2 should have 1 token');
  TestContext.AssertTrue((Ord(hcComment1))=(Ord(tokens[0].Category)), 'Line 2 should be comment');
end;

procedure TTestXMLHighlighter.TestCDATA;
var
  tokens: THighlightTokenArray;
begin
  FHL.Tokenise('<![CDATA[some data]]>');
  tokens := FHL.GetLineTokens(0);
  TestContext.AssertTrue((1)=(Length(tokens)), 'Should have 1 CDATA token');
  TestContext.AssertTrue((Ord(hcDirective))=(Ord(tokens[0].Category)), 'CDATA should be hcDirective');
end;


constructor TTestXMLHighlighter.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestXMLHighlighterTestSimpleTag(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestSimpleTag');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleTag; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestClosingTag(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestClosingTag');
  try
    lFixture.SetUp;
    try lFixture.TestClosingTag; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestSelfClosingTag(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestSelfClosingTag');
  try
    lFixture.SetUp;
    try lFixture.TestSelfClosingTag; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestAttribute(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestAttribute');
  try
    lFixture.SetUp;
    try lFixture.TestAttribute; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestComment(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestComment');
  try
    lFixture.SetUp;
    try lFixture.TestComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestProcessingInstruction(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestProcessingInstruction');
  try
    lFixture.SetUp;
    try lFixture.TestProcessingInstruction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestEntityReference(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestEntityReference');
  try
    lFixture.SetUp;
    try lFixture.TestEntityReference; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestMultiLineComment(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestMultiLineComment');
  try
    lFixture.SetUp;
    try lFixture.TestMultiLineComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLHighlighterTestCDATA(AContext: TNXTestContext);
var lFixture: TTestXMLHighlighter;
begin
  lFixture:=TTestXMLHighlighter.Create(AContext, 'TestCDATA');
  try
    lFixture.SetUp;
    try lFixture.TestCDATA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetesthighlighterxmlTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.highlighter.xml.TTestXMLHighlighter');
  lSuite.AddTest('TestSimpleTag', @RunTTestXMLHighlighterTestSimpleTag);
  lSuite.AddTest('TestClosingTag', @RunTTestXMLHighlighterTestClosingTag);
  lSuite.AddTest('TestSelfClosingTag', @RunTTestXMLHighlighterTestSelfClosingTag);
  lSuite.AddTest('TestAttribute', @RunTTestXMLHighlighterTestAttribute);
  lSuite.AddTest('TestComment', @RunTTestXMLHighlighterTestComment);
  lSuite.AddTest('TestProcessingInstruction', @RunTTestXMLHighlighterTestProcessingInstruction);
  lSuite.AddTest('TestEntityReference', @RunTTestXMLHighlighterTestEntityReference);
  lSuite.AddTest('TestMultiLineComment', @RunTTestXMLHighlighterTestMultiLineComment);
  lSuite.AddTest('TestCDATA', @RunTTestXMLHighlighterTestCDATA);
end;

end.

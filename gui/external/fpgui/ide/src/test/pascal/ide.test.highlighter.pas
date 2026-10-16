{
    fpGUI IDE - Syntax Highlighter Tests

    Tests for TEditorHighlighter and TPascalHighlighter.
    These tests verify token positions, lengths, and categories
    against known Pascal source inputs.
}
unit ide.test.highlighter;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.highlighter;

type

  { TTestPascalHighlighter }

  TTestPascalHighlighter = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FHL: TPascalHighlighter;
    procedure CheckToken(ALine, AIndex: Integer; AExpCol, AExpLen: Integer;
      AExpCat: THighlightCategory; const AContext: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Basic token positioning }
    procedure TestKeywordUnit;
    procedure TestKeywordAndIdentifier;
    procedure TestKeywordBeginEnd;

    { Numbers }
    procedure TestDecimalNumber;
    procedure TestHexNumber;

    { Strings }
    procedure TestSimpleString;

    { Comments }
    procedure TestLineComment;
    procedure TestBraceComment;
    procedure TestParenStarComment;

    { Directives }
    procedure TestBraceDirective;
    procedure TestModeDirective;

    { Multi-line comments }
    procedure TestMultiLineBraceComment;

    { Combined: unit header }
    procedure TestUnitHeader;

    { Line count }
    procedure TestLineCount;

    { Empty input }
    procedure TestEmptyInput;

    { Scanner error resilience }
    procedure TestIncompleteSource;

    { Trailing line comments }
    procedure TestTrailingLineComment;
    procedure TestLineCommentAfterCode;

    { Include directives }
    procedure TestIncludeDirectiveContinues;

    { Conditional compilation directives }
    procedure TestIfdefDirective;
    procedure TestIfdefSkippedContent;

    { Modifier/directive keywords (hcKeyword2) }
    procedure TestVisibilityModifiers;
    procedure TestMethodModifiers;
    procedure TestCallingConventions;
    procedure TestModifierMixedWithKeyword;
  end;


  { TTestHighlighterTStrings - the Tokenise(TStrings) overload must behave
    identically to the Tokenise(string) path (GitHub issue #187) }

  TTestHighlighterTStrings = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FHL: TPascalHighlighter;
    FRef: TPascalHighlighter;
    FList: TStringList;
    procedure AssertSameTokens(const AContext: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Single-line source produces identical tokens via both entry points }
    procedure TestSingleLineMatchesStringPath;
    { Multi-line source produces identical tokens via both entry points }
    procedure TestMultiLineMatchesStringPath;
    { Multi-line brace comment survives the TStrings path }
    procedure TestMultiLineCommentMatchesStringPath;
    { An empty list clears all previous token state }
    procedure TestEmptyListClearsState;
  end;


procedure RegisteridetesthighlighterTests(ARegistry: TNXTestRegistry);

implementation

{ TTestPascalHighlighter }

procedure TTestPascalHighlighter.SetUp;
begin
  FHL := TPascalHighlighter.Create;
end;

procedure TTestPascalHighlighter.TearDown;
begin
  FHL.Free;
end;

procedure TTestPascalHighlighter.CheckToken(ALine, AIndex: Integer;
  AExpCol, AExpLen: Integer; AExpCat: THighlightCategory;
  const AContext: string);
var
  tokens: THighlightTokenArray;
  tok: THighlightToken;
  catNames: array[THighlightCategory] of string = (
    'hcWhitespace', 'hcKeyword1', 'hcKeyword2', 'hcKeyword3',
    'hcIdentifier', 'hcString1', 'hcString2', 'hcNumber',
    'hcComment1', 'hcComment2', 'hcDirective', 'hcSymbol',
    'hcOperator', 'hcFunction', 'hcLabel', 'hcMarkup', 'hcInvalid');
begin
  tokens := FHL.GetLineTokens(ALine);
  FContext.AssertTrue(tokens <> nil, Format('%s: line %d has no tokens', [AContext, ALine]));
  FContext.AssertTrue(AIndex < Length(tokens), Format('%s: line %d token index %d out of range (count=%d)',
    [AContext, ALine, AIndex, Length(tokens)]));
  tok := tokens[AIndex];
  FContext.AssertTrue((AExpCol)=(tok.Column), Format('%s: line %d token %d Column', [AContext, ALine, AIndex]));
  FContext.AssertTrue((AExpLen)=(tok.Length), Format('%s: line %d token %d Length', [AContext, ALine, AIndex]));
  FContext.AssertTrue(AExpCat = tok.Category, Format('%s: line %d token %d Category expected %s got %s',
    [AContext, ALine, AIndex, catNames[AExpCat], catNames[tok.Category]]));
end;

procedure TTestPascalHighlighter.TestKeywordUnit;
begin
  { "unit foo;" -> keyword "unit" at col 0, len 4 }
  FHL.Tokenise('unit foo;');
  CheckToken(0, 0, 0, 4, hcKeyword1, 'unit keyword');
  CheckToken(0, 1, 5, 3, hcIdentifier, 'unit name');
  CheckToken(0, 2, 8, 1, hcSymbol, 'semicolon');
end;

procedure TTestPascalHighlighter.TestKeywordAndIdentifier;
begin
  { "var x: Integer;" }
  FHL.Tokenise('var x: Integer;');
  CheckToken(0, 0, 0, 3, hcKeyword1, 'var keyword');
  CheckToken(0, 1, 4, 1, hcIdentifier, 'x identifier');
  CheckToken(0, 2, 5, 1, hcSymbol, 'colon');
  CheckToken(0, 3, 7, 7, hcIdentifier, 'Integer identifier');
  CheckToken(0, 4, 14, 1, hcSymbol, 'semicolon');
end;

procedure TTestPascalHighlighter.TestKeywordBeginEnd;
begin
  FHL.Tokenise('begin' + LineEnding + 'end.');
  CheckToken(0, 0, 0, 5, hcKeyword1, 'begin');
  CheckToken(1, 0, 0, 3, hcKeyword1, 'end');
  CheckToken(1, 1, 3, 1, hcSymbol, 'dot');
end;

procedure TTestPascalHighlighter.TestDecimalNumber;
begin
  FHL.Tokenise('x := 42;');
  CheckToken(0, 2, 5, 2, hcNumber, 'decimal 42');
end;

procedure TTestPascalHighlighter.TestHexNumber;
begin
  FHL.Tokenise('x := $FF;');
  CheckToken(0, 2, 5, 3, hcNumber, 'hex $FF');
end;

procedure TTestPascalHighlighter.TestSimpleString;
begin
  { 'hello' -> string token including quotes }
  FHL.Tokenise('s := ''hello'';');
  CheckToken(0, 2, 5, 7, hcString1, 'string literal');
end;

procedure TTestPascalHighlighter.TestLineComment;
begin
  { "// comment" -> comment starting at col 0, length 10 }
  FHL.Tokenise('// comment');
  CheckToken(0, 0, 0, 10, hcComment1, 'line comment');
end;

procedure TTestPascalHighlighter.TestBraceComment;
begin
  (* "{ comment }" -> comment at col 0, length 11 including braces *)
  FHL.Tokenise('{ comment }');
  CheckToken(0, 0, 0, 11, hcComment1, 'brace comment');
end;

procedure TTestPascalHighlighter.TestParenStarComment;
begin
  { "(* comment *)" -> comment at col 0, length 14 }
  { (* comment *) is 13 characters: ( * space c o m m e n t space * ) }
  FHL.Tokenise('(* comment *)');
  CheckToken(0, 0, 0, 13, hcComment1, 'paren-star comment');
end;

procedure TTestPascalHighlighter.TestBraceDirective;
begin
  (* "{$mode objfpc}" -> directive at col 0, length 14 *)
  FHL.Tokenise('{$mode objfpc}');
  CheckToken(0, 0, 0, 14, hcDirective, 'brace directive');
end;

procedure TTestPascalHighlighter.TestModeDirective;
begin
  (* Two directives on one line: "{$mode objfpc}{$H+}" *)
  FHL.Tokenise('{$mode objfpc}{$H+}');
  CheckToken(0, 0, 0, 14, hcDirective, 'first directive');
  CheckToken(0, 1, 14, 5, hcDirective, 'second directive');
end;

procedure TTestPascalHighlighter.TestMultiLineBraceComment;
var
  src: string;
begin
  { A brace comment spanning 3 lines }
  src := '{ line one' + LineEnding +
         '  line two' + LineEnding +
         '  line three }';
  FHL.Tokenise(src);
  { First line }
  FContext.AssertTrue(FHL.GetLineTokenCount(0) > 0, 'line 0 has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(0)[0].Category = hcComment1, 'line 0 is comment');
  { Middle line }
  FContext.AssertTrue(FHL.GetLineTokenCount(1) > 0, 'line 1 has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(1)[0].Category = hcComment1, 'line 1 is comment');
  { Last line }
  FContext.AssertTrue(FHL.GetLineTokenCount(2) > 0, 'line 2 has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(2)[0].Category = hcComment1, 'line 2 is comment');
end;

procedure TTestPascalHighlighter.TestUnitHeader;
begin
  { "unit MyUnit;" on one line }
  FHL.Tokenise('unit MyUnit;');
  FContext.AssertTrue((3)=(FHL.GetLineTokenCount(0)), 'token count');
  CheckToken(0, 0, 0, 4, hcKeyword1, 'unit keyword');
  CheckToken(0, 1, 5, 6, hcIdentifier, 'MyUnit');
  CheckToken(0, 2, 11, 1, hcSymbol, 'semicolon');
end;

procedure TTestPascalHighlighter.TestLineCount;
begin
  FHL.Tokenise('a' + LineEnding + 'b' + LineEnding + 'c');
  FContext.AssertTrue(FHL.LineCount >= 3, 'at least 3 lines');
end;

procedure TTestPascalHighlighter.TestEmptyInput;
begin
  FHL.Tokenise('');
  FContext.AssertTrue((0)=(FHL.LineCount), 'no lines');
end;

procedure TTestPascalHighlighter.TestIncompleteSource;
begin
  { Unclosed string — scanner should error but not crash.
    We should get at least partial tokens. }
  FHL.Tokenise('x := ''unclosed');
  { Should not raise, and should have some tokens for "x" and ":=" }
  FContext.AssertTrue(FHL.GetLineTokenCount(0) > 0, 'has some tokens');
end;

procedure TTestPascalHighlighter.TestTrailingLineComment;
begin
  { "x := 1; // a comment" — the // comment trails code }
  FHL.Tokenise('x := 1; // a comment');
  { Find the comment token — should cover "// a comment" = 12 chars }
  CheckToken(0, 4, 8, 12, hcComment1, 'trailing line comment');
end;

procedure TTestPascalHighlighter.TestLineCommentAfterCode;
var
  tokens: THighlightTokenArray;
  i: Integer;
  found: Boolean;
begin
  { "syncobjs, // TCriticalSection usage" }
  FHL.Tokenise('syncobjs, // TCriticalSection usage');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue(tokens <> nil, 'has tokens');
  { Find a comment token on this line }
  found := False;
  for i := 0 to Length(tokens) - 1 do
    if tokens[i].Category = hcComment1 then
    begin
      found := True;
      FContext.AssertTrue((10)=(tokens[i].Column), 'comment col');
      FContext.AssertTrue((25)=(tokens[i].Length), 'comment len');
      Break;
    end;
  FContext.AssertTrue(found, 'comment token found');
end;

procedure TTestPascalHighlighter.TestIncludeDirectiveContinues;
var
  src: string;
begin
  { Include directive should not stop tokenisation.
    Code after the include must still be highlighted. }
  src := '{$I somefile.inc}' + LineEnding +
         '// comment after include';
  FHL.Tokenise(src);
  { Line 0: the include directive }
  FContext.AssertTrue(FHL.GetLineTokenCount(0) > 0, 'include line has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(0)[0].Category = hcDirective, 'include is directive');
  { Line 1: code after include must be tokenised }
  FContext.AssertTrue(FHL.GetLineTokenCount(1) > 0, 'line after include has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(1)[0].Category = hcComment1, 'comment after include');
end;

procedure TTestPascalHighlighter.TestIfdefDirective;
var
  src: string;
begin
  { IFDEF with undefined symbol - the directive itself must still
     be classified as hcDirective, not hcComment1 }
  src := '{$IFDEF UNDEFINED_SYM}' + LineEnding +
         'x := 1;' + LineEnding +
         '{$ENDIF}';
  FHL.Tokenise(src);
  { Line 0: the IFDEF directive }
  FContext.AssertTrue(FHL.GetLineTokenCount(0) > 0, 'IFDEF line has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(0)[0].Category = hcDirective, 'IFDEF is directive');
  { Line 2: the ENDIF directive }
  FContext.AssertTrue(FHL.GetLineTokenCount(2) > 0, 'ENDIF line has tokens');
  FContext.AssertTrue(FHL.GetLineTokens(2)[0].Category = hcDirective, 'ENDIF is directive');
end;

procedure TTestPascalHighlighter.TestIfdefSkippedContent;
var
  src: string;
  tokens: THighlightTokenArray;
begin
  (* Content between false IFDEF and ENDIF is skipped by the scanner.
     Verify we still get the directive tokens. *)
  src := '{$IFDEF NOSYMBOL}' + LineEnding +
         'writeln(''skipped'');' + LineEnding +
         '{$ENDIF}';
  FHL.Tokenise(src);
  { IFDEF on line 0 }
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue(tokens <> nil, 'IFDEF token exists');
  FContext.AssertTrue((0)=(tokens[0].Column), 'IFDEF col');
  FContext.AssertTrue(tokens[0].Category = hcDirective, 'IFDEF category');
  { ENDIF on line 2 }
  tokens := FHL.GetLineTokens(2);
  FContext.AssertTrue(tokens <> nil, 'ENDIF token exists');
  FContext.AssertTrue(tokens[0].Category = hcDirective, 'ENDIF category');
end;

procedure TTestPascalHighlighter.TestVisibilityModifiers;
begin
  { private, protected, public, published — visibility sections }
  FHL.Tokenise('private');
  CheckToken(0, 0, 0, 7, hcKeyword2, 'private modifier');

  FHL.Tokenise('protected');
  CheckToken(0, 0, 0, 9, hcKeyword2, 'protected modifier');

  FHL.Tokenise('public');
  CheckToken(0, 0, 0, 6, hcKeyword2, 'public modifier');

  FHL.Tokenise('published');
  CheckToken(0, 0, 0, 9, hcKeyword2, 'published modifier');

  FHL.Tokenise('strict');
  CheckToken(0, 0, 0, 6, hcKeyword2, 'strict modifier');
end;

procedure TTestPascalHighlighter.TestMethodModifiers;
begin
  { override, virtual, abstract, final, dynamic }
  FHL.Tokenise('override');
  CheckToken(0, 0, 0, 8, hcKeyword2, 'override modifier');

  FHL.Tokenise('virtual');
  CheckToken(0, 0, 0, 7, hcKeyword2, 'virtual modifier');

  FHL.Tokenise('abstract');
  CheckToken(0, 0, 0, 8, hcKeyword2, 'abstract modifier');

  FHL.Tokenise('final');
  CheckToken(0, 0, 0, 5, hcKeyword2, 'final modifier');

  FHL.Tokenise('dynamic');
  CheckToken(0, 0, 0, 7, hcKeyword2, 'dynamic modifier');

  FHL.Tokenise('reintroduce');
  CheckToken(0, 0, 0, 11, hcKeyword2, 'reintroduce modifier');

  FHL.Tokenise('overload');
  CheckToken(0, 0, 0, 8, hcKeyword2, 'overload modifier');
end;

procedure TTestPascalHighlighter.TestCallingConventions;
begin
  FHL.Tokenise('stdcall');
  CheckToken(0, 0, 0, 7, hcKeyword2, 'stdcall modifier');

  FHL.Tokenise('cdecl');
  CheckToken(0, 0, 0, 5, hcKeyword2, 'cdecl modifier');

  FHL.Tokenise('register');
  CheckToken(0, 0, 0, 8, hcKeyword2, 'register modifier');

  FHL.Tokenise('safecall');
  CheckToken(0, 0, 0, 8, hcKeyword2, 'safecall modifier');
end;

procedure TTestPascalHighlighter.TestModifierMixedWithKeyword;
var
  tokens: THighlightTokenArray;
  i: Integer;
  foundVirtual, foundOverride: Boolean;
begin
  { "procedure Foo; virtual; override;" — mix of keyword and modifiers.
    Token sequence (whitespace skipped): procedure Foo ; virtual ; override ;
    Indices:                              0         1   2 3       4 5        6 }
  FHL.Tokenise('procedure Foo; virtual; override;');
  tokens := FHL.GetLineTokens(0);
  FContext.AssertTrue(Length(tokens) >= 7, 'has tokens');
  FContext.AssertTrue((Ord(hcKeyword1))=(Ord(tokens[0].Category)), 'procedure is keyword1');
  FContext.AssertTrue((15)=(tokens[3].Column), 'virtual col');
  FContext.AssertTrue((Ord(hcKeyword2))=(Ord(tokens[3].Category)), 'virtual cat');
  FContext.AssertTrue((24)=(tokens[5].Column), 'override col');
  FContext.AssertTrue((Ord(hcKeyword2))=(Ord(tokens[5].Category)), 'override cat');
  { Also verify no modifier was misclassified as keyword1 }
  foundVirtual  := False;
  foundOverride := False;
  for i := 0 to High(tokens) do
  begin
    if tokens[i].Column = 15 then foundVirtual  := tokens[i].Category = hcKeyword2;
    if tokens[i].Column = 24 then foundOverride := tokens[i].Category = hcKeyword2;
  end;
  FContext.AssertTrue(foundVirtual, 'virtual is hcKeyword2');
  FContext.AssertTrue(foundOverride, 'override is hcKeyword2');
end;

{ TTestHighlighterTStrings }

procedure TTestHighlighterTStrings.SetUp;
begin
  FHL := TPascalHighlighter.Create;
  FRef := TPascalHighlighter.Create;
  FList := TStringList.Create;
end;

procedure TTestHighlighterTStrings.TearDown;
begin
  FList.Free;
  FRef.Free;
  FHL.Free;
end;

procedure TTestHighlighterTStrings.AssertSameTokens(const AContext: string);
var
  line, i: Integer;
  a, b: THighlightTokenArray;
begin
  { FRef holds the reference result from Tokenise(string);
    FHL holds the result from Tokenise(TStrings) }
  FContext.AssertTrue((FRef.LineCount)=(FHL.LineCount), AContext + ': line count');
  for line := 0 to FRef.LineCount - 1 do
  begin
    a := FRef.GetLineTokens(line);
    b := FHL.GetLineTokens(line);
    FContext.AssertTrue((Length(a))=(Length(b)), Format('%s: line %d token count', [AContext, line]));
    for i := 0 to Length(a) - 1 do
    begin
      FContext.AssertTrue((a[i].Column)=(b[i].Column), Format('%s: line %d token %d Column', [AContext, line, i]));
      FContext.AssertTrue((a[i].Length)=(b[i].Length), Format('%s: line %d token %d Length', [AContext, line, i]));
      FContext.AssertTrue(a[i].Category = b[i].Category, Format('%s: line %d token %d Category', [AContext, line, i]));
    end;
  end;
end;

procedure TTestHighlighterTStrings.TestSingleLineMatchesStringPath;
begin
  FList.Add('unit foo;');
  FRef.Tokenise(FList.Text);
  FHL.Tokenise(FList);
  AssertSameTokens('single line');
end;

procedure TTestHighlighterTStrings.TestMultiLineMatchesStringPath;
begin
  FList.Add('unit foo;');
  FList.Add('interface');
  FList.Add('var x: Integer; // trailing comment');
  FList.Add('implementation');
  FList.Add('end.');
  FRef.Tokenise(FList.Text);
  FHL.Tokenise(FList);
  AssertSameTokens('multi line');
end;

procedure TTestHighlighterTStrings.TestMultiLineCommentMatchesStringPath;
begin
  FList.Add('{ line one');
  FList.Add('  line two');
  FList.Add('  line three }');
  FList.Add('begin end.');
  FRef.Tokenise(FList.Text);
  FHL.Tokenise(FList);
  AssertSameTokens('multi-line comment');
end;

procedure TTestHighlighterTStrings.TestEmptyListClearsState;
begin
  FHL.Tokenise('unit foo;');
  FContext.AssertTrue(FHL.LineCount > 0, 'has state before');
  FHL.Tokenise(FList);
  FContext.AssertTrue((0)=(FHL.LineCount), 'state cleared');
end;



procedure RunTTestPascalHighlighterTestKeywordUnit(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeywordUnit';
    lFixture.SetUp;
    try lFixture.TestKeywordUnit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestKeywordAndIdentifier(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeywordAndIdentifier';
    lFixture.SetUp;
    try lFixture.TestKeywordAndIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestKeywordBeginEnd(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeywordBeginEnd';
    lFixture.SetUp;
    try lFixture.TestKeywordBeginEnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestDecimalNumber(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDecimalNumber';
    lFixture.SetUp;
    try lFixture.TestDecimalNumber; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestHexNumber(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHexNumber';
    lFixture.SetUp;
    try lFixture.TestHexNumber; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestSimpleString(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleString';
    lFixture.SetUp;
    try lFixture.TestSimpleString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestLineComment(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineComment';
    lFixture.SetUp;
    try lFixture.TestLineComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestBraceComment(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBraceComment';
    lFixture.SetUp;
    try lFixture.TestBraceComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestParenStarComment(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParenStarComment';
    lFixture.SetUp;
    try lFixture.TestParenStarComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestBraceDirective(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBraceDirective';
    lFixture.SetUp;
    try lFixture.TestBraceDirective; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestModeDirective(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModeDirective';
    lFixture.SetUp;
    try lFixture.TestModeDirective; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestMultiLineBraceComment(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultiLineBraceComment';
    lFixture.SetUp;
    try lFixture.TestMultiLineBraceComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestUnitHeader(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUnitHeader';
    lFixture.SetUp;
    try lFixture.TestUnitHeader; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestLineCount(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineCount';
    lFixture.SetUp;
    try lFixture.TestLineCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestEmptyInput(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyInput';
    lFixture.SetUp;
    try lFixture.TestEmptyInput; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestIncompleteSource(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncompleteSource';
    lFixture.SetUp;
    try lFixture.TestIncompleteSource; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestTrailingLineComment(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrailingLineComment';
    lFixture.SetUp;
    try lFixture.TestTrailingLineComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestLineCommentAfterCode(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineCommentAfterCode';
    lFixture.SetUp;
    try lFixture.TestLineCommentAfterCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestIncludeDirectiveContinues(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncludeDirectiveContinues';
    lFixture.SetUp;
    try lFixture.TestIncludeDirectiveContinues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestIfdefDirective(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIfdefDirective';
    lFixture.SetUp;
    try lFixture.TestIfdefDirective; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestIfdefSkippedContent(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIfdefSkippedContent';
    lFixture.SetUp;
    try lFixture.TestIfdefSkippedContent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestVisibilityModifiers(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestVisibilityModifiers';
    lFixture.SetUp;
    try lFixture.TestVisibilityModifiers; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestMethodModifiers(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMethodModifiers';
    lFixture.SetUp;
    try lFixture.TestMethodModifiers; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestCallingConventions(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCallingConventions';
    lFixture.SetUp;
    try lFixture.TestCallingConventions; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalHighlighterTestModifierMixedWithKeyword(AContext: TNXTestContext);
var lFixture: TTestPascalHighlighter;
begin
  lFixture:=TTestPascalHighlighter.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifierMixedWithKeyword';
    lFixture.SetUp;
    try lFixture.TestModifierMixedWithKeyword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterTStringsTestSingleLineMatchesStringPath(AContext: TNXTestContext);
var lFixture: TTestHighlighterTStrings;
begin
  lFixture:=TTestHighlighterTStrings.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleLineMatchesStringPath';
    lFixture.SetUp;
    try lFixture.TestSingleLineMatchesStringPath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterTStringsTestMultiLineMatchesStringPath(AContext: TNXTestContext);
var lFixture: TTestHighlighterTStrings;
begin
  lFixture:=TTestHighlighterTStrings.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultiLineMatchesStringPath';
    lFixture.SetUp;
    try lFixture.TestMultiLineMatchesStringPath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterTStringsTestMultiLineCommentMatchesStringPath(AContext: TNXTestContext);
var lFixture: TTestHighlighterTStrings;
begin
  lFixture:=TTestHighlighterTStrings.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultiLineCommentMatchesStringPath';
    lFixture.SetUp;
    try lFixture.TestMultiLineCommentMatchesStringPath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterTStringsTestEmptyListClearsState(AContext: TNXTestContext);
var lFixture: TTestHighlighterTStrings;
begin
  lFixture:=TTestHighlighterTStrings.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyListClearsState';
    lFixture.SetUp;
    try lFixture.TestEmptyListClearsState; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetesthighlighterTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.highlighter.TTestPascalHighlighter');
  lSuite.AddTest('TestKeywordUnit', @RunTTestPascalHighlighterTestKeywordUnit);
  lSuite.AddTest('TestKeywordAndIdentifier', @RunTTestPascalHighlighterTestKeywordAndIdentifier);
  lSuite.AddTest('TestKeywordBeginEnd', @RunTTestPascalHighlighterTestKeywordBeginEnd);
  lSuite.AddTest('TestDecimalNumber', @RunTTestPascalHighlighterTestDecimalNumber);
  lSuite.AddTest('TestHexNumber', @RunTTestPascalHighlighterTestHexNumber);
  lSuite.AddTest('TestSimpleString', @RunTTestPascalHighlighterTestSimpleString);
  lSuite.AddTest('TestLineComment', @RunTTestPascalHighlighterTestLineComment);
  lSuite.AddTest('TestBraceComment', @RunTTestPascalHighlighterTestBraceComment);
  lSuite.AddTest('TestParenStarComment', @RunTTestPascalHighlighterTestParenStarComment);
  lSuite.AddTest('TestBraceDirective', @RunTTestPascalHighlighterTestBraceDirective);
  lSuite.AddTest('TestModeDirective', @RunTTestPascalHighlighterTestModeDirective);
  lSuite.AddTest('TestMultiLineBraceComment', @RunTTestPascalHighlighterTestMultiLineBraceComment);
  lSuite.AddTest('TestUnitHeader', @RunTTestPascalHighlighterTestUnitHeader);
  lSuite.AddTest('TestLineCount', @RunTTestPascalHighlighterTestLineCount);
  lSuite.AddTest('TestEmptyInput', @RunTTestPascalHighlighterTestEmptyInput);
  lSuite.AddTest('TestIncompleteSource', @RunTTestPascalHighlighterTestIncompleteSource);
  lSuite.AddTest('TestTrailingLineComment', @RunTTestPascalHighlighterTestTrailingLineComment);
  lSuite.AddTest('TestLineCommentAfterCode', @RunTTestPascalHighlighterTestLineCommentAfterCode);
  lSuite.AddTest('TestIncludeDirectiveContinues', @RunTTestPascalHighlighterTestIncludeDirectiveContinues);
  lSuite.AddTest('TestIfdefDirective', @RunTTestPascalHighlighterTestIfdefDirective);
  lSuite.AddTest('TestIfdefSkippedContent', @RunTTestPascalHighlighterTestIfdefSkippedContent);
  lSuite.AddTest('TestVisibilityModifiers', @RunTTestPascalHighlighterTestVisibilityModifiers);
  lSuite.AddTest('TestMethodModifiers', @RunTTestPascalHighlighterTestMethodModifiers);
  lSuite.AddTest('TestCallingConventions', @RunTTestPascalHighlighterTestCallingConventions);
  lSuite.AddTest('TestModifierMixedWithKeyword', @RunTTestPascalHighlighterTestModifierMixedWithKeyword);
  lSuite:=ARegistry.AddSuite('ide.test.highlighter.TTestHighlighterTStrings');
  lSuite.AddTest('TestSingleLineMatchesStringPath', @RunTTestHighlighterTStringsTestSingleLineMatchesStringPath);
  lSuite.AddTest('TestMultiLineMatchesStringPath', @RunTTestHighlighterTStringsTestMultiLineMatchesStringPath);
  lSuite.AddTest('TestMultiLineCommentMatchesStringPath', @RunTTestHighlighterTStringsTestMultiLineCommentMatchesStringPath);
  lSuite.AddTest('TestEmptyListClearsState', @RunTTestHighlighterTStringsTestEmptyListClearsState);
end;

end.

{
    fpGUI IDE - Highlight Renderer Tests

    Tests for BuildRenderSegments and related functions in
    ide.highlight.renderer. These tests verify that token-based rendering
    produces correct segment data (colours, positions, gap filling) without
    requiring a canvas or widget.
}
unit ide.test.highlight.renderer;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  ide.highlighter,
  ide.editor.theme,
  ide.bracketmatch,
  ide.highlight.renderer;

type

  { TTestBuildRenderSegments }

  TTestBuildRenderSegments = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FHL: TPascalHighlighter;
    FTheme: TEditorTheme;
    FNoMatch: TBracketMatchResult;
    procedure SetupSource(const ASource: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestEmptyLine;
    procedure TestNilTokensDrawsPlain;
    procedure TestSingleKeyword;
    procedure TestGapBeforeToken;
    procedure TestMultipleTokens;
    procedure TestBracketMatchHighlight;
    procedure TestBracketMatchOnMatchLine;
    procedure TestNoBracketMatchWhenDisabled;
    procedure TestTokenStyleForegroundFallback;
    procedure TestTokenStyleBackgroundFallback;
  end;

  { TTestBuildPatchSegments }

  TTestBuildPatchSegments = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FTheme: TEditorTheme;
  protected
    procedure SetUp; virtual;
  public
    procedure TestAddedLine;
    procedure TestRemovedLine;
    procedure TestHunkHeader;
    procedure TestLeftFile;
    procedure TestRightFile;
    procedure TestStartOfFile;
    procedure TestPlainLine;
  end;

  { TTestHighlighterCache }

  TTestHighlighterCache = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestCreateDestroy;
    procedure TestInvalidateEditor;
  end;

procedure RegisteridetesthighlightrendererTests(ARegistry: TNXTestRegistry);

implementation

{ TTestBuildRenderSegments }

procedure TTestBuildRenderSegments.SetupSource(const ASource: string);
begin
  FHL.Tokenise(ASource);
end;

procedure TTestBuildRenderSegments.SetUp;
begin
  FHL := TPascalHighlighter.Create;
  FTheme := DefaultTheme;
  FNoMatch.Found := False;
end;

procedure TTestBuildRenderSegments.TearDown;
begin
  FHL.Free;
end;

procedure TTestBuildRenderSegments.TestEmptyLine;
var
  segs: TRenderSegmentArray;
begin
  SetupSource('');
  segs := BuildRenderSegments(FHL, '', 0, FTheme, FNoMatch, False);
  TestContext.AssertTrue((0)=(Length(segs)), 'empty line should produce no segments');
end;

procedure TTestBuildRenderSegments.TestNilTokensDrawsPlain;
var
  segs: TRenderSegmentArray;
begin
  { Line index beyond what was tokenised — GetLineTokens returns nil }
  SetupSource('program test;');
  segs := BuildRenderSegments(FHL, 'some text', 999, FTheme, FNoMatch, False);
  { Should return a single plain-text segment }
  TestContext.AssertTrue((1)=(Length(segs)), 'nil tokens should produce one plain segment');
  TestContext.AssertTrue((0)=(segs[0].Column), 'plain segment column');
  TestContext.AssertTrue(('some text')=(segs[0].Text), 'plain segment text');
  TestContext.AssertTrue(segs[0].Foreground = FTheme.Chrome.Foreground, 'plain segment uses default foreground');
  TestContext.AssertTrue(segs[0].Background = FTheme.Chrome.Background, 'plain segment uses default background');
end;

procedure TTestBuildRenderSegments.TestSingleKeyword;
var
  segs: TRenderSegmentArray;
  i: Integer;
  foundKw: Boolean;
begin
  SetupSource('begin' + LineEnding + 'end.');
  segs := BuildRenderSegments(FHL, 'begin', 0, FTheme, FNoMatch, False);
  TestContext.AssertTrue(Length(segs) > 0, 'should have at least one segment');
  { Find the keyword segment }
  foundKw := False;
  for i := 0 to High(segs) do
    if segs[i].Text = 'begin' then
    begin
      foundKw := True;
      TestContext.AssertTrue(segs[i].Foreground = FTheme.TokenStyles[hcKeyword1].Foreground, 'keyword should use keyword1 foreground');
    end;
  TestContext.AssertTrue(foundKw, 'should contain a begin keyword segment');
end;

procedure TTestBuildRenderSegments.TestGapBeforeToken;
var
  segs: TRenderSegmentArray;
begin
  { "  begin" — two spaces gap before keyword }
  SetupSource('  begin' + LineEnding + '  end.');
  segs := BuildRenderSegments(FHL, '  begin', 0, FTheme, FNoMatch, False);
  TestContext.AssertTrue(Length(segs) > 0, 'should have segments');
  { First segment should be the gap (spaces) at column 0 }
  TestContext.AssertTrue((0)=(segs[0].Column), 'first segment should start at column 0');
  TestContext.AssertTrue(('  ')=(segs[0].Text), 'gap text should be two spaces');
end;

procedure TTestBuildRenderSegments.TestMultipleTokens;
var
  segs: TRenderSegmentArray;
begin
  SetupSource('var x: integer;');
  segs := BuildRenderSegments(FHL, 'var x: integer;', 0, FTheme, FNoMatch, False);
  TestContext.AssertTrue(Length(segs) > 2, 'should have multiple segments');
end;

procedure TTestBuildRenderSegments.TestBracketMatchHighlight;
var
  segs: TRenderSegmentArray;
  match: TBracketMatchResult;
  i: Integer;
  foundHighlight: Boolean;
begin
  SetupSource('(x)');
  { Simulate bracket match at source column 0, match column 2 }
  match.Found := True;
  match.SourceLine := 0;
  match.SourceCol := 0;
  match.SourceLength := 1;
  match.MatchLine := 0;
  match.MatchCol := 2;
  match.MatchLength := 1;
  segs := BuildRenderSegments(FHL, '(x)', 0, FTheme, match, True);
  { Find a segment at column 0 with bracket match background }
  foundHighlight := False;
  for i := 0 to High(segs) do
    if (segs[i].Column = 0) and (segs[i].Background = FTheme.Chrome.BracketMatch) then
      foundHighlight := True;
  TestContext.AssertTrue(foundHighlight, 'source bracket should have BracketMatch background');
end;

procedure TTestBuildRenderSegments.TestBracketMatchOnMatchLine;
var
  segs: TRenderSegmentArray;
  match: TBracketMatchResult;
  i: Integer;
  foundHighlight: Boolean;
begin
  SetupSource('(x)');
  match.Found := True;
  match.SourceLine := 0;
  match.SourceCol := 0;
  match.SourceLength := 1;
  match.MatchLine := 0;
  match.MatchCol := 2;
  match.MatchLength := 1;
  segs := BuildRenderSegments(FHL, '(x)', 0, FTheme, match, True);
  { Find a segment at column 2 with bracket match background }
  foundHighlight := False;
  for i := 0 to High(segs) do
    if (segs[i].Column = 2) and (segs[i].Background = FTheme.Chrome.BracketMatch) then
      foundHighlight := True;
  TestContext.AssertTrue(foundHighlight, 'match bracket should have BracketMatch background');
end;

procedure TTestBuildRenderSegments.TestNoBracketMatchWhenDisabled;
var
  segs: TRenderSegmentArray;
  match: TBracketMatchResult;
  i: Integer;
begin
  SetupSource('(x)');
  match.Found := True;
  match.SourceLine := 0;
  match.SourceCol := 0;
  match.SourceLength := 1;
  match.MatchLine := 0;
  match.MatchCol := 2;
  match.MatchLength := 1;
  { Pass AShowBracketMatch = False }
  segs := BuildRenderSegments(FHL, '(x)', 0, FTheme, match, False);
  for i := 0 to High(segs) do
    TestContext.AssertTrue(not (segs[i].Background = FTheme.Chrome.BracketMatch), 'no segment should have BracketMatch bg when disabled');
end;

procedure TTestBuildRenderSegments.TestTokenStyleForegroundFallback;
var
  segs: TRenderSegmentArray;
  i: Integer;
begin
  { Whitespace category has clNone foreground — should fall back to Chrome.Foreground }
  FTheme.TokenStyles[hcWhitespace].Foreground := clNone;
  SetupSource('  begin' + LineEnding + '  end.');
  segs := BuildRenderSegments(FHL, '  begin', 0, FTheme, FNoMatch, False);
  { The gap/whitespace segment should use Chrome.Foreground }
  for i := 0 to High(segs) do
    TestContext.AssertTrue(not (segs[i].Foreground = clNone), 'no segment should have clNone foreground');
end;

procedure TTestBuildRenderSegments.TestTokenStyleBackgroundFallback;
var
  segs: TRenderSegmentArray;
  i: Integer;
begin
  SetupSource('begin' + LineEnding + 'end.');
  segs := BuildRenderSegments(FHL, 'begin', 0, FTheme, FNoMatch, False);
  for i := 0 to High(segs) do
    TestContext.AssertTrue(not (segs[i].Background = clNone), 'no segment should have clNone background');
end;

{ TTestBuildPatchSegments }

procedure TTestBuildPatchSegments.SetUp;
begin
  FTheme := DefaultTheme;
end;

procedure TTestBuildPatchSegments.TestAddedLine;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('+added line', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Foreground = clGreen, 'added line should be green');
end;

procedure TTestBuildPatchSegments.TestRemovedLine;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('-removed line', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Foreground = clRed, 'removed line should be red');
end;

procedure TTestBuildPatchSegments.TestHunkHeader;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('@@ -1,5 +1,6 @@', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Foreground = clBlue, 'hunk header should be blue');
end;

procedure TTestBuildPatchSegments.TestLeftFile;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('--- a/file.pas', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Foreground = clMagenta, 'left file should be magenta');
end;

procedure TTestBuildPatchSegments.TestRightFile;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('+++ b/file.pas', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Foreground = clMagenta, 'right file should be magenta');
end;

procedure TTestBuildPatchSegments.TestStartOfFile;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments('diff --git a/file.pas b/file.pas', FTheme);
  TestContext.AssertTrue(Length(segs) > 0, 'should produce segments');
  TestContext.AssertTrue(segs[0].Background = clSilver, 'start-of-file background should be clSilver');
end;

procedure TTestBuildPatchSegments.TestPlainLine;
var
  segs: TRenderSegmentArray;
begin
  segs := BuildPatchRenderSegments(' context line', FTheme);
  TestContext.AssertTrue(Length(segs) = 1, 'should produce one segment');
  TestContext.AssertTrue(segs[0].Foreground = FTheme.Chrome.Foreground, 'plain line should use default foreground');
end;

{ TTestHighlighterCache }

procedure TTestHighlighterCache.TestCreateDestroy;
var
  cache: THighlighterCache;
begin
  cache := THighlighterCache.Create;
  try
    TestContext.AssertTrue((cache.PascalHighlighter)<>nil, 'Pascal highlighter should be created');
    TestContext.AssertTrue((cache.INIHighlighter)<>nil, 'INI highlighter should be created');
    TestContext.AssertTrue((cache.XMLHighlighter)<>nil, 'XML highlighter should be created');
  finally
    cache.Free;
  end;
end;

procedure TTestHighlighterCache.TestInvalidateEditor;
var
  cache: THighlighterCache;
begin
  cache := THighlighterCache.Create;
  try
    { Invalidate with nil should not crash }
    cache.InvalidateEditor(nil);
    { After invalidation, tracked editors should be nil }
    TestContext.AssertTrue((cache.PascalEditor)=nil, 'Pascal editor should be nil after invalidation');
    TestContext.AssertTrue((cache.INIEditor)=nil, 'INI editor should be nil after invalidation');
    TestContext.AssertTrue((cache.XMLEditor)=nil, 'XML editor should be nil after invalidation');
  finally
    cache.Free;
  end;
end;


constructor TTestBuildRenderSegments.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestBuildPatchSegments.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestHighlighterCache.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBuildRenderSegmentsTestEmptyLine(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestEmptyLine');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestNilTokensDrawsPlain(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestNilTokensDrawsPlain');
  try
    lFixture.SetUp;
    try lFixture.TestNilTokensDrawsPlain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestSingleKeyword(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestSingleKeyword');
  try
    lFixture.SetUp;
    try lFixture.TestSingleKeyword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestGapBeforeToken(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestGapBeforeToken');
  try
    lFixture.SetUp;
    try lFixture.TestGapBeforeToken; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestMultipleTokens(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestMultipleTokens');
  try
    lFixture.SetUp;
    try lFixture.TestMultipleTokens; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestBracketMatchHighlight(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestBracketMatchHighlight');
  try
    lFixture.SetUp;
    try lFixture.TestBracketMatchHighlight; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestBracketMatchOnMatchLine(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestBracketMatchOnMatchLine');
  try
    lFixture.SetUp;
    try lFixture.TestBracketMatchOnMatchLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestNoBracketMatchWhenDisabled(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestNoBracketMatchWhenDisabled');
  try
    lFixture.SetUp;
    try lFixture.TestNoBracketMatchWhenDisabled; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestTokenStyleForegroundFallback(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestTokenStyleForegroundFallback');
  try
    lFixture.SetUp;
    try lFixture.TestTokenStyleForegroundFallback; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildRenderSegmentsTestTokenStyleBackgroundFallback(AContext: TNXTestContext);
var lFixture: TTestBuildRenderSegments;
begin
  lFixture:=TTestBuildRenderSegments.Create(AContext, 'TestTokenStyleBackgroundFallback');
  try
    lFixture.SetUp;
    try lFixture.TestTokenStyleBackgroundFallback; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestAddedLine(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestAddedLine');
  try
    lFixture.SetUp;
    lFixture.TestAddedLine;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestRemovedLine(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestRemovedLine');
  try
    lFixture.SetUp;
    lFixture.TestRemovedLine;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestHunkHeader(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestHunkHeader');
  try
    lFixture.SetUp;
    lFixture.TestHunkHeader;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestLeftFile(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestLeftFile');
  try
    lFixture.SetUp;
    lFixture.TestLeftFile;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestRightFile(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestRightFile');
  try
    lFixture.SetUp;
    lFixture.TestRightFile;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestStartOfFile(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestStartOfFile');
  try
    lFixture.SetUp;
    lFixture.TestStartOfFile;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildPatchSegmentsTestPlainLine(AContext: TNXTestContext);
var lFixture: TTestBuildPatchSegments;
begin
  lFixture:=TTestBuildPatchSegments.Create(AContext, 'TestPlainLine');
  try
    lFixture.SetUp;
    lFixture.TestPlainLine;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterCacheTestCreateDestroy(AContext: TNXTestContext);
var lFixture: TTestHighlighterCache;
begin
  lFixture:=TTestHighlighterCache.Create(AContext, 'TestCreateDestroy');
  try
    lFixture.TestCreateDestroy;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlighterCacheTestInvalidateEditor(AContext: TNXTestContext);
var lFixture: TTestHighlighterCache;
begin
  lFixture:=TTestHighlighterCache.Create(AContext, 'TestInvalidateEditor');
  try
    lFixture.TestInvalidateEditor;
  finally lFixture.Free; end;
end;

procedure RegisteridetesthighlightrendererTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.highlight.renderer.TTestBuildRenderSegments');
  lSuite.AddTest('TestEmptyLine', @RunTTestBuildRenderSegmentsTestEmptyLine);
  lSuite.AddTest('TestNilTokensDrawsPlain', @RunTTestBuildRenderSegmentsTestNilTokensDrawsPlain);
  lSuite.AddTest('TestSingleKeyword', @RunTTestBuildRenderSegmentsTestSingleKeyword);
  lSuite.AddTest('TestGapBeforeToken', @RunTTestBuildRenderSegmentsTestGapBeforeToken);
  lSuite.AddTest('TestMultipleTokens', @RunTTestBuildRenderSegmentsTestMultipleTokens);
  lSuite.AddTest('TestBracketMatchHighlight', @RunTTestBuildRenderSegmentsTestBracketMatchHighlight);
  lSuite.AddTest('TestBracketMatchOnMatchLine', @RunTTestBuildRenderSegmentsTestBracketMatchOnMatchLine);
  lSuite.AddTest('TestNoBracketMatchWhenDisabled', @RunTTestBuildRenderSegmentsTestNoBracketMatchWhenDisabled);
  lSuite.AddTest('TestTokenStyleForegroundFallback', @RunTTestBuildRenderSegmentsTestTokenStyleForegroundFallback);
  lSuite.AddTest('TestTokenStyleBackgroundFallback', @RunTTestBuildRenderSegmentsTestTokenStyleBackgroundFallback);
  lSuite:=ARegistry.AddSuite('ide.test.highlight.renderer.TTestBuildPatchSegments');
  lSuite.AddTest('TestAddedLine', @RunTTestBuildPatchSegmentsTestAddedLine);
  lSuite.AddTest('TestRemovedLine', @RunTTestBuildPatchSegmentsTestRemovedLine);
  lSuite.AddTest('TestHunkHeader', @RunTTestBuildPatchSegmentsTestHunkHeader);
  lSuite.AddTest('TestLeftFile', @RunTTestBuildPatchSegmentsTestLeftFile);
  lSuite.AddTest('TestRightFile', @RunTTestBuildPatchSegmentsTestRightFile);
  lSuite.AddTest('TestStartOfFile', @RunTTestBuildPatchSegmentsTestStartOfFile);
  lSuite.AddTest('TestPlainLine', @RunTTestBuildPatchSegmentsTestPlainLine);
  lSuite:=ARegistry.AddSuite('ide.test.highlight.renderer.TTestHighlighterCache');
  lSuite.AddTest('TestCreateDestroy', @RunTTestHighlighterCacheTestCreateDestroy);
  lSuite.AddTest('TestInvalidateEditor', @RunTTestHighlighterCacheTestInvalidateEditor);
end;

end.

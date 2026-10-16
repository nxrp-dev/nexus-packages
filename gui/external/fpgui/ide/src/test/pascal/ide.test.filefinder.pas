{
    fpGUI IDE - File Finder Tests

    Tests for fuzzy file matching logic used by the
    Navigate to File dialog (Ctrl+Shift+N).
}
unit ide.test.filefinder;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.filefinder;

type

  { TTestFuzzyMatch }

  TTestFuzzyMatch = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    { Basic matching }
    procedure TestExactPrefixMatch;
    procedure TestSubstringMatch;
    procedure TestCamelCaseMatch;
    procedure TestCamelCaseMatchDotSeparated;
    procedure TestSubsequenceMatch;
    procedure TestNoMatch;
    procedure TestCaseInsensitive;
    procedure TestEmptyPatternMatchesAll;
    procedure TestExactMatchFullName;

    { Score ordering }
    procedure TestExactPrefixScoresHigherThanSubstring;
    procedure TestShorterMatchScoresHigher;
    procedure TestExactMatchScoresHighest;
  end;

  { TTestFuzzyMatchEx - match position tracking }

  TTestFuzzyMatchEx = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestExactMatchPositions;
    procedure TestPrefixMatchPositions;
    procedure TestSubstringMatchPositions;
    procedure TestWordStartMatchPositions;
    procedure TestSubsequenceMatchPositions;
    procedure TestNoMatchReturnsEmptyPositions;
  end;

  { TTestFilterFiles }

  TTestFilterFiles = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FFiles: TFileEntryArray;
    function MakeEntry(const AFileName, ARelPath: string): TFileEntry;
    procedure SetupTestFiles;
  protected
    procedure SetUp; virtual;
  public
    procedure TestFilterReturnsMatchesSortedByScore;
    procedure TestFilterEmptyPatternReturnsAll;
    procedure TestFilterNoMatchReturnsEmpty;
    procedure TestFilterCamelCaseOrdering;
  end;


procedure RegisteridetestfilefinderTests(ARegistry: TNXTestRegistry);

implementation

{ TTestFuzzyMatch }

procedure TTestFuzzyMatch.TestExactPrefixMatch;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('ide', 'ide.form.main.pas', Score), 'Should match prefix "ide"');
  TestContext.AssertTrue(Score > 0, 'Score should be positive');
end;

procedure TTestFuzzyMatch.TestSubstringMatch;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('form', 'ide.form.main.pas', Score), 'Should match substring "form"');
end;

procedure TTestFuzzyMatch.TestCamelCaseMatch;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('BT', 'BuilderThread.pas', Score), 'Should match CamelCase "BT" in BuilderThread');
end;

procedure TTestFuzzyMatch.TestCamelCaseMatchDotSeparated;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('ifm', 'ide.form.main.pas', Score), 'Should match word starts "ifm" in ide.form.main');
end;

procedure TTestFuzzyMatch.TestSubsequenceMatch;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('imn', 'ide.form.main.pas', Score), 'Should match subsequence "imn" (i...m...n)');
end;

procedure TTestFuzzyMatch.TestNoMatch;
var
  Score: Integer;
begin
  TestContext.AssertTrue(not (FuzzyMatch('xyz', 'ide.form.main.pas', Score)), 'Should not match "xyz"');
end;

procedure TTestFuzzyMatch.TestCaseInsensitive;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('IDE', 'ide.form.main.pas', Score), 'Should match case-insensitively');
end;

procedure TTestFuzzyMatch.TestEmptyPatternMatchesAll;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('', 'ide.form.main.pas', Score), 'Empty pattern should match everything');
end;

procedure TTestFuzzyMatch.TestExactMatchFullName;
var
  Score: Integer;
begin
  TestContext.AssertTrue(FuzzyMatch('ide.form.main.pas', 'ide.form.main.pas', Score), 'Exact full name should match');
end;

procedure TTestFuzzyMatch.TestExactPrefixScoresHigherThanSubstring;
var
  PrefixScore, SubstringScore: Integer;
begin
  FuzzyMatch('ide', 'ide.main.pas', PrefixScore);
  FuzzyMatch('ide', 'maxide.pas', SubstringScore);
  TestContext.AssertTrue(PrefixScore > SubstringScore, Format('Prefix score (%d) should exceed substring score (%d)',
      [PrefixScore, SubstringScore]));
end;

procedure TTestFuzzyMatch.TestShorterMatchScoresHigher;
var
  ShortScore, LongScore: Integer;
begin
  FuzzyMatch('main', 'main.pas', ShortScore);
  FuzzyMatch('main', 'ide.form.main.pas', LongScore);
  TestContext.AssertTrue(ShortScore > LongScore, Format('Shorter filename score (%d) should exceed longer (%d)',
      [ShortScore, LongScore]));
end;

procedure TTestFuzzyMatch.TestExactMatchScoresHighest;
var
  ExactScore, PrefixScore, SubstringScore: Integer;
begin
  FuzzyMatch('main.pas', 'main.pas', ExactScore);
  FuzzyMatch('main', 'main.pas', PrefixScore);
  FuzzyMatch('main', 'ide.form.main.pas', SubstringScore);
  TestContext.AssertTrue(ExactScore > PrefixScore, 'Exact match should score higher than prefix');
  TestContext.AssertTrue(PrefixScore > SubstringScore, 'Prefix should score higher than substring in longer name');
end;

{ TTestFilterFiles }

function TTestFilterFiles.MakeEntry(const AFileName, ARelPath: string): TFileEntry;
begin
  Result.FileName := AFileName;
  Result.RelativePath := ARelPath;
  Result.FullPath := '/project/' + ARelPath + AFileName;
end;

procedure TTestFilterFiles.SetupTestFiles;
begin
  SetLength(FFiles, 5);
  FFiles[0] := MakeEntry('ide.form.main.pas', 'src/main/pascal/');
  FFiles[1] := MakeEntry('ide.main.pas', 'src/main/pascal/');
  FFiles[2] := MakeEntry('ide.utils.pas', 'src/main/pascal/');
  FFiles[3] := MakeEntry('ide.filemonitor.pas', 'src/main/pascal/');
  FFiles[4] := MakeEntry('main.pas', 'src/main/pascal/');
end;

procedure TTestFilterFiles.SetUp;
begin
  SetupTestFiles;
end;

procedure TTestFilterFiles.TestFilterReturnsMatchesSortedByScore;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('main', FFiles);
  TestContext.AssertTrue(Length(Results) >= 2, 'Should match at least 2 files containing "main"');
  { "main.pas" should score highest (exact prefix on short name) }
  TestContext.AssertTrue(('main.pas')=(Results[0].FileName), 'First result should be "main.pas" (best match)');
end;

procedure TTestFilterFiles.TestFilterEmptyPatternReturnsAll;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('', FFiles);
  TestContext.AssertTrue((Length(FFiles))=(Length(Results)), 'Empty pattern should return all files');
end;

procedure TTestFilterFiles.TestFilterNoMatchReturnsEmpty;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('zzzzz', FFiles);
  TestContext.AssertTrue((0)=(Length(Results)), 'Non-matching pattern should return empty');
end;

procedure TTestFilterFiles.TestFilterCamelCaseOrdering;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('ifm', FFiles);
  { "ide.form.main.pas" matches word starts i.f.m, "ide.filemonitor.pas" matches i.f.m too }
  TestContext.AssertTrue(Length(Results) >= 1, 'Should match at least 1 file for "ifm"');
end;


{ TTestFuzzyMatchEx }

procedure TTestFuzzyMatchEx.TestExactMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(FuzzyMatchEx('main.pas', 'main.pas', Score, Positions), 'Exact match should succeed');
  TestContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for exact match');
  TestContext.AssertTrue((1)=(Positions[0].Start), 'Range should start at 1');
  TestContext.AssertTrue((8)=(Positions[0].Length), 'Range should cover full filename');
end;

procedure TTestFuzzyMatchEx.TestPrefixMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(FuzzyMatchEx('ide', 'ide.form.main.pas', Score, Positions), 'Prefix match should succeed');
  TestContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for prefix match');
  TestContext.AssertTrue((1)=(Positions[0].Start), 'Range should start at 1');
  TestContext.AssertTrue((3)=(Positions[0].Length), 'Range should cover pattern length');
end;

procedure TTestFuzzyMatchEx.TestSubstringMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(FuzzyMatchEx('form', 'ide.form.main.pas', Score, Positions), 'Substring match should succeed');
  TestContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for substring match');
  TestContext.AssertTrue((5)=(Positions[0].Start), 'Range should start at position of "form"');
  TestContext.AssertTrue((4)=(Positions[0].Length), 'Range should cover pattern length');
end;

procedure TTestFuzzyMatchEx.TestWordStartMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(FuzzyMatchEx('ifm', 'ide.form.main.pas', Score, Positions), 'Word-start match should succeed');
  TestContext.AssertTrue(Length(Positions) >= 3, Format('Should have at least 3 positions for "ifm", got %d', [Length(Positions)]));
  { Each position should be a single character at a word boundary }
  TestContext.AssertTrue((1)=(Positions[0].Start), 'First match at "i" in "ide"');
  TestContext.AssertTrue((1)=(Positions[0].Length), 'Single character match');
end;

procedure TTestFuzzyMatchEx.TestSubsequenceMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(FuzzyMatchEx('imn', 'ide.form.main.pas', Score, Positions), 'Subsequence match should succeed');
  TestContext.AssertTrue(Length(Positions) >= 3, Format('Should have at least 3 positions for "imn", got %d', [Length(Positions)]));
  { Each matched character should be a single-char range }
  TestContext.AssertTrue((1)=(Positions[0].Length), 'Each match should be 1 character');
  TestContext.AssertTrue((1)=(Positions[1].Length), 'Each match should be 1 character');
  TestContext.AssertTrue((1)=(Positions[2].Length), 'Each match should be 1 character');
end;

procedure TTestFuzzyMatchEx.TestNoMatchReturnsEmptyPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  TestContext.AssertTrue(not (FuzzyMatchEx('xyz', 'ide.form.main.pas', Score, Positions)), 'Should not match');
  TestContext.AssertTrue((0)=(Length(Positions)), 'No match should return empty positions');
end;



constructor TTestFuzzyMatch.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestFuzzyMatchEx.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestFilterFiles.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestFuzzyMatchTestExactPrefixMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestExactPrefixMatch');
  try
    lFixture.TestExactPrefixMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestSubstringMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestSubstringMatch');
  try
    lFixture.TestSubstringMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCamelCaseMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestCamelCaseMatch');
  try
    lFixture.TestCamelCaseMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCamelCaseMatchDotSeparated(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestCamelCaseMatchDotSeparated');
  try
    lFixture.TestCamelCaseMatchDotSeparated;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestSubsequenceMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestSubsequenceMatch');
  try
    lFixture.TestSubsequenceMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestNoMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestNoMatch');
  try
    lFixture.TestNoMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestCaseInsensitive');
  try
    lFixture.TestCaseInsensitive;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestEmptyPatternMatchesAll(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestEmptyPatternMatchesAll');
  try
    lFixture.TestEmptyPatternMatchesAll;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactMatchFullName(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestExactMatchFullName');
  try
    lFixture.TestExactMatchFullName;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactPrefixScoresHigherThanSubstring(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestExactPrefixScoresHigherThanSubstring');
  try
    lFixture.TestExactPrefixScoresHigherThanSubstring;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestShorterMatchScoresHigher(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestShorterMatchScoresHigher');
  try
    lFixture.TestShorterMatchScoresHigher;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactMatchScoresHighest(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create(AContext, 'TestExactMatchScoresHighest');
  try
    lFixture.TestExactMatchScoresHighest;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestExactMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestExactMatchPositions');
  try
    lFixture.TestExactMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestPrefixMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestPrefixMatchPositions');
  try
    lFixture.TestPrefixMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestSubstringMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestSubstringMatchPositions');
  try
    lFixture.TestSubstringMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestWordStartMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestWordStartMatchPositions');
  try
    lFixture.TestWordStartMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestSubsequenceMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestSubsequenceMatchPositions');
  try
    lFixture.TestSubsequenceMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestNoMatchReturnsEmptyPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create(AContext, 'TestNoMatchReturnsEmptyPositions');
  try
    lFixture.TestNoMatchReturnsEmptyPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterReturnsMatchesSortedByScore(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create(AContext, 'TestFilterReturnsMatchesSortedByScore');
  try
    lFixture.SetUp;
    lFixture.TestFilterReturnsMatchesSortedByScore;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterEmptyPatternReturnsAll(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create(AContext, 'TestFilterEmptyPatternReturnsAll');
  try
    lFixture.SetUp;
    lFixture.TestFilterEmptyPatternReturnsAll;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterNoMatchReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create(AContext, 'TestFilterNoMatchReturnsEmpty');
  try
    lFixture.SetUp;
    lFixture.TestFilterNoMatchReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterCamelCaseOrdering(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create(AContext, 'TestFilterCamelCaseOrdering');
  try
    lFixture.SetUp;
    lFixture.TestFilterCamelCaseOrdering;
  finally lFixture.Free; end;
end;

procedure RegisteridetestfilefinderTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.filefinder.TTestFuzzyMatch');
  lSuite.AddTest('TestExactPrefixMatch', @RunTTestFuzzyMatchTestExactPrefixMatch);
  lSuite.AddTest('TestSubstringMatch', @RunTTestFuzzyMatchTestSubstringMatch);
  lSuite.AddTest('TestCamelCaseMatch', @RunTTestFuzzyMatchTestCamelCaseMatch);
  lSuite.AddTest('TestCamelCaseMatchDotSeparated', @RunTTestFuzzyMatchTestCamelCaseMatchDotSeparated);
  lSuite.AddTest('TestSubsequenceMatch', @RunTTestFuzzyMatchTestSubsequenceMatch);
  lSuite.AddTest('TestNoMatch', @RunTTestFuzzyMatchTestNoMatch);
  lSuite.AddTest('TestCaseInsensitive', @RunTTestFuzzyMatchTestCaseInsensitive);
  lSuite.AddTest('TestEmptyPatternMatchesAll', @RunTTestFuzzyMatchTestEmptyPatternMatchesAll);
  lSuite.AddTest('TestExactMatchFullName', @RunTTestFuzzyMatchTestExactMatchFullName);
  lSuite.AddTest('TestExactPrefixScoresHigherThanSubstring', @RunTTestFuzzyMatchTestExactPrefixScoresHigherThanSubstring);
  lSuite.AddTest('TestShorterMatchScoresHigher', @RunTTestFuzzyMatchTestShorterMatchScoresHigher);
  lSuite.AddTest('TestExactMatchScoresHighest', @RunTTestFuzzyMatchTestExactMatchScoresHighest);
  lSuite:=ARegistry.AddSuite('ide.test.filefinder.TTestFuzzyMatchEx');
  lSuite.AddTest('TestExactMatchPositions', @RunTTestFuzzyMatchExTestExactMatchPositions);
  lSuite.AddTest('TestPrefixMatchPositions', @RunTTestFuzzyMatchExTestPrefixMatchPositions);
  lSuite.AddTest('TestSubstringMatchPositions', @RunTTestFuzzyMatchExTestSubstringMatchPositions);
  lSuite.AddTest('TestWordStartMatchPositions', @RunTTestFuzzyMatchExTestWordStartMatchPositions);
  lSuite.AddTest('TestSubsequenceMatchPositions', @RunTTestFuzzyMatchExTestSubsequenceMatchPositions);
  lSuite.AddTest('TestNoMatchReturnsEmptyPositions', @RunTTestFuzzyMatchExTestNoMatchReturnsEmptyPositions);
  lSuite:=ARegistry.AddSuite('ide.test.filefinder.TTestFilterFiles');
  lSuite.AddTest('TestFilterReturnsMatchesSortedByScore', @RunTTestFilterFilesTestFilterReturnsMatchesSortedByScore);
  lSuite.AddTest('TestFilterEmptyPatternReturnsAll', @RunTTestFilterFilesTestFilterEmptyPatternReturnsAll);
  lSuite.AddTest('TestFilterNoMatchReturnsEmpty', @RunTTestFilterFilesTestFilterNoMatchReturnsEmpty);
  lSuite.AddTest('TestFilterCamelCaseOrdering', @RunTTestFilterFilesTestFilterCamelCaseOrdering);
end;

end.

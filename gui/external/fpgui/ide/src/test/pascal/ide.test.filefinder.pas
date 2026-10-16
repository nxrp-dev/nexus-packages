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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue(FuzzyMatch('ide', 'ide.form.main.pas', Score), 'Should match prefix "ide"');
  FContext.AssertTrue(Score > 0, 'Score should be positive');
end;

procedure TTestFuzzyMatch.TestSubstringMatch;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('form', 'ide.form.main.pas', Score), 'Should match substring "form"');
end;

procedure TTestFuzzyMatch.TestCamelCaseMatch;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('BT', 'BuilderThread.pas', Score), 'Should match CamelCase "BT" in BuilderThread');
end;

procedure TTestFuzzyMatch.TestCamelCaseMatchDotSeparated;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('ifm', 'ide.form.main.pas', Score), 'Should match word starts "ifm" in ide.form.main');
end;

procedure TTestFuzzyMatch.TestSubsequenceMatch;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('imn', 'ide.form.main.pas', Score), 'Should match subsequence "imn" (i...m...n)');
end;

procedure TTestFuzzyMatch.TestNoMatch;
var
  Score: Integer;
begin
  FContext.AssertTrue(not (FuzzyMatch('xyz', 'ide.form.main.pas', Score)), 'Should not match "xyz"');
end;

procedure TTestFuzzyMatch.TestCaseInsensitive;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('IDE', 'ide.form.main.pas', Score), 'Should match case-insensitively');
end;

procedure TTestFuzzyMatch.TestEmptyPatternMatchesAll;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('', 'ide.form.main.pas', Score), 'Empty pattern should match everything');
end;

procedure TTestFuzzyMatch.TestExactMatchFullName;
var
  Score: Integer;
begin
  FContext.AssertTrue(FuzzyMatch('ide.form.main.pas', 'ide.form.main.pas', Score), 'Exact full name should match');
end;

procedure TTestFuzzyMatch.TestExactPrefixScoresHigherThanSubstring;
var
  PrefixScore, SubstringScore: Integer;
begin
  FuzzyMatch('ide', 'ide.main.pas', PrefixScore);
  FuzzyMatch('ide', 'maxide.pas', SubstringScore);
  FContext.AssertTrue(PrefixScore > SubstringScore, Format('Prefix score (%d) should exceed substring score (%d)',
      [PrefixScore, SubstringScore]));
end;

procedure TTestFuzzyMatch.TestShorterMatchScoresHigher;
var
  ShortScore, LongScore: Integer;
begin
  FuzzyMatch('main', 'main.pas', ShortScore);
  FuzzyMatch('main', 'ide.form.main.pas', LongScore);
  FContext.AssertTrue(ShortScore > LongScore, Format('Shorter filename score (%d) should exceed longer (%d)',
      [ShortScore, LongScore]));
end;

procedure TTestFuzzyMatch.TestExactMatchScoresHighest;
var
  ExactScore, PrefixScore, SubstringScore: Integer;
begin
  FuzzyMatch('main.pas', 'main.pas', ExactScore);
  FuzzyMatch('main', 'main.pas', PrefixScore);
  FuzzyMatch('main', 'ide.form.main.pas', SubstringScore);
  FContext.AssertTrue(ExactScore > PrefixScore, 'Exact match should score higher than prefix');
  FContext.AssertTrue(PrefixScore > SubstringScore, 'Prefix should score higher than substring in longer name');
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
  FContext.AssertTrue(Length(Results) >= 2, 'Should match at least 2 files containing "main"');
  { "main.pas" should score highest (exact prefix on short name) }
  FContext.AssertTrue(('main.pas')=(Results[0].FileName), 'First result should be "main.pas" (best match)');
end;

procedure TTestFilterFiles.TestFilterEmptyPatternReturnsAll;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('', FFiles);
  FContext.AssertTrue((Length(FFiles))=(Length(Results)), 'Empty pattern should return all files');
end;

procedure TTestFilterFiles.TestFilterNoMatchReturnsEmpty;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('zzzzz', FFiles);
  FContext.AssertTrue((0)=(Length(Results)), 'Non-matching pattern should return empty');
end;

procedure TTestFilterFiles.TestFilterCamelCaseOrdering;
var
  Results: TFileEntryArray;
begin
  Results := FilterFiles('ifm', FFiles);
  { "ide.form.main.pas" matches word starts i.f.m, "ide.filemonitor.pas" matches i.f.m too }
  FContext.AssertTrue(Length(Results) >= 1, 'Should match at least 1 file for "ifm"');
end;


{ TTestFuzzyMatchEx }

procedure TTestFuzzyMatchEx.TestExactMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(FuzzyMatchEx('main.pas', 'main.pas', Score, Positions), 'Exact match should succeed');
  FContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for exact match');
  FContext.AssertTrue((1)=(Positions[0].Start), 'Range should start at 1');
  FContext.AssertTrue((8)=(Positions[0].Length), 'Range should cover full filename');
end;

procedure TTestFuzzyMatchEx.TestPrefixMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(FuzzyMatchEx('ide', 'ide.form.main.pas', Score, Positions), 'Prefix match should succeed');
  FContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for prefix match');
  FContext.AssertTrue((1)=(Positions[0].Start), 'Range should start at 1');
  FContext.AssertTrue((3)=(Positions[0].Length), 'Range should cover pattern length');
end;

procedure TTestFuzzyMatchEx.TestSubstringMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(FuzzyMatchEx('form', 'ide.form.main.pas', Score, Positions), 'Substring match should succeed');
  FContext.AssertTrue((1)=(Length(Positions)), 'Should have 1 range for substring match');
  FContext.AssertTrue((5)=(Positions[0].Start), 'Range should start at position of "form"');
  FContext.AssertTrue((4)=(Positions[0].Length), 'Range should cover pattern length');
end;

procedure TTestFuzzyMatchEx.TestWordStartMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(FuzzyMatchEx('ifm', 'ide.form.main.pas', Score, Positions), 'Word-start match should succeed');
  FContext.AssertTrue(Length(Positions) >= 3, Format('Should have at least 3 positions for "ifm", got %d', [Length(Positions)]));
  { Each position should be a single character at a word boundary }
  FContext.AssertTrue((1)=(Positions[0].Start), 'First match at "i" in "ide"');
  FContext.AssertTrue((1)=(Positions[0].Length), 'Single character match');
end;

procedure TTestFuzzyMatchEx.TestSubsequenceMatchPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(FuzzyMatchEx('imn', 'ide.form.main.pas', Score, Positions), 'Subsequence match should succeed');
  FContext.AssertTrue(Length(Positions) >= 3, Format('Should have at least 3 positions for "imn", got %d', [Length(Positions)]));
  { Each matched character should be a single-char range }
  FContext.AssertTrue((1)=(Positions[0].Length), 'Each match should be 1 character');
  FContext.AssertTrue((1)=(Positions[1].Length), 'Each match should be 1 character');
  FContext.AssertTrue((1)=(Positions[2].Length), 'Each match should be 1 character');
end;

procedure TTestFuzzyMatchEx.TestNoMatchReturnsEmptyPositions;
var
  Score: Integer;
  Positions: TMatchRangeArray;
begin
  FContext.AssertTrue(not (FuzzyMatchEx('xyz', 'ide.form.main.pas', Score, Positions)), 'Should not match');
  FContext.AssertTrue((0)=(Length(Positions)), 'No match should return empty positions');
end;



procedure RunTTestFuzzyMatchTestExactPrefixMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExactPrefixMatch';
    lFixture.TestExactPrefixMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestSubstringMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSubstringMatch';
    lFixture.TestSubstringMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCamelCaseMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCamelCaseMatch';
    lFixture.TestCamelCaseMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCamelCaseMatchDotSeparated(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCamelCaseMatchDotSeparated';
    lFixture.TestCamelCaseMatchDotSeparated;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestSubsequenceMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSubsequenceMatch';
    lFixture.TestSubsequenceMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestNoMatch(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoMatch';
    lFixture.TestNoMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestCaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCaseInsensitive';
    lFixture.TestCaseInsensitive;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestEmptyPatternMatchesAll(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyPatternMatchesAll';
    lFixture.TestEmptyPatternMatchesAll;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactMatchFullName(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExactMatchFullName';
    lFixture.TestExactMatchFullName;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactPrefixScoresHigherThanSubstring(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExactPrefixScoresHigherThanSubstring';
    lFixture.TestExactPrefixScoresHigherThanSubstring;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestShorterMatchScoresHigher(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShorterMatchScoresHigher';
    lFixture.TestShorterMatchScoresHigher;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchTestExactMatchScoresHighest(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatch;
begin
  lFixture:=TTestFuzzyMatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExactMatchScoresHighest';
    lFixture.TestExactMatchScoresHighest;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestExactMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExactMatchPositions';
    lFixture.TestExactMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestPrefixMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPrefixMatchPositions';
    lFixture.TestPrefixMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestSubstringMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSubstringMatchPositions';
    lFixture.TestSubstringMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestWordStartMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWordStartMatchPositions';
    lFixture.TestWordStartMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestSubsequenceMatchPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSubsequenceMatchPositions';
    lFixture.TestSubsequenceMatchPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFuzzyMatchExTestNoMatchReturnsEmptyPositions(AContext: TNXTestContext);
var lFixture: TTestFuzzyMatchEx;
begin
  lFixture:=TTestFuzzyMatchEx.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoMatchReturnsEmptyPositions';
    lFixture.TestNoMatchReturnsEmptyPositions;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterReturnsMatchesSortedByScore(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterReturnsMatchesSortedByScore';
    lFixture.SetUp;
    lFixture.TestFilterReturnsMatchesSortedByScore;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterEmptyPatternReturnsAll(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterEmptyPatternReturnsAll';
    lFixture.SetUp;
    lFixture.TestFilterEmptyPatternReturnsAll;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterNoMatchReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterNoMatchReturnsEmpty';
    lFixture.SetUp;
    lFixture.TestFilterNoMatchReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterFilesTestFilterCamelCaseOrdering(AContext: TNXTestContext);
var lFixture: TTestFilterFiles;
begin
  lFixture:=TTestFilterFiles.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterCamelCaseOrdering';
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

{
    fpGUI IDE - Cursor History Tests

    Tests for the cursor history stack used by back/forward
    navigation (Alt+Left / Alt+Right).
}
unit ide.test.cursorhistory;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.cursorhistory;

type

  { TTestCursorHistory }

  TTestCursorHistory = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FHistory: TCursorHistory;
    function MakeLoc(const AFile: string; ALine: Integer; ACol: Integer = 0): TCursorLocation;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Basic operations }
    procedure TestEmptyHistory;
    procedure TestRecordSingleLocation;
    procedure TestRecordTwoLocations;
    procedure TestGoBackReturnsCorrectLocation;
    procedure TestGoForwardAfterBack;
    procedure TestGoBackTwice;

    { Edge cases }
    procedure TestGoBackAtStart;
    procedure TestGoForwardAtEnd;
    procedure TestCanGoBackAfterGoBack;

    { Deduplication }
    procedure TestDuplicateSameFileLine;
    procedure TestDuplicateDifferentCol;
    procedure TestDifferentLine;
    procedure TestDifferentFile;

    { Forward truncation }
    procedure TestRecordAfterGoBackTruncates;
    procedure TestCanGoForwardFalseAfterTruncation;

    { Capacity }
    procedure TestCapacityOverflow;
    procedure TestCapacityOverflowPreservesNewest;

    { RecordBeforeJump }
    procedure TestRecordBeforeJumpAtTip;
    procedure TestRecordBeforeJumpWhileTraversing;
    procedure TestRecordBeforeJumpThenGoBack;
    procedure TestRecordLocationResetsTraversal;

    { IsTraversing }
    procedure TestIsTraversingInitiallyFalse;
    procedure TestIsTraversingAfterGoBack;
    procedure TestIsTraversingAfterGoForwardToTip;

    { Clear }
    procedure TestClear;
  end;


procedure RegisteridetestcursorhistoryTests(ARegistry: TNXTestRegistry);

implementation

{ TTestCursorHistory }

function TTestCursorHistory.MakeLoc(const AFile: string; ALine: Integer;
  ACol: Integer): TCursorLocation;
begin
  Result.Filename := AFile;
  Result.Line := ALine;
  Result.Col := ACol;
end;

procedure TTestCursorHistory.SetUp;
begin
  FHistory := TCursorHistory.Create(50);
end;

procedure TTestCursorHistory.TearDown;
begin
  FHistory.Free;
end;

{ --- Basic operations --- }

procedure TTestCursorHistory.TestEmptyHistory;
begin
  FContext.AssertTrue(not (FHistory.CanGoBack), 'CanGoBack should be False for empty history');
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False for empty history');
  FContext.AssertTrue((0)=(FHistory.Count), 'Count should be 0');
end;

procedure TTestCursorHistory.TestRecordSingleLocation;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FContext.AssertTrue((1)=(FHistory.Count), 'Count should be 1 after one record');
  FContext.AssertTrue(not (FHistory.CanGoBack), 'CanGoBack should be False with single entry');
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False at tip');
end;

procedure TTestCursorHistory.TestRecordTwoLocations;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FHistory.RecordLocation(MakeLoc('file1.pas', 50));
  FContext.AssertTrue((2)=(FHistory.Count), 'Count should be 2');
  FContext.AssertTrue(FHistory.CanGoBack, 'CanGoBack should be True with two entries');
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False at tip');
end;

procedure TTestCursorHistory.TestGoBackReturnsCorrectLocation;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FHistory.RecordLocation(MakeLoc('file2.pas', 20));
  FContext.AssertTrue(FHistory.GoBack(loc), 'GoBack should succeed');
  FContext.AssertTrue(('file1.pas')=(loc.Filename), 'GoBack should return first location');
  FContext.AssertTrue((10)=(loc.Line), 'GoBack should return line 10');
end;

procedure TTestCursorHistory.TestGoForwardAfterBack;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FHistory.RecordLocation(MakeLoc('file2.pas', 20));
  FHistory.GoBack(loc);
  FContext.AssertTrue(FHistory.GoForward(loc), 'GoForward should succeed after GoBack');
  FContext.AssertTrue(('file2.pas')=(loc.Filename), 'GoForward should return second location');
  FContext.AssertTrue((20)=(loc.Line), 'GoForward should return line 20');
end;

procedure TTestCursorHistory.TestGoBackTwice;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordLocation(MakeLoc('c.pas', 3));
  FContext.AssertTrue(FHistory.GoBack(loc), 'First GoBack should succeed');
  FContext.AssertTrue(('b.pas')=(loc.Filename), 'First GoBack returns B');
  FContext.AssertTrue(FHistory.GoBack(loc), 'Second GoBack should succeed');
  FContext.AssertTrue(('a.pas')=(loc.Filename), 'Second GoBack returns A');
end;

{ --- Edge cases --- }

procedure TTestCursorHistory.TestGoBackAtStart;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FContext.AssertTrue(not (FHistory.GoBack(loc)), 'GoBack should fail with single entry');
end;

procedure TTestCursorHistory.TestGoForwardAtEnd;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 10));
  FHistory.RecordLocation(MakeLoc('file2.pas', 20));
  FContext.AssertTrue(not (FHistory.GoForward(loc)), 'GoForward should fail at tip');
end;

procedure TTestCursorHistory.TestCanGoBackAfterGoBack;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordLocation(MakeLoc('c.pas', 3));
  FHistory.GoBack(loc);  { now at B }
  FContext.AssertTrue(FHistory.CanGoBack, 'CanGoBack should be True at B (A still behind)');
  FHistory.GoBack(loc);  { now at A }
  FContext.AssertTrue(not (FHistory.CanGoBack), 'CanGoBack should be False at start');
end;

{ --- Deduplication --- }

procedure TTestCursorHistory.TestDuplicateSameFileLine;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 5, 0));
  FHistory.RecordLocation(MakeLoc('file1.pas', 5, 0));
  FContext.AssertTrue((1)=(FHistory.Count), 'Duplicate same file+line should not add entry');
end;

procedure TTestCursorHistory.TestDuplicateDifferentCol;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 5, 0));
  FHistory.RecordLocation(MakeLoc('file1.pas', 5, 15));
  FContext.AssertTrue((1)=(FHistory.Count), 'Same file+line with different col should deduplicate');
end;

procedure TTestCursorHistory.TestDifferentLine;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 5));
  FHistory.RecordLocation(MakeLoc('file1.pas', 50));
  FContext.AssertTrue((2)=(FHistory.Count), 'Different line should record');
end;

procedure TTestCursorHistory.TestDifferentFile;
begin
  FHistory.RecordLocation(MakeLoc('file1.pas', 5));
  FHistory.RecordLocation(MakeLoc('file2.pas', 5));
  FContext.AssertTrue((2)=(FHistory.Count), 'Different file should record');
end;

{ --- Forward truncation --- }

procedure TTestCursorHistory.TestRecordAfterGoBackTruncates;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordLocation(MakeLoc('c.pas', 3));
  FHistory.GoBack(loc);  { now at B, C is forward }
  FHistory.RecordLocation(MakeLoc('d.pas', 4));  { should truncate C }
  FContext.AssertTrue((3)=(FHistory.Count), 'Count should be 3 (A, B, D) after truncation');
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False after recording new location');
  FContext.AssertTrue(FHistory.GoBack(loc), 'GoBack should succeed');
  FContext.AssertTrue(('b.pas')=(loc.Filename), 'GoBack from D should return B');
end;

procedure TTestCursorHistory.TestCanGoForwardFalseAfterTruncation;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.GoBack(loc);
  FHistory.RecordLocation(MakeLoc('c.pas', 3));
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False after truncation');
end;

{ --- Capacity --- }

procedure TTestCursorHistory.TestCapacityOverflow;
var
  h: TCursorHistory;
  i: Integer;
  loc: TCursorLocation;
begin
  h := TCursorHistory.Create(5);
  try
    for i := 1 to 7 do
      h.RecordLocation(MakeLoc('file.pas', i * 10));
    FContext.AssertTrue((5)=(h.Count), 'Count should not exceed capacity');
    { Oldest entries (line 10, 20) should be dropped. Newest is line 70. }
    FContext.AssertTrue(h.GoBack(loc), 'GoBack should succeed');
    FContext.AssertTrue((60)=(loc.Line), 'GoBack from line 70 should return line 60');
  finally
    h.Free;
  end;
end;

procedure TTestCursorHistory.TestCapacityOverflowPreservesNewest;
var
  h: TCursorHistory;
  i: Integer;
  loc: TCursorLocation;
  ok: Boolean;
begin
  h := TCursorHistory.Create(5);
  try
    for i := 1 to 7 do
      h.RecordLocation(MakeLoc('file.pas', i * 10));
    { Should be able to traverse back through all 5 entries: 70, 60, 50, 40, 30 }
    ok := True;
    for i := 1 to 4 do
      ok := ok and h.GoBack(loc);
    FContext.AssertTrue(ok, 'Should traverse back through 4 entries');
    FContext.AssertTrue((30)=(loc.Line), 'Oldest surviving entry should be line 30');
    FContext.AssertTrue(not (h.CanGoBack), 'Should not be able to go further back');
  finally
    h.Free;
  end;
end;

{ --- RecordBeforeJump --- }

procedure TTestCursorHistory.TestRecordBeforeJumpAtTip;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordBeforeJump(MakeLoc('c.pas', 3));
  FContext.AssertTrue((3)=(FHistory.Count), 'RecordBeforeJump at tip should record (Count = 3)');
end;

procedure TTestCursorHistory.TestRecordBeforeJumpWhileTraversing;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordLocation(MakeLoc('c.pas', 3));
  FHistory.GoBack(loc);  { now traversing }
  FHistory.RecordBeforeJump(MakeLoc('x.pas', 99));
  FContext.AssertTrue((3)=(FHistory.Count), 'RecordBeforeJump while traversing should be no-op');
end;

procedure TTestCursorHistory.TestRecordBeforeJumpThenGoBack;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.RecordBeforeJump(MakeLoc('c.pas', 3));
  FContext.AssertTrue(FHistory.GoBack(loc), 'GoBack from C should succeed');
  FContext.AssertTrue(('b.pas')=(loc.Filename), 'GoBack from C should return B');
  FContext.AssertTrue(FHistory.GoBack(loc), 'GoBack from B should succeed');
  FContext.AssertTrue(('a.pas')=(loc.Filename), 'GoBack from B should return A');
end;

procedure TTestCursorHistory.TestRecordLocationResetsTraversal;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.GoBack(loc);  { traversing }
  FContext.AssertTrue(FHistory.IsTraversing, 'Should be traversing after GoBack');
  FHistory.RecordLocation(MakeLoc('d.pas', 4));
  FContext.AssertTrue(not (FHistory.IsTraversing), 'RecordLocation should reset traversal');
end;

{ --- IsTraversing --- }

procedure TTestCursorHistory.TestIsTraversingInitiallyFalse;
begin
  FContext.AssertTrue(not (FHistory.IsTraversing), 'IsTraversing should be False initially');
end;

procedure TTestCursorHistory.TestIsTraversingAfterGoBack;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.GoBack(loc);
  FContext.AssertTrue(FHistory.IsTraversing, 'IsTraversing should be True after GoBack');
end;

procedure TTestCursorHistory.TestIsTraversingAfterGoForwardToTip;
var
  loc: TCursorLocation;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.GoBack(loc);
  FHistory.GoForward(loc);
  FContext.AssertTrue(not (FHistory.IsTraversing), 'IsTraversing should be False after returning to tip');
end;

{ --- Clear --- }

procedure TTestCursorHistory.TestClear;
begin
  FHistory.RecordLocation(MakeLoc('a.pas', 1));
  FHistory.RecordLocation(MakeLoc('b.pas', 2));
  FHistory.Clear;
  FContext.AssertTrue((0)=(FHistory.Count), 'Count should be 0 after Clear');
  FContext.AssertTrue(not (FHistory.CanGoBack), 'CanGoBack should be False after Clear');
  FContext.AssertTrue(not (FHistory.CanGoForward), 'CanGoForward should be False after Clear');
end;



procedure RunTTestCursorHistoryTestEmptyHistory(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyHistory';
    lFixture.SetUp;
    try lFixture.TestEmptyHistory; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordSingleLocation(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordSingleLocation';
    lFixture.SetUp;
    try lFixture.TestRecordSingleLocation; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordTwoLocations(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordTwoLocations';
    lFixture.SetUp;
    try lFixture.TestRecordTwoLocations; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestGoBackReturnsCorrectLocation(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGoBackReturnsCorrectLocation';
    lFixture.SetUp;
    try lFixture.TestGoBackReturnsCorrectLocation; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestGoForwardAfterBack(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGoForwardAfterBack';
    lFixture.SetUp;
    try lFixture.TestGoForwardAfterBack; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestGoBackTwice(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGoBackTwice';
    lFixture.SetUp;
    try lFixture.TestGoBackTwice; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestGoBackAtStart(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGoBackAtStart';
    lFixture.SetUp;
    try lFixture.TestGoBackAtStart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestGoForwardAtEnd(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGoForwardAtEnd';
    lFixture.SetUp;
    try lFixture.TestGoForwardAtEnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestCanGoBackAfterGoBack(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCanGoBackAfterGoBack';
    lFixture.SetUp;
    try lFixture.TestCanGoBackAfterGoBack; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestDuplicateSameFileLine(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDuplicateSameFileLine';
    lFixture.SetUp;
    try lFixture.TestDuplicateSameFileLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestDuplicateDifferentCol(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDuplicateDifferentCol';
    lFixture.SetUp;
    try lFixture.TestDuplicateDifferentCol; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestDifferentLine(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDifferentLine';
    lFixture.SetUp;
    try lFixture.TestDifferentLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestDifferentFile(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDifferentFile';
    lFixture.SetUp;
    try lFixture.TestDifferentFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordAfterGoBackTruncates(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordAfterGoBackTruncates';
    lFixture.SetUp;
    try lFixture.TestRecordAfterGoBackTruncates; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestCanGoForwardFalseAfterTruncation(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCanGoForwardFalseAfterTruncation';
    lFixture.SetUp;
    try lFixture.TestCanGoForwardFalseAfterTruncation; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestCapacityOverflow(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCapacityOverflow';
    lFixture.SetUp;
    try lFixture.TestCapacityOverflow; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestCapacityOverflowPreservesNewest(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCapacityOverflowPreservesNewest';
    lFixture.SetUp;
    try lFixture.TestCapacityOverflowPreservesNewest; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordBeforeJumpAtTip(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordBeforeJumpAtTip';
    lFixture.SetUp;
    try lFixture.TestRecordBeforeJumpAtTip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordBeforeJumpWhileTraversing(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordBeforeJumpWhileTraversing';
    lFixture.SetUp;
    try lFixture.TestRecordBeforeJumpWhileTraversing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordBeforeJumpThenGoBack(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordBeforeJumpThenGoBack';
    lFixture.SetUp;
    try lFixture.TestRecordBeforeJumpThenGoBack; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestRecordLocationResetsTraversal(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordLocationResetsTraversal';
    lFixture.SetUp;
    try lFixture.TestRecordLocationResetsTraversal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestIsTraversingInitiallyFalse(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsTraversingInitiallyFalse';
    lFixture.SetUp;
    try lFixture.TestIsTraversingInitiallyFalse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestIsTraversingAfterGoBack(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsTraversingAfterGoBack';
    lFixture.SetUp;
    try lFixture.TestIsTraversingAfterGoBack; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestIsTraversingAfterGoForwardToTip(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsTraversingAfterGoForwardToTip';
    lFixture.SetUp;
    try lFixture.TestIsTraversingAfterGoForwardToTip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCursorHistoryTestClear(AContext: TNXTestContext);
var lFixture: TTestCursorHistory;
begin
  lFixture:=TTestCursorHistory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClear';
    lFixture.SetUp;
    try lFixture.TestClear; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestcursorhistoryTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.cursorhistory.TTestCursorHistory');
  lSuite.AddTest('TestEmptyHistory', @RunTTestCursorHistoryTestEmptyHistory);
  lSuite.AddTest('TestRecordSingleLocation', @RunTTestCursorHistoryTestRecordSingleLocation);
  lSuite.AddTest('TestRecordTwoLocations', @RunTTestCursorHistoryTestRecordTwoLocations);
  lSuite.AddTest('TestGoBackReturnsCorrectLocation', @RunTTestCursorHistoryTestGoBackReturnsCorrectLocation);
  lSuite.AddTest('TestGoForwardAfterBack', @RunTTestCursorHistoryTestGoForwardAfterBack);
  lSuite.AddTest('TestGoBackTwice', @RunTTestCursorHistoryTestGoBackTwice);
  lSuite.AddTest('TestGoBackAtStart', @RunTTestCursorHistoryTestGoBackAtStart);
  lSuite.AddTest('TestGoForwardAtEnd', @RunTTestCursorHistoryTestGoForwardAtEnd);
  lSuite.AddTest('TestCanGoBackAfterGoBack', @RunTTestCursorHistoryTestCanGoBackAfterGoBack);
  lSuite.AddTest('TestDuplicateSameFileLine', @RunTTestCursorHistoryTestDuplicateSameFileLine);
  lSuite.AddTest('TestDuplicateDifferentCol', @RunTTestCursorHistoryTestDuplicateDifferentCol);
  lSuite.AddTest('TestDifferentLine', @RunTTestCursorHistoryTestDifferentLine);
  lSuite.AddTest('TestDifferentFile', @RunTTestCursorHistoryTestDifferentFile);
  lSuite.AddTest('TestRecordAfterGoBackTruncates', @RunTTestCursorHistoryTestRecordAfterGoBackTruncates);
  lSuite.AddTest('TestCanGoForwardFalseAfterTruncation', @RunTTestCursorHistoryTestCanGoForwardFalseAfterTruncation);
  lSuite.AddTest('TestCapacityOverflow', @RunTTestCursorHistoryTestCapacityOverflow);
  lSuite.AddTest('TestCapacityOverflowPreservesNewest', @RunTTestCursorHistoryTestCapacityOverflowPreservesNewest);
  lSuite.AddTest('TestRecordBeforeJumpAtTip', @RunTTestCursorHistoryTestRecordBeforeJumpAtTip);
  lSuite.AddTest('TestRecordBeforeJumpWhileTraversing', @RunTTestCursorHistoryTestRecordBeforeJumpWhileTraversing);
  lSuite.AddTest('TestRecordBeforeJumpThenGoBack', @RunTTestCursorHistoryTestRecordBeforeJumpThenGoBack);
  lSuite.AddTest('TestRecordLocationResetsTraversal', @RunTTestCursorHistoryTestRecordLocationResetsTraversal);
  lSuite.AddTest('TestIsTraversingInitiallyFalse', @RunTTestCursorHistoryTestIsTraversingInitiallyFalse);
  lSuite.AddTest('TestIsTraversingAfterGoBack', @RunTTestCursorHistoryTestIsTraversingAfterGoBack);
  lSuite.AddTest('TestIsTraversingAfterGoForwardToTip', @RunTTestCursorHistoryTestIsTraversingAfterGoForwardToTip);
  lSuite.AddTest('TestClear', @RunTTestCursorHistoryTestClear);
end;

end.

(*
    fpGUI IDE — Watch List Tests

    Tests for TWatchList: expression management, deduplication,
    ordering, and session round-trip.
*)
unit ide.test.watches;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, SysUtils,
  ide.watches;

type
  TWatchListTests = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FList: TWatchList;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestEmptyListHasCountZero;
    procedure TestAddWatchIncreasesCount;
    procedure TestAddWatchReturnsIndex;
    procedure TestAddDuplicateReturnsExistingIndex;
    procedure TestAddDuplicateCaseSensitive;
    procedure TestExpressionByIndex;
    procedure TestExpressionOutOfRangeReturnsEmpty;
    procedure TestRemoveWatchDecreasesCount;
    procedure TestRemoveWatchShiftsEntries;
    procedure TestRemoveWatchOutOfRangeIsHarmless;
    procedure TestIndexOfFindsExistingEntry;
    procedure TestIndexOfReturnsMinus1WhenMissing;
    procedure TestIndexOfIsCaseSensitive;
    procedure TestGetExpressionsMatchesList;
    procedure TestGetExpressionsEmptyList;
    procedure TestLoadExpressions;
    procedure TestLoadExpressionsDeduplicate;
    procedure TestLoadExpressionsSkipsEmpty;
    procedure TestClearEmptiesList;
    procedure TestAddAfterClear;
  end;

procedure RegisteridetestwatchesTests(ARegistry: TNXTestRegistry);

implementation

procedure TWatchListTests.SetUp;
begin
  FList := TWatchList.Create;
end;

procedure TWatchListTests.TearDown;
begin
  FList.Free;
end;

procedure TWatchListTests.TestEmptyListHasCountZero;
begin
  TestContext.AssertTrue((0)=(FList.Count), 'Empty list count');
end;

procedure TWatchListTests.TestAddWatchIncreasesCount;
begin
  FList.AddWatch('myVar');
  TestContext.AssertTrue((1)=(FList.Count), 'Count after add');
  FList.AddWatch('otherVar');
  TestContext.AssertTrue((2)=(FList.Count), 'Count after second add');
end;

procedure TWatchListTests.TestAddWatchReturnsIndex;
var
  Idx: Integer;
begin
  Idx := FList.AddWatch('x');
  TestContext.AssertTrue((0)=(Idx), 'First add returns 0');
  Idx := FList.AddWatch('y');
  TestContext.AssertTrue((1)=(Idx), 'Second add returns 1');
end;

procedure TWatchListTests.TestAddDuplicateReturnsExistingIndex;
var
  Idx1, Idx2: Integer;
begin
  Idx1 := FList.AddWatch('SomeExpr');
  Idx2 := FList.AddWatch('SomeExpr');
  TestContext.AssertTrue((Idx1)=(Idx2), 'Duplicate add returns same index');
  TestContext.AssertTrue((1)=(FList.Count), 'Count unchanged after duplicate');
end;

procedure TWatchListTests.TestAddDuplicateCaseSensitive;
var
  Idx1, Idx2: Integer;
begin
  Idx1 := FList.AddWatch('myVar');
  Idx2 := FList.AddWatch('MyVar');
  TestContext.AssertTrue(Idx1 <> Idx2, 'Different case adds separate entry');
  TestContext.AssertTrue((2)=(FList.Count), 'Two entries after case-different adds');
end;

procedure TWatchListTests.TestExpressionByIndex;
begin
  FList.AddWatch('alpha');
  FList.AddWatch('beta');
  TestContext.AssertTrue(('alpha')=(FList.Expression[0]), 'Expression at 0');
  TestContext.AssertTrue(('beta')=(FList.Expression[1]), 'Expression at 1');
end;

procedure TWatchListTests.TestExpressionOutOfRangeReturnsEmpty;
begin
  FList.AddWatch('x');
  TestContext.AssertTrue(('')=(FList.Expression[-1]), 'Negative index');
  TestContext.AssertTrue(('')=(FList.Expression[99]), 'Out-of-bounds index');
end;

procedure TWatchListTests.TestRemoveWatchDecreasesCount;
begin
  FList.AddWatch('a');
  FList.AddWatch('b');
  FList.RemoveWatch(0);
  TestContext.AssertTrue((1)=(FList.Count), 'Count after remove');
end;

procedure TWatchListTests.TestRemoveWatchShiftsEntries;
begin
  FList.AddWatch('first');
  FList.AddWatch('second');
  FList.AddWatch('third');
  FList.RemoveWatch(0);
  TestContext.AssertTrue(('second')=(FList.Expression[0]), 'After removing 0, index 0 becomes second');
  TestContext.AssertTrue(('third')=(FList.Expression[1]), 'After removing 0, index 1 becomes third');
end;

procedure TWatchListTests.TestRemoveWatchOutOfRangeIsHarmless;
begin
  FList.AddWatch('x');
  FList.RemoveWatch(-1);
  FList.RemoveWatch(99);
  TestContext.AssertTrue((1)=(FList.Count), 'Count unchanged after invalid removes');
end;

procedure TWatchListTests.TestIndexOfFindsExistingEntry;
begin
  FList.AddWatch('alpha');
  FList.AddWatch('beta');
  TestContext.AssertTrue((0)=(FList.IndexOf('alpha')), 'IndexOf alpha');
  TestContext.AssertTrue((1)=(FList.IndexOf('beta')), 'IndexOf beta');
end;

procedure TWatchListTests.TestIndexOfReturnsMinus1WhenMissing;
begin
  FList.AddWatch('alpha');
  TestContext.AssertTrue((-1)=(FList.IndexOf('gamma')), 'IndexOf missing');
end;

procedure TWatchListTests.TestIndexOfIsCaseSensitive;
begin
  FList.AddWatch('myVar');
  TestContext.AssertTrue((0)=(FList.IndexOf('myVar')), 'Exact case found');
  TestContext.AssertTrue((-1)=(FList.IndexOf('myvar')), 'Different case not found');
  TestContext.AssertTrue((-1)=(FList.IndexOf('MYVAR')), 'Upper case not found');
end;

procedure TWatchListTests.TestGetExpressionsMatchesList;
var
  Exprs: TStringArray;
begin
  FList.AddWatch('a');
  FList.AddWatch('b.field');
  FList.AddWatch('arr[0]');
  Exprs := FList.GetExpressions;
  TestContext.AssertTrue((3)=(Length(Exprs)), 'Array length');
  TestContext.AssertTrue(('a')=(Exprs[0]), 'Expr 0');
  TestContext.AssertTrue(('b.field')=(Exprs[1]), 'Expr 1');
  TestContext.AssertTrue(('arr[0]')=(Exprs[2]), 'Expr 2');
end;

procedure TWatchListTests.TestGetExpressionsEmptyList;
var
  Exprs: TStringArray;
begin
  Exprs := FList.GetExpressions;
  TestContext.AssertTrue((0)=(Length(Exprs)), 'Empty list returns empty array');
end;

procedure TWatchListTests.TestLoadExpressions;
var
  Exprs: TStringArray;
begin
  SetLength(Exprs, 3);
  Exprs[0] := 'x';
  Exprs[1] := 'y';
  Exprs[2] := 'z';
  FList.LoadExpressions(Exprs);
  TestContext.AssertTrue((3)=(FList.Count), 'Count after load');
  TestContext.AssertTrue(('x')=(FList.Expression[0]), 'Expr 0');
  TestContext.AssertTrue(('y')=(FList.Expression[1]), 'Expr 1');
  TestContext.AssertTrue(('z')=(FList.Expression[2]), 'Expr 2');
end;

procedure TWatchListTests.TestLoadExpressionsDeduplicate;
var
  Exprs: TStringArray;
begin
  SetLength(Exprs, 3);
  Exprs[0] := 'x';
  Exprs[1] := 'x';
  Exprs[2] := 'y';
  FList.LoadExpressions(Exprs);
  TestContext.AssertTrue((2)=(FList.Count), 'Deduplicates on load');
end;

procedure TWatchListTests.TestLoadExpressionsSkipsEmpty;
var
  Exprs: TStringArray;
begin
  SetLength(Exprs, 3);
  Exprs[0] := 'x';
  Exprs[1] := '';
  Exprs[2] := 'y';
  FList.LoadExpressions(Exprs);
  TestContext.AssertTrue((2)=(FList.Count), 'Empty string skipped on load');
end;

procedure TWatchListTests.TestClearEmptiesList;
begin
  FList.AddWatch('a');
  FList.AddWatch('b');
  FList.Clear;
  TestContext.AssertTrue((0)=(FList.Count), 'Count after clear');
end;

procedure TWatchListTests.TestAddAfterClear;
var
  Idx: Integer;
begin
  FList.AddWatch('a');
  FList.Clear;
  Idx := FList.AddWatch('a');
  TestContext.AssertTrue((0)=(Idx), 'Add after clear returns 0');
  TestContext.AssertTrue((1)=(FList.Count), 'Count is 1 after add after clear');
end;



constructor TWatchListTests.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTWatchListTestsTestEmptyListHasCountZero(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestEmptyListHasCountZero');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyListHasCountZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddWatchIncreasesCount(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestAddWatchIncreasesCount');
  try
    lFixture.SetUp;
    try lFixture.TestAddWatchIncreasesCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddWatchReturnsIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestAddWatchReturnsIndex');
  try
    lFixture.SetUp;
    try lFixture.TestAddWatchReturnsIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddDuplicateReturnsExistingIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestAddDuplicateReturnsExistingIndex');
  try
    lFixture.SetUp;
    try lFixture.TestAddDuplicateReturnsExistingIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddDuplicateCaseSensitive(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestAddDuplicateCaseSensitive');
  try
    lFixture.SetUp;
    try lFixture.TestAddDuplicateCaseSensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestExpressionByIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestExpressionByIndex');
  try
    lFixture.SetUp;
    try lFixture.TestExpressionByIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestExpressionOutOfRangeReturnsEmpty(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestExpressionOutOfRangeReturnsEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestExpressionOutOfRangeReturnsEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchDecreasesCount(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestRemoveWatchDecreasesCount');
  try
    lFixture.SetUp;
    try lFixture.TestRemoveWatchDecreasesCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchShiftsEntries(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestRemoveWatchShiftsEntries');
  try
    lFixture.SetUp;
    try lFixture.TestRemoveWatchShiftsEntries; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchOutOfRangeIsHarmless(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestRemoveWatchOutOfRangeIsHarmless');
  try
    lFixture.SetUp;
    try lFixture.TestRemoveWatchOutOfRangeIsHarmless; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfFindsExistingEntry(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestIndexOfFindsExistingEntry');
  try
    lFixture.SetUp;
    try lFixture.TestIndexOfFindsExistingEntry; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfReturnsMinus1WhenMissing(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestIndexOfReturnsMinus1WhenMissing');
  try
    lFixture.SetUp;
    try lFixture.TestIndexOfReturnsMinus1WhenMissing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfIsCaseSensitive(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestIndexOfIsCaseSensitive');
  try
    lFixture.SetUp;
    try lFixture.TestIndexOfIsCaseSensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestGetExpressionsMatchesList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestGetExpressionsMatchesList');
  try
    lFixture.SetUp;
    try lFixture.TestGetExpressionsMatchesList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestGetExpressionsEmptyList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestGetExpressionsEmptyList');
  try
    lFixture.SetUp;
    try lFixture.TestGetExpressionsEmptyList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressions(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestLoadExpressions');
  try
    lFixture.SetUp;
    try lFixture.TestLoadExpressions; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressionsDeduplicate(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestLoadExpressionsDeduplicate');
  try
    lFixture.SetUp;
    try lFixture.TestLoadExpressionsDeduplicate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressionsSkipsEmpty(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestLoadExpressionsSkipsEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadExpressionsSkipsEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestClearEmptiesList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestClearEmptiesList');
  try
    lFixture.SetUp;
    try lFixture.TestClearEmptiesList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddAfterClear(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create(AContext, 'TestAddAfterClear');
  try
    lFixture.SetUp;
    try lFixture.TestAddAfterClear; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestwatchesTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.watches.TWatchListTests');
  lSuite.AddTest('TestEmptyListHasCountZero', @RunTWatchListTestsTestEmptyListHasCountZero);
  lSuite.AddTest('TestAddWatchIncreasesCount', @RunTWatchListTestsTestAddWatchIncreasesCount);
  lSuite.AddTest('TestAddWatchReturnsIndex', @RunTWatchListTestsTestAddWatchReturnsIndex);
  lSuite.AddTest('TestAddDuplicateReturnsExistingIndex', @RunTWatchListTestsTestAddDuplicateReturnsExistingIndex);
  lSuite.AddTest('TestAddDuplicateCaseSensitive', @RunTWatchListTestsTestAddDuplicateCaseSensitive);
  lSuite.AddTest('TestExpressionByIndex', @RunTWatchListTestsTestExpressionByIndex);
  lSuite.AddTest('TestExpressionOutOfRangeReturnsEmpty', @RunTWatchListTestsTestExpressionOutOfRangeReturnsEmpty);
  lSuite.AddTest('TestRemoveWatchDecreasesCount', @RunTWatchListTestsTestRemoveWatchDecreasesCount);
  lSuite.AddTest('TestRemoveWatchShiftsEntries', @RunTWatchListTestsTestRemoveWatchShiftsEntries);
  lSuite.AddTest('TestRemoveWatchOutOfRangeIsHarmless', @RunTWatchListTestsTestRemoveWatchOutOfRangeIsHarmless);
  lSuite.AddTest('TestIndexOfFindsExistingEntry', @RunTWatchListTestsTestIndexOfFindsExistingEntry);
  lSuite.AddTest('TestIndexOfReturnsMinus1WhenMissing', @RunTWatchListTestsTestIndexOfReturnsMinus1WhenMissing);
  lSuite.AddTest('TestIndexOfIsCaseSensitive', @RunTWatchListTestsTestIndexOfIsCaseSensitive);
  lSuite.AddTest('TestGetExpressionsMatchesList', @RunTWatchListTestsTestGetExpressionsMatchesList);
  lSuite.AddTest('TestGetExpressionsEmptyList', @RunTWatchListTestsTestGetExpressionsEmptyList);
  lSuite.AddTest('TestLoadExpressions', @RunTWatchListTestsTestLoadExpressions);
  lSuite.AddTest('TestLoadExpressionsDeduplicate', @RunTWatchListTestsTestLoadExpressionsDeduplicate);
  lSuite.AddTest('TestLoadExpressionsSkipsEmpty', @RunTWatchListTestsTestLoadExpressionsSkipsEmpty);
  lSuite.AddTest('TestClearEmptiesList', @RunTWatchListTestsTestClearEmptiesList);
  lSuite.AddTest('TestAddAfterClear', @RunTWatchListTestsTestAddAfterClear);
end;

end.

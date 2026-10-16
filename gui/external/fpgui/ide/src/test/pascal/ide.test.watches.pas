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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue((0)=(FList.Count), 'Empty list count');
end;

procedure TWatchListTests.TestAddWatchIncreasesCount;
begin
  FList.AddWatch('myVar');
  FContext.AssertTrue((1)=(FList.Count), 'Count after add');
  FList.AddWatch('otherVar');
  FContext.AssertTrue((2)=(FList.Count), 'Count after second add');
end;

procedure TWatchListTests.TestAddWatchReturnsIndex;
var
  Idx: Integer;
begin
  Idx := FList.AddWatch('x');
  FContext.AssertTrue((0)=(Idx), 'First add returns 0');
  Idx := FList.AddWatch('y');
  FContext.AssertTrue((1)=(Idx), 'Second add returns 1');
end;

procedure TWatchListTests.TestAddDuplicateReturnsExistingIndex;
var
  Idx1, Idx2: Integer;
begin
  Idx1 := FList.AddWatch('SomeExpr');
  Idx2 := FList.AddWatch('SomeExpr');
  FContext.AssertTrue((Idx1)=(Idx2), 'Duplicate add returns same index');
  FContext.AssertTrue((1)=(FList.Count), 'Count unchanged after duplicate');
end;

procedure TWatchListTests.TestAddDuplicateCaseSensitive;
var
  Idx1, Idx2: Integer;
begin
  Idx1 := FList.AddWatch('myVar');
  Idx2 := FList.AddWatch('MyVar');
  FContext.AssertTrue(Idx1 <> Idx2, 'Different case adds separate entry');
  FContext.AssertTrue((2)=(FList.Count), 'Two entries after case-different adds');
end;

procedure TWatchListTests.TestExpressionByIndex;
begin
  FList.AddWatch('alpha');
  FList.AddWatch('beta');
  FContext.AssertTrue(('alpha')=(FList.Expression[0]), 'Expression at 0');
  FContext.AssertTrue(('beta')=(FList.Expression[1]), 'Expression at 1');
end;

procedure TWatchListTests.TestExpressionOutOfRangeReturnsEmpty;
begin
  FList.AddWatch('x');
  FContext.AssertTrue(('')=(FList.Expression[-1]), 'Negative index');
  FContext.AssertTrue(('')=(FList.Expression[99]), 'Out-of-bounds index');
end;

procedure TWatchListTests.TestRemoveWatchDecreasesCount;
begin
  FList.AddWatch('a');
  FList.AddWatch('b');
  FList.RemoveWatch(0);
  FContext.AssertTrue((1)=(FList.Count), 'Count after remove');
end;

procedure TWatchListTests.TestRemoveWatchShiftsEntries;
begin
  FList.AddWatch('first');
  FList.AddWatch('second');
  FList.AddWatch('third');
  FList.RemoveWatch(0);
  FContext.AssertTrue(('second')=(FList.Expression[0]), 'After removing 0, index 0 becomes second');
  FContext.AssertTrue(('third')=(FList.Expression[1]), 'After removing 0, index 1 becomes third');
end;

procedure TWatchListTests.TestRemoveWatchOutOfRangeIsHarmless;
begin
  FList.AddWatch('x');
  FList.RemoveWatch(-1);
  FList.RemoveWatch(99);
  FContext.AssertTrue((1)=(FList.Count), 'Count unchanged after invalid removes');
end;

procedure TWatchListTests.TestIndexOfFindsExistingEntry;
begin
  FList.AddWatch('alpha');
  FList.AddWatch('beta');
  FContext.AssertTrue((0)=(FList.IndexOf('alpha')), 'IndexOf alpha');
  FContext.AssertTrue((1)=(FList.IndexOf('beta')), 'IndexOf beta');
end;

procedure TWatchListTests.TestIndexOfReturnsMinus1WhenMissing;
begin
  FList.AddWatch('alpha');
  FContext.AssertTrue((-1)=(FList.IndexOf('gamma')), 'IndexOf missing');
end;

procedure TWatchListTests.TestIndexOfIsCaseSensitive;
begin
  FList.AddWatch('myVar');
  FContext.AssertTrue((0)=(FList.IndexOf('myVar')), 'Exact case found');
  FContext.AssertTrue((-1)=(FList.IndexOf('myvar')), 'Different case not found');
  FContext.AssertTrue((-1)=(FList.IndexOf('MYVAR')), 'Upper case not found');
end;

procedure TWatchListTests.TestGetExpressionsMatchesList;
var
  Exprs: TStringArray;
begin
  FList.AddWatch('a');
  FList.AddWatch('b.field');
  FList.AddWatch('arr[0]');
  Exprs := FList.GetExpressions;
  FContext.AssertTrue((3)=(Length(Exprs)), 'Array length');
  FContext.AssertTrue(('a')=(Exprs[0]), 'Expr 0');
  FContext.AssertTrue(('b.field')=(Exprs[1]), 'Expr 1');
  FContext.AssertTrue(('arr[0]')=(Exprs[2]), 'Expr 2');
end;

procedure TWatchListTests.TestGetExpressionsEmptyList;
var
  Exprs: TStringArray;
begin
  Exprs := FList.GetExpressions;
  FContext.AssertTrue((0)=(Length(Exprs)), 'Empty list returns empty array');
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
  FContext.AssertTrue((3)=(FList.Count), 'Count after load');
  FContext.AssertTrue(('x')=(FList.Expression[0]), 'Expr 0');
  FContext.AssertTrue(('y')=(FList.Expression[1]), 'Expr 1');
  FContext.AssertTrue(('z')=(FList.Expression[2]), 'Expr 2');
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
  FContext.AssertTrue((2)=(FList.Count), 'Deduplicates on load');
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
  FContext.AssertTrue((2)=(FList.Count), 'Empty string skipped on load');
end;

procedure TWatchListTests.TestClearEmptiesList;
begin
  FList.AddWatch('a');
  FList.AddWatch('b');
  FList.Clear;
  FContext.AssertTrue((0)=(FList.Count), 'Count after clear');
end;

procedure TWatchListTests.TestAddAfterClear;
var
  Idx: Integer;
begin
  FList.AddWatch('a');
  FList.Clear;
  Idx := FList.AddWatch('a');
  FContext.AssertTrue((0)=(Idx), 'Add after clear returns 0');
  FContext.AssertTrue((1)=(FList.Count), 'Count is 1 after add after clear');
end;



procedure RunTWatchListTestsTestEmptyListHasCountZero(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyListHasCountZero';
    lFixture.SetUp;
    try lFixture.TestEmptyListHasCountZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddWatchIncreasesCount(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddWatchIncreasesCount';
    lFixture.SetUp;
    try lFixture.TestAddWatchIncreasesCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddWatchReturnsIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddWatchReturnsIndex';
    lFixture.SetUp;
    try lFixture.TestAddWatchReturnsIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddDuplicateReturnsExistingIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddDuplicateReturnsExistingIndex';
    lFixture.SetUp;
    try lFixture.TestAddDuplicateReturnsExistingIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddDuplicateCaseSensitive(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddDuplicateCaseSensitive';
    lFixture.SetUp;
    try lFixture.TestAddDuplicateCaseSensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestExpressionByIndex(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExpressionByIndex';
    lFixture.SetUp;
    try lFixture.TestExpressionByIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestExpressionOutOfRangeReturnsEmpty(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExpressionOutOfRangeReturnsEmpty';
    lFixture.SetUp;
    try lFixture.TestExpressionOutOfRangeReturnsEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchDecreasesCount(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveWatchDecreasesCount';
    lFixture.SetUp;
    try lFixture.TestRemoveWatchDecreasesCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchShiftsEntries(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveWatchShiftsEntries';
    lFixture.SetUp;
    try lFixture.TestRemoveWatchShiftsEntries; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestRemoveWatchOutOfRangeIsHarmless(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveWatchOutOfRangeIsHarmless';
    lFixture.SetUp;
    try lFixture.TestRemoveWatchOutOfRangeIsHarmless; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfFindsExistingEntry(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIndexOfFindsExistingEntry';
    lFixture.SetUp;
    try lFixture.TestIndexOfFindsExistingEntry; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfReturnsMinus1WhenMissing(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIndexOfReturnsMinus1WhenMissing';
    lFixture.SetUp;
    try lFixture.TestIndexOfReturnsMinus1WhenMissing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestIndexOfIsCaseSensitive(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIndexOfIsCaseSensitive';
    lFixture.SetUp;
    try lFixture.TestIndexOfIsCaseSensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestGetExpressionsMatchesList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetExpressionsMatchesList';
    lFixture.SetUp;
    try lFixture.TestGetExpressionsMatchesList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestGetExpressionsEmptyList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetExpressionsEmptyList';
    lFixture.SetUp;
    try lFixture.TestGetExpressionsEmptyList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressions(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoadExpressions';
    lFixture.SetUp;
    try lFixture.TestLoadExpressions; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressionsDeduplicate(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoadExpressionsDeduplicate';
    lFixture.SetUp;
    try lFixture.TestLoadExpressionsDeduplicate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestLoadExpressionsSkipsEmpty(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoadExpressionsSkipsEmpty';
    lFixture.SetUp;
    try lFixture.TestLoadExpressionsSkipsEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestClearEmptiesList(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearEmptiesList';
    lFixture.SetUp;
    try lFixture.TestClearEmptiesList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTWatchListTestsTestAddAfterClear(AContext: TNXTestContext);
var lFixture: TWatchListTests;
begin
  lFixture:=TWatchListTests.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddAfterClear';
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

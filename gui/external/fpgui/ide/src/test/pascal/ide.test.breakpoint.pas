{
    fpGUI IDE - Breakpoint Tests

    Tests for TBreakpointList — toggle, query, persistence, and handle
    management.
}
unit ide.test.breakpoint;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.breakpoint;

type

  { TTestBreakpointList }

  TTestBreakpointList = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FBP: TBreakpointList;
    FTempFile: String;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Toggle }
    procedure TestToggleAddsBreakpoint;
    procedure TestToggleExistingRemovesIt;
    procedure TestToggleTwiceResultsInNoBreakpoint;
    procedure TestToggleTwiceCountIsZero;

    { HasBreakpoint / FindIndex }
    procedure TestHasBreakpointFalseOnEmpty;
    procedure TestHasBreakpointTrueAfterAdd;
    procedure TestHasBreakpointFalseAfterRemove;
    procedure TestFindIndexMinusOneWhenMissing;
    procedure TestFindIndexCorrectAfterAdd;

    { Count }
    procedure TestCountZeroOnEmpty;
    procedure TestCountOneAfterAdd;
    procedure TestCountZeroAfterRemove;
    procedure TestCountTwoAfterTwoAdds;

    { GetItem }
    procedure TestGetItemFileName;
    procedure TestGetItemLine;
    procedure TestGetItemEnabledByDefault;
    procedure TestGetItemHandleMinusOne;

    { Filename matching — basename only }
    procedure TestMatchByBasename;
    procedure TestNoMatchDifferentBasename;

    { Multiple breakpoints }
    procedure TestTwoBreakpointsSameFile;
    procedure TestTwoBreakpointsDifferentFiles;
    procedure TestRemoveFirstKeepsSecond;
    procedure TestRemoveSecondKeepsFirst;

    { Handle management }
    procedure TestSetHandle;
    procedure TestClearHandles;

    { Clear }
    procedure TestClearResetsCount;
    procedure TestClearAllowsReAdd;

    { Persistence }
    procedure TestSaveAndLoadRoundTrip;
    procedure TestLoadNonExistentFileIsNoError;
    procedure TestSaveEmptyList;
    procedure TestLoadIgnoresInvalidEntries;
  end;

procedure RegisteridetestbreakpointTests(ARegistry: TNXTestRegistry);

implementation

{ TTestBreakpointList }

procedure TTestBreakpointList.SetUp;
begin
  FBP := TBreakpointList.Create;
  FTempFile := GetTempFileName + '.json';
end;

procedure TTestBreakpointList.TearDown;
begin
  FBP.Free;
  if FileExists(FTempFile) then
    DeleteFile(FTempFile);
end;

{ Toggle }

procedure TTestBreakpointList.TestToggleAddsBreakpoint;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((1)=(FBP.Count), 'count after add');
end;

procedure TTestBreakpointList.TestToggleExistingRemovesIt;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((0)=(FBP.Count), 'count after remove');
end;

procedure TTestBreakpointList.TestToggleTwiceResultsInNoBreakpoint;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 10)), 'no breakpoint after double-toggle');
end;

procedure TTestBreakpointList.TestToggleTwiceCountIsZero;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((0)=(FBP.Count), 'count zero after double-toggle');
end;

{ HasBreakpoint / FindIndex }

procedure TTestBreakpointList.TestHasBreakpointFalseOnEmpty;
begin
  TestContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 1)), 'empty list');
end;

procedure TTestBreakpointList.TestHasBreakpointTrueAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 42);
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 42), 'has breakpoint');
end;

procedure TTestBreakpointList.TestHasBreakpointFalseAfterRemove;
begin
  FBP.Toggle('/src/foo.pas', 42);
  FBP.Toggle('/src/foo.pas', 42);
  TestContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 42)), 'no breakpoint after remove');
end;

procedure TTestBreakpointList.TestFindIndexMinusOneWhenMissing;
begin
  TestContext.AssertTrue((-1)=(FBP.FindIndex('/src/foo.pas', 1)), '-1 when missing');
end;

procedure TTestBreakpointList.TestFindIndexCorrectAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((0)=(FBP.FindIndex('/src/foo.pas', 10)), 'index 0');
end;

{ Count }

procedure TTestBreakpointList.TestCountZeroOnEmpty;
begin
  TestContext.AssertTrue((0)=(FBP.Count), 'zero on empty');
end;

procedure TTestBreakpointList.TestCountOneAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((1)=(FBP.Count), 'one after add');
end;

procedure TTestBreakpointList.TestCountZeroAfterRemove;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((0)=(FBP.Count), 'zero after remove');
end;

procedure TTestBreakpointList.TestCountTwoAfterTwoAdds;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  TestContext.AssertTrue((2)=(FBP.Count), 'two after two adds');
end;

{ GetItem }

procedure TTestBreakpointList.TestGetItemFileName;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue(('/src/foo.pas')=(FBP.GetItem(0).FileName), 'filename');
end;

procedure TTestBreakpointList.TestGetItemLine;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((10)=(FBP.GetItem(0).Line), 'line');
end;

procedure TTestBreakpointList.TestGetItemEnabledByDefault;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue(FBP.GetItem(0).Enabled, 'enabled by default');
end;

procedure TTestBreakpointList.TestGetItemHandleMinusOne;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((-1)=(FBP.GetItem(0).Handle), 'handle -1 by default');
end;

{ Filename matching — basename only }

procedure TTestBreakpointList.TestMatchByBasename;
begin
  FBP.Toggle('/project/src/foo.pas', 10);
  TestContext.AssertTrue(FBP.HasBreakpoint('/other/path/foo.pas', 10), 'basename match from different path');
end;

procedure TTestBreakpointList.TestNoMatchDifferentBasename;
begin
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue(not (FBP.HasBreakpoint('/src/bar.pas', 10)), 'no match for different basename');
end;

{ Multiple breakpoints }

procedure TTestBreakpointList.TestTwoBreakpointsSameFile;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'line 10');
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 20), 'line 20');
end;

procedure TTestBreakpointList.TestTwoBreakpointsDifferentFiles;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/bar.pas', 10);
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'foo.pas');
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/bar.pas', 10), 'bar.pas');
end;

procedure TTestBreakpointList.TestRemoveFirstKeepsSecond;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Toggle('/src/foo.pas', 10);  { remove first }
  TestContext.AssertTrue((1)=(FBP.Count), 'count 1');
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 20), 'line 20 still present');
end;

procedure TTestBreakpointList.TestRemoveSecondKeepsFirst;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Toggle('/src/foo.pas', 20);  { remove second }
  TestContext.AssertTrue((1)=(FBP.Count), 'count 1');
  TestContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'line 10 still present');
end;

{ Handle management }

procedure TTestBreakpointList.TestSetHandle;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.SetHandle(0, 42);
  TestContext.AssertTrue((42)=(FBP.GetItem(0).Handle), 'handle updated');
end;

procedure TTestBreakpointList.TestClearHandles;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.SetHandle(0, 1);
  FBP.SetHandle(1, 2);
  FBP.ClearHandles;
  TestContext.AssertTrue((-1)=(FBP.GetItem(0).Handle), 'handle 0 cleared');
  TestContext.AssertTrue((-1)=(FBP.GetItem(1).Handle), 'handle 1 cleared');
end;

{ Clear }

procedure TTestBreakpointList.TestClearResetsCount;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Clear;
  TestContext.AssertTrue((0)=(FBP.Count), 'count zero after clear');
end;

procedure TTestBreakpointList.TestClearAllowsReAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Clear;
  FBP.Toggle('/src/foo.pas', 10);
  TestContext.AssertTrue((1)=(FBP.Count), 'count 1 after re-add');
end;

{ Persistence }

procedure TTestBreakpointList.TestSaveAndLoadRoundTrip;
var
  BPLoad: TBreakpointList;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/bar.pas', 42);
  FBP.SaveToFile(FTempFile);

  BPLoad := TBreakpointList.Create;
  try
    BPLoad.LoadFromFile(FTempFile);
    TestContext.AssertTrue((2)=(BPLoad.Count), 'count');
    TestContext.AssertTrue(BPLoad.HasBreakpoint('/src/foo.pas', 10), 'foo.pas:10');
    TestContext.AssertTrue(BPLoad.HasBreakpoint('/src/bar.pas', 42), 'bar.pas:42');
  finally
    BPLoad.Free;
  end;
end;

procedure TTestBreakpointList.TestLoadNonExistentFileIsNoError;
begin
  FBP.LoadFromFile('/nonexistent/path/breakpoints.json');
  TestContext.AssertTrue((0)=(FBP.Count), 'count zero');
end;

procedure TTestBreakpointList.TestSaveEmptyList;
var
  BPLoad: TBreakpointList;
begin
  FBP.SaveToFile(FTempFile);
  BPLoad := TBreakpointList.Create;
  try
    BPLoad.LoadFromFile(FTempFile);
    TestContext.AssertTrue((0)=(BPLoad.Count), 'count zero after loading empty');
  finally
    BPLoad.Free;
  end;
end;

procedure TTestBreakpointList.TestLoadIgnoresInvalidEntries;
var
  FS: TFileStream;
  S: String;
  BPLoad: TBreakpointList;
begin
  { Write JSON with one valid and one invalid (no file) entry }
  S := '[{"file":"/src/foo.pas","line":10,"enabled":true},{"line":5}]';
  FS := TFileStream.Create(FTempFile, fmCreate);
  try
    FS.Write(S[1], Length(S));
  finally
    FS.Free;
  end;

  BPLoad := TBreakpointList.Create;
  try
    BPLoad.LoadFromFile(FTempFile);
    TestContext.AssertTrue((1)=(BPLoad.Count), 'only valid entry loaded');
    TestContext.AssertTrue(BPLoad.HasBreakpoint('/src/foo.pas', 10), 'foo.pas:10 present');
  finally
    BPLoad.Free;
  end;
end;



constructor TTestBreakpointList.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBreakpointListTestToggleAddsBreakpoint(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestToggleAddsBreakpoint');
  try
    lFixture.SetUp;
    try lFixture.TestToggleAddsBreakpoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleExistingRemovesIt(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestToggleExistingRemovesIt');
  try
    lFixture.SetUp;
    try lFixture.TestToggleExistingRemovesIt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleTwiceResultsInNoBreakpoint(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestToggleTwiceResultsInNoBreakpoint');
  try
    lFixture.SetUp;
    try lFixture.TestToggleTwiceResultsInNoBreakpoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleTwiceCountIsZero(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestToggleTwiceCountIsZero');
  try
    lFixture.SetUp;
    try lFixture.TestToggleTwiceCountIsZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointFalseOnEmpty(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestHasBreakpointFalseOnEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestHasBreakpointFalseOnEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointTrueAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestHasBreakpointTrueAfterAdd');
  try
    lFixture.SetUp;
    try lFixture.TestHasBreakpointTrueAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointFalseAfterRemove(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestHasBreakpointFalseAfterRemove');
  try
    lFixture.SetUp;
    try lFixture.TestHasBreakpointFalseAfterRemove; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestFindIndexMinusOneWhenMissing(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestFindIndexMinusOneWhenMissing');
  try
    lFixture.SetUp;
    try lFixture.TestFindIndexMinusOneWhenMissing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestFindIndexCorrectAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestFindIndexCorrectAfterAdd');
  try
    lFixture.SetUp;
    try lFixture.TestFindIndexCorrectAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountZeroOnEmpty(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestCountZeroOnEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestCountZeroOnEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountOneAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestCountOneAfterAdd');
  try
    lFixture.SetUp;
    try lFixture.TestCountOneAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountZeroAfterRemove(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestCountZeroAfterRemove');
  try
    lFixture.SetUp;
    try lFixture.TestCountZeroAfterRemove; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountTwoAfterTwoAdds(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestCountTwoAfterTwoAdds');
  try
    lFixture.SetUp;
    try lFixture.TestCountTwoAfterTwoAdds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemFileName(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestGetItemFileName');
  try
    lFixture.SetUp;
    try lFixture.TestGetItemFileName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemLine(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestGetItemLine');
  try
    lFixture.SetUp;
    try lFixture.TestGetItemLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemEnabledByDefault(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestGetItemEnabledByDefault');
  try
    lFixture.SetUp;
    try lFixture.TestGetItemEnabledByDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemHandleMinusOne(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestGetItemHandleMinusOne');
  try
    lFixture.SetUp;
    try lFixture.TestGetItemHandleMinusOne; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestMatchByBasename(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestMatchByBasename');
  try
    lFixture.SetUp;
    try lFixture.TestMatchByBasename; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestNoMatchDifferentBasename(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestNoMatchDifferentBasename');
  try
    lFixture.SetUp;
    try lFixture.TestNoMatchDifferentBasename; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestTwoBreakpointsSameFile(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestTwoBreakpointsSameFile');
  try
    lFixture.SetUp;
    try lFixture.TestTwoBreakpointsSameFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestTwoBreakpointsDifferentFiles(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestTwoBreakpointsDifferentFiles');
  try
    lFixture.SetUp;
    try lFixture.TestTwoBreakpointsDifferentFiles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestRemoveFirstKeepsSecond(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestRemoveFirstKeepsSecond');
  try
    lFixture.SetUp;
    try lFixture.TestRemoveFirstKeepsSecond; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestRemoveSecondKeepsFirst(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestRemoveSecondKeepsFirst');
  try
    lFixture.SetUp;
    try lFixture.TestRemoveSecondKeepsFirst; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSetHandle(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestSetHandle');
  try
    lFixture.SetUp;
    try lFixture.TestSetHandle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearHandles(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestClearHandles');
  try
    lFixture.SetUp;
    try lFixture.TestClearHandles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearResetsCount(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestClearResetsCount');
  try
    lFixture.SetUp;
    try lFixture.TestClearResetsCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearAllowsReAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestClearAllowsReAdd');
  try
    lFixture.SetUp;
    try lFixture.TestClearAllowsReAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSaveAndLoadRoundTrip(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestSaveAndLoadRoundTrip');
  try
    lFixture.SetUp;
    try lFixture.TestSaveAndLoadRoundTrip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestLoadNonExistentFileIsNoError(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestLoadNonExistentFileIsNoError');
  try
    lFixture.SetUp;
    try lFixture.TestLoadNonExistentFileIsNoError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSaveEmptyList(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestSaveEmptyList');
  try
    lFixture.SetUp;
    try lFixture.TestSaveEmptyList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestLoadIgnoresInvalidEntries(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create(AContext, 'TestLoadIgnoresInvalidEntries');
  try
    lFixture.SetUp;
    try lFixture.TestLoadIgnoresInvalidEntries; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestbreakpointTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.breakpoint.TTestBreakpointList');
  lSuite.AddTest('TestToggleAddsBreakpoint', @RunTTestBreakpointListTestToggleAddsBreakpoint);
  lSuite.AddTest('TestToggleExistingRemovesIt', @RunTTestBreakpointListTestToggleExistingRemovesIt);
  lSuite.AddTest('TestToggleTwiceResultsInNoBreakpoint', @RunTTestBreakpointListTestToggleTwiceResultsInNoBreakpoint);
  lSuite.AddTest('TestToggleTwiceCountIsZero', @RunTTestBreakpointListTestToggleTwiceCountIsZero);
  lSuite.AddTest('TestHasBreakpointFalseOnEmpty', @RunTTestBreakpointListTestHasBreakpointFalseOnEmpty);
  lSuite.AddTest('TestHasBreakpointTrueAfterAdd', @RunTTestBreakpointListTestHasBreakpointTrueAfterAdd);
  lSuite.AddTest('TestHasBreakpointFalseAfterRemove', @RunTTestBreakpointListTestHasBreakpointFalseAfterRemove);
  lSuite.AddTest('TestFindIndexMinusOneWhenMissing', @RunTTestBreakpointListTestFindIndexMinusOneWhenMissing);
  lSuite.AddTest('TestFindIndexCorrectAfterAdd', @RunTTestBreakpointListTestFindIndexCorrectAfterAdd);
  lSuite.AddTest('TestCountZeroOnEmpty', @RunTTestBreakpointListTestCountZeroOnEmpty);
  lSuite.AddTest('TestCountOneAfterAdd', @RunTTestBreakpointListTestCountOneAfterAdd);
  lSuite.AddTest('TestCountZeroAfterRemove', @RunTTestBreakpointListTestCountZeroAfterRemove);
  lSuite.AddTest('TestCountTwoAfterTwoAdds', @RunTTestBreakpointListTestCountTwoAfterTwoAdds);
  lSuite.AddTest('TestGetItemFileName', @RunTTestBreakpointListTestGetItemFileName);
  lSuite.AddTest('TestGetItemLine', @RunTTestBreakpointListTestGetItemLine);
  lSuite.AddTest('TestGetItemEnabledByDefault', @RunTTestBreakpointListTestGetItemEnabledByDefault);
  lSuite.AddTest('TestGetItemHandleMinusOne', @RunTTestBreakpointListTestGetItemHandleMinusOne);
  lSuite.AddTest('TestMatchByBasename', @RunTTestBreakpointListTestMatchByBasename);
  lSuite.AddTest('TestNoMatchDifferentBasename', @RunTTestBreakpointListTestNoMatchDifferentBasename);
  lSuite.AddTest('TestTwoBreakpointsSameFile', @RunTTestBreakpointListTestTwoBreakpointsSameFile);
  lSuite.AddTest('TestTwoBreakpointsDifferentFiles', @RunTTestBreakpointListTestTwoBreakpointsDifferentFiles);
  lSuite.AddTest('TestRemoveFirstKeepsSecond', @RunTTestBreakpointListTestRemoveFirstKeepsSecond);
  lSuite.AddTest('TestRemoveSecondKeepsFirst', @RunTTestBreakpointListTestRemoveSecondKeepsFirst);
  lSuite.AddTest('TestSetHandle', @RunTTestBreakpointListTestSetHandle);
  lSuite.AddTest('TestClearHandles', @RunTTestBreakpointListTestClearHandles);
  lSuite.AddTest('TestClearResetsCount', @RunTTestBreakpointListTestClearResetsCount);
  lSuite.AddTest('TestClearAllowsReAdd', @RunTTestBreakpointListTestClearAllowsReAdd);
  lSuite.AddTest('TestSaveAndLoadRoundTrip', @RunTTestBreakpointListTestSaveAndLoadRoundTrip);
  lSuite.AddTest('TestLoadNonExistentFileIsNoError', @RunTTestBreakpointListTestLoadNonExistentFileIsNoError);
  lSuite.AddTest('TestSaveEmptyList', @RunTTestBreakpointListTestSaveEmptyList);
  lSuite.AddTest('TestLoadIgnoresInvalidEntries', @RunTTestBreakpointListTestLoadIgnoresInvalidEntries);
end;

end.

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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue((1)=(FBP.Count), 'count after add');
end;

procedure TTestBreakpointList.TestToggleExistingRemovesIt;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((0)=(FBP.Count), 'count after remove');
end;

procedure TTestBreakpointList.TestToggleTwiceResultsInNoBreakpoint;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 10)), 'no breakpoint after double-toggle');
end;

procedure TTestBreakpointList.TestToggleTwiceCountIsZero;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((0)=(FBP.Count), 'count zero after double-toggle');
end;

{ HasBreakpoint / FindIndex }

procedure TTestBreakpointList.TestHasBreakpointFalseOnEmpty;
begin
  FContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 1)), 'empty list');
end;

procedure TTestBreakpointList.TestHasBreakpointTrueAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 42);
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 42), 'has breakpoint');
end;

procedure TTestBreakpointList.TestHasBreakpointFalseAfterRemove;
begin
  FBP.Toggle('/src/foo.pas', 42);
  FBP.Toggle('/src/foo.pas', 42);
  FContext.AssertTrue(not (FBP.HasBreakpoint('/src/foo.pas', 42)), 'no breakpoint after remove');
end;

procedure TTestBreakpointList.TestFindIndexMinusOneWhenMissing;
begin
  FContext.AssertTrue((-1)=(FBP.FindIndex('/src/foo.pas', 1)), '-1 when missing');
end;

procedure TTestBreakpointList.TestFindIndexCorrectAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((0)=(FBP.FindIndex('/src/foo.pas', 10)), 'index 0');
end;

{ Count }

procedure TTestBreakpointList.TestCountZeroOnEmpty;
begin
  FContext.AssertTrue((0)=(FBP.Count), 'zero on empty');
end;

procedure TTestBreakpointList.TestCountOneAfterAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((1)=(FBP.Count), 'one after add');
end;

procedure TTestBreakpointList.TestCountZeroAfterRemove;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((0)=(FBP.Count), 'zero after remove');
end;

procedure TTestBreakpointList.TestCountTwoAfterTwoAdds;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FContext.AssertTrue((2)=(FBP.Count), 'two after two adds');
end;

{ GetItem }

procedure TTestBreakpointList.TestGetItemFileName;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue(('/src/foo.pas')=(FBP.GetItem(0).FileName), 'filename');
end;

procedure TTestBreakpointList.TestGetItemLine;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((10)=(FBP.GetItem(0).Line), 'line');
end;

procedure TTestBreakpointList.TestGetItemEnabledByDefault;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue(FBP.GetItem(0).Enabled, 'enabled by default');
end;

procedure TTestBreakpointList.TestGetItemHandleMinusOne;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((-1)=(FBP.GetItem(0).Handle), 'handle -1 by default');
end;

{ Filename matching — basename only }

procedure TTestBreakpointList.TestMatchByBasename;
begin
  FBP.Toggle('/project/src/foo.pas', 10);
  FContext.AssertTrue(FBP.HasBreakpoint('/other/path/foo.pas', 10), 'basename match from different path');
end;

procedure TTestBreakpointList.TestNoMatchDifferentBasename;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue(not (FBP.HasBreakpoint('/src/bar.pas', 10)), 'no match for different basename');
end;

{ Multiple breakpoints }

procedure TTestBreakpointList.TestTwoBreakpointsSameFile;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'line 10');
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 20), 'line 20');
end;

procedure TTestBreakpointList.TestTwoBreakpointsDifferentFiles;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/bar.pas', 10);
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'foo.pas');
  FContext.AssertTrue(FBP.HasBreakpoint('/src/bar.pas', 10), 'bar.pas');
end;

procedure TTestBreakpointList.TestRemoveFirstKeepsSecond;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Toggle('/src/foo.pas', 10);  { remove first }
  FContext.AssertTrue((1)=(FBP.Count), 'count 1');
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 20), 'line 20 still present');
end;

procedure TTestBreakpointList.TestRemoveSecondKeepsFirst;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Toggle('/src/foo.pas', 20);  { remove second }
  FContext.AssertTrue((1)=(FBP.Count), 'count 1');
  FContext.AssertTrue(FBP.HasBreakpoint('/src/foo.pas', 10), 'line 10 still present');
end;

{ Handle management }

procedure TTestBreakpointList.TestSetHandle;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.SetHandle(0, 42);
  FContext.AssertTrue((42)=(FBP.GetItem(0).Handle), 'handle updated');
end;

procedure TTestBreakpointList.TestClearHandles;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.SetHandle(0, 1);
  FBP.SetHandle(1, 2);
  FBP.ClearHandles;
  FContext.AssertTrue((-1)=(FBP.GetItem(0).Handle), 'handle 0 cleared');
  FContext.AssertTrue((-1)=(FBP.GetItem(1).Handle), 'handle 1 cleared');
end;

{ Clear }

procedure TTestBreakpointList.TestClearResetsCount;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Toggle('/src/foo.pas', 20);
  FBP.Clear;
  FContext.AssertTrue((0)=(FBP.Count), 'count zero after clear');
end;

procedure TTestBreakpointList.TestClearAllowsReAdd;
begin
  FBP.Toggle('/src/foo.pas', 10);
  FBP.Clear;
  FBP.Toggle('/src/foo.pas', 10);
  FContext.AssertTrue((1)=(FBP.Count), 'count 1 after re-add');
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
    FContext.AssertTrue((2)=(BPLoad.Count), 'count');
    FContext.AssertTrue(BPLoad.HasBreakpoint('/src/foo.pas', 10), 'foo.pas:10');
    FContext.AssertTrue(BPLoad.HasBreakpoint('/src/bar.pas', 42), 'bar.pas:42');
  finally
    BPLoad.Free;
  end;
end;

procedure TTestBreakpointList.TestLoadNonExistentFileIsNoError;
begin
  FBP.LoadFromFile('/nonexistent/path/breakpoints.json');
  FContext.AssertTrue((0)=(FBP.Count), 'count zero');
end;

procedure TTestBreakpointList.TestSaveEmptyList;
var
  BPLoad: TBreakpointList;
begin
  FBP.SaveToFile(FTempFile);
  BPLoad := TBreakpointList.Create;
  try
    BPLoad.LoadFromFile(FTempFile);
    FContext.AssertTrue((0)=(BPLoad.Count), 'count zero after loading empty');
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
    FContext.AssertTrue((1)=(BPLoad.Count), 'only valid entry loaded');
    FContext.AssertTrue(BPLoad.HasBreakpoint('/src/foo.pas', 10), 'foo.pas:10 present');
  finally
    BPLoad.Free;
  end;
end;



procedure RunTTestBreakpointListTestToggleAddsBreakpoint(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestToggleAddsBreakpoint';
    lFixture.SetUp;
    try lFixture.TestToggleAddsBreakpoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleExistingRemovesIt(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestToggleExistingRemovesIt';
    lFixture.SetUp;
    try lFixture.TestToggleExistingRemovesIt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleTwiceResultsInNoBreakpoint(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestToggleTwiceResultsInNoBreakpoint';
    lFixture.SetUp;
    try lFixture.TestToggleTwiceResultsInNoBreakpoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestToggleTwiceCountIsZero(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestToggleTwiceCountIsZero';
    lFixture.SetUp;
    try lFixture.TestToggleTwiceCountIsZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointFalseOnEmpty(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHasBreakpointFalseOnEmpty';
    lFixture.SetUp;
    try lFixture.TestHasBreakpointFalseOnEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointTrueAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHasBreakpointTrueAfterAdd';
    lFixture.SetUp;
    try lFixture.TestHasBreakpointTrueAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestHasBreakpointFalseAfterRemove(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHasBreakpointFalseAfterRemove';
    lFixture.SetUp;
    try lFixture.TestHasBreakpointFalseAfterRemove; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestFindIndexMinusOneWhenMissing(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFindIndexMinusOneWhenMissing';
    lFixture.SetUp;
    try lFixture.TestFindIndexMinusOneWhenMissing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestFindIndexCorrectAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFindIndexCorrectAfterAdd';
    lFixture.SetUp;
    try lFixture.TestFindIndexCorrectAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountZeroOnEmpty(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCountZeroOnEmpty';
    lFixture.SetUp;
    try lFixture.TestCountZeroOnEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountOneAfterAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCountOneAfterAdd';
    lFixture.SetUp;
    try lFixture.TestCountOneAfterAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountZeroAfterRemove(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCountZeroAfterRemove';
    lFixture.SetUp;
    try lFixture.TestCountZeroAfterRemove; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestCountTwoAfterTwoAdds(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCountTwoAfterTwoAdds';
    lFixture.SetUp;
    try lFixture.TestCountTwoAfterTwoAdds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemFileName(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetItemFileName';
    lFixture.SetUp;
    try lFixture.TestGetItemFileName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemLine(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetItemLine';
    lFixture.SetUp;
    try lFixture.TestGetItemLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemEnabledByDefault(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetItemEnabledByDefault';
    lFixture.SetUp;
    try lFixture.TestGetItemEnabledByDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestGetItemHandleMinusOne(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetItemHandleMinusOne';
    lFixture.SetUp;
    try lFixture.TestGetItemHandleMinusOne; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestMatchByBasename(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMatchByBasename';
    lFixture.SetUp;
    try lFixture.TestMatchByBasename; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestNoMatchDifferentBasename(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoMatchDifferentBasename';
    lFixture.SetUp;
    try lFixture.TestNoMatchDifferentBasename; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestTwoBreakpointsSameFile(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTwoBreakpointsSameFile';
    lFixture.SetUp;
    try lFixture.TestTwoBreakpointsSameFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestTwoBreakpointsDifferentFiles(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTwoBreakpointsDifferentFiles';
    lFixture.SetUp;
    try lFixture.TestTwoBreakpointsDifferentFiles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestRemoveFirstKeepsSecond(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveFirstKeepsSecond';
    lFixture.SetUp;
    try lFixture.TestRemoveFirstKeepsSecond; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestRemoveSecondKeepsFirst(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveSecondKeepsFirst';
    lFixture.SetUp;
    try lFixture.TestRemoveSecondKeepsFirst; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSetHandle(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSetHandle';
    lFixture.SetUp;
    try lFixture.TestSetHandle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearHandles(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearHandles';
    lFixture.SetUp;
    try lFixture.TestClearHandles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearResetsCount(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearResetsCount';
    lFixture.SetUp;
    try lFixture.TestClearResetsCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestClearAllowsReAdd(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearAllowsReAdd';
    lFixture.SetUp;
    try lFixture.TestClearAllowsReAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSaveAndLoadRoundTrip(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSaveAndLoadRoundTrip';
    lFixture.SetUp;
    try lFixture.TestSaveAndLoadRoundTrip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestLoadNonExistentFileIsNoError(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoadNonExistentFileIsNoError';
    lFixture.SetUp;
    try lFixture.TestLoadNonExistentFileIsNoError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestSaveEmptyList(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSaveEmptyList';
    lFixture.SetUp;
    try lFixture.TestSaveEmptyList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestBreakpointListTestLoadIgnoresInvalidEntries(AContext: TNXTestContext);
var lFixture: TTestBreakpointList;
begin
  lFixture:=TTestBreakpointList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoadIgnoresInvalidEntries';
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

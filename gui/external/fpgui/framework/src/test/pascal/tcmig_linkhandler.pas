unit tcmig_linkhandler;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_linkhandler;

type
  TTestMigLinkHandler = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FLayout1: TObject;
    FLayout2: TObject;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestSetAndGetBounds;
    procedure TestMultipleLayouts;
    procedure TestClearBounds;
    procedure TestClearTemporaryBounds;
    procedure TestExpandBounds;
    procedure TestGetValueTypes;
  end;

procedure RegistertcmiglinkhandlerTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigLinkHandler }

procedure TTestMigLinkHandler.SetUp;
begin
  FLayout1 := TObject.Create;
  FLayout2 := TObject.Create;
  TfpgMigLinkHandler.ClearAll;
end;

procedure TTestMigLinkHandler.TearDown;
begin
  TfpgMigLinkHandler.ClearAll;
  FLayout1.Free;
  FLayout2.Free;
end;

procedure TTestMigLinkHandler.TestSetAndGetBounds;
var
  changed: Boolean;
  val: PInteger;
begin
  // Set bounds for a component
  changed := TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 10, 20, 100, 50);
  FContext.AssertTrue(changed, 'First SetBounds should return true');

  // Get X value
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((val)<>nil, 'X value should not be nil');
  FContext.AssertTrue((10)=(val^), 'X value should be 10');
  Dispose(val);

  // Get Y value
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_Y);
  FContext.AssertTrue((val)<>nil, 'Y value should not be nil');
  FContext.AssertTrue((20)=(val^), 'Y value should be 20');
  Dispose(val);

  // Get Width value
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_WIDTH);
  FContext.AssertTrue((val)<>nil, 'Width value should not be nil');
  FContext.AssertTrue((100)=(val^), 'Width value should be 100');
  Dispose(val);

  // Get Height value
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_HEIGHT);
  FContext.AssertTrue((val)<>nil, 'Height value should not be nil');
  FContext.AssertTrue((50)=(val^), 'Height value should be 50');
  Dispose(val);

  // Get X2 value (calculated)
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X2);
  FContext.AssertTrue((val)<>nil, 'X2 value should not be nil');
  FContext.AssertTrue((110)=(val^), 'X2 value should be 110 (10+100)');
  Dispose(val);

  // Get Y2 value (calculated)
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_Y2);
  FContext.AssertTrue((val)<>nil, 'Y2 value should not be nil');
  FContext.AssertTrue((70)=(val^), 'Y2 value should be 70 (20+50)');
  Dispose(val);
end;

procedure TTestMigLinkHandler.TestMultipleLayouts;
var
  val: PInteger;
begin
  // Set bounds in different layouts
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 10, 20, 100, 50);
  TfpgMigLinkHandler.SetBounds(FLayout2, 'comp1', 30, 40, 200, 80);

  // Verify layout1 values
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((10)=(val^), 'Layout1 X should be 10');
  Dispose(val);

  // Verify layout2 values
  val := TfpgMigLinkHandler.GetValue(FLayout2, 'comp1', LINK_X);
  FContext.AssertTrue((30)=(val^), 'Layout2 X should be 30');
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout2, 'comp1', LINK_WIDTH);
  FContext.AssertTrue((200)=(val^), 'Layout2 Width should be 200');
  Dispose(val);
end;

procedure TTestMigLinkHandler.TestClearBounds;
var
  cleared: Boolean;
  val: PInteger;
begin
  // Set then clear
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 10, 20, 100, 50);
  cleared := TfpgMigLinkHandler.ClearBounds(FLayout1, 'comp1');
  FContext.AssertTrue(cleared, 'ClearBounds should return true when clearing existing bounds');

  // Verify it's cleared
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((val)=nil, 'Value should be nil after clearing');

  // Clear non-existent should return false
  cleared := TfpgMigLinkHandler.ClearBounds(FLayout1, 'nonexistent');
  FContext.AssertTrue(not (cleared), 'ClearBounds should return false for non-existent key');
end;

procedure TTestMigLinkHandler.TestClearTemporaryBounds;
var
  val: PInteger;
begin
  // Set permanent bounds
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 10, 20, 100, 50, False, False);

  // Set temporary bounds
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp2', 30, 40, 200, 80, True, False);

  // Clear temporary
  TfpgMigLinkHandler.ClearTemporaryBounds(FLayout1);

  // Permanent should still exist
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((val)<>nil, 'Permanent bounds should still exist');
  FContext.AssertTrue((10)=(val^), 'Permanent X should be 10');
  Dispose(val);

  // Temporary should be gone
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp2', LINK_X);
  FContext.AssertTrue((val)=nil, 'Temporary bounds should be cleared');
end;

procedure TTestMigLinkHandler.TestExpandBounds;
var
  changed: Boolean;
  val: PInteger;
begin
  // Set initial bounds
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 10, 20, 100, 50);

  // Expand bounds (AIncCur = True)
  changed := TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 5, 15, 110, 60, False, True);
  FContext.AssertTrue(changed, 'Expanding bounds should return true');

  // X should be minimum (5 < 10)
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((5)=(val^), 'X should be expanded to 5');
  Dispose(val);

  // Width should expand to cover both ranges
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_WIDTH);
  FContext.AssertTrue((val)<>nil, 'Width should not be nil');
  Dispose(val);
end;

procedure TTestMigLinkHandler.TestGetValueTypes;
var
  val: PInteger;
begin
  TfpgMigLinkHandler.SetBounds(FLayout1, 'comp1', 100, 200, 300, 400);

  // Test all value types
  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X);
  FContext.AssertTrue((100)=(val^), 'LINK_X');
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_Y);
  FContext.AssertTrue((200)=(val^), 'LINK_Y');
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_WIDTH);
  FContext.AssertTrue((300)=(val^), 'LINK_WIDTH');
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_HEIGHT);
  FContext.AssertTrue((400)=(val^), 'LINK_HEIGHT');
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_X2);
  FContext.AssertTrue((400)=(val^), 'LINK_X2');  // 100 + 300
  Dispose(val);

  val := TfpgMigLinkHandler.GetValue(FLayout1, 'comp1', LINK_Y2);
  FContext.AssertTrue((600)=(val^), 'LINK_Y2');  // 200 + 400
  Dispose(val);
end;


procedure RunTTestMigLinkHandlerTestSetAndGetBounds(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSetAndGetBounds';
    lFixture.SetUp;
    try lFixture.TestSetAndGetBounds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLinkHandlerTestMultipleLayouts(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultipleLayouts';
    lFixture.SetUp;
    try lFixture.TestMultipleLayouts; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLinkHandlerTestClearBounds(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearBounds';
    lFixture.SetUp;
    try lFixture.TestClearBounds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLinkHandlerTestClearTemporaryBounds(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClearTemporaryBounds';
    lFixture.SetUp;
    try lFixture.TestClearTemporaryBounds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLinkHandlerTestExpandBounds(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExpandBounds';
    lFixture.SetUp;
    try lFixture.TestExpandBounds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLinkHandlerTestGetValueTypes(AContext: TNXTestContext);
var lFixture: TTestMigLinkHandler;
begin
  lFixture:=TTestMigLinkHandler.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetValueTypes';
    lFixture.SetUp;
    try lFixture.TestGetValueTypes; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcmiglinkhandlerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_linkhandler.TTestMigLinkHandler');
  lSuite.AddTest('TestSetAndGetBounds', @RunTTestMigLinkHandlerTestSetAndGetBounds);
  lSuite.AddTest('TestMultipleLayouts', @RunTTestMigLinkHandlerTestMultipleLayouts);
  lSuite.AddTest('TestClearBounds', @RunTTestMigLinkHandlerTestClearBounds);
  lSuite.AddTest('TestClearTemporaryBounds', @RunTTestMigLinkHandlerTestClearTemporaryBounds);
  lSuite.AddTest('TestExpandBounds', @RunTTestMigLinkHandlerTestExpandBounds);
  lSuite.AddTest('TestGetValueTypes', @RunTTestMigLinkHandlerTestGetValueTypes);
end;

end.

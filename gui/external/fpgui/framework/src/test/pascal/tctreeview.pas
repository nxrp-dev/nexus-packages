unit tcTreeview;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  //TestFramework,
  fpg_tree;

type

  TTestTreeview= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FTree: TfpgTreeview;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestCount;
    procedure TestCountRecursive;
    procedure TestNext;
    procedure TestPrev;
    procedure TestAppendText;
    procedure TestFindSubNode_Text;
  end;


procedure RegistertcTreeviewTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_main;


{ TTestTreeview }

procedure TTestTreeview.SetUp;
begin
    { Initialize fpGUI application once - calling fpgApplication creates it if needed }
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;

  FTree := TfpgTreeview.Create(nil);
end;

procedure TTestTreeview.TearDown;
begin
  FTree.Free;
end;

procedure TTestTreeview.TestCount;
var
  n: TfpgTreeNode;
begin
  TestContext.AssertTrue((0)=(FTree.RootNode.Count), 'Failed on 1');
  FTree.RootNode.AppendText('n1');
  TestContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 2');
  n := FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue((2)=(FTree.RootNode.Count), 'Failed on 3');
  FTree.RootNode.Remove(n);
  TestContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 4');
end;

procedure TTestTreeview.TestCountRecursive;
var
  n1, n2: TfpgTreeNode;
begin
  { root
      |--n1
      |  |--n1.1
      |--n2
         |--n2.1
         |--n2.2
  }
  TestContext.AssertTrue((0)=(FTree.RootNode.CountRecursive), 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  TestContext.AssertTrue((1)=(FTree.RootNode.CountRecursive), 'Failed on 2');
  n2 := FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue((2)=(FTree.RootNode.CountRecursive), 'Failed on 3');
  n2.AppendText('n2.1');
  TestContext.AssertTrue((3)=(FTree.RootNode.CountRecursive), 'Failed on 4');
  n2.AppendText('n2.2');
  TestContext.AssertTrue((4)=(FTree.RootNode.CountRecursive), 'Failed on 5');
  n1.AppendText('n1.1');
  TestContext.AssertTrue((5)=(FTree.RootNode.CountRecursive), 'Failed on 6');
  FTree.RootNode.Remove(n2); // removing 3 nodes
  TestContext.AssertTrue((2)=(FTree.RootNode.CountRecursive), 'Failed on 6');
end;

procedure TTestTreeview.TestNext;
var
  n1, n2: TfpgTreeNode;
begin
  TestContext.AssertTrue(FTree.RootNode.Next = nil, 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  n2 := FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue(n1.Next = n2, 'Failed on 2');
  TestContext.AssertTrue(n2.Next = nil, 'Failed on 3');
  n1.AppendText('n1.1');
  TestContext.AssertTrue(n1.Next = n2, 'Failed on 4');
end;

procedure TTestTreeview.TestPrev;
var
  n1, n2: TfpgTreeNode;
begin
  TestContext.AssertTrue(FTree.RootNode.Prev = nil, 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  n2 := FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue(n2.Prev = n1, 'Failed on 2');
  TestContext.AssertTrue(n1.Prev = nil, 'Failed on 3');
  n1.AppendText('n1.1');
  TestContext.AssertTrue(n2.Prev = n1, 'Failed on 4');
end;

procedure TTestTreeview.TestAppendText;
var
  n1: TfpgTreeNode;
begin
  n1 := FTree.RootNode.AppendText('n1');
  TestContext.AssertTrue(FTree.RootNode.FirstSubNode = n1, 'Failed on 1');
  TestContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 2');
  FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue((2)=(FTree.RootNode.Count), 'Failed on 3');
end;

procedure TTestTreeview.TestFindSubNode_Text;
var
  n1, n2, n3: TfpgTreeNode;
  r: TfpgTreeNode;
begin
  { root
      |--n1
      |  |--n1.1
      |
      |--n2
      |  |--n2.1
      |  |  |--n2.1.1
      |  |
      |  |--n2.2
      |
      |--n3
  }
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n1', False) = nil, 'Failed on 1');

  n1 := FTree.RootNode.AppendText('n1');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n1', False) = n1, 'Failed on 2');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n1', True) = n1, 'Failed on 3');

  n2 := FTree.RootNode.AppendText('n2');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2', False) = n2, 'Failed on 4');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2', True) = n2, 'Failed on 5');

  r := n2.AppendText('n2.1');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1', False) = nil, 'Failed on 6');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1', True) = r, 'Failed on 7');

  r := n2.AppendText('n2.2');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.2', False) = nil, 'Failed on 8');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.2', True) = r, 'Failed on 9');

  n3 := FTree.RootNode.AppendText('n3');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n3', False) = n3, 'Failed on 10');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n3', True) = n3, 'Failed on 11');

  r := n1.AppendText('n1.1');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n1.1', False) = nil, 'Failed on 12');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n1.1', True) = r, 'Failed on 13');

  r := n2.FindSubNode('n2.1', True).AppendText('n2.1.1');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1.1', False) = nil, 'Failed on 14');
  TestContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1.1', True) = r, 'Failed on 15');
end;

constructor TTestTreeview.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestTreeviewTestCount(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestCount');
  try
    lFixture.SetUp;
    try lFixture.TestCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestCountRecursive(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestCountRecursive');
  try
    lFixture.SetUp;
    try lFixture.TestCountRecursive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestNext(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestNext');
  try
    lFixture.SetUp;
    try lFixture.TestNext; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestPrev(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestPrev');
  try
    lFixture.SetUp;
    try lFixture.TestPrev; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestAppendText(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestAppendText');
  try
    lFixture.SetUp;
    try lFixture.TestAppendText; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestFindSubNode_Text(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create(AContext, 'TestFindSubNode_Text');
  try
    lFixture.SetUp;
    try lFixture.TestFindSubNode_Text; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcTreeviewTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcTreeview.TTestTreeview');
  lSuite.AddTest('TestCount', @RunTTestTreeviewTestCount);
  lSuite.AddTest('TestCountRecursive', @RunTTestTreeviewTestCountRecursive);
  lSuite.AddTest('TestNext', @RunTTestTreeviewTestNext);
  lSuite.AddTest('TestPrev', @RunTTestTreeviewTestPrev);
  lSuite.AddTest('TestAppendText', @RunTTestTreeviewTestAppendText);
  lSuite.AddTest('TestFindSubNode_Text', @RunTTestTreeviewTestFindSubNode_Text);
end;


end.


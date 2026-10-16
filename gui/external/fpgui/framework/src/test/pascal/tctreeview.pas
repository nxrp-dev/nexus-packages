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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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


procedure RegisterTests;
begin
  //TestFramework.
  
end;

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
  FContext.AssertTrue((0)=(FTree.RootNode.Count), 'Failed on 1');
  FTree.RootNode.AppendText('n1');
  FContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 2');
  n := FTree.RootNode.AppendText('n2');
  FContext.AssertTrue((2)=(FTree.RootNode.Count), 'Failed on 3');
  FTree.RootNode.Remove(n);
  FContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 4');
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
  FContext.AssertTrue((0)=(FTree.RootNode.CountRecursive), 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  FContext.AssertTrue((1)=(FTree.RootNode.CountRecursive), 'Failed on 2');
  n2 := FTree.RootNode.AppendText('n2');
  FContext.AssertTrue((2)=(FTree.RootNode.CountRecursive), 'Failed on 3');
  n2.AppendText('n2.1');
  FContext.AssertTrue((3)=(FTree.RootNode.CountRecursive), 'Failed on 4');
  n2.AppendText('n2.2');
  FContext.AssertTrue((4)=(FTree.RootNode.CountRecursive), 'Failed on 5');
  n1.AppendText('n1.1');
  FContext.AssertTrue((5)=(FTree.RootNode.CountRecursive), 'Failed on 6');
  FTree.RootNode.Remove(n2); // removing 3 nodes
  FContext.AssertTrue((2)=(FTree.RootNode.CountRecursive), 'Failed on 6');
end;

procedure TTestTreeview.TestNext;
var
  n1, n2: TfpgTreeNode;
begin
  FContext.AssertTrue(FTree.RootNode.Next = nil, 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  n2 := FTree.RootNode.AppendText('n2');
  FContext.AssertTrue(n1.Next = n2, 'Failed on 2');
  FContext.AssertTrue(n2.Next = nil, 'Failed on 3');
  n1.AppendText('n1.1');
  FContext.AssertTrue(n1.Next = n2, 'Failed on 4');
end;

procedure TTestTreeview.TestPrev;
var
  n1, n2: TfpgTreeNode;
begin
  FContext.AssertTrue(FTree.RootNode.Prev = nil, 'Failed on 1');
  n1 := FTree.RootNode.AppendText('n1');
  n2 := FTree.RootNode.AppendText('n2');
  FContext.AssertTrue(n2.Prev = n1, 'Failed on 2');
  FContext.AssertTrue(n1.Prev = nil, 'Failed on 3');
  n1.AppendText('n1.1');
  FContext.AssertTrue(n2.Prev = n1, 'Failed on 4');
end;

procedure TTestTreeview.TestAppendText;
var
  n1: TfpgTreeNode;
begin
  n1 := FTree.RootNode.AppendText('n1');
  FContext.AssertTrue(FTree.RootNode.FirstSubNode = n1, 'Failed on 1');
  FContext.AssertTrue((1)=(FTree.RootNode.Count), 'Failed on 2');
  FTree.RootNode.AppendText('n2');
  FContext.AssertTrue((2)=(FTree.RootNode.Count), 'Failed on 3');
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
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n1', False) = nil, 'Failed on 1');

  n1 := FTree.RootNode.AppendText('n1');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n1', False) = n1, 'Failed on 2');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n1', True) = n1, 'Failed on 3');

  n2 := FTree.RootNode.AppendText('n2');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2', False) = n2, 'Failed on 4');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2', True) = n2, 'Failed on 5');

  r := n2.AppendText('n2.1');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1', False) = nil, 'Failed on 6');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1', True) = r, 'Failed on 7');

  r := n2.AppendText('n2.2');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.2', False) = nil, 'Failed on 8');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.2', True) = r, 'Failed on 9');

  n3 := FTree.RootNode.AppendText('n3');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n3', False) = n3, 'Failed on 10');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n3', True) = n3, 'Failed on 11');

  r := n1.AppendText('n1.1');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n1.1', False) = nil, 'Failed on 12');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n1.1', True) = r, 'Failed on 13');

  r := n2.FindSubNode('n2.1', True).AppendText('n2.1.1');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1.1', False) = nil, 'Failed on 14');
  FContext.AssertTrue(FTree.RootNode.FindSubNode('n2.1.1', True) = r, 'Failed on 15');
end;

procedure RunTTestTreeviewTestCount(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCount';
    lFixture.SetUp;
    try lFixture.TestCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestCountRecursive(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCountRecursive';
    lFixture.SetUp;
    try lFixture.TestCountRecursive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestNext(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNext';
    lFixture.SetUp;
    try lFixture.TestNext; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestPrev(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPrev';
    lFixture.SetUp;
    try lFixture.TestPrev; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestAppendText(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAppendText';
    lFixture.SetUp;
    try lFixture.TestAppendText; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTreeviewTestFindSubNode_Text(AContext: TNXTestContext);
var lFixture: TTestTreeview;
begin
  lFixture:=TTestTreeview.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFindSubNode_Text';
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


initialization
  RegisterTests;

end.


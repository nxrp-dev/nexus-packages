{
    fpGUI IDE - Build Dispatch Tests

    Tests for pure functions in ide.build.dispatch: module detection from
    tree nodes and build request construction.
}
unit ide.test.build.dispatch;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_tree,
  ide.build.dispatch,
  ide.project.pasbuild;

type

  { TTestDetectModuleFromTreeNode }

  TTestDetectModuleFromTreeNode = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestNilNode;
    procedure TestNodeWithNilData;
    procedure TestNodeWithCategoryTag;
    procedure TestNodeWithModuleInfo;
  end;

procedure RegisteridetestbuilddispatchTests(ARegistry: TNXTestRegistry);

implementation

{ TTestDetectModuleFromTreeNode }

procedure TTestDetectModuleFromTreeNode.TestNilNode;
begin
  FContext.AssertTrue(('')=(DetectModuleFromTreeNode(nil)), 'nil node should return empty');
end;

procedure TTestDetectModuleFromTreeNode.TestNodeWithNilData;
var
  n: TfpgTreeNode;
begin
  n := TfpgTreeNode.Create;
  try
    FContext.AssertTrue(('')=(DetectModuleFromTreeNode(n)), 'node with nil data should return empty');
  finally
    n.Free;
  end;
end;

procedure TTestDetectModuleFromTreeNode.TestNodeWithCategoryTag;
var
  n: TfpgTreeNode;
begin
  n := TfpgTreeNode.Create;
  try
    n.Data := Pointer(PtrInt(2));  { category tag }
    FContext.AssertTrue(('')=(DetectModuleFromTreeNode(n)), 'category tag node should return empty');
  finally
    n.Free;
  end;
end;

procedure TTestDetectModuleFromTreeNode.TestNodeWithModuleInfo;
var
  n: TfpgTreeNode;
  info: TAggregatorModuleInfo;
begin
  n := TfpgTreeNode.Create;
  info := TAggregatorModuleInfo.Create;
  try
    info.Name := 'fpgui-framework';
    n.Data := info;
    FContext.AssertTrue(('fpgui-framework')=(DetectModuleFromTreeNode(n)), 'module info node should return module name');
  finally
    info.Free;
    n.Free;
  end;
end;


procedure RunTTestDetectModuleFromTreeNodeTestNilNode(AContext: TNXTestContext);
var lFixture: TTestDetectModuleFromTreeNode;
begin
  lFixture:=TTestDetectModuleFromTreeNode.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNilNode';
    lFixture.TestNilNode;
  finally lFixture.Free; end;
end;

procedure RunTTestDetectModuleFromTreeNodeTestNodeWithNilData(AContext: TNXTestContext);
var lFixture: TTestDetectModuleFromTreeNode;
begin
  lFixture:=TTestDetectModuleFromTreeNode.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNodeWithNilData';
    lFixture.TestNodeWithNilData;
  finally lFixture.Free; end;
end;

procedure RunTTestDetectModuleFromTreeNodeTestNodeWithCategoryTag(AContext: TNXTestContext);
var lFixture: TTestDetectModuleFromTreeNode;
begin
  lFixture:=TTestDetectModuleFromTreeNode.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNodeWithCategoryTag';
    lFixture.TestNodeWithCategoryTag;
  finally lFixture.Free; end;
end;

procedure RunTTestDetectModuleFromTreeNodeTestNodeWithModuleInfo(AContext: TNXTestContext);
var lFixture: TTestDetectModuleFromTreeNode;
begin
  lFixture:=TTestDetectModuleFromTreeNode.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNodeWithModuleInfo';
    lFixture.TestNodeWithModuleInfo;
  finally lFixture.Free; end;
end;

procedure RegisteridetestbuilddispatchTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.build.dispatch.TTestDetectModuleFromTreeNode');
  lSuite.AddTest('TestNilNode', @RunTTestDetectModuleFromTreeNodeTestNilNode);
  lSuite.AddTest('TestNodeWithNilData', @RunTTestDetectModuleFromTreeNodeTestNodeWithNilData);
  lSuite.AddTest('TestNodeWithCategoryTag', @RunTTestDetectModuleFromTreeNodeTestNodeWithCategoryTag);
  lSuite.AddTest('TestNodeWithModuleInfo', @RunTTestDetectModuleFromTreeNodeTestNodeWithModuleInfo);
end;

end.

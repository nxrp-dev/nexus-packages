{
    fpGUI IDE - Project Tree Tests

    Tests for pure functions in ide.projecttree: node file path resolution
    from tree structure without requiring filesystem or widgets.
}
unit ide.test.projecttree;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_tree,
  ide.projecttree,
  ide.project.pasbuild;

type

  { TTestResolveNodeFilePath }

  TTestResolveNodeFilePath = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestNilNode;
    procedure TestNonLeafNode;
    procedure TestLeafWithNoCategoryAncestor;
    procedure TestLeafUnderSourcesCategory;
    procedure TestLeafUnderTestsCategory;
    procedure TestLeafUnderResourcesCategory;
    procedure TestLeafUnderTestResourcesCategory;
    procedure TestLeafWithSubdirectory;
    procedure TestAggregatorModuleLeaf;
    procedure TestAggregatorModuleTestsCategory;
  end;

procedure RegisteridetestprojecttreeTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestResolveNodeFilePath.TestNilNode;
begin
  FContext.AssertTrue(('')=(ResolveNodeFilePath(nil, '/proj/', 'src/main/pascal', False)), 'nil node should return empty');
end;

procedure TTestResolveNodeFilePath.TestNonLeafNode;
var
  root, cat: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Sources');
    cat.Data := Pointer(1);
    { cat has a child, so cat is not a leaf }
    cat.AppendText('child.pas');
    FContext.AssertTrue(('')=(ResolveNodeFilePath(cat, '/proj/', 'src/main/pascal', False)), 'non-leaf node should return empty');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafWithNoCategoryAncestor;
var
  root, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    { root has no Data, so no category ancestor found }
    leaf := root.AppendText('file.pas');
    FContext.AssertTrue(('')=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'leaf with no category ancestor should return empty');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafUnderSourcesCategory;
var
  root, cat, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Sources');
    cat.Data := Pointer(1);
    leaf := cat.AppendText('myunit.pas');
    FContext.AssertTrue((SetDirSeparators('/proj/src/main/pascal/myunit.pas'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'should resolve to source directory + filename');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafUnderTestsCategory;
var
  root, cat, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Tests');
    cat.Data := Pointer(2);
    leaf := cat.AppendText('testunit.pas');
    FContext.AssertTrue((SetDirSeparators('/proj/src/test/pascal/testunit.pas'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'should resolve to test directory + filename');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafUnderResourcesCategory;
var
  root, cat, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Resources');
    cat.Data := Pointer(3);
    leaf := cat.AppendText('config.ini');
    FContext.AssertTrue((SetDirSeparators('/proj/src/main/resources/config.ini'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'should resolve to resources directory + filename');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafUnderTestResourcesCategory;
var
  root, cat, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Test Resources');
    cat.Data := Pointer(4);
    leaf := cat.AppendText('testdata.txt');
    FContext.AssertTrue((SetDirSeparators('/proj/src/test/resources/testdata.txt'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'should resolve to test resources directory + filename');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestLeafWithSubdirectory;
var
  root, cat, subdir, leaf: TfpgTreeNode;
begin
  root := TfpgTreeNode.Create;
  try
    cat := root.AppendText('Sources');
    cat.Data := Pointer(1);
    { Intermediate directory node — no Data }
    subdir := cat.AppendText('gui');
    leaf := subdir.AppendText('fpg_button.pas');
    FContext.AssertTrue((SetDirSeparators('/proj/src/main/pascal/gui/fpg_button.pas'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', False)), 'should include subdirectory in path');
  finally
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestAggregatorModuleLeaf;
var
  root, modNode, cat, leaf: TfpgTreeNode;
  info: TAggregatorModuleInfo;
begin
  root := TfpgTreeNode.Create;
  info := TAggregatorModuleInfo.Create;
  try
    info.Name := 'fpgui-framework';
    info.ProjectDir := '/proj/framework/';
    info.SourceDirectory := 'src/main/pascal';

    modNode := root.AppendText('fpgui-framework');
    modNode.Data := info;

    cat := modNode.AppendText('Sources');
    cat.Data := Pointer(1);

    leaf := cat.AppendText('fpg_main.pas');
    FContext.AssertTrue((SetDirSeparators('/proj/framework/src/main/pascal/fpg_main.pas'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', True)), 'aggregator leaf should use module directory');
  finally
    info.Free;
    root.Free;
  end;
end;

procedure TTestResolveNodeFilePath.TestAggregatorModuleTestsCategory;
var
  root, modNode, cat, leaf: TfpgTreeNode;
  info: TAggregatorModuleInfo;
begin
  root := TfpgTreeNode.Create;
  info := TAggregatorModuleInfo.Create;
  try
    info.Name := 'fpgui-ide';
    info.ProjectDir := '/proj/ide/';
    info.SourceDirectory := 'src/main/pascal';

    modNode := root.AppendText('fpgui-ide');
    modNode.Data := info;

    cat := modNode.AppendText('Tests');
    cat.Data := Pointer(2);

    leaf := cat.AppendText('TestRunner.pas');
    FContext.AssertTrue((SetDirSeparators('/proj/ide/src/test/pascal/TestRunner.pas'))=(ResolveNodeFilePath(leaf, '/proj/', 'src/main/pascal', True)), 'aggregator test leaf should use module test directory');
  finally
    info.Free;
    root.Free;
  end;
end;


procedure RunTTestResolveNodeFilePathTestNilNode(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNilNode';
    lFixture.TestNilNode;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestNonLeafNode(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNonLeafNode';
    lFixture.TestNonLeafNode;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafWithNoCategoryAncestor(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafWithNoCategoryAncestor';
    lFixture.TestLeafWithNoCategoryAncestor;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafUnderSourcesCategory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafUnderSourcesCategory';
    lFixture.TestLeafUnderSourcesCategory;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafUnderTestsCategory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafUnderTestsCategory';
    lFixture.TestLeafUnderTestsCategory;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafUnderResourcesCategory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafUnderResourcesCategory';
    lFixture.TestLeafUnderResourcesCategory;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafUnderTestResourcesCategory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafUnderTestResourcesCategory';
    lFixture.TestLeafUnderTestResourcesCategory;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestLeafWithSubdirectory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeafWithSubdirectory';
    lFixture.TestLeafWithSubdirectory;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestAggregatorModuleLeaf(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAggregatorModuleLeaf';
    lFixture.TestAggregatorModuleLeaf;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveNodeFilePathTestAggregatorModuleTestsCategory(AContext: TNXTestContext);
var lFixture: TTestResolveNodeFilePath;
begin
  lFixture:=TTestResolveNodeFilePath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAggregatorModuleTestsCategory';
    lFixture.TestAggregatorModuleTestsCategory;
  finally lFixture.Free; end;
end;

procedure RegisteridetestprojecttreeTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.projecttree.TTestResolveNodeFilePath');
  lSuite.AddTest('TestNilNode', @RunTTestResolveNodeFilePathTestNilNode);
  lSuite.AddTest('TestNonLeafNode', @RunTTestResolveNodeFilePathTestNonLeafNode);
  lSuite.AddTest('TestLeafWithNoCategoryAncestor', @RunTTestResolveNodeFilePathTestLeafWithNoCategoryAncestor);
  lSuite.AddTest('TestLeafUnderSourcesCategory', @RunTTestResolveNodeFilePathTestLeafUnderSourcesCategory);
  lSuite.AddTest('TestLeafUnderTestsCategory', @RunTTestResolveNodeFilePathTestLeafUnderTestsCategory);
  lSuite.AddTest('TestLeafUnderResourcesCategory', @RunTTestResolveNodeFilePathTestLeafUnderResourcesCategory);
  lSuite.AddTest('TestLeafUnderTestResourcesCategory', @RunTTestResolveNodeFilePathTestLeafUnderTestResourcesCategory);
  lSuite.AddTest('TestLeafWithSubdirectory', @RunTTestResolveNodeFilePathTestLeafWithSubdirectory);
  lSuite.AddTest('TestAggregatorModuleLeaf', @RunTTestResolveNodeFilePathTestAggregatorModuleLeaf);
  lSuite.AddTest('TestAggregatorModuleTestsCategory', @RunTTestResolveNodeFilePathTestAggregatorModuleTestsCategory);
end;

end.

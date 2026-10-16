{
    fpGUI IDE - Variables Panel Logic Tests

    Tests for the pure-logic functions in ide.variables:
      - BuildVarNodeText
      - VarValueIsExpandable
      - ExtractVarTypeName
      - ParseVarChildren
}
unit ide.test.variables;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils,
  ide.variables;

type

  { TTestBuildVarNodeText }

  TTestBuildVarNodeText = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestSimpleWithType;
    procedure TestSimpleWithoutType;
    procedure TestEmptyTypeNameIgnoredWhenShowTypeTrue;
    procedure TestStringValue;
    procedure TestCompositeValueSummary;
  end;

  { TTestVarValueIsExpandable }

  TTestVarValueIsExpandable = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestSimpleIntegerNotExpandable;
    procedure TestNilNotExpandable;
    procedure TestEllipsisNotExpandable;
    procedure TestErrorStringNotExpandable;
    procedure TestEmptyStringNotExpandable;
    procedure TestBooleanNotExpandable;
    procedure TestQuotedStringNotExpandable;
    procedure TestRecordIsExpandable;
    procedure TestClassWithAddressIsExpandable;
    procedure TestNestedRecordIsExpandable;
  end;

  { TTestExtractVarTypeName }

  TTestExtractVarTypeName = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestSimpleIntegerReturnsEmpty;
    procedure TestNilReturnsEmpty;
    procedure TestQuotedStringReturnsEmpty;
    procedure TestRecordReturnsTypeName;
    procedure TestClassReturnsTypeName;
    procedure TestNestedDoesNotLeakParenthesis;
  end;

  { TTestParseVarChildren }

  TTestParseVarChildren = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    procedure AssertChildCount(AExpected: Integer; const AParentPath, AValue: string);
    procedure AssertChild(const AChildren: TVarNodeDataArray; AIndex: Integer;
        const AExpectedName, AExpectedValue: string);
  public
    { Empty / degenerate inputs }
    procedure TestEmptyValueReturnsNoChildren;
    procedure TestNilReturnsNoChildren;
    procedure TestSimpleIntegerReturnsNoChildren;

    { Single field }
    procedure TestSingleFieldRecord;

    { Multiple fields }
    procedure TestTwoFieldRecord;
    procedure TestThreeFieldRecord;

    { Nested composite }
    procedure TestNestedRecordChildIsExpandable;
    procedure TestNestedRecordChildParsesCorrectly;

    { String values containing commas }
    procedure TestStringWithCommaNotSplit;

    { FullPath construction }
    procedure TestChildFullPathWithParent;
    procedure TestChildFullPathNoParent;

    { Class values }
    procedure TestClassNonNilIsExpandable;

    { Type extraction on children }
    procedure TestChildTypeExtractedFromValue;
  end;


procedure RegisteridetestvariablesTests(ARegistry: TNXTestRegistry);

implementation


{ TTestBuildVarNodeText }

procedure TTestBuildVarNodeText.TestSimpleWithType;
begin
  TestContext.AssertTrue(('i = 42 : Integer')=(BuildVarNodeText('i', '42', 'Integer', True)), '');
end;

procedure TTestBuildVarNodeText.TestSimpleWithoutType;
begin
  TestContext.AssertTrue(('i = 42')=(BuildVarNodeText('i', '42', 'Integer', False)), '');
end;

procedure TTestBuildVarNodeText.TestEmptyTypeNameIgnoredWhenShowTypeTrue;
begin
  { When TypeName is empty, type suffix must not appear even if ShowType=True }
  TestContext.AssertTrue(('x = 5')=(BuildVarNodeText('x', '5', '', True)), '');
end;

procedure TTestBuildVarNodeText.TestStringValue;
begin
  TestContext.AssertTrue(('s = ''hello'' : String')=(BuildVarNodeText('s', '''hello''', 'String', True)), '');
end;

procedure TTestBuildVarNodeText.TestCompositeValueSummary;
begin
  { Composite: the full value summary is the display value }
  TestContext.AssertTrue(('r = TPoint { X: 10, Y: 20 } : TPoint')=(BuildVarNodeText('r', 'TPoint { X: 10, Y: 20 }', 'TPoint', True)), '');
end;


{ TTestVarValueIsExpandable }

procedure TTestVarValueIsExpandable.TestSimpleIntegerNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('42')), '');
end;

procedure TTestVarValueIsExpandable.TestNilNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('nil')), '');
end;

procedure TTestVarValueIsExpandable.TestEllipsisNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('...')), '');
end;

procedure TTestVarValueIsExpandable.TestErrorStringNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('<error: type not found>')), '');
end;

procedure TTestVarValueIsExpandable.TestEmptyStringNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('')), '');
end;

procedure TTestVarValueIsExpandable.TestBooleanNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('True')), '');
  TestContext.AssertTrue(not (VarValueIsExpandable('False')), '');
end;

procedure TTestVarValueIsExpandable.TestQuotedStringNotExpandable;
begin
  TestContext.AssertTrue(not (VarValueIsExpandable('''hello world''')), '');
end;

procedure TTestVarValueIsExpandable.TestRecordIsExpandable;
begin
  TestContext.AssertTrue(VarValueIsExpandable('TPoint { X: 10, Y: 20 }'), '');
end;

procedure TTestVarValueIsExpandable.TestClassWithAddressIsExpandable;
begin
  TestContext.AssertTrue(VarValueIsExpandable('TMyClass(@$1234ABCD) { FName: ''hello'', FCount: 3 }'), '');
end;

procedure TTestVarValueIsExpandable.TestNestedRecordIsExpandable;
begin
  TestContext.AssertTrue(VarValueIsExpandable('TOuter { Inner: TInner { A: 1 }, B: 2 }'), '');
end;


{ TTestExtractVarTypeName }

procedure TTestExtractVarTypeName.TestSimpleIntegerReturnsEmpty;
begin
  TestContext.AssertTrue(('')=(ExtractVarTypeName('42')), '');
end;

procedure TTestExtractVarTypeName.TestNilReturnsEmpty;
begin
  TestContext.AssertTrue(('')=(ExtractVarTypeName('nil')), '');
end;

procedure TTestExtractVarTypeName.TestQuotedStringReturnsEmpty;
begin
  TestContext.AssertTrue(('')=(ExtractVarTypeName('''hello''')), '');
end;

procedure TTestExtractVarTypeName.TestRecordReturnsTypeName;
begin
  TestContext.AssertTrue(('TPoint')=(ExtractVarTypeName('TPoint { X: 10, Y: 20 }')), '');
end;

procedure TTestExtractVarTypeName.TestClassReturnsTypeName;
begin
  TestContext.AssertTrue(('TMyClass')=(ExtractVarTypeName('TMyClass(@$1234ABCD) { FField: 99 }')), '');
end;

procedure TTestExtractVarTypeName.TestNestedDoesNotLeakParenthesis;
begin
  { The result must not contain '@' or parentheses }
  TestContext.AssertTrue(('TObj')=(ExtractVarTypeName('TObj(@$DEADBEEF) { X: TPoint { A: 1, B: 2 } }')), '');
end;


{ TTestParseVarChildren }

procedure TTestParseVarChildren.AssertChildCount(AExpected: Integer;
    const AParentPath, AValue: string);
var
  Children: TVarNodeDataArray;
  i: Integer;
begin
  Children := ParseVarChildren(AParentPath, AValue);
  try
    TestContext.AssertTrue((AExpected)=(Length(Children)), 'child count');
  finally
    for i := 0 to High(Children) do
      Children[i].Free;
  end;
end;

procedure TTestParseVarChildren.AssertChild(const AChildren: TVarNodeDataArray;
    AIndex: Integer; const AExpectedName, AExpectedValue: string);
begin
  TestContext.AssertTrue((AExpectedName)=(AChildren[AIndex].Name), 'child[' + IntToStr(AIndex) + '].Name');
  TestContext.AssertTrue((AExpectedValue)=(AChildren[AIndex].Value), 'child[' + IntToStr(AIndex) + '].Value');
end;

procedure TTestParseVarChildren.TestEmptyValueReturnsNoChildren;
begin
  AssertChildCount(0, 'v', '');
end;

procedure TTestParseVarChildren.TestNilReturnsNoChildren;
begin
  AssertChildCount(0, 'obj', 'nil');
end;

procedure TTestParseVarChildren.TestSimpleIntegerReturnsNoChildren;
begin
  AssertChildCount(0, 'n', '42');
end;

procedure TTestParseVarChildren.TestSingleFieldRecord;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('r', 'TPoint1D { X: 5 }');
  try
    TestContext.AssertTrue((1)=(Length(Children)), '');
    AssertChild(Children, 0, 'X', '5');
  finally
    if Length(Children) > 0 then Children[0].Free;
  end;
end;

procedure TTestParseVarChildren.TestTwoFieldRecord;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('p', 'TPoint { X: 10, Y: 20 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    AssertChild(Children, 0, 'X', '10');
    AssertChild(Children, 1, 'Y', '20');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestThreeFieldRecord;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('r', 'TRect { Left: 0, Top: 0, Width: 100 }');
  try
    TestContext.AssertTrue((3)=(Length(Children)), '');
    AssertChild(Children, 0, 'Left',  '0');
    AssertChild(Children, 1, 'Top',   '0');
    AssertChild(Children, 2, 'Width', '100');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
    if Length(Children) > 2 then Children[2].Free;
  end;
end;

procedure TTestParseVarChildren.TestNestedRecordChildIsExpandable;
var
  Children: TVarNodeDataArray;
begin
  { The nested child 'Inner: TInner { A: 1 }' should be expandable }
  Children := ParseVarChildren('r', 'TOuter { Inner: TInner { A: 1 }, B: 2 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    TestContext.AssertTrue(Children[0].IsExpandable, 'Inner should be expandable');
    TestContext.AssertTrue(not (Children[1].IsExpandable), 'B should not be expandable');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestNestedRecordChildParsesCorrectly;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('r', 'TOuter { Inner: TInner { A: 1 }, B: 42 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    AssertChild(Children, 0, 'Inner', 'TInner { A: 1 }');
    AssertChild(Children, 1, 'B', '42');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestStringWithCommaNotSplit;
var
  Children: TVarNodeDataArray;
begin
  { A string value containing ', ' must not be treated as a separator }
  Children := ParseVarChildren('r', 'TRec { Name: ''hello, world'', Age: 25 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    AssertChild(Children, 0, 'Name', '''hello, world''');
    AssertChild(Children, 1, 'Age',  '25');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestChildFullPathWithParent;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('myVar', 'TPoint { X: 1, Y: 2 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    TestContext.AssertTrue(('myVar.X')=(Children[0].FullPath), '');
    TestContext.AssertTrue(('myVar.Y')=(Children[1].FullPath), '');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestChildFullPathNoParent;
var
  Children: TVarNodeDataArray;
begin
  { When AParentPath is empty, FullPath is just the field name }
  Children := ParseVarChildren('', 'TPoint { X: 1, Y: 2 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    TestContext.AssertTrue(('X')=(Children[0].FullPath), '');
    TestContext.AssertTrue(('Y')=(Children[1].FullPath), '');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestClassNonNilIsExpandable;
var
  Children: TVarNodeDataArray;
begin
  Children := ParseVarChildren('obj',
    'TMyClass(@$1234ABCD) { FName: ''test'', FCount: 7 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    AssertChild(Children, 0, 'FName',  '''test''');
    AssertChild(Children, 1, 'FCount', '7');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;

procedure TTestParseVarChildren.TestChildTypeExtractedFromValue;
var
  Children: TVarNodeDataArray;
begin
  { A child whose value is itself a composite should have TypeName extracted }
  Children := ParseVarChildren('r', 'TOuter { Sub: TPoint { X: 1, Y: 2 }, N: 99 }');
  try
    TestContext.AssertTrue((2)=(Length(Children)), '');
    TestContext.AssertTrue(('TPoint')=(Children[0].TypeName), '');
    TestContext.AssertTrue(('')=(Children[1].TypeName), '');
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;



constructor TTestBuildVarNodeText.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestVarValueIsExpandable.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestExtractVarTypeName.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestParseVarChildren.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBuildVarNodeTextTestSimpleWithType(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create(AContext, 'TestSimpleWithType');
  try
    lFixture.TestSimpleWithType;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestSimpleWithoutType(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create(AContext, 'TestSimpleWithoutType');
  try
    lFixture.TestSimpleWithoutType;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestEmptyTypeNameIgnoredWhenShowTypeTrue(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create(AContext, 'TestEmptyTypeNameIgnoredWhenShowTypeTrue');
  try
    lFixture.TestEmptyTypeNameIgnoredWhenShowTypeTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestStringValue(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create(AContext, 'TestStringValue');
  try
    lFixture.TestStringValue;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestCompositeValueSummary(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create(AContext, 'TestCompositeValueSummary');
  try
    lFixture.TestCompositeValueSummary;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestSimpleIntegerNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestSimpleIntegerNotExpandable');
  try
    lFixture.TestSimpleIntegerNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestNilNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestNilNotExpandable');
  try
    lFixture.TestNilNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestEllipsisNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestEllipsisNotExpandable');
  try
    lFixture.TestEllipsisNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestErrorStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestErrorStringNotExpandable');
  try
    lFixture.TestErrorStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestEmptyStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestEmptyStringNotExpandable');
  try
    lFixture.TestEmptyStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestBooleanNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestBooleanNotExpandable');
  try
    lFixture.TestBooleanNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestQuotedStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestQuotedStringNotExpandable');
  try
    lFixture.TestQuotedStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestRecordIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestRecordIsExpandable');
  try
    lFixture.TestRecordIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestClassWithAddressIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestClassWithAddressIsExpandable');
  try
    lFixture.TestClassWithAddressIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestNestedRecordIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create(AContext, 'TestNestedRecordIsExpandable');
  try
    lFixture.TestNestedRecordIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestSimpleIntegerReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestSimpleIntegerReturnsEmpty');
  try
    lFixture.TestSimpleIntegerReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestNilReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestNilReturnsEmpty');
  try
    lFixture.TestNilReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestQuotedStringReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestQuotedStringReturnsEmpty');
  try
    lFixture.TestQuotedStringReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestRecordReturnsTypeName(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestRecordReturnsTypeName');
  try
    lFixture.TestRecordReturnsTypeName;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestClassReturnsTypeName(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestClassReturnsTypeName');
  try
    lFixture.TestClassReturnsTypeName;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestNestedDoesNotLeakParenthesis(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create(AContext, 'TestNestedDoesNotLeakParenthesis');
  try
    lFixture.TestNestedDoesNotLeakParenthesis;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestEmptyValueReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestEmptyValueReturnsNoChildren');
  try
    lFixture.TestEmptyValueReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNilReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestNilReturnsNoChildren');
  try
    lFixture.TestNilReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestSimpleIntegerReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestSimpleIntegerReturnsNoChildren');
  try
    lFixture.TestSimpleIntegerReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestSingleFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestSingleFieldRecord');
  try
    lFixture.TestSingleFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestTwoFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestTwoFieldRecord');
  try
    lFixture.TestTwoFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestThreeFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestThreeFieldRecord');
  try
    lFixture.TestThreeFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNestedRecordChildIsExpandable(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestNestedRecordChildIsExpandable');
  try
    lFixture.TestNestedRecordChildIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNestedRecordChildParsesCorrectly(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestNestedRecordChildParsesCorrectly');
  try
    lFixture.TestNestedRecordChildParsesCorrectly;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestStringWithCommaNotSplit(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestStringWithCommaNotSplit');
  try
    lFixture.TestStringWithCommaNotSplit;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildFullPathWithParent(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestChildFullPathWithParent');
  try
    lFixture.TestChildFullPathWithParent;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildFullPathNoParent(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestChildFullPathNoParent');
  try
    lFixture.TestChildFullPathNoParent;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestClassNonNilIsExpandable(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestClassNonNilIsExpandable');
  try
    lFixture.TestClassNonNilIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildTypeExtractedFromValue(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create(AContext, 'TestChildTypeExtractedFromValue');
  try
    lFixture.TestChildTypeExtractedFromValue;
  finally lFixture.Free; end;
end;

procedure RegisteridetestvariablesTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.variables.TTestBuildVarNodeText');
  lSuite.AddTest('TestSimpleWithType', @RunTTestBuildVarNodeTextTestSimpleWithType);
  lSuite.AddTest('TestSimpleWithoutType', @RunTTestBuildVarNodeTextTestSimpleWithoutType);
  lSuite.AddTest('TestEmptyTypeNameIgnoredWhenShowTypeTrue', @RunTTestBuildVarNodeTextTestEmptyTypeNameIgnoredWhenShowTypeTrue);
  lSuite.AddTest('TestStringValue', @RunTTestBuildVarNodeTextTestStringValue);
  lSuite.AddTest('TestCompositeValueSummary', @RunTTestBuildVarNodeTextTestCompositeValueSummary);
  lSuite:=ARegistry.AddSuite('ide.test.variables.TTestVarValueIsExpandable');
  lSuite.AddTest('TestSimpleIntegerNotExpandable', @RunTTestVarValueIsExpandableTestSimpleIntegerNotExpandable);
  lSuite.AddTest('TestNilNotExpandable', @RunTTestVarValueIsExpandableTestNilNotExpandable);
  lSuite.AddTest('TestEllipsisNotExpandable', @RunTTestVarValueIsExpandableTestEllipsisNotExpandable);
  lSuite.AddTest('TestErrorStringNotExpandable', @RunTTestVarValueIsExpandableTestErrorStringNotExpandable);
  lSuite.AddTest('TestEmptyStringNotExpandable', @RunTTestVarValueIsExpandableTestEmptyStringNotExpandable);
  lSuite.AddTest('TestBooleanNotExpandable', @RunTTestVarValueIsExpandableTestBooleanNotExpandable);
  lSuite.AddTest('TestQuotedStringNotExpandable', @RunTTestVarValueIsExpandableTestQuotedStringNotExpandable);
  lSuite.AddTest('TestRecordIsExpandable', @RunTTestVarValueIsExpandableTestRecordIsExpandable);
  lSuite.AddTest('TestClassWithAddressIsExpandable', @RunTTestVarValueIsExpandableTestClassWithAddressIsExpandable);
  lSuite.AddTest('TestNestedRecordIsExpandable', @RunTTestVarValueIsExpandableTestNestedRecordIsExpandable);
  lSuite:=ARegistry.AddSuite('ide.test.variables.TTestExtractVarTypeName');
  lSuite.AddTest('TestSimpleIntegerReturnsEmpty', @RunTTestExtractVarTypeNameTestSimpleIntegerReturnsEmpty);
  lSuite.AddTest('TestNilReturnsEmpty', @RunTTestExtractVarTypeNameTestNilReturnsEmpty);
  lSuite.AddTest('TestQuotedStringReturnsEmpty', @RunTTestExtractVarTypeNameTestQuotedStringReturnsEmpty);
  lSuite.AddTest('TestRecordReturnsTypeName', @RunTTestExtractVarTypeNameTestRecordReturnsTypeName);
  lSuite.AddTest('TestClassReturnsTypeName', @RunTTestExtractVarTypeNameTestClassReturnsTypeName);
  lSuite.AddTest('TestNestedDoesNotLeakParenthesis', @RunTTestExtractVarTypeNameTestNestedDoesNotLeakParenthesis);
  lSuite:=ARegistry.AddSuite('ide.test.variables.TTestParseVarChildren');
  lSuite.AddTest('TestEmptyValueReturnsNoChildren', @RunTTestParseVarChildrenTestEmptyValueReturnsNoChildren);
  lSuite.AddTest('TestNilReturnsNoChildren', @RunTTestParseVarChildrenTestNilReturnsNoChildren);
  lSuite.AddTest('TestSimpleIntegerReturnsNoChildren', @RunTTestParseVarChildrenTestSimpleIntegerReturnsNoChildren);
  lSuite.AddTest('TestSingleFieldRecord', @RunTTestParseVarChildrenTestSingleFieldRecord);
  lSuite.AddTest('TestTwoFieldRecord', @RunTTestParseVarChildrenTestTwoFieldRecord);
  lSuite.AddTest('TestThreeFieldRecord', @RunTTestParseVarChildrenTestThreeFieldRecord);
  lSuite.AddTest('TestNestedRecordChildIsExpandable', @RunTTestParseVarChildrenTestNestedRecordChildIsExpandable);
  lSuite.AddTest('TestNestedRecordChildParsesCorrectly', @RunTTestParseVarChildrenTestNestedRecordChildParsesCorrectly);
  lSuite.AddTest('TestStringWithCommaNotSplit', @RunTTestParseVarChildrenTestStringWithCommaNotSplit);
  lSuite.AddTest('TestChildFullPathWithParent', @RunTTestParseVarChildrenTestChildFullPathWithParent);
  lSuite.AddTest('TestChildFullPathNoParent', @RunTTestParseVarChildrenTestChildFullPathNoParent);
  lSuite.AddTest('TestClassNonNilIsExpandable', @RunTTestParseVarChildrenTestClassNonNilIsExpandable);
  lSuite.AddTest('TestChildTypeExtractedFromValue', @RunTTestParseVarChildrenTestChildTypeExtractedFromValue);
end;

end.

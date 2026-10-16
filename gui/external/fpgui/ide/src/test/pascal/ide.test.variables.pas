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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestSimpleWithType;
    procedure TestSimpleWithoutType;
    procedure TestEmptyTypeNameIgnoredWhenShowTypeTrue;
    procedure TestStringValue;
    procedure TestCompositeValueSummary;
  end;

  { TTestVarValueIsExpandable }

  TTestVarValueIsExpandable = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue(('i = 42 : Integer')=(BuildVarNodeText('i', '42', 'Integer', True)), '');
end;

procedure TTestBuildVarNodeText.TestSimpleWithoutType;
begin
  FContext.AssertTrue(('i = 42')=(BuildVarNodeText('i', '42', 'Integer', False)), '');
end;

procedure TTestBuildVarNodeText.TestEmptyTypeNameIgnoredWhenShowTypeTrue;
begin
  { When TypeName is empty, type suffix must not appear even if ShowType=True }
  FContext.AssertTrue(('x = 5')=(BuildVarNodeText('x', '5', '', True)), '');
end;

procedure TTestBuildVarNodeText.TestStringValue;
begin
  FContext.AssertTrue(('s = ''hello'' : String')=(BuildVarNodeText('s', '''hello''', 'String', True)), '');
end;

procedure TTestBuildVarNodeText.TestCompositeValueSummary;
begin
  { Composite: the full value summary is the display value }
  FContext.AssertTrue(('r = TPoint { X: 10, Y: 20 } : TPoint')=(BuildVarNodeText('r', 'TPoint { X: 10, Y: 20 }', 'TPoint', True)), '');
end;


{ TTestVarValueIsExpandable }

procedure TTestVarValueIsExpandable.TestSimpleIntegerNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('42')), '');
end;

procedure TTestVarValueIsExpandable.TestNilNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('nil')), '');
end;

procedure TTestVarValueIsExpandable.TestEllipsisNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('...')), '');
end;

procedure TTestVarValueIsExpandable.TestErrorStringNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('<error: type not found>')), '');
end;

procedure TTestVarValueIsExpandable.TestEmptyStringNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('')), '');
end;

procedure TTestVarValueIsExpandable.TestBooleanNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('True')), '');
  FContext.AssertTrue(not (VarValueIsExpandable('False')), '');
end;

procedure TTestVarValueIsExpandable.TestQuotedStringNotExpandable;
begin
  FContext.AssertTrue(not (VarValueIsExpandable('''hello world''')), '');
end;

procedure TTestVarValueIsExpandable.TestRecordIsExpandable;
begin
  FContext.AssertTrue(VarValueIsExpandable('TPoint { X: 10, Y: 20 }'), '');
end;

procedure TTestVarValueIsExpandable.TestClassWithAddressIsExpandable;
begin
  FContext.AssertTrue(VarValueIsExpandable('TMyClass(@$1234ABCD) { FName: ''hello'', FCount: 3 }'), '');
end;

procedure TTestVarValueIsExpandable.TestNestedRecordIsExpandable;
begin
  FContext.AssertTrue(VarValueIsExpandable('TOuter { Inner: TInner { A: 1 }, B: 2 }'), '');
end;


{ TTestExtractVarTypeName }

procedure TTestExtractVarTypeName.TestSimpleIntegerReturnsEmpty;
begin
  FContext.AssertTrue(('')=(ExtractVarTypeName('42')), '');
end;

procedure TTestExtractVarTypeName.TestNilReturnsEmpty;
begin
  FContext.AssertTrue(('')=(ExtractVarTypeName('nil')), '');
end;

procedure TTestExtractVarTypeName.TestQuotedStringReturnsEmpty;
begin
  FContext.AssertTrue(('')=(ExtractVarTypeName('''hello''')), '');
end;

procedure TTestExtractVarTypeName.TestRecordReturnsTypeName;
begin
  FContext.AssertTrue(('TPoint')=(ExtractVarTypeName('TPoint { X: 10, Y: 20 }')), '');
end;

procedure TTestExtractVarTypeName.TestClassReturnsTypeName;
begin
  FContext.AssertTrue(('TMyClass')=(ExtractVarTypeName('TMyClass(@$1234ABCD) { FField: 99 }')), '');
end;

procedure TTestExtractVarTypeName.TestNestedDoesNotLeakParenthesis;
begin
  { The result must not contain '@' or parentheses }
  FContext.AssertTrue(('TObj')=(ExtractVarTypeName('TObj(@$DEADBEEF) { X: TPoint { A: 1, B: 2 } }')), '');
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
    FContext.AssertTrue((AExpected)=(Length(Children)), 'child count');
  finally
    for i := 0 to High(Children) do
      Children[i].Free;
  end;
end;

procedure TTestParseVarChildren.AssertChild(const AChildren: TVarNodeDataArray;
    AIndex: Integer; const AExpectedName, AExpectedValue: string);
begin
  FContext.AssertTrue((AExpectedName)=(AChildren[AIndex].Name), 'child[' + IntToStr(AIndex) + '].Name');
  FContext.AssertTrue((AExpectedValue)=(AChildren[AIndex].Value), 'child[' + IntToStr(AIndex) + '].Value');
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
    FContext.AssertTrue((1)=(Length(Children)), '');
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
    FContext.AssertTrue((2)=(Length(Children)), '');
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
    FContext.AssertTrue((3)=(Length(Children)), '');
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
    AssertEquals(2, Length(Children));
    AssertTrue('Inner should be expandable', Children[0].IsExpandable);
    AssertFalse('B should not be expandable', Children[1].IsExpandable);
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
    AssertEquals(2, Length(Children));
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
    AssertEquals(2, Length(Children));
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
    AssertEquals(2, Length(Children));
    AssertEquals('myVar.X', Children[0].FullPath);
    AssertEquals('myVar.Y', Children[1].FullPath);
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
    AssertEquals(2, Length(Children));
    AssertEquals('X', Children[0].FullPath);
    AssertEquals('Y', Children[1].FullPath);
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
    AssertEquals(2, Length(Children));
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
    AssertEquals(2, Length(Children));
    AssertEquals('TPoint', Children[0].TypeName);
    AssertEquals('',       Children[1].TypeName);
  finally
    if Length(Children) > 0 then Children[0].Free;
    if Length(Children) > 1 then Children[1].Free;
  end;
end;



procedure RunTTestBuildVarNodeTextTestSimpleWithType(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleWithType';
    lFixture.TestSimpleWithType;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestSimpleWithoutType(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleWithoutType';
    lFixture.TestSimpleWithoutType;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestEmptyTypeNameIgnoredWhenShowTypeTrue(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyTypeNameIgnoredWhenShowTypeTrue';
    lFixture.TestEmptyTypeNameIgnoredWhenShowTypeTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestStringValue(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStringValue';
    lFixture.TestStringValue;
  finally lFixture.Free; end;
end;

procedure RunTTestBuildVarNodeTextTestCompositeValueSummary(AContext: TNXTestContext);
var lFixture: TTestBuildVarNodeText;
begin
  lFixture:=TTestBuildVarNodeText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCompositeValueSummary';
    lFixture.TestCompositeValueSummary;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestSimpleIntegerNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleIntegerNotExpandable';
    lFixture.TestSimpleIntegerNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestNilNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNilNotExpandable';
    lFixture.TestNilNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestEllipsisNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEllipsisNotExpandable';
    lFixture.TestEllipsisNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestErrorStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestErrorStringNotExpandable';
    lFixture.TestErrorStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestEmptyStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyStringNotExpandable';
    lFixture.TestEmptyStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestBooleanNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBooleanNotExpandable';
    lFixture.TestBooleanNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestQuotedStringNotExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestQuotedStringNotExpandable';
    lFixture.TestQuotedStringNotExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestRecordIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordIsExpandable';
    lFixture.TestRecordIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestClassWithAddressIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClassWithAddressIsExpandable';
    lFixture.TestClassWithAddressIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestVarValueIsExpandableTestNestedRecordIsExpandable(AContext: TNXTestContext);
var lFixture: TTestVarValueIsExpandable;
begin
  lFixture:=TTestVarValueIsExpandable.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNestedRecordIsExpandable';
    lFixture.TestNestedRecordIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestSimpleIntegerReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleIntegerReturnsEmpty';
    lFixture.TestSimpleIntegerReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestNilReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNilReturnsEmpty';
    lFixture.TestNilReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestQuotedStringReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestQuotedStringReturnsEmpty';
    lFixture.TestQuotedStringReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestRecordReturnsTypeName(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRecordReturnsTypeName';
    lFixture.TestRecordReturnsTypeName;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestClassReturnsTypeName(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClassReturnsTypeName';
    lFixture.TestClassReturnsTypeName;
  finally lFixture.Free; end;
end;

procedure RunTTestExtractVarTypeNameTestNestedDoesNotLeakParenthesis(AContext: TNXTestContext);
var lFixture: TTestExtractVarTypeName;
begin
  lFixture:=TTestExtractVarTypeName.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNestedDoesNotLeakParenthesis';
    lFixture.TestNestedDoesNotLeakParenthesis;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestEmptyValueReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyValueReturnsNoChildren';
    lFixture.TestEmptyValueReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNilReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNilReturnsNoChildren';
    lFixture.TestNilReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestSimpleIntegerReturnsNoChildren(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleIntegerReturnsNoChildren';
    lFixture.TestSimpleIntegerReturnsNoChildren;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestSingleFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleFieldRecord';
    lFixture.TestSingleFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestTwoFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTwoFieldRecord';
    lFixture.TestTwoFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestThreeFieldRecord(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestThreeFieldRecord';
    lFixture.TestThreeFieldRecord;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNestedRecordChildIsExpandable(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNestedRecordChildIsExpandable';
    lFixture.TestNestedRecordChildIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestNestedRecordChildParsesCorrectly(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNestedRecordChildParsesCorrectly';
    lFixture.TestNestedRecordChildParsesCorrectly;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestStringWithCommaNotSplit(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStringWithCommaNotSplit';
    lFixture.TestStringWithCommaNotSplit;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildFullPathWithParent(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestChildFullPathWithParent';
    lFixture.TestChildFullPathWithParent;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildFullPathNoParent(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestChildFullPathNoParent';
    lFixture.TestChildFullPathNoParent;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestClassNonNilIsExpandable(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClassNonNilIsExpandable';
    lFixture.TestClassNonNilIsExpandable;
  finally lFixture.Free; end;
end;

procedure RunTTestParseVarChildrenTestChildTypeExtractedFromValue(AContext: TNXTestContext);
var lFixture: TTestParseVarChildren;
begin
  lFixture:=TTestParseVarChildren.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestChildTypeExtractedFromValue';
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

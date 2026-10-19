unit utcexprparsops;

{$mode objfpc}
{$h+}
interface

uses
  Classes, SysUtils, math, obNXTestContext, obNXTestRegistry, obNXTestSuite, fpexprpars;

procedure RegisterutcexprparsopsTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo;

Type
  TMyDestroyNode = Class(TFPConstExpression)
  Public
    Destructor Destroy; override;
  end;

Var
  FCheckNode : TFPExprNode;
  FDestroyCalled : Integer;

procedure DoCheck;
begin
  if Assigned(FCheckNode) then
    FCheckNode.Check;
end;

procedure AssertNodeType(AContext: TNXTestContext; Msg: String; AClass: TClass;  ANode: TFPExprNode);
begin
  AContext.AssertTrue((ANode) <> nil, Msg+': Not null');
  AContext.AssertTrue((AClass) = (ANode.ClassType), Msg+': Class OK');
end;

function CreateIntNode(AInteger: Integer): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateInteger(AInteger);
end;

function CreateFloatNode(AFloat: TExprFloat): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateFloat(AFloat);
end;

function CreateStringNode(Astring: String): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateString(AString);
end;

function CreateDateTimeNode(ADateTime: TDateTime): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateDateTime(ADateTime);
end;

function CreateBoolNode(ABoolean: Boolean): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateBoolean(ABoolean);
end;

procedure AssertNodeOK(AContext: TNXTestContext; FN: TFPExprNode);
Var
  B : Boolean;
  Msg : String;
begin
  AContext.AssertTrue((FN) <> nil, 'Node to test OK');
  B:=False;
  try
    FN.Check;
    B:=True;
  except
    On E : Exception do
      Msg:=E.Message;
  end;
  If Not B then
    AContext.Fail(Format('Node %s not OK: %s',[FN.ClassName,Msg]));
end;

procedure AssertNodeNotOK(AContext: TNXTestContext; const MSg : String; FN: TFPExprNode);
begin
  FCheckNode:=FN;
  AContext.AssertRaises(EExprParser, @DoCheck, Msg);
end;

destructor TMyDestroyNode.Destroy;
begin
  Inc(FDestroyCalled);
  inherited Destroy;
end;

procedure SuiteSetup(AContext: TNXTestContext);
begin

  FCheckNode := Nil;
  FDestroyCalled:=0;
end;

procedure SuiteTearDown(AContext: TNXTestContext);
begin

end;

procedure TestIfOperation_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateIntNode(1),CreateIntNode(2));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((1) = (FN.NodeValue.ResInteger), 'Correct result');
    finally
      FN.Free;
    end;
    FN:=TIfOperation.Create(CreateBoolNode(False),CreateIntNode(1),CreateIntNode(2));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((2) = (FN.NodeValue.ResInteger), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((True) = (FN.NodeValue.ResBoolean), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBoolean2(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(False),CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((False) = (FN.NodeValue.ResBoolean), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateString(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateStringNode('a'),CreateStringNode('b'));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('a') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
    FN:=TIfOperation.Create(CreateBoolNode(False),CreateStringNode('a'),CreateStringNode('b'));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('b') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateFloatNode(1.23),CreateFloatNode(2.34));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((1.23)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
    FN:=TIfOperation.Create(CreateBoolNode(False),CreateFloatNode(1.23),CreateFloatNode(2.34));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((2.34)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TIfOperation;
  D1,D2 : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D1:=Now;
    D2:=D1-1;
    FN:=TIfOperation.Create(CreateBoolNode(True),CreateDateTimeNode(D1),CreateDateTimeNode(D2));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((D1)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
    FN:=TIfOperation.Create(CreateBoolNode(False),CreateDateTimeNode(D1),CreateDateTimeNode(D2));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((D2)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanInteger(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateBoolNode(True),CreateIntNode(2));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanInteger2(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateIntNode(2),CreateBoolNode(True));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanString(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateBoolNode(True),CreateStringNode('b'));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanString2(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateStringNode('b'),CreateBoolNode(True));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanDateTime(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateBoolNode(True),CreateDateTimeNode(Now));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestCreateBooleanDateTime2(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TIfOperation.Create(CreateBoolNode(True),CreateDateTimeNode(Now),CreateBoolNode(True));
    try
      AssertNodeNotOK(AContext, 'No type promotion for boolean',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestIfOperation_TestDestroy(AContext: TNXTestContext);
var
  FN : TIfOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TIfOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((3) = (FDestroyCalled), 'Destroy called for all nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

function CreateArgs(  Args: array of const): TExprArgumentArray;

Var
  I : Integer;

begin
  Result:=Default(TExprArgumentArray);
  SetLength(Result,High(Args)-Low(Args)+1);
  For I:=Low(Args) to High(Args) do
    Result[I]:=Args[i].VObject as TFPExprNode;
end;

procedure TestCaseOperation_TestCreateOne(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Too little arguments',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateTwo(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(False),CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Too little arguments',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateThree(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(False),CreateBoolNode(False),CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Too little arguments',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateOdd(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(False),CreateBoolNode(False),
                                            CreateBoolNode(False),CreateBoolNode(False),
                                            CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Odd number of arguments',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateNoExpression(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(False),
                                            CreateBoolNode(False),
                                            TFPBinaryOrOperation.Create(CreateBoolNode(False),CreateBoolNode(False)),
                                            CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Label is not a constant expression',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateWrongLabel(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateBoolNode(False),
                                          CreateIntNode(1),CreateBoolNode(False),
                                          CreateBoolNode(True),CreateBoolNode(False)]));
    try
      AssertNodeNotOK(AContext, 'Wrong label type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestCreateWrongValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateBoolNode(False),
                                            CreateIntNode(1),CreateBoolNode(False),
                                            CreateIntNode(2),CreateIntNode(1)]));
    try
      AssertNodeNotOK(AContext, 'Wrong value',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestIntegerTag(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateStringNode('many'),
                                            CreateIntNode(1),CreateStringNode('one'),
                                            CreateIntNode(2),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('one') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestIntegerTagDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateStringNode('many'),
                                          CreateIntNode(1),CreateStringNode('one'),
                                          CreateIntNode(2),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('many') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestStringTag(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateStringNode('many'),
                                          CreateIntNode(1),CreateStringNode('one'),
                                          CreateIntNode(2),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('many') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestStringTagDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateStringNode('many'),CreateIntNode(3),
                                          CreateStringNode('one'),CreateIntNode(1),
                                          CreateStringNode('two'),CreateIntNode(2)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((3) = (FN.NodeValue.ResInteger), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestFloatTag(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateFloatNode(1.0),CreateStringNode('many'),
                                          CreateFloatNode(1.0),CreateStringNode('one'),
                                          CreateFloatNode(2.0),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('one') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestFloatTagDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateFloatNode(1.0),CreateStringNode('many'),
                                            CreateFloatNode(1.0),CreateStringNode('one'),
                                            CreateFloatNode(2.0),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('one') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestBooleanTag(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(True),CreateStringNode('unknown'),
                                          CreateBoolNode(True),CreateStringNode('one'),
                                          CreateBoolNode(False),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('one') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestBooleanTagDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateBoolNode(True),CreateStringNode('unknown'),
                                          CreateBoolNode(False),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('unknown') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestDateTimeTag(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateDateTimeNode(Date),CreateStringNode('later'),
                                          CreateDateTimeNode(Date),CreateStringNode('today'),
                                          CreateDateTimeNode(Date+1),CreateStringNode('tomorrow')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('today') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestDateTimeTagDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateDateTimeNode(Date),CreateStringNode('later'),
                                            CreateDateTimeNode(Date),CreateStringNode('today'),
                                            CreateDateTimeNode(Date+1),CreateStringNode('tomorrow')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('today') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestIntegerValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateIntNode(0),
                                            CreateIntNode(1),CreateIntNode(-1),
                                            CreateIntNode(2),CreateIntNode(-2)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((-1) = (FN.NodeValue.ResInteger), 'Correct result');  finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestIntegerValueDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateIntNode(0),
                                          CreateIntNode(1),CreateIntNode(-1),
                                          CreateIntNode(2),CreateIntNode(-2)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((0) = (FN.NodeValue.ResInteger), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestStringValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateStringNode('many'),
                                          CreateIntNode(1),CreateStringNode('one'),
                                          CreateIntNode(2),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('one') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestStringValueDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateStringNode('many'),
                                          CreateIntNode(1),CreateStringNode('one'),
                                          CreateIntNode(2),CreateStringNode('two')]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(('many') = (FN.NodeValue.ResString), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestFloatValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateFloatNode(0.0),
                                          CreateIntNode(1),CreateFloatNode(2.0),
                                          CreateIntNode(2),CreateFloatNode(1.0)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((2.0)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestFloatValueDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateFloatNode(0.0),
                                          CreateIntNode(1),CreateFloatNode(2.0),
                                          CreateIntNode(2),CreateFloatNode(1.0)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((0.0)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestBooleanValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateBoolNode(False),
                                          CreateIntNode(1),CreateBoolNode(True),
                                          CreateIntNode(2),CreateBoolNode(False)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((True) = (FN.NodeValue.ResBoolean), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestBooleanValueDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateBoolNode(False),
                                          CreateIntNode(1),CreateBoolNode(True),
                                          CreateIntNode(2),CreateBoolNode(False)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((False) = (FN.NodeValue.ResBoolean), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestDateTimeValue(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(1),CreateDateTimeNode(Date+1),
                                          CreateIntNode(1),CreateDateTimeNode(Date),
                                          CreateIntNode(2),CreateDateTimeNode(Date-1)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((Date)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestDateTimeValueDefault(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([CreateIntNode(3),CreateDateTimeNode(Date+1),
                                          CreateIntNode(1),CreateDateTimeNode(Date),
                                          CreateIntNode(2),CreateDateTimeNode(Date-1)]));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue(Abs((Date+1)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestCaseOperation_TestDestroy(AContext: TNXTestContext);
var
  FN : TCaseOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TCaseOperation.Create(CreateArgs([TMyDestroyNode.CreateInteger(1),
                                          TMyDestroyNode.CreateInteger(1),
                                          TMyDestroyNode.CreateInteger(2),
                                          TMyDestroyNode.CreateInteger(3)]));
    FreeAndNil(FN);
    AContext.AssertTrue((4) = (FDestroyCalled), 'Destroy called for operand')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure RegisterutcexprparsopsTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Expressions.TIfOperation');
  lSuite.AddTest('TestCreateInteger', @TestIfOperation_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestCreateBoolean', @TestIfOperation_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestCreateBoolean2', @TestIfOperation_TestCreateBoolean2, 'expressions');
  lSuite.AddTest('TestCreateString', @TestIfOperation_TestCreateString, 'expressions');
  lSuite.AddTest('TestCreateFloat', @TestIfOperation_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestCreateDateTime', @TestIfOperation_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestCreateBooleanInteger', @TestIfOperation_TestCreateBooleanInteger, 'expressions');
  lSuite.AddTest('TestCreateBooleanInteger2', @TestIfOperation_TestCreateBooleanInteger2, 'expressions');
  lSuite.AddTest('TestCreateBooleanString', @TestIfOperation_TestCreateBooleanString, 'expressions');
  lSuite.AddTest('TestCreateBooleanString2', @TestIfOperation_TestCreateBooleanString2, 'expressions');
  lSuite.AddTest('TestCreateBooleanDateTime', @TestIfOperation_TestCreateBooleanDateTime, 'expressions');
  lSuite.AddTest('TestCreateBooleanDateTime2', @TestIfOperation_TestCreateBooleanDateTime2, 'expressions');
  lSuite.AddTest('TestDestroy', @TestIfOperation_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TCaseOperationTests');
  lSuite.AddTest('TestCreateOne', @TestCaseOperation_TestCreateOne, 'expressions');
  lSuite.AddTest('TestCreateTwo', @TestCaseOperation_TestCreateTwo, 'expressions');
  lSuite.AddTest('TestCreateThree', @TestCaseOperation_TestCreateThree, 'expressions');
  lSuite.AddTest('TestCreateOdd', @TestCaseOperation_TestCreateOdd, 'expressions');
  lSuite.AddTest('TestCreateNoExpression', @TestCaseOperation_TestCreateNoExpression, 'expressions');
  lSuite.AddTest('TestCreateWrongLabel', @TestCaseOperation_TestCreateWrongLabel, 'expressions');
  lSuite.AddTest('TestCreateWrongValue', @TestCaseOperation_TestCreateWrongValue, 'expressions');
  lSuite.AddTest('TestIntegerTag', @TestCaseOperation_TestIntegerTag, 'expressions');
  lSuite.AddTest('TestIntegerTagDefault', @TestCaseOperation_TestIntegerTagDefault, 'expressions');
  lSuite.AddTest('TestStringTag', @TestCaseOperation_TestStringTag, 'expressions');
  lSuite.AddTest('TestStringTagDefault', @TestCaseOperation_TestStringTagDefault, 'expressions');
  lSuite.AddTest('TestFloatTag', @TestCaseOperation_TestFloatTag, 'expressions');
  lSuite.AddTest('TestFloatTagDefault', @TestCaseOperation_TestFloatTagDefault, 'expressions');
  lSuite.AddTest('TestBooleanTag', @TestCaseOperation_TestBooleanTag, 'expressions');
  lSuite.AddTest('TestBooleanTagDefault', @TestCaseOperation_TestBooleanTagDefault, 'expressions');
  lSuite.AddTest('TestDateTimeTag', @TestCaseOperation_TestDateTimeTag, 'expressions');
  lSuite.AddTest('TestDateTimeTagDefault', @TestCaseOperation_TestDateTimeTagDefault, 'expressions');
  lSuite.AddTest('TestIntegerValue', @TestCaseOperation_TestIntegerValue, 'expressions');
  lSuite.AddTest('TestIntegerValueDefault', @TestCaseOperation_TestIntegerValueDefault, 'expressions');
  lSuite.AddTest('TestStringValue', @TestCaseOperation_TestStringValue, 'expressions');
  lSuite.AddTest('TestStringValueDefault', @TestCaseOperation_TestStringValueDefault, 'expressions');
  lSuite.AddTest('TestFloatValue', @TestCaseOperation_TestFloatValue, 'expressions');
  lSuite.AddTest('TestFloatValueDefault', @TestCaseOperation_TestFloatValueDefault, 'expressions');
  lSuite.AddTest('TestBooleanValue', @TestCaseOperation_TestBooleanValue, 'expressions');
  lSuite.AddTest('TestBooleanValueDefault', @TestCaseOperation_TestBooleanValueDefault, 'expressions');
  lSuite.AddTest('TestDateTimeValue', @TestCaseOperation_TestDateTimeValue, 'expressions');
  lSuite.AddTest('TestDateTimeValueDefault', @TestCaseOperation_TestDateTimeValueDefault, 'expressions');
  lSuite.AddTest('TestDestroy', @TestCaseOperation_TestDestroy, 'expressions');
end;

end.

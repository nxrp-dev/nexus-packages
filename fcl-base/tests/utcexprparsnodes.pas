unit utcExprParsNodes;

{$mode objfpc}
{$h+}
interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, fpexprpars;

procedure RegisterutcExprParsNodesTests(ARegistry: TNXTestRegistry);

implementation

Type
  TMyDestroyNode = Class(TFPConstExpression)
  Public
    Destructor Destroy; override;
  end;

Var
  FCheckNode : TFPExprNode;
  FDestroyCalled : Integer;

procedure SuiteSetup(AContext: TNXTestContext);
begin

  FCheckNode := Nil;
  FDestroyCalled:=0;
end;

procedure SuiteTearDown(AContext: TNXTestContext);
begin

end;

procedure DoCheck;
begin
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

function CreateBoolNode(ABoolean: Boolean): TFPExprNode;
begin
  Result:=TFPConstExpression.CreateBoolean(ABoolean);
end;

destructor TMyDestroyNode.Destroy;
begin
  Inc(FDestroyCalled);
  inherited Destroy;
end;

procedure TestDestroyNode_TestDestroy(AContext: TNXTestContext);
Var
  FN : TMyDestroyNode;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    AContext.AssertTrue((0) = (FDestroyCalled), 'Destroy not called yet');
    FN:=TMyDestroyNode.CreateInteger(1);
    FN.Free;
    AContext.AssertTrue((1) = (FDestroyCalled), 'Destroy called')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestConstExprNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPConstExpression;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPConstExpression.CreateInteger(1);
    try
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct type');
      AContext.AssertTrue((1) = (FN.ConstValue.ResInteger), 'Correct result');
      AContext.AssertTrue((1) = (FN.NodeValue.ResInteger), 'Correct result');
      AContext.AssertTrue(('1') = (FN.AsString), 'AsString ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestConstExprNode_TestCreateFloat(AContext: TNXTestContext);
Var
  FN : TFPConstExpression;
  F : Double;
  C : Integer;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPConstExpression.CreateFloat(2.34);
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Correct type');
      AContext.AssertTrue(Abs((2.34)-(FN.ConstValue.ResFloat)) <= 1E-14, 'Correct result');
      AContext.AssertTrue(Abs((2.34)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Correct result');
      Val(FN.AsString,F,C);
      AContext.AssertTrue((0) = (C), 'Correct conversion');
      AContext.AssertTrue(Abs((2.34)-(F)) <= (0.001), 'AsString ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestConstExprNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPConstExpression;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPConstExpression.CreateBoolean(True);
    try
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Correct type');
      AContext.AssertTrue((True) = (FN.ConstValue.ResBoolean), 'Correct result');
      AContext.AssertTrue((True) = (FN.NodeValue.ResBoolean), 'Correct result');
      AContext.AssertTrue(('True') = (FN.AsString), 'AsString ok');
    finally
      FN.Free;
    end;
    FN:=TFPConstExpression.CreateBoolean(False);
    try
      AContext.AssertTrue(('False') = (FN.AsString), 'AsString ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestConstExprNode_TestCreateDateTime(AContext: TNXTestContext);
Var
  FN : TFPConstExpression;
  D : TDateTime;
  S : String;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPConstExpression.CreateDateTime(D);
    try
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Correct type');
      AContext.AssertTrue(Abs((D)-(FN.ConstValue.ResDateTime)) <= 1E-14, 'Correct result');
      AContext.AssertTrue(Abs((D)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Correct result');
      S:=''''+FormatDateTime('cccc',D)+'''';
      AContext.AssertTrue((S) = (FN.AsString), 'AsString ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestConstExprNode_TestCreateString(AContext: TNXTestContext);
Var
  FN : TFPConstExpression;
  S : String;
begin
  try
    SuiteSetup(AContext);

    S:='Ohlala';
    FN:=TFPConstExpression.CreateString(S);
    try
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Correct type');
      AContext.AssertTrue((S) = (FN.ConstValue.ResString), 'Correct result');
      AContext.AssertTrue((S) = (FN.NodeValue.ResString), 'Correct result');
      AContext.AssertTrue((''''+S+'''') = (FN.AsString), 'AsString ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNegateExprNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPNegateOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNegateOperation.Create(CreateIntNode(23));
    try
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Negate has correct type');
      AContext.AssertTrue((-23) = (FN.NodeValue.Resinteger), 'Negate has correct result');
      AContext.AssertTrue(('-23') = (FN.AsString), 'Negate has correct string');
      AssertNodeOK(AContext, FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNegateExprNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPNegateOperation;
  S : String;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNegateOperation.Create(CreateFloatNode(1.23));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Negate has correct type');
      AContext.AssertTrue(Abs((-1.23)-(FN.NodeValue.ResFloat)) <= 1E-14, 'Negate has correct result');
      Str(TExprFloat(-1.23),S);
      AContext.AssertTrue((S) = (FN.AsString), 'Negate has correct string');
      AssertNodeOK(AContext, FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNegateExprNode_TestCreateOther1(AContext: TNXTestContext);
var
  FN : TFPNegateOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNegateOperation.Create(TFPConstExpression.CreateString('1.23'));
    try
      AssertNodeNotOK(AContext, 'Negate does not accept string',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNegateExprNode_TestCreateOther2(AContext: TNXTestContext);
var
  FN : TFPNegateOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNegateOperation.Create(TFPConstExpression.CreateBoolean(True));
    try
      AssertNodeNotOK(AContext, 'Negate does not accept boolean',FN)
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNegateExprNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPNegateOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPNegateOperation.Create(TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((1) = (FDestroyCalled), 'Operand Destroy called')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryAndNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateIntNode(3),CreateIntNode(2));
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

procedure TestBinaryAndNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateBoolNode(True),CreateBoolNode(True));
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

procedure TestBinaryAndNode_TestCreateBooleanInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateBoolNode(True),CreateIntNode(0));
    try
      AssertNodeNotOK(AContext, 'Different node types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryAndNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateStringNode('True'),CreateStringNode('True'));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryAndNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.23));
    try
      AssertNodeNotOK(AContext, 'float node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryAndNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryAndOperation.Create(CreateDateTimeNode(Now),CreateDateTimeNode(Now));
    try
      AssertNodeNotOK(AContext, 'DateTime node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryAndNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPBinaryAndOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPBinaryAndOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNotNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNotNode.Create(CreateIntNode(3));
    try
      AssertNodeOK(AContext, FN);
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Correct node type');
      AContext.AssertTrue((Not(Int64(3))) = (FN.NodeValue.ResInteger), 'Correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNotNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNotNode.Create(CreateBoolNode(True));
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

procedure TestNotNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNotNode.Create(CreateStringNode('True'));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNotNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNotNode.Create(CreateFloatNode(1.23));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNotNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPNotNode.Create(CreateDateTimeNode(Now));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestNotNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPNotNode;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPNotNode.Create(TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((1) = (FDestroyCalled), 'Destroy called for operand')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryOrNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateIntNode(1),CreateIntNode(2));
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

procedure TestBinaryOrNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
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

procedure TestBinaryOrNode_TestCreateBooleanInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateBoolNode(True),CreateIntNode(0));
    try
      AssertNodeNotOK(AContext, 'Different node types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryOrNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateStringNode('True'),CreateStringNode('True'));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryOrNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.23));
    try
      AssertNodeNotOK(AContext, 'float node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryOrNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryOrOperation.Create(CreateDateTimeNode(Now),CreateDateTimeNode(Now));
    try
      AssertNodeNotOK(AContext, 'DateTime node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryOrNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPBinaryOrOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPBinaryOrOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryXorNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateIntNode(1),CreateIntNode(2));
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

procedure TestBinaryXorNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateBoolNode(True),CreateBoolNode(True));
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

procedure TestBinaryXorNode_TestCreateBooleanInteger(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateBoolNode(True),CreateIntNode(0));
    try
      AssertNodeNotOK(AContext, 'Different node types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryXorNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateStringNode('True'),CreateStringNode('True'));
    try
      AssertNodeNotOK(AContext, 'String node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryXorNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.23));
    try
      AssertNodeNotOK(AContext, 'float node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryXorNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPBinaryXorOperation.Create(CreateDateTimeNode(Now),CreateDateTimeNode(Now));
    try
      AssertNodeNotOK(AContext, 'DateTime node type',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBinaryXorNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPBinaryXorOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPBinaryXorOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode(AContext: TNXTestContext; B: TFPBooleanResultOperation; AResult: Boolean);
begin
  AContext.AssertTrue((AResult) = (B.NodeValue.resBoolean), Format('Test %s(%s,%s) result',[B.ClassName,B.Left.AsString,B.Right.AsString]));
end;

procedure TestEqualNode_TestCreateIntegerEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateIntNode(1),CreateIntNode(1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateIntegerUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateIntNode(2),CreateIntNode(1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateFloatEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.23));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateFloatUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.34));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateStringUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateBooleanEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateBoolNode(True),CreateBoolNode(True));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateBooleanUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateBoolNode(False),CreateBoolNode(True));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateDateTimeEqual(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestCreateDateTimeUnEqual(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPEqualOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateFloatNode(1),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestEqualNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPEqualOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 = 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateIntegerEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateIntNode(1),CreateIntNode(1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateIntegerUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateIntNode(2),CreateIntNode(1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateFloatEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.23));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateFloatUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateFloatNode(1.23),CreateFloatNode(1.34));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateStringUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateBooleanEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateBoolNode(True),CreateBoolNode(True));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateBooleanUnEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateBoolNode(False),CreateBoolNode(True));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateDateTimeEqual(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPUnEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestCreateDateTimeUnEqual(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPUnEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPUnEqualOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes')
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateFloatNode(1),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestUnEqualNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPUnEqualOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 <> 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestCreateDateTimeSmaller(AContext: TNXTestContext);
Var
   FN : TFPBooleanResultOperation;
   D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPLessThanOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D+1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestCreateDateTimeLarger(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPLessThanOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestCreateStringSmaller(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestCreateStringLarger(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateStringNode('then'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateFloatNode(1.23),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestNoBoolean1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateBoolNode(False),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestNoBoolean2(AContext: TNXTestContext);
 var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateIntNode(1),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestNoBoolean3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateBoolNode(False),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 < 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestCreateDateTimeSmaller(AContext: TNXTestContext);
Var
   FN : TFPBooleanResultOperation;
   D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPLessThanEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D+1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestCreateDateTimeLarger(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPLessThanEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestCreateStringSmaller(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestCreateStringLarger(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateStringNode('then'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateFloatNode(1.23),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestNoBoolean1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateBoolNode(False),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestNoBoolean2(AContext: TNXTestContext);
 var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateIntNode(1),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestNoBoolean3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateBoolNode(False),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLessThanEqualNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPLessThanEqualOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 <= 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestCreateDateTimeSmaller(AContext: TNXTestContext);
Var
   FN : TFPBooleanResultOperation;
   D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPGreaterThanOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D+1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestCreateDateTimeLarger(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPGreaterThanOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestCreateStringSmaller(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestCreateStringLarger(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateStringNode('then'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateFloatNode(1.23),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestNoBoolean1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateBoolNode(False),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestNoBoolean2(AContext: TNXTestContext);
 var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateIntNode(1),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestNoBoolean3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateBoolNode(False),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 > 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestCreateDateTimeSmaller(AContext: TNXTestContext);
Var
   FN : TFPBooleanResultOperation;
   D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPGreaterThanEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D+1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestCreateDateTimeLarger(AContext: TNXTestContext);
Var
  FN : TFPBooleanResultOperation;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    FN:=TFPGreaterThanEqualOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(D-1));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestCreateStringEqual(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateStringNode('now'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestCreateStringSmaller(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateStringNode('now'),CreateStringNode('then'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,False);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestCreateStringLarger(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateStringNode('then'),CreateStringNode('now'));
    try
      AssertNodeOk(AContext, FN);
      AContext.AssertTrue((rtBoolean) = (FN.NodeType), 'Boolean result');
      TestEqualNode(AContext, FN,True);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestWrongTypes1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateIntNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestWrongTypes2(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateDateTimeNode(3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestWrongTypes3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateFloatNode(1.3),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestWrongTypes4(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateBoolNode(False),CreateStringNode('1.23'));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestWrongTypes5(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateFloatNode(1.23),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestNoBoolean1(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateBoolNode(False),CreateIntNode(1));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestNoBoolean2(AContext: TNXTestContext);
 var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateIntNode(1),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestNoBoolean3(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateBoolNode(False),CreateBoolNode(False));
    try
      AssertNodeNotOk(AContext, 'Wrong Types',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestLargerThanEqualNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPBooleanResultOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPGreaterThanEqualOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 >= 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPAddOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Add has correct type');
      AContext.AssertTrue((3) = (FN.NodeValue.ResInteger), 'Add has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPAddOperation.Create(CreateFloatNode(1.23),CreateFloatNode(4.56));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Add has correct type');
      AContext.AssertTrue(Abs((5.79)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Add has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
  D,T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Date;
    T:=Time;
    FN:=TFPAddOperation.Create(CreateDateTimeNode(D),CreateDateTimeNode(T));
    try
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Add has correct type');
      AContext.AssertTrue(Abs((D+T)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Add has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPAddOperation.Create(CreateStringNode('alo'),CreateStringNode('ha'));
    try
      AContext.AssertTrue((rtString) = (FN.NodeType), 'Add has correct type');
      AContext.AssertTrue(('aloha') = (FN.NodeValue.ResString), 'Add has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPAddOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeNotOK(AContext, 'No boolean addition',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPAddOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestAddNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPAddOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPAddOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 + 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPSubtractOperation.Create(CreateIntNode(4),CreateIntNode(1));
    try
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'Subtract has correct type');
      AContext.AssertTrue((3) = (FN.NodeValue.ResInteger), 'Subtract has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPSubtractOperation.Create(CreateFloatNode(4.56),CreateFloatNode(1.23));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Subtract has correct type');
      AContext.AssertTrue(Abs((3.33)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Subtract has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
  D,T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Date;
    T:=Time;
    FN:=TFPSubtractOperation.Create(CreateDateTimeNode(D+T),CreateDateTimeNode(T));
    try
      AContext.AssertTrue((rtDateTime) = (FN.NodeType), 'Subtract has correct type');
      AContext.AssertTrue(Abs((D)-(FN.NodeValue.ResDateTime)) <= 1E-14, 'Subtract has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPSubtractOperation.Create(CreateStringNode('alo'),CreateStringNode('ha'));
    try
      AssertNodeNotOK(AContext, 'No string Subtract',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPSubtractOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeNotOK(AContext, 'No boolean Subtract',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPSubtractOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestSubtractNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPSubtractOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPSubtractOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 - 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPMultiplyOperation.Create(CreateIntNode(4),CreateIntNode(2));
    try
      AContext.AssertTrue((rtInteger) = (FN.NodeType), 'multiply has correct type');
      AContext.AssertTrue((8) = (FN.NodeValue.ResInteger), 'multiply has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPMultiplyOperation.Create(CreateFloatNode(2.0),CreateFloatNode(1.23));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'multiply has correct type');
      AContext.AssertTrue(Abs((2.46)-(FN.NodeValue.ResFloat)) <= (1e-9), 'multiply has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
  D,T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Date;
    T:=Time;
    FN:=TFPMultiplyOperation.Create(CreateDateTimeNode(D+T),CreateDateTimeNode(T));
    try
      AssertNodeNotOK(AContext, 'No datetime multiply',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPMultiplyOperation.Create(CreateStringNode('alo'),CreateStringNode('ha'));
    try
      AssertNodeNotOK(AContext, 'No string multiply',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPMultiplyOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeNotOK(AContext, 'No boolean multiply',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPMultiplyOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestMultiplyNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPMultiplyOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPMultiplyOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 * 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPPowerOperation.Create(CreateIntNode(4),CreateIntNode(2));
    try
      AContext.AssertTrue((rtfloat) = (FN.NodeType), 'Power has correct type');
      AContext.AssertTrue(Abs((16.0)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Power has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPPowerOperation.Create(CreateFloatNode(2.0),CreateFloatNode(3.0));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Power has correct type');
      AContext.AssertTrue(Abs((8.0)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Power has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
  D,T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Date;
    T:=Time;
    FN:=TFPPowerOperation.Create(CreateDateTimeNode(D+T),CreateDateTimeNode(T));
    try
      AssertNodeNotOK(AContext, 'No datetime Power',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPPowerOperation.Create(CreateStringNode('alo'),CreateStringNode('ha'));
    try
      AssertNodeNotOK(AContext, 'No string Power',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPPowerOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeNotOK(AContext, 'No boolean Power',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPPowerOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestPowerNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPPowerOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPPowerOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1^2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestCreateInteger(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPDivideOperation.Create(CreateIntNode(4),CreateIntNode(2));
    try
      AContext.AssertTrue((rtfloat) = (FN.NodeType), 'Divide has correct type');
      AContext.AssertTrue(Abs((2.0)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Divide has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestCreateFloat(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPDivideOperation.Create(CreateFloatNode(9.0),CreateFloatNode(3.0));
    try
      AContext.AssertTrue((rtFloat) = (FN.NodeType), 'Divide has correct type');
      AContext.AssertTrue(Abs((3.0)-(FN.NodeValue.ResFloat)) <= (1e-9), 'Divide has correct result');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestCreateDateTime(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
  D,T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Date;
    T:=Time;
    FN:=TFPDivideOperation.Create(CreateDateTimeNode(D+T),CreateDateTimeNode(T));
    try
      AssertNodeNotOK(AContext, 'No datetime division',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestCreateString(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPDivideOperation.Create(CreateStringNode('alo'),CreateStringNode('ha'));
    try
      AssertNodeNotOK(AContext, 'No string division',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestCreateBoolean(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPDivideOperation.Create(CreateBoolNode(True),CreateBoolNode(False));
    try
      AssertNodeNotOK(AContext, 'No boolean division',FN);
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestDestroy(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FDestroyCalled := 0;
    FN:=TFPDivideOperation.Create(TMyDestroyNode.CreateInteger(1),TMyDestroyNode.CreateInteger(1));
    FN.Free;
    AContext.AssertTrue((2) = (FDestroyCalled), 'Destroy called for left and right nodes');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TTestDivideNode_TestAsString(AContext: TNXTestContext);
var
  FN : TFPDivideOperation;
begin
  try
    SuiteSetup(AContext);

    FN:=TFPDivideOperation.Create(CreateIntNode(1),CreateIntNode(2));
    try
      AContext.AssertTrue(('1 / 2') = (FN.AsString), 'Asstring works ok');
    finally
      FN.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure RegisterutcExprParsNodesTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Expressions.TExprParsNodes');
  lSuite.AddTest('TestDestroyNode', @TestDestroyNode_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestConstExprNode');
  lSuite.AddTest('TestConstCreateInteger', @TestConstExprNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestConstCreateFloat', @TestConstExprNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestConstCreateBoolean', @TestConstExprNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestConstCreateDateTime', @TestConstExprNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestConstCreateString', @TestConstExprNode_TestCreateString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestNegateExprNode');
  lSuite.AddTest('TestNegateCreateInteger', @TestNegateExprNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestNegateCreateFloat', @TestNegateExprNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestNegateCreateOther1', @TestNegateExprNode_TestCreateOther1, 'expressions');
  lSuite.AddTest('TestNegateCreateOther2', @TestNegateExprNode_TestCreateOther2, 'expressions');
  lSuite.AddTest('TestNegateDestroy', @TestNegateExprNode_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestBinaryAndNode');
  lSuite.AddTest('TestBinaryAndCreateInteger', @TestBinaryAndNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestBinaryAndCreateBoolean', @TestBinaryAndNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestBinaryAndCreateBooleanInteger', @TestBinaryAndNode_TestCreateBooleanInteger, 'expressions');
  lSuite.AddTest('TestBinaryAndCreateString', @TestBinaryAndNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestBinaryAndCreateFloat', @TestBinaryAndNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestBinaryAndCreateDateTime', @TestBinaryAndNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestBinaryAndDestroy', @TestBinaryAndNode_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestNotNode');
  lSuite.AddTest('TestNotCreateInteger', @TestNotNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestNotCreateBoolean', @TestNotNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestNotCreateString', @TestNotNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestNotCreateFloat', @TestNotNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestNotCreateDateTime', @TestNotNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestNotDestroy', @TestNotNode_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestBinaryOrNode');
  lSuite.AddTest('TestBinaryOrCreateInteger', @TestBinaryOrNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestBinaryOrCreateBoolean', @TestBinaryOrNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestBinaryOrCreateBooleanInteger', @TestBinaryOrNode_TestCreateBooleanInteger, 'expressions');
  lSuite.AddTest('TestBinaryOrCreateString', @TestBinaryOrNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestBinaryOrCreateFloat', @TestBinaryOrNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestBinaryOrCreateDateTime', @TestBinaryOrNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestBinaryOrDestroy', @TestBinaryOrNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateInteger', @TestBinaryXorNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateBoolean', @TestBinaryXorNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateBooleanInteger', @TestBinaryXorNode_TestCreateBooleanInteger, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateString', @TestBinaryXorNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateFloat', @TestBinaryXorNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestBinaryXorCreateDateTime', @TestBinaryXorNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestBinaryXorDestroy', @TestBinaryXorNode_TestDestroy, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestEqualNode');
  lSuite.AddTest('TestEqualCreateIntegerEqual', @TestEqualNode_TestCreateIntegerEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateIntegerUnEqual', @TestEqualNode_TestCreateIntegerUnEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateFloatEqual', @TestEqualNode_TestCreateFloatEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateFloatUnEqual', @TestEqualNode_TestCreateFloatUnEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateStringEqual', @TestEqualNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateStringUnEqual', @TestEqualNode_TestCreateStringUnEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateBooleanEqual', @TestEqualNode_TestCreateBooleanEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateBooleanUnEqual', @TestEqualNode_TestCreateBooleanUnEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateDateTimeEqual', @TestEqualNode_TestCreateDateTimeEqual, 'expressions');
  lSuite.AddTest('TestEqualCreateDateTimeUnEqual', @TestEqualNode_TestCreateDateTimeUnEqual, 'expressions');
  lSuite.AddTest('TestEqualDestroy', @TestEqualNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestEqualWrongTypes1', @TestEqualNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestEqualWrongTypes2', @TestEqualNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestEqualWrongTypes3', @TestEqualNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestEqualWrongTypes4', @TestEqualNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestEqualWrongTypes5', @TestEqualNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestEqualAsString', @TestEqualNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestUnEqualNode');
  lSuite.AddTest('TestUnEqualCreateIntegerEqual', @TestUnEqualNode_TestCreateIntegerEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateIntegerUnEqual', @TestUnEqualNode_TestCreateIntegerUnEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateFloatEqual', @TestUnEqualNode_TestCreateFloatEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateFloatUnEqual', @TestUnEqualNode_TestCreateFloatUnEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateStringEqual', @TestUnEqualNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateStringUnEqual', @TestUnEqualNode_TestCreateStringUnEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateBooleanEqual', @TestUnEqualNode_TestCreateBooleanEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateBooleanUnEqual', @TestUnEqualNode_TestCreateBooleanUnEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateDateTimeEqual', @TestUnEqualNode_TestCreateDateTimeEqual, 'expressions');
  lSuite.AddTest('TestUnEqualCreateDateTimeUnEqual', @TestUnEqualNode_TestCreateDateTimeUnEqual, 'expressions');
  lSuite.AddTest('TestUnEqualDestroy', @TestUnEqualNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestUnEqualWrongTypes1', @TestUnEqualNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestUnEqualWrongTypes2', @TestUnEqualNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestUnEqualWrongTypes3', @TestUnEqualNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestUnEqualWrongTypes4', @TestUnEqualNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestUnEqualWrongTypes5', @TestUnEqualNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestUnEqualAsString', @TestUnEqualNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestLessThanNode');
  lSuite.AddTest('TestLessThanCreateDateTimeSmaller', @TestLessThanNode_TestCreateDateTimeSmaller, 'expressions');
  lSuite.AddTest('TestLessThanCreateDateTimeLarger', @TestLessThanNode_TestCreateDateTimeLarger, 'expressions');
  lSuite.AddTest('TestLessThanCreateStringEqual', @TestLessThanNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestLessThanCreateStringSmaller', @TestLessThanNode_TestCreateStringSmaller, 'expressions');
  lSuite.AddTest('TestLessThanCreateStringLarger', @TestLessThanNode_TestCreateStringLarger, 'expressions');
  lSuite.AddTest('TestLessThanWrongTypes1', @TestLessThanNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestLessThanWrongTypes2', @TestLessThanNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestLessThanWrongTypes3', @TestLessThanNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestLessThanWrongTypes4', @TestLessThanNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestLessThanWrongTypes5', @TestLessThanNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestLessThanNoBoolean1', @TestLessThanNode_TestNoBoolean1, 'expressions');
  lSuite.AddTest('TestLessThanNoBoolean2', @TestLessThanNode_TestNoBoolean2, 'expressions');
  lSuite.AddTest('TestLessThanNoBoolean3', @TestLessThanNode_TestNoBoolean3, 'expressions');
  lSuite.AddTest('TestLessThanAsString', @TestLessThanNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestLessThanEqualNode');
  lSuite.AddTest('TestLessThanEqualCreateDateTimeSmaller', @TestLessThanEqualNode_TestCreateDateTimeSmaller, 'expressions');
  lSuite.AddTest('TestLessThanEqualCreateDateTimeLarger', @TestLessThanEqualNode_TestCreateDateTimeLarger, 'expressions');
  lSuite.AddTest('TestLessThanEqualCreateStringEqual', @TestLessThanEqualNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestLessThanEqualCreateStringSmaller', @TestLessThanEqualNode_TestCreateStringSmaller, 'expressions');
  lSuite.AddTest('TestLessThanEqualCreateStringLarger', @TestLessThanEqualNode_TestCreateStringLarger, 'expressions');
  lSuite.AddTest('TestLessThanEqualWrongTypes1', @TestLessThanEqualNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestLessThanEqualWrongTypes2', @TestLessThanEqualNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestLessThanEqualWrongTypes3', @TestLessThanEqualNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestLessThanEqualWrongTypes4', @TestLessThanEqualNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestLessThanEqualWrongTypes5', @TestLessThanEqualNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestLessThanEqualNoBoolean1', @TestLessThanEqualNode_TestNoBoolean1, 'expressions');
  lSuite.AddTest('TestLessThanEqualNoBoolean2', @TestLessThanEqualNode_TestNoBoolean2, 'expressions');
  lSuite.AddTest('TestLessThanEqualNoBoolean3', @TestLessThanEqualNode_TestNoBoolean3, 'expressions');
  lSuite.AddTest('TestLessThanEqualAsString', @TestLessThanEqualNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestLargerThanNode');
  lSuite.AddTest('TestLargerThanCreateDateTimeSmaller', @TestLargerThanNode_TestCreateDateTimeSmaller, 'expressions');
  lSuite.AddTest('TestLargerThanCreateDateTimeLarger', @TestLargerThanNode_TestCreateDateTimeLarger, 'expressions');
  lSuite.AddTest('TestLargerThanCreateStringEqual', @TestLargerThanNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestLargerThanCreateStringSmaller', @TestLargerThanNode_TestCreateStringSmaller, 'expressions');
  lSuite.AddTest('TestLargerThanCreateStringLarger', @TestLargerThanNode_TestCreateStringLarger, 'expressions');
  lSuite.AddTest('TestLargerThanWrongTypes1', @TestLargerThanNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestLargerThanWrongTypes2', @TestLargerThanNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestLargerThanWrongTypes3', @TestLargerThanNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestLargerThanWrongTypes4', @TestLargerThanNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestLargerThanWrongTypes5', @TestLargerThanNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestLargerThanNoBoolean1', @TestLargerThanNode_TestNoBoolean1, 'expressions');
  lSuite.AddTest('TestLargerThanNoBoolean2', @TestLargerThanNode_TestNoBoolean2, 'expressions');
  lSuite.AddTest('TestLargerThanNoBoolean3', @TestLargerThanNode_TestNoBoolean3, 'expressions');
  lSuite.AddTest('TestLargerThanAsString', @TestLargerThanNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TestLargerThanEqualNode');
  lSuite.AddTest('TestLargerThanEqualCreateDateTimeSmaller', @TestLargerThanEqualNode_TestCreateDateTimeSmaller, 'expressions');
  lSuite.AddTest('TestLargerThanEqualCreateDateTimeLarger', @TestLargerThanEqualNode_TestCreateDateTimeLarger, 'expressions');
  lSuite.AddTest('TestLargerThanEqualCreateStringEqual', @TestLargerThanEqualNode_TestCreateStringEqual, 'expressions');
  lSuite.AddTest('TestLargerThanEqualCreateStringSmaller', @TestLargerThanEqualNode_TestCreateStringSmaller, 'expressions');
  lSuite.AddTest('TestLargerThanEqualCreateStringLarger', @TestLargerThanEqualNode_TestCreateStringLarger, 'expressions');
  lSuite.AddTest('TestLargerThanEqualWrongTypes1', @TestLargerThanEqualNode_TestWrongTypes1, 'expressions');
  lSuite.AddTest('TestLargerThanEqualWrongTypes2', @TestLargerThanEqualNode_TestWrongTypes2, 'expressions');
  lSuite.AddTest('TestLargerThanEqualWrongTypes3', @TestLargerThanEqualNode_TestWrongTypes3, 'expressions');
  lSuite.AddTest('TestLargerThanEqualWrongTypes4', @TestLargerThanEqualNode_TestWrongTypes4, 'expressions');
  lSuite.AddTest('TestLargerThanEqualWrongTypes5', @TestLargerThanEqualNode_TestWrongTypes5, 'expressions');
  lSuite.AddTest('TestLargerThanEqualNoBoolean1', @TestLargerThanEqualNode_TestNoBoolean1, 'expressions');
  lSuite.AddTest('TestLargerThanEqualNoBoolean2', @TestLargerThanEqualNode_TestNoBoolean2, 'expressions');
  lSuite.AddTest('TestLargerThanEqualNoBoolean3', @TestLargerThanEqualNode_TestNoBoolean3, 'expressions');
  lSuite.AddTest('TestLargerThanEqualAsString', @TestLargerThanEqualNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TTestAddNode');
  lSuite.AddTest('TestAddNode_CreateInteger', @TTestAddNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestAddNode_CreateFloat', @TTestAddNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestAddNode_CreateDateTime', @TTestAddNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestAddNode_CreateString', @TTestAddNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestAddNode_CreateBoolean', @TTestAddNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestAddNode_Destroy', @TTestAddNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestAddNode_AsString', @TTestAddNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TTestSubtractNode');
  lSuite.AddTest('TestSubtractNode_CreateInteger', @TTestSubtractNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestSubtractNode_CreateFloat', @TTestSubtractNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestSubtractNode_CreateDateTime', @TTestSubtractNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestSubtractNode_CreateString', @TTestSubtractNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestSubtractNode_CreateBoolean', @TTestSubtractNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestSubtractNode_Destroy', @TTestSubtractNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestSubtractNode_AsString', @TTestSubtractNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TTestMultiplyNode');
  lSuite.AddTest('TestMultiplyNode_CreateInteger', @TTestMultiplyNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestMultiplyNode_CreateFloat', @TTestMultiplyNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestMultiplyNode_CreateDateTime', @TTestMultiplyNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestMultiplyNode_CreateString', @TTestMultiplyNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestMultiplyNode_CreateBoolean', @TTestMultiplyNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestMultiplyNode_Destroy', @TTestMultiplyNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestMultiplyNode_AsString', @TTestMultiplyNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TTestPowerNode');
  lSuite.AddTest('TestPowerNode_CreateInteger', @TTestPowerNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestPowerNode_CreateFloat', @TTestPowerNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestPowerNode_CreateDateTime', @TTestPowerNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestPowerNode_CreateString', @TTestPowerNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestPowerNode_CreateBoolean', @TTestPowerNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestPowerNode_Destroy', @TTestPowerNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestPowerNode_AsString', @TTestPowerNode_TestAsString, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.TTestDivideNode');
  lSuite.AddTest('TestDivideNode_CreateInteger', @TTestDivideNode_TestCreateInteger, 'expressions');
  lSuite.AddTest('TestDivideNode_CreateFloat', @TTestDivideNode_TestCreateFloat, 'expressions');
  lSuite.AddTest('TestDivideNode_CreateDateTime', @TTestDivideNode_TestCreateDateTime, 'expressions');
  lSuite.AddTest('TestDivideNode_CreateString', @TTestDivideNode_TestCreateString, 'expressions');
  lSuite.AddTest('TestDivideNode_CreateBoolean', @TTestDivideNode_TestCreateBoolean, 'expressions');
  lSuite.AddTest('TestDivideNode_Destroy', @TTestDivideNode_TestDestroy, 'expressions');
  lSuite.AddTest('TestDivideNode_AsString', @TTestDivideNode_TestAsString, 'expressions');
end;

end.

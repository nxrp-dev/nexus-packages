unit utcExprParsAggr;

{$mode objfpc}
{$h+}
interface

uses
  Classes, SysUtils, math, obNXTestContext, obNXTestRegistry, obNXTestSuite, fpexprpars;

procedure RegisterutcExprParsAggrTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo;

type
  TAggregateNode = Class(TFPExprNode)
  Public
    InitCount : Integer;
    UpdateCount : Integer;
    Class Function IsAggregate: Boolean; override;
    Function NodeType: TResultType; override;
    Procedure InitAggregate; override;
    Procedure UpdateAggregate; override;
    procedure GetNodeValue(var Result: TFPExpressionResult); override;
  end;

  TVarCallback = class
    procedure GetVar(var Result: TFPExpressionResult; constref AName: ShortString);
  end;

var
  VarCallBack : TVarCallback;
  FVarValue : Integer;
  FLeft : TAggregateNode;
  FRight : TAggregateNode;
  FFunction : TFPExprIdentifierDef;
  FFunction2 : TFPExprIdentifierDef;

procedure TVarCallback.GetVar(var Result: TFPExpressionResult; constref AName: ShortString);
begin
  Result.ResultType:=FFunction2.ResultType;
  Case Result.ResultType of
    rtInteger : Result.ResInteger:=FVarValue;
    rtFloat : Result.ResFloat:=FVarValue / 2;
    rtCurrency : Result.ResCurrency:=FVarValue / 2;
  end;
end;

procedure SuiteSetup(AContext: TNXTestContext);
begin

  FVarValue:=0;
  VarCallBack:=TVarCallback.Create;
  FFunction:=TFPExprIdentifierDef.Create(Nil);
  FFunction.Name:='Count';
  FFunction2:=TFPExprIdentifierDef.Create(Nil);
  FFunction2.Name:='MyVar';
  FFunction2.ResultType:=rtInteger;
  FFunction2.IdentifierType:=itVariable;
  FFunction2.OnGetVariableValue:=@VarCallBack.GetVar;
  FLeft:=TAggregateNode.Create;
  FRight:=TAggregateNode.Create;
end;

procedure SuiteTearDown(AContext: TNXTestContext);
begin

  FreeAndNil(VarCallBack);
  FreeAndNil(FFunction);
  FreeAndNil(FFunction2);
  FreeAndNil(FLeft);
  FreeAndNil(FRight);
end;

procedure TestParserAggregate_TestIsAggregate(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AContext.AssertTrue((False) = (TFPExprNode.IsAggregate), 'ExprNode');
    AContext.AssertTrue((True) = (TAggregateExpr.IsAggregate), 'TAggregateExpr');
    AContext.AssertTrue((False) = (TFPBinaryOperation.IsAggregate), 'TAggregateExpr');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestHasAggregate(AContext: TNXTestContext);
Var
  N :  TFPExprNode;
begin
  try
    SuiteSetup(AContext);

    N:=TFPExprNode.Create;
    try
      AContext.AssertTrue((False) = (N.HasAggregate), 'ExprNode');
    finally
      N.Free;
    end;
    N:=TAggregateExpr.Create;
    try
      AContext.AssertTrue((True) = (N.HasAggregate), 'TAggregateExpr');
    finally
      N.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestBinaryAggregate(AContext: TNXTestContext);
Var
  B :  TFPBinaryOperation;
begin
  try
    SuiteSetup(AContext);

    B:=TFPBinaryOperation.Create(Fleft,TFPConstExpression.CreateInteger(1));
    try
      FLeft:=Nil;
      AContext.AssertTrue((True) = (B.HasAggregate), 'Binary');
    finally
      B.Free;
      FLeft:=TAggregateNode.Create; // Recreate for next test
    end;
    B:=TFPBinaryOperation.Create(TFPConstExpression.CreateInteger(1),FRight);
    try
      FRight:=Nil;
      AContext.AssertTrue((True) = (B.HasAggregate), 'Binary');
    finally
      B.Free;
      FRight:=TAggregateNode.Create; // Recreate for next test
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestUnaryAggregate(AContext: TNXTestContext);
Var
  B : TFPUnaryOperator;
begin
  try
    SuiteSetup(AContext);

    B:=TFPUnaryOperator.Create(Fleft);
    try
      FLeft:=Nil;
      AContext.AssertTrue((True) = (B.HasAggregate), 'Unary');
    finally
      B.Free;
      FLeft:=TAggregateNode.Create; // Recreate for next test
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestCountAggregate(AContext: TNXTestContext);
Var
  C : TAggregateCount;
  I : Integer;
  R : TFPExpressionResult;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtInteger;
    FFunction.ParameterTypes:='';
    C:=TAggregateCount.CreateFunction(FFunction,Nil);
    try
      C.Check;
      C.InitAggregate;
      For I:=1 to 11 do
        C.UpdateAggregate;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtInteger) = (R.ResultType), 'Correct type');
      AContext.AssertTrue((11) = (R.ResInteger), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestSumAggregate(AContext: TNXTestContext);
Var
  C : TAggregateSum;
  V : TFPExprVariable;
  I : Integer;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtInteger;
    FFunction.ParameterTypes:='I';
    FFunction.Name:='SUM';
    FFunction2.ResultType:=rtInteger;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateSum.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      For I:=1 to 10 do
        begin
        FVarValue:=I;
        C.UpdateAggregate;
        end;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtInteger) = (R.ResultType), 'Correct type');
      AContext.AssertTrue((55) = (R.ResInteger), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestSumAggregate2(AContext: TNXTestContext);
Var
  C : TAggregateSum;
  V : TFPExprVariable;
  I : Integer;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtFloat;
    FFunction.ParameterTypes:='F';
    FFunction.Name:='SUM';
    FFunction2.ResultType:=rtFloat;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateSum.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      For I:=1 to 10 do
        begin
        FVarValue:=I;
        C.UpdateAggregate;
        end;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtFloat) = (R.ResultType), 'Correct type');
      AContext.AssertTrue(Abs((55/2)-(R.ResFloat)) <= (0.1), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestSumAggregate3(AContext: TNXTestContext);
Var
  C : TAggregateSum;
  V : TFPExprVariable;
  I : Integer;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtCurrency;
    FFunction.ParameterTypes:='F';
    FFunction.Name:='SUM';
    FFunction2.ResultType:=rtCurrency;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateSum.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      For I:=1 to 10 do
        begin
        FVarValue:=I;
        C.UpdateAggregate;
        end;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtCurrency) = (R.ResultType), 'Correct type');
      AContext.AssertTrue(Abs((55/2)-(R.ResCurrency)) <= (0.1), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestAvgAggregate(AContext: TNXTestContext);
Var
  C : TAggregateAvg;
  V : TFPExprVariable;
  I : Integer;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtInteger;
    FFunction.ParameterTypes:='F';
    FFunction.Name:='AVG';
    FFunction2.ResultType:=rtInteger;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateAvg.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      For I:=1 to 10 do
        begin
        FVarValue:=I;
        C.UpdateAggregate;
        end;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtFloat) = (R.ResultType), 'Correct type');
      AContext.AssertTrue(Abs((5.5)-(R.ResFloat)) <= (0.1), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestAvgAggregate2(AContext: TNXTestContext);
Var
  C : TAggregateAvg;
  V : TFPExprVariable;
  I : Integer;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtInteger;
    FFunction.ParameterTypes:='F';
    FFunction.Name:='AVG';
    FFunction2.ResultType:=rtFloat;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateAvg.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      For I:=1 to 10 do
        begin
        FVarValue:=I;
        C.UpdateAggregate;
        end;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtFloat) = (R.ResultType), 'Correct type');
      AContext.AssertTrue(Abs((5.5/2)-(R.ResFloat)) <= (0.1), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestParserAggregate_TestAvgAggregate3(AContext: TNXTestContext);
Var
  C : TAggregateAvg;
  V : TFPExprVariable;
  R : TFPExpressionResult;
  A : TExprArgumentArray;
begin
  try
    SuiteSetup(AContext);

    FFunction.ResultType:=rtInteger;
    FFunction.ParameterTypes:='F';
    FFunction.Name:='AVG';
    FFunction2.ResultType:=rtFloat;
    C:=Nil;
    V:=TFPExprVariable.CreateIdentifier(FFunction2);
    try
      SetLength(A,1);
      A[0]:=V;
      C:=TAggregateAvg.CreateFunction(FFunction,A);
      C.Check;
      C.InitAggregate;
      C.GetNodeValue(R);
      AContext.AssertTrue((rtFloat) = (R.ResultType), 'Correct type');
      AContext.AssertTrue(Abs((0.0)-(R.ResFloat)) <= (0.1), 'Correct value');
    finally
      C.Free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

{ TAggregateNode }

class function TAggregateNode.IsAggregate: Boolean;
begin
  Result:=True
end;

function TAggregateNode.NodeType: TResultType;
begin
  Result:=rtInteger;
end;

procedure TAggregateNode.InitAggregate;
begin
  inherited InitAggregate;
  inc(InitCount)
end;

procedure TAggregateNode.UpdateAggregate;
begin
  inherited UpdateAggregate;
  inc(UpdateCount);
end;

procedure TAggregateNode.GetNodeValue(var Result: TFPExpressionResult);
begin
  Result.ResultType:=rtInteger;
  Result.ResInteger:=updateCount;
end;

procedure RegisterutcExprParsAggrTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Expressions.TParserAggregateTests');
  lSuite.AddTest('TestIsAggregate', @TestParserAggregate_TestIsAggregate, 'expressions');
  lSuite.AddTest('TestHasAggregate', @TestParserAggregate_TestHasAggregate, 'expressions');
  lSuite.AddTest('TestBinaryAggregate', @TestParserAggregate_TestBinaryAggregate, 'expressions');
  lSuite.AddTest('TestUnaryAggregate', @TestParserAggregate_TestUnaryAggregate, 'expressions');
  lSuite.AddTest('TestCountAggregate', @TestParserAggregate_TestCountAggregate, 'expressions');
  lSuite.AddTest('TestSumAggregate', @TestParserAggregate_TestSumAggregate, 'expressions');
  lSuite.AddTest('TestSumAggregate2', @TestParserAggregate_TestSumAggregate2, 'expressions');
  lSuite.AddTest('TestSumAggregate3', @TestParserAggregate_TestSumAggregate3, 'expressions');
  lSuite.AddTest('TestAvgAggregate', @TestParserAggregate_TestAvgAggregate, 'expressions');
  lSuite.AddTest('TestAvgAggregate2', @TestParserAggregate_TestAvgAggregate2, 'expressions');
  lSuite.AddTest('TestAvgAggregate3', @TestParserAggregate_TestAvgAggregate3, 'expressions');
end;

end.

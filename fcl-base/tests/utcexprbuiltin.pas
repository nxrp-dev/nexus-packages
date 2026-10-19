unit utcExprBuiltin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, math, fpexprpars;

procedure RegisterutcExprBuiltinTests(ARegistry: TNXTestRegistry);

implementation

uses dateutils, typinfo;

type
  TMyFPExpressionParser = class(TFPExpressionParser)
  public
    property ExprNode;
    property Scanner;
    property Dirty;
  end;

var
  FValue : Integer;
  FP: TMyFPExpressionParser;
  FM : TExprBuiltInManager;
  FileFormatSettings: TFormatSettings;

procedure DummyGetDate(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.resDateTime:=Date;
end;

procedure DummyEchoDate(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.resDateTime:=Args[0].resDateTime;
end;

procedure SuiteSetup(AContext: TNXTestContext);
begin

  FP := TMyFPExpressionParser.Create(nil);
  FM := TExprBuiltInManager.Create(Nil);
  FValue := 0;
end;

procedure SuiteTearDown(AContext: TNXTestContext);
begin

  FValue := 0;
  FreeAndNil(FM);
  FreeAndNil(FP);
end;

procedure TestBuiltinsManager_TestCreate(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AContext.AssertTrue((0) = (FM.IdentifierCount), 'Have no builtin expressions');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable1(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddVariable(bcuser,'a',rtBoolean,'True');
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtBoolean) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue(('True') = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable2(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddBooleanVariable(bcUser,'a',False);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtBoolean) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue(('False') = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable3(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddIntegerVariable(bcUser,'a',123);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtInteger) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue(('123') = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable4(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddFloatVariable(bcUser,'a',1.23);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtFloat) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue((FloatToStr(1.23, FileFormatSettings)) = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable5(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddStringVariable(bcUser,'a','1.23');
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtString) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue(('1.23') = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable6(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
  D : TDateTime;
begin
  try
    SuiteSetup(AContext);

    D:=Now;
    I:=FM.AddDateTimeVariable(bcUser,'a',D);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtDateTime) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue((FormatDateTime('yyyy-mm-dd hh:nn:ss',D)) = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestVariable7(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddCurrencyVariable(bcUser,'a',1.23);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtCurrency) = (I.ResultType), 'Variable has correct resulttype');
    AContext.AssertTrue((CurrToStr(1.23, FileFormatSettings)) = (I.Value), 'Variable has correct value');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestFunction1(AContext: TNXTestContext);
Var
  I : TFPBuiltinExprIdentifierDef;
begin
  try
    SuiteSetup(AContext);

    I:=FM.AddFunction(bcUser,'Date','D','',@DummyGetDate);
    AContext.AssertTrue((I) <> nil, 'Addvariable returns result');
    AContext.AssertTrue((1) = (FM.IdentifierCount), 'One variable added');
    AContext.AssertTrue((I) = (FM.Identifiers[0]), 'Result equals variable added');
    AContext.AssertTrue((ord(bcUser)) = (Ord(I.Category)), 'Variable has correct category');
    AContext.AssertTrue((rtDateTime) = (I.ResultType), 'Function has correct resulttype');
    AContext.AssertTrue((Pointer(@DummyGetDate)) = (Pointer(I.OnGetFunctionValueCallBack)), 'Function has correct address');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestFunction2(AContext: TNXTestContext);
Var
  I,I2 : TFPBuiltinExprIdentifierDef;
  ind : Integer;
begin
  try
    SuiteSetup(AContext);

    FM.AddFunction(bcUser,'EchoDate','D','D',@DummyEchoDate);
    I:=FM.AddFunction(bcUser,'Echo','D','D',@DummyEchoDate);
    FM.AddFunction(bcUser,'DoEcho','D','D',@DummyEchoDate);
    ind:=FM.IndexOfIdentifier('Echo');
    AContext.AssertTrue((1) = (ind), 'Found identifier');
    I2:=FM.FindIdentifier('Echo');
    AContext.AssertTrue((I2) <> nil, 'FindIdentifier returns result');
    AContext.AssertTrue((I) = (I2), 'Findidentifier returns correct result');
    ind:=FM.IndexOfIdentifier('NoNoNo');
    AContext.AssertTrue((-1) = (ind), 'Found no such identifier');
    I2:=FM.FindIdentifier('NoNoNo');
    AContext.AssertTrue((I2) = nil, 'FindIdentifier returns no result');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestDelete(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FM.AddFunction(bcUser,'EchoDate','D','D',@DummyEchoDate);
    FM.AddFunction(bcUser,'EchoDate2','D','D',@DummyEchoDate);
    FM.AddFunction(bcUser,'EchoDate3','D','D',@DummyEchoDate);
    AContext.AssertTrue((3) = (FM.IdentifierCount), 'Count before');
    FM.Delete(2);
    AContext.AssertTrue((2) = (FM.IdentifierCount), 'Count after');
    AContext.AssertTrue((-1) = (FM.IndexOfIdentifier('EchoDate3')), 'No more');
    AContext.AssertTrue((0) = (FM.IndexOfIdentifier('EchoDate')), 'Left 1');
    AContext.AssertTrue((1) = (FM.IndexOfIdentifier('EchoDate2')), 'Left 2');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltinsManager_TestRemove(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FM.AddFunction(bcUser,'EchoDate','D','D',@DummyEchoDate);
    FM.AddFunction(bcUser,'EchoDate2','D','D',@DummyEchoDate);
    FM.AddFunction(bcUser,'EchoDate3','D','D',@DummyEchoDate);
    AContext.AssertTrue((3) = (FM.IdentifierCount), 'Count before');
    AContext.AssertTrue((1) = (FM.Remove('EchoDate2')), 'Result ');
    AContext.AssertTrue((2) = (FM.IdentifierCount), 'Count after');
    AContext.AssertTrue((-1) = (FM.IndexOfIdentifier('EchoDate2')), 'No more');
    AContext.AssertTrue((0) = (FM.IndexOfIdentifier('EchoDate')), 'Left 1');
    AContext.AssertTrue((1) = (FM.IndexOfIdentifier('EchoDate3')), 'Left 2');
    AContext.AssertTrue((-1) = (FM.Remove('Nono')), 'Result ');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure SetExpression(AContext: TNXTestContext; const AExpression: String);
Var
  Msg : String;
begin
  Msg:='';
  try
    FP.Expression:=AExpression;
  except
    On E : Exception do
      Msg:=E.message;
  end;
  If (Msg<>'') then
    AContext.Fail('Parsing of expression "'+AExpression+'" failed :'+Msg);
end;

procedure AssertResult(AContext: TNXTestContext; F: TExprFloat);
begin
  AContext.AssertTrue(Abs((F)-(FP.AsFloat)) <= (1E-9), 'Float result');
end;

procedure AssertResult(AContext: TNXTestContext; I: Int64);
begin
  AContext.AssertTrue((I) = (FP.AsInteger), 'Integer result');
end;

procedure AssertResult(AContext: TNXTestContext; S: String);
begin
  AContext.AssertTrue((S) = (FP.AsString), 'String result');
end;

procedure AssertResult(AContext: TNXTestContext; B: Boolean);
begin
  AContext.AssertTrue((B) = (FP.AsBoolean), 'Boolean result');
end;

procedure AssertDateTimeResult(AContext: TNXTestContext; D: TDateTime);
begin
  AContext.AssertTrue(Abs((D)-(FP.AsDateTime)) <= (2/SecsPerDay), 'DateTime result');
end;

procedure AssertCurrencyResult(AContext: TNXTestContext; C: Currency);
begin
  AContext.AssertTrue(Abs((C)-(FP.AsCurrency)) <= (1E-9), 'Currency result');
end;

procedure AssertExpression(AContext: TNXTestContext; const AExpression: String; AResult: Int64);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AssertResult(AContext, AResult);
end;

procedure AssertExpression(AContext: TNXTestContext; const AExpression: String; const AResult: String);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AssertResult(AContext, AResult);
end;

procedure AssertExpression(AContext: TNXTestContext; const AExpression: String; const AResult: TExprFloat);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AssertResult(AContext, AResult);
end;

procedure AssertExpression(AContext: TNXTestContext; const AExpression: String; const AResult: Boolean);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AssertResult(AContext, AResult);
end;

procedure AssertDateTimeExpression(AContext: TNXTestContext; const AExpression: String; const AResult: TDateTime);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AssertDateTimeResult(AContext, AResult);
end;

procedure AssertAggregateExpression(AContext: TNXTestContext; const AExpression: String; AResult: Int64; AUpdateCount: integer);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AContext.AssertTrue((True) = (FP.ExprNode.HasAggregate), 'Has aggregate');
  FP.InitAggregate;
  While AUpdateCount>0 do
    begin
    FP.UpdateAggregate;
    Dec(AUpdateCount);
    end;
  AssertResult(AContext, AResult);
end;

procedure AssertAggregateExpression(AContext: TNXTestContext; const AExpression: String; AResult: TExprFloat; AUpdateCount: integer);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AContext.AssertTrue((True) = (FP.ExprNode.HasAggregate), 'Has aggregate');
  FP.InitAggregate;
  While AUpdateCount>0 do
    begin
    FP.UpdateAggregate;
    Dec(AUpdateCount);
    end;
  AssertResult(AContext, AResult);
end;

procedure AssertAggregateCurrExpression(AContext: TNXTestContext; Const AExpression : String; AResult : Currency; AUpdateCount : integer);
begin
  FP.BuiltIns:=AllBuiltIns;
  SetExpression(AContext, AExpression);
  AContext.AssertTrue((True) = (FP.ExprNode.HasAggregate), 'Has aggregate');
  FP.InitAggregate;
  While AUpdateCount>0 do
    begin
    FP.UpdateAggregate;
    Dec(AUpdateCount);
    end;
  AssertCurrencyResult(AContext, AResult);
end;

procedure TestBuiltins_TestVariablepi(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'pi',Pi);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctioncos(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'cos(0.5)',Cos(0.5));
    AssertExpression(AContext, 'cos(0.75)',Cos(0.75));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionsin(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'sin(0.5)',sin(0.5));
    AssertExpression(AContext, 'sin(0.75)',sin(0.75));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionarctan(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'arctan(0.5)',arctan(0.5));
    AssertExpression(AContext, 'arctan(0.75)',arctan(0.75));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionabs(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'abs(0.5)',0.5);
    AssertExpression(AContext, 'abs(-0.75)',0.75);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionsqr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'sqr(0.5)',sqr(0.5));
    AssertExpression(AContext, 'sqr(-0.75)',sqr(0.75));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionsqrt(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'sqrt(0.5)',sqrt(0.5));
    AssertExpression(AContext, 'sqrt(0.75)',sqrt(0.75));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionexp(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'exp(1.0)',exp(1));
    AssertExpression(AContext, 'exp(0.0)',1.0);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionln(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'ln(0.5)',ln(0.5));
    AssertExpression(AContext, 'ln(1.5)',ln(1.5));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionlog(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'log(0.5)',ln(0.5)/ln(10.0));
    AssertExpression(AContext, 'log(1.5)',ln(1.5)/ln(10.0));
    AssertExpression(AContext, 'log(10.0)',1.0);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionfrac(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'frac(0.5)',frac(0.5));
    AssertExpression(AContext, 'frac(1.5)',frac(1.5));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionint(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'int(0.5)',int(0.5));
    AssertExpression(AContext, 'int(1.5)',int(1.5));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionround(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'round(0.5)',round(0.5));
    AssertExpression(AContext, 'round(1.55)',round(1.55));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiontrunc(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'trunc(0.5)',trunc(0.5));
    AssertExpression(AContext, 'trunc(1.55)',trunc(1.55));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionlength(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'length(''123'')',3);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctioncopy(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'copy(''123456'',2,4)','2345');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiondelete(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'delete(''123456'',2,4)','16');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionpos(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'pos(''234'',''123456'')',2);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionlowercase(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'lowercase(''AbCdEf'')','abcdef');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionuppercase(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'uppercase(''AbCdEf'')','ABCDEF');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstringreplace(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    // last options are replaceall, ignorecase
    AssertExpression(AContext, 'stringreplace(''AbCdEf'',''C'',''Z'',false,false)','AbZdEf');
    AssertExpression(AContext, 'stringreplace(''AbCdEf'',''c'',''Z'',false,false)','AbCdEf');
    AssertExpression(AContext, 'stringreplace(''AbCdEf'',''c'',''Z'',false,true)','AbZdEf');
    AssertExpression(AContext, 'stringreplace(''AbCdEfC'',''C'',''Z'',false,false)','AbZdEfC');
    AssertExpression(AContext, 'stringreplace(''AbCdEfC'',''C'',''Z'',True,false)','AbZdEfZ');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctioncomparetext(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'comparetext(''AbCdEf'',''AbCdEf'')',0);
    AssertExpression(AContext, 'comparetext(''AbCdEf'',''ABCDEF'')',0);
    AssertExpression(AContext, 'comparetext(''AbCdEf'',''FEDCBA'')',comparetext('AbCdEf','FEDCBA'));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiondate(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'date',date);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiontime(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'time',time);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionnow(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'now',now);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiondayofweek(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddDateTimeVariable('D',Date);
    AssertExpression(AContext, 'dayofweek(d)',DayOfWeek(date));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractyear(AContext: TNXTestContext);
Var
  Y,M,D : Word;
begin
  try
    SuiteSetup(AContext);

    DecodeDate(Date,Y,M,D);
    FP.Identifiers.AddDateTimeVariable('D',Date);
    AssertExpression(AContext, 'extractyear(d)',Y);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractmonth(AContext: TNXTestContext);
Var
  Y,M,D : Word;
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddDateTimeVariable('D',Date);
    DecodeDate(Date,Y,M,D);
    AssertExpression(AContext, 'extractmonth(d)',M);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractday(AContext: TNXTestContext);
Var
  Y,M,D : Word;
begin
  try
    SuiteSetup(AContext);

    DecodeDate(Date,Y,M,D);
    FP.Identifiers.AddDateTimeVariable('D',Date);
    AssertExpression(AContext, 'extractday(d)',D);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextracthour(AContext: TNXTestContext);
Var
  T : TDateTime;
  H,m,s,ms : Word;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    DecodeTime(T,h,m,s,ms);
    FP.Identifiers.AddDateTimeVariable('T',T);
    AssertExpression(AContext, 'extracthour(t)',h);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractmin(AContext: TNXTestContext);
Var
  T : TDateTime;
  H,m,s,ms : Word;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    DecodeTime(T,h,m,s,ms);
    FP.Identifiers.AddDateTimeVariable('T',T);
    AssertExpression(AContext, 'extractmin(t)',m);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractsec(AContext: TNXTestContext);
Var
  T : TDateTime;
  H,m,s,ms : Word;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    DecodeTime(T,h,m,s,ms);
    FP.Identifiers.AddDateTimeVariable('T',T);
    AssertExpression(AContext, 'extractsec(t)',s);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionextractmsec(AContext: TNXTestContext);
Var
  T : TDateTime;
  H,m,s,ms : Word;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    DecodeTime(T,h,m,s,ms);
    FP.Identifiers.AddDateTimeVariable('T',T);
    AssertExpression(AContext, 'extractmsec(t)',ms);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionencodedate(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'encodedate(2008,10,11)',EncodeDate(2008,10,11));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionencodetime(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'encodetime(14,10,11,0)',EncodeTime(14,10,11,0));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionencodedatetime(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertDateTimeExpression(AContext, 'encodedatetime(2008,12,13,14,10,11,0)',EncodeDate(2008,12,13)+EncodeTime(14,10,11,0));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionshortdayname(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'shortdayname(1)',ShortDayNames[1]);
    AssertExpression(AContext, 'shortdayname(7)',ShortDayNames[7]);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionshortmonthname(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'shortmonthname(1)',ShortMonthNames[1]);
    AssertExpression(AContext, 'shortmonthname(12)',ShortMonthNames[12]);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionlongdayname(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'longdayname(1)',longDayNames[1]);
    AssertExpression(AContext, 'longdayname(7)',longDayNames[7]);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionlongmonthname(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'longmonthname(1)',longMonthNames[1]);
    AssertExpression(AContext, 'longmonthname(12)',longMonthNames[12]);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionformatdatetime(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'FormatDateTime(''cccc'',Date)',FormatDateTime('cccc',Date));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionshl(AContext: TNXTestContext);
Var
  I : Int64;
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'shl(12,3)',12 shl 3);
    I:=12 shl 30;
    AssertExpression(AContext, 'shl(12,30)',I);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionshr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'shr(12,2)',12 shr 2);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionIFS(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'ifs(true,''string1'',''string2'')','string1');
    AssertExpression(AContext, 'ifs(false,''string1'',''string2'')','string2');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionIFF(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'iff(true,1.0,2.0)',1.0);
    AssertExpression(AContext, 'iff(false,1.0,2.0)',2.0);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionIFD(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddDateTimeVariable('A',Date);
    FP.Identifiers.AddDateTimeVariable('B',Date-1);
    AssertDateTimeExpression(AContext, 'ifd(true,A,B)',Date);
    AssertDateTimeExpression(AContext, 'ifd(false,A,B)',Date-1);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionIFI(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'ifi(true,1,2)',1);
    AssertExpression(AContext, 'ifi(false,1,2)',2);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctioninttostr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'inttostr(2)','2');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtoint(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'strtoint(''2'')',2);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtointdef(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'strtointdef(''abc'',2)',2);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionfloattostr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'floattostr(1.23)',Floattostr(1.23));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtofloat(AContext: TNXTestContext);
Var
  S : String;
begin
  try
    SuiteSetup(AContext);

    S:='1.23';
    S[2]:=DecimalSeparator;
    AssertExpression(AContext, 'strtofloat('''+S+''')',1.23);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtofloatdef(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'strtofloatdef(''abc'',1.23)',1.23);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionbooltostr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'booltostr(True)','True');
    AssertExpression(AContext, 'booltostr(False)','False');
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtobool(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'strtobool(''0'')',false);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtobooldef(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertExpression(AContext, 'strtobooldef(''XYZ'',True)',True);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiondatetostr(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddDateTimeVariable('A',Date);
    AssertExpression(AContext, 'DateToStr(A)',DateToStr(Date));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctiontimetostr(AContext: TNXTestContext);
Var
  T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    FP.Identifiers.AddDateTimeVariable('A',T);
    AssertExpression(AContext, 'TimeToStr(A)',TimeToStr(T));
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtodate(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddStringVariable('S',DateToStr(Date));
    AssertDateTimeExpression(AContext, 'StrToDate(S)',Date);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtodatedef(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddDateTimeVariable('A',Date);
    AssertDateTimeExpression(AContext, 'StrToDateDef(''S'',A)',Date);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtotime(AContext: TNXTestContext);
Var
  T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    FP.Identifiers.AddStringVariable('S',TimeToStr(T));
    AssertDateTimeExpression(AContext, 'StrToTime(S)',T);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtotimedef(AContext: TNXTestContext);
Var
  T : TDateTime;
begin
  try
    SuiteSetup(AContext);

    T:=Time;
    FP.Identifiers.AddDateTimeVariable('S',T);
    AssertDateTimeExpression(AContext, 'StrToTimeDef(''q'',S)',T);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtodatetime(AContext: TNXTestContext);
Var
  T : TDateTime;
  S : String;
begin
  try
    SuiteSetup(AContext);

    T:=Now;
    S:=DateTimetostr(T);
    AssertDateTimeExpression(AContext, 'StrToDateTime('''+S+''')',T);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionstrtodatetimedef(AContext: TNXTestContext);
Var
  T : TDateTime;
  S : String;
begin
  try
    SuiteSetup(AContext);

    T:=Now;
    S:=DateTimetostr(T);
    FP.Identifiers.AddDateTimeVariable('S',T);
    AssertDateTimeExpression(AContext, 'StrToDateTimeDef('''+S+''',S)',T);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateSum(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddIntegerVariable('S',2);
    AssertAggregateExpression(AContext, 'sum(S)',10,5);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateSumFloat(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddFloatVariable('S',2.0);
    AssertAggregateExpression(AContext, 'sum(S)',10.0,5);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateSumCurrency(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddCurrencyVariable('S',2.0);
    AssertAggregateCurrExpression(AContext, 'sum(S)',Currency(10.0),5);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateCount(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    AssertAggregateExpression(AContext, 'count',5,5);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure DoAverage(var Result: TFPExpressionResult; ConstRef AName: ShortString);
begin
  Inc(FValue);
  Result.ResInteger:=FValue;
  Result.ResultType:=rtInteger;
end;

procedure DoSeries(var Result: TFPExpressionResult; ConstRef AName: ShortString);
Const
  Values : Array[1..10] of double =
  (1.3,1.8,1.1,9.9,1.4,2.4,5.8,6.5,7.8,8.1);
begin
  Inc(FValue);
  Result.ResFloat:=Values[FValue];
  Result.ResultType:=rtFloat;
end;

procedure TestBuiltins_TestFunctionAggregateAvg(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddVariable('S',rtInteger,@DoAverage);
    AssertAggregateExpression(AContext, 'avg(S)',5.5,10);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateMin(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddVariable('S',rtFloat,@DoSeries);
    AssertAggregateExpression(AContext, 'Min(S)',1.1,10);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TestBuiltins_TestFunctionAggregateMax(AContext: TNXTestContext);
begin
  try
    SuiteSetup(AContext);

    FP.Identifiers.AddVariable('S',rtFloat,@DoSeries);
    AssertAggregateExpression(AContext, 'Max(S)',9.9,10);
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure InitFileFormatSettings;
begin
  FileFormatSettings := DefaultFormatSettings;
  FileFormatSettings.DecimalSeparator := '.';
  FileFormatSettings.DateSeparator := '-';
  FileFormatSettings.TimeSeparator := ':';
  FileFormatsettings.ShortDateFormat := 'yyyy-mm-dd';
  FileFormatSettings.LongTimeFormat := 'hh:nn:ss';
end;

procedure RegisterutcExprBuiltinTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  InitFileFormatSettings;
  lSuite := ARegistry.AddSuite('FCL.Expressions.TBuiltinsManagerTests');
  lSuite.AddTest('TestCreate', @TestBuiltinsManager_TestCreate, 'expressions');
  lSuite.AddTest('TestVariable1', @TestBuiltinsManager_TestVariable1, 'expressions');
  lSuite.AddTest('TestVariable2', @TestBuiltinsManager_TestVariable2, 'expressions');
  lSuite.AddTest('TestVariable3', @TestBuiltinsManager_TestVariable3, 'expressions');
  lSuite.AddTest('TestVariable4', @TestBuiltinsManager_TestVariable4, 'expressions');
  lSuite.AddTest('TestVariable5', @TestBuiltinsManager_TestVariable5, 'expressions');
  lSuite.AddTest('TestVariable6', @TestBuiltinsManager_TestVariable6, 'expressions');
  lSuite.AddTest('TestVariable7', @TestBuiltinsManager_TestVariable7, 'expressions');
  lSuite.AddTest('TestFunction1', @TestBuiltinsManager_TestFunction1, 'expressions');
  lSuite.AddTest('TestFunction2', @TestBuiltinsManager_TestFunction2, 'expressions');
  lSuite.AddTest('TestDelete', @TestBuiltinsManager_TestDelete, 'expressions');
  lSuite.AddTest('TestRemove', @TestBuiltinsManager_TestRemove, 'expressions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Math');
  lSuite.AddTest('TestVariablepi', @TestBuiltins_TestVariablepi, 'expressions-math');
  lSuite.AddTest('TestFunctioncos', @TestBuiltins_TestFunctioncos, 'expressions-math');
  lSuite.AddTest('TestFunctionsin', @TestBuiltins_TestFunctionsin, 'expressions-math');
  lSuite.AddTest('TestFunctionarctan', @TestBuiltins_TestFunctionarctan, 'expressions-math');
  lSuite.AddTest('TestFunctionabs', @TestBuiltins_TestFunctionabs, 'expressions-math');
  lSuite.AddTest('TestFunctionsqr', @TestBuiltins_TestFunctionsqr, 'expressions-math');
  lSuite.AddTest('TestFunctionsqrt', @TestBuiltins_TestFunctionsqrt, 'expressions-math');
  lSuite.AddTest('TestFunctionexp', @TestBuiltins_TestFunctionexp, 'expressions-math');
  lSuite.AddTest('TestFunctionln', @TestBuiltins_TestFunctionln, 'expressions-math');
  lSuite.AddTest('TestFunctionlog', @TestBuiltins_TestFunctionlog, 'expressions-math');
  lSuite.AddTest('TestFunctionfrac', @TestBuiltins_TestFunctionfrac, 'expressions-math');
  lSuite.AddTest('TestFunctionint', @TestBuiltins_TestFunctionint, 'expressions-math');
  lSuite.AddTest('TestFunctionround', @TestBuiltins_TestFunctionround, 'expressions-math');
  lSuite.AddTest('TestFunctiontrunc', @TestBuiltins_TestFunctiontrunc, 'expressions-math');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Strings');
  lSuite.AddTest('TestFunctionlength', @TestBuiltins_TestFunctionlength, 'expressions-strings');
  lSuite.AddTest('TestFunctioncopy', @TestBuiltins_TestFunctioncopy, 'expressions-strings');
  lSuite.AddTest('TestFunctiondelete', @TestBuiltins_TestFunctiondelete, 'expressions-strings');
  lSuite.AddTest('TestFunctionpos', @TestBuiltins_TestFunctionpos, 'expressions-strings');
  lSuite.AddTest('TestFunctionlowercase', @TestBuiltins_TestFunctionlowercase, 'expressions-strings');
  lSuite.AddTest('TestFunctionuppercase', @TestBuiltins_TestFunctionuppercase, 'expressions-strings');
  lSuite.AddTest('TestFunctionstringreplace', @TestBuiltins_TestFunctionstringreplace, 'expressions-strings');
  lSuite.AddTest('TestFunctioncomparetext', @TestBuiltins_TestFunctioncomparetext, 'expressions-strings');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Dates');
  lSuite.AddTest('TestFunctiondate', @TestBuiltins_TestFunctiondate, 'expressions-dates');
  lSuite.AddTest('TestFunctiontime', @TestBuiltins_TestFunctiontime, 'expressions-dates');
  lSuite.AddTest('TestFunctionnow', @TestBuiltins_TestFunctionnow, 'expressions-dates');
  lSuite.AddTest('TestFunctiondayofweek', @TestBuiltins_TestFunctiondayofweek, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractyear', @TestBuiltins_TestFunctionextractyear, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractmonth', @TestBuiltins_TestFunctionextractmonth, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractday', @TestBuiltins_TestFunctionextractday, 'expressions-dates');
  lSuite.AddTest('TestFunctionextracthour', @TestBuiltins_TestFunctionextracthour, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractmin', @TestBuiltins_TestFunctionextractmin, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractsec', @TestBuiltins_TestFunctionextractsec, 'expressions-dates');
  lSuite.AddTest('TestFunctionextractmsec', @TestBuiltins_TestFunctionextractmsec, 'expressions-dates');
  lSuite.AddTest('TestFunctionencodedate', @TestBuiltins_TestFunctionencodedate, 'expressions-dates');
  lSuite.AddTest('TestFunctionencodetime', @TestBuiltins_TestFunctionencodetime, 'expressions-dates');
  lSuite.AddTest('TestFunctionencodedatetime', @TestBuiltins_TestFunctionencodedatetime, 'expressions-dates');
  lSuite.AddTest('TestFunctionshortdayname', @TestBuiltins_TestFunctionshortdayname, 'expressions-dates');
  lSuite.AddTest('TestFunctionshortmonthname', @TestBuiltins_TestFunctionshortmonthname, 'expressions-dates');
  lSuite.AddTest('TestFunctionlongdayname', @TestBuiltins_TestFunctionlongdayname, 'expressions-dates');
  lSuite.AddTest('TestFunctionlongmonthname', @TestBuiltins_TestFunctionlongmonthname, 'expressions-dates');
  lSuite.AddTest('TestFunctionformatdatetime', @TestBuiltins_TestFunctionformatdatetime, 'expressions-dates');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Math');
  lSuite.AddTest('TestFunctionshl', @TestBuiltins_TestFunctionshl, 'expressions-math');
  lSuite.AddTest('TestFunctionshr', @TestBuiltins_TestFunctionshr, 'expressions-math');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Conditionals');
  lSuite.AddTest('TestFunctionIFS', @TestBuiltins_TestFunctionIFS, 'expressions-conditionals');
  lSuite.AddTest('TestFunctionIFF', @TestBuiltins_TestFunctionIFF, 'expressions-conditionals');
  lSuite.AddTest('TestFunctionIFD', @TestBuiltins_TestFunctionIFD, 'expressions-conditionals');
  lSuite.AddTest('TestFunctionIFI', @TestBuiltins_TestFunctionIFI, 'expressions-conditionals');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Conversions');
  lSuite.AddTest('TestFunctioninttostr', @TestBuiltins_TestFunctioninttostr, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtoint', @TestBuiltins_TestFunctionstrtoint, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtointdef', @TestBuiltins_TestFunctionstrtointdef, 'expressions-conversions');
  lSuite.AddTest('TestFunctionfloattostr', @TestBuiltins_TestFunctionfloattostr, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtofloat', @TestBuiltins_TestFunctionstrtofloat, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtofloatdef', @TestBuiltins_TestFunctionstrtofloatdef, 'expressions-conversions');
  lSuite.AddTest('TestFunctionbooltostr', @TestBuiltins_TestFunctionbooltostr, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtobool', @TestBuiltins_TestFunctionstrtobool, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtobooldef', @TestBuiltins_TestFunctionstrtobooldef, 'expressions-conversions');
  lSuite.AddTest('TestFunctiondatetostr', @TestBuiltins_TestFunctiondatetostr, 'expressions-conversions');
  lSuite.AddTest('TestFunctiontimetostr', @TestBuiltins_TestFunctiontimetostr, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtodate', @TestBuiltins_TestFunctionstrtodate, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtodatedef', @TestBuiltins_TestFunctionstrtodatedef, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtotime', @TestBuiltins_TestFunctionstrtotime, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtotimedef', @TestBuiltins_TestFunctionstrtotimedef, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtodatetime', @TestBuiltins_TestFunctionstrtodatetime, 'expressions-conversions');
  lSuite.AddTest('TestFunctionstrtodatetimedef', @TestBuiltins_TestFunctionstrtodatetimedef, 'expressions-conversions');
  lSuite := ARegistry.AddSuite('FCL.Expressions.Builtins.Aggregates');
  lSuite.AddTest('TestFunctionAggregateSum', @TestBuiltins_TestFunctionAggregateSum, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateSumFloat', @TestBuiltins_TestFunctionAggregateSumFloat, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateSumCurrency', @TestBuiltins_TestFunctionAggregateSumCurrency, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateCount', @TestBuiltins_TestFunctionAggregateCount, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateAvg', @TestBuiltins_TestFunctionAggregateAvg, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateMin', @TestBuiltins_TestFunctionAggregateMin, 'expressions-aggregates');
  lSuite.AddTest('TestFunctionAggregateMax', @TestBuiltins_TestFunctionAggregateMax, 'expressions-aggregates');
end;

end.

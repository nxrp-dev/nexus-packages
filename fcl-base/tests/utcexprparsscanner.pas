unit utcExprParsScanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, math, fpexprpars;

procedure RegisterutcExprParsScannerTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo;

var
  FP: TFPExpressionScanner;

procedure TestExpressionScanner_SetUp(AContext: TNXTestContext);
begin

  FP := TFPExpressionScanner.Create;

end;

procedure TestExpressionScanner_TearDown(AContext: TNXTestContext);
begin

  FreeAndNil(FP);
end;

procedure AssertEqualsToken(AContext: TNXTestContext; Msg: String; AExpected, AActual: TTokenType);
var
  S1, S2: String;
begin
  S1 := TokenName(AExpected);
  S2 := GetEnumName(TypeInfo(TTokenType), Ord(AActual));
  AContext.AssertTrue((S1) = (S2), Msg);
end;

procedure TestString(AContext: TNXTestContext; const AString: String; AToken: TTokenType);
begin
  FP.Source := AString;
  AssertEqualsToken(AContext, 'String "' + AString + '" results in token ' + TokenName(AToken), AToken, FP.GetToken);
  if not (FP.TokenType in [ttString, ttEOF]) then
    AContext.AssertTrue((AString) = (FP.Token), 'String "' + AString + '" results in token string ' + TokenName(AToken))
  else if FP.TokenType = ttString then
    AContext.AssertTrue((StringReplace(AString, '''''', '''', [rfReplaceAll])) = ('''' + FP.Token + ''''), 'String "' + AString + '" results in token string ' + TokenName(AToken));
end;

procedure TestExpressionScanner_TestCreate(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    AContext.AssertTrue(('') = (FP.Source), 'Empty source');
    AContext.AssertTrue((0) = (FP.Pos), 'Pos is zero');
    AContext.AssertTrue((#0) = (FP.CurrentChar), 'CurrentChar is zero');
    AssertEqualsToken(AContext, 'Current token type is EOF', ttEOF, FP.TokenType);
    AContext.AssertTrue(('') = (FP.Token), 'Current token is empty');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure TestExpressionScanner_TestSetSource(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    FP.Source := 'Abc';
    FP.Source := '';
    AContext.AssertTrue(('') = (FP.Source), 'Empty source');
    AContext.AssertTrue((0) = (FP.Pos), 'Pos is zero');
    AContext.AssertTrue((#0) = (FP.CurrentChar), 'CurrentChar is zero');
    AssertEqualsToken(AContext, 'Current token type is EOF', ttEOF, FP.TokenType);
    AContext.AssertTrue(('') = (FP.Token), 'Current token is empty');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure TestExpressionScanner_TestWhiteSpace(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    TestString(AContext, '  ', ttEOF);
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure TestExpressionScanner_TestTokens(AContext: TNXTestContext);
const
  TestStrings: array[TTokenType] of String =
    ('+', '-', '<', '>', '=', '/',
    'mod', '*', '(', ')', '<=',
    '>=', '<>', '1', '''abc''', 'abc',
    ',', 'and', 'or', 'xor', 'true', 'false', 'not',
    'if', 'case', '^', '');
var
  t: TTokenType;
begin
  try
    TestExpressionScanner_SetUp(AContext);

    for t := Low(TTokenType) to High(TTokenType) do
      TestString(AContext, TestStrings[t], t);
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure DoInvalidNumber(AString: String);
begin
  FP.Source := AString;
  while FP.GetToken <> ttEOF do ;
end;


procedure DoTestInvalidNumberGG;
begin
  DoInvalidNumber('$GG');
end;

procedure DoTestInvalidNumber88;
begin
  DoInvalidNumber('&88');
end;

procedure DoTestInvalidNumber22;
begin
  DoInvalidNumber('%22');
end;

procedure DoTestInvalidNumber11;
begin
  DoInvalidNumber('1..1');
end;

procedure DoTestInvalidNumber1E;
begin
  DoInvalidNumber('1.E--1');
end;

procedure TestExpressionScanner_TestNumber(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    TestString(AContext, '123', ttNumber);
    TestString(AContext, '$FF', ttNumber);
    TestString(AContext, '&77', ttNumber);
    TestString(AContext, '%11111111', ttNumber);
    TestString(AContext, '123.4', ttNumber);
    TestString(AContext, '123.E4', ttNumber);
    TestString(AContext, '1.E4', ttNumber);
    TestString(AContext, '1e-2', ttNumber);
    AContext.AssertRaises(EExprScanner, @DoTestInvalidNumberGG, 'Invalid number "$GG"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidNumber88, 'Invalid number "&88"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidNumber22, 'Invalid number "%22"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidNumber11, 'Invalid number "1..1"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidNumber1E, 'Invalid number "1.E--1"');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure DoTestInvalidCharTilde;
begin
  DoInvalidNumber('~');
end;

procedure DoTestInvalidCharHash;
begin
  DoInvalidNumber('#');
end;

procedure DoTestInvalidCharDollar;
begin
  DoInvalidNumber('$');
end;

procedure TestExpressionScanner_TestInvalidCharacter(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    AContext.AssertRaises(EExprScanner, @DoTestInvalidCharTilde, 'Invalid character "~"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidCharHash, 'Invalid character "#"');
    AContext.AssertRaises(EExprScanner, @DoTestInvalidCharDollar, 'Invalid character "$"');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure DoTestUnterminatedString;
begin
  DoInvalidNumber('''abc');
end;

procedure TestExpressionScanner_TestUnterminatedString(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    AContext.AssertRaises(EExprScanner, @DoTestUnterminatedString, 'Unterminated string');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure TestExpressionScanner_TestQuotesInString(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    TestString(AContext, '''That''''s it''', ttString);
    TestString(AContext, '''''''s it''', ttString);
    TestString(AContext, '''s it''''''', ttString);
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure TestIdentifier(AContext: TNXTestContext; const ASource, ATokenName: String);
begin
  FP.Source := ASource;
  AssertEqualsToken(AContext, 'Token type', ttIdentifier, FP.GetToken);
  AContext.AssertTrue((ATokenName) = (FP.Token), 'Token name');
end;

procedure TestExpressionScanner_TestIdentifiers(AContext: TNXTestContext);
begin
  try
    TestExpressionScanner_SetUp(AContext);

    TestIdentifier(AContext, 'a', 'a');
    TestIdentifier(AContext, ' a', 'a');
    TestIdentifier(AContext, 'a ', 'a');
    TestIdentifier(AContext, 'a^b', 'a');
    TestIdentifier(AContext, 'a-b', 'a');
    TestIdentifier(AContext, 'a.b', 'a.b');
    TestIdentifier(AContext, '"a b"', 'a b');
    TestIdentifier(AContext, 'c."a b"', 'c.a b');
    TestIdentifier(AContext, 'c."ab"', 'c.ab');
  finally
    TestExpressionScanner_TearDown(AContext);
  end;
end;

procedure RegisterutcExprParsScannerTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Expressions.TExpressionScannerTests');
  lSuite.AddTest('TestCreate', @TestExpressionScanner_TestCreate, 'expressions');
  lSuite.AddTest('TestSetSource', @TestExpressionScanner_TestSetSource, 'expressions');
  lSuite.AddTest('TestWhiteSpace', @TestExpressionScanner_TestWhiteSpace, 'expressions');
  lSuite.AddTest('TestTokens', @TestExpressionScanner_TestTokens, 'expressions');
  lSuite.AddTest('TestNumber', @TestExpressionScanner_TestNumber, 'expressions');
  lSuite.AddTest('TestInvalidCharacter', @TestExpressionScanner_TestInvalidCharacter, 'expressions');
  lSuite.AddTest('TestUnterminatedString', @TestExpressionScanner_TestUnterminatedString, 'expressions');
  lSuite.AddTest('TestQuotesInString', @TestExpressionScanner_TestQuotesInString, 'expressions');
  lSuite.AddTest('TestIdentifiers', @TestExpressionScanner_TestIdentifiers, 'expressions');
end;

end.

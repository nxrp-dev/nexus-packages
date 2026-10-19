unit utcExprParsParser;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterutcExprParsParserTests(ARegistry: TNXTestRegistry);
implementation
uses SysUtils, fpexprpars, obNXTestContext;

procedure NumericLiterals(AContext: TNXTestContext);
var lParser: TFPExpressionParser;
begin
  lParser := TFPExpressionParser.Create(nil);
  try
    lParser.Expression := '123';
    AContext.AssertTrue(lParser.AsInteger = 123, 'Integer literal evaluation');
    lParser.Expression := '123.456';
    AContext.AssertTrue(Abs(lParser.AsFloat - 123.456) <= 1E-9,
      'Float literal evaluation');
  finally
    lParser.Free;
  end;
end;

procedure RegisterutcExprParsParserTests(ARegistry: TNXTestRegistry);
begin
  ARegistry.AddSuite('FCL.Expressions.Parser').AddTest('NumericLiterals',
    @NumericLiterals, 'expressions-parser');
end;
end.

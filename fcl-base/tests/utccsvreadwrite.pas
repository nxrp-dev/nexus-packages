unit utcCSVReadWrite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, csvreadwrite;

procedure RegisterutcCSVReadWriteTests(ARegistry: TNXTestRegistry);

implementation

var
  FData: TStrings;
  FParser: TCSVParser;

procedure HaveNext(AContext: TNXTestContext; ARow, ACol: integer; AValue: String);
var
  CN: String;
begin
  CN := Format('Cell(row: %d, col: %d)', [ARow, ACol]);
  AContext.AssertTrue(FParser.ParseNextCell, 'Have ' + CN);
  AContext.AssertTrue((ARow) = (FParser.CurrentRow), CN + ': Row matches');
  AContext.AssertTrue((ACol) = (FParser.CurrentCol), CN + ': Col matches');
  AContext.AssertTrue((AValue) = (FParser.CurrentCellText), CN + ': Value');
end;

procedure AssertLine(AContext: TNXTestContext; ARow: Integer; const AValues: array of String);
var
  I: Integer;
begin
  for I := 0 to High(AValues) do
    HaveNext(AContext, ARow, I, AValues[I]);
end;

procedure Setup(AContext: TNXTestContext);
begin

  if Assigned(FParser) then
    FParser.Free;
  FParser := TCSVParser.Create;
  if Assigned(FData) then
    FData.Free;
  FData := TStringList.Create;
end;

procedure TearDown(AContext: TNXTestContext);
begin

  FreeAndNil(FData);
  FreeAndNil(FParser);
end;

procedure TCSVReadWrite_TestEmpty(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    AContext.AssertTrue((FParser) <> nil, 'Have parser');
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_TestNormalLine(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('this,is,a,normal,line');
    AssertLine(AContext, 0, ['this', 'is', 'a', 'normal', 'line']);
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_TestQuotedLine(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('"this","is","a","quoted","line"');
    AssertLine(AContext, 0, ['this', 'is', 'a', 'quoted', 'line']);
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_TestInlineQuotedLine(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('"this","line",has,mixed" quoting"');
    AssertLine(AContext, 0, ['this', 'line', 'has', 'mixed quoting']);
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_TestQuotedNewLine(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('"this","line",has,"an embedded' + LineEnding + 'newline"');
    AssertLine(AContext, 0, ['this', 'line', 'has', 'an embedded' + LineEnding + 'newline']);
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_Test2Lines(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('"this","line",has,an embedded' + LineEnding + 'newline');
    AssertLine(AContext, 0, ['this', 'line', 'has', 'an embedded']);
    AssertLine(AContext, 1, ['newline']);
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVReadWrite_TestEscapedQuotes(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    FParser.SetSource('"this","line",has,"an embedded "" quote"');
    AssertLine(AContext, 0, ['this', 'line', 'has', 'an embedded " quote']);
  finally
    TearDown(AContext);
  end;
end;

procedure RegisterutcCSVReadWriteTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Text.TCSVReadWriteTests');
  lSuite.AddTest('TestEmpty', @TCSVReadWrite_TestEmpty, 'text');
  lSuite.AddTest('TestNormalLine', @TCSVReadWrite_TestNormalLine, 'text');
  lSuite.AddTest('TestQuotedLine', @TCSVReadWrite_TestQuotedLine, 'text');
  lSuite.AddTest('TestInlineQuotedLine', @TCSVReadWrite_TestInlineQuotedLine, 'text');
  lSuite.AddTest('TestQuotedNewLine', @TCSVReadWrite_TestQuotedNewLine, 'text');
  lSuite.AddTest('Test2Lines', @TCSVReadWrite_Test2Lines, 'text');
  lSuite.AddTest('TestEscapedQuotes', @TCSVReadWrite_TestEscapedQuotes, 'text');
end;

end.

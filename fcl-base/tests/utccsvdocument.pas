unit utcCSVDocument;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, csvdocument;

procedure RegisterutcCSVDocumentTests(ARegistry: TNXTestRegistry);

implementation

const
  TestFileName = 'test.csv';
  ColCount = 3;
  RowCount = 4;

type
  TRow = array[0..ColCount-1] of String;
  TCells = array[0..RowCount-1] of TRow;

const
  Cells : TCells = (
    ('a','b','c'),
    ('1','"one"','1.1'),
    ('2','"two"','2.2'),
    ('3','"three"','3.3')
  );

var
  FDoc: TCSVDocument;

procedure RemoveTestFile;
begin
  if FileExists(TestFileName) then
    DeleteFile(TestFileName);
end;

function StripQuotes(S: String): String;
var
  L: integer;
begin
  Result := S;
  L := Length(Result);
  if (L > 1) and (Result[1] = '"') and (Result[L] = '"') then
    Result := Copy(Result, 2, L - 2);
end;

procedure CreateTestFile;
var
  L: TStringList;
  R, C: Integer;
  S: String;
begin
  L := TStringList.Create;
  try
    for R := 0 to RowCount - 1 do
    begin
      S := '';
      for C := 0 to ColCount - 1 do
      begin
        if S <> '' then
          S := S + ',';
        S := S + Cells[R, C];
      end;
      L.Add(S);
    end;
    L.SaveToFile(TestFileName);
  finally
    L.Free;
  end;
end;

procedure TestTheFile(AContext: TNXTestContext);
var
  R, C: Integer;
begin
  AContext.AssertTrue((RowCount) = (FDoc.RowCount), 'Row count');
  for R := 0 to RowCount - 1 do
    for C := 0 to ColCount - 1 do
    begin
      AContext.AssertTrue((ColCount) = (FDoc.ColCount[R]), 'Col[' + IntToStr(R) + '] count');
      AContext.AssertTrue((StripQuotes(Cells[R, C])) = (FDoc.Cells[C, R]), Format('Cell[%d,%d]', [C, R]));
    end;
end;

procedure Setup(AContext: TNXTestContext);
begin

  FDoc := TCSVDocument.Create;
end;

procedure TearDown(AContext: TNXTestContext);
begin

  RemoveTestFile;
  FreeAndNil(FDoc);
end;

procedure TCSVDocument_TestEmpty(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    AContext.AssertTrue((FDoc) <> nil, 'Have document');
  finally
    TearDown(AContext);
  end;
end;

procedure TCSVDocument_TestRead(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    CreateTestFile;
    FDoc.LoadFromFile(TestFileName);
    TestTheFile(AContext);
  finally
    TearDown(AContext);
  end;
end;

procedure RegisterutcCSVDocumentTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Text.TCSVDocumentTests');
  lSuite.AddTest('TestEmpty', @TCSVDocument_TestEmpty, 'text');
  lSuite.AddTest('TestRead', @TCSVDocument_TestRead, 'text');
end;

end.

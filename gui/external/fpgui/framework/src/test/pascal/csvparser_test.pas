{
    CSV Parser unit tests
}
unit CsvParser_Test;

{$mode objfpc}{$H+}

interface
uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes
  ,SysUtils
  ,fpg_csvparser
  //,TestFramework
  ;


type
  TTestCSVParser= class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FParser: TCsvParser;
    FFieldList: TStringList;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    procedure BadChar;
    procedure MissingQuote;
  public
    procedure TestExtractFields;
    procedure TestBadChar;
    procedure TestMissingQuote;
  end;


procedure RegisterCsvParserTestTests(ARegistry: TNXTestRegistry);

implementation

uses
  StrUtils
  ;

procedure RegisterTests;
begin
  //AddToNonPersistentTestSuite(TTestCSVParser);
  
end;


procedure TTestCSVParser.SetUp;
begin
  FParser    := TCsvParser.Create;
  FFieldList := TStringList.Create;
end;


procedure TTestCSVParser.TearDown;
begin
  FParser.Free;
  FFieldList.Free;
end;


procedure TTestCSVParser.BadChar;
const
  TestLine = '"This is a bad string"see?';
begin
  FParser.ExtractFields(TestLine,FFieldList);
end;


procedure TTestCSVParser.MissingQuote;
const
  TestLine = '"This is a line with a missing quote';
begin
  FParser.ExtractFields(TestLine,FFieldList);
end;


procedure TTestCSVParser.TestExtractFields;
const
  Field1   = '123';
  Field2   = '"Field with comma, in it"';
  Field3   = '';
  Field4   = 'LastField';
  TestLine = Field1 + ',' + Field2 + ',' + Field3 + ',' + Field4;
begin
  FParser.ExtractFields(TestLine,FFieldList);
  FContext.AssertTrue((Field1)=(FFieldList[0]), 'Failing on 1');
  { Remove quotes to test Field2 - parser remove outer double quotes }
  FContext.AssertTrue((MidStr(Field2, 2, Length(Field2)-2))=(FFieldList[1]), 'Failing on 2');
  FContext.AssertTrue((Field3)=(FFieldList[2]), 'Failing on 3');
  FContext.AssertTrue((Field4)=(FFieldList[3]), 'Failing on 4');
end;


procedure TTestCSVParser.TestBadChar;
begin
  FContext.AssertRaises(Exception, @BadChar, 'Did not raise exception for extra chars after end quote');
end;


procedure TTestCSVParser.TestMissingQuote;
begin
  FContext.AssertRaises(Exception, @MissingQuote, 'Did not raise exception for missing quote');
end;

procedure RunTTestCSVParserTestExtractFields(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractFields';
    lFixture.SetUp;
    try lFixture.TestExtractFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCSVParserTestBadChar(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBadChar';
    lFixture.SetUp;
    try lFixture.TestBadChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCSVParserTestMissingQuote(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMissingQuote';
    lFixture.SetUp;
    try lFixture.TestMissingQuote; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisterCsvParserTestTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('CsvParser_Test.TTestCSVParser');
  lSuite.AddTest('TestExtractFields', @RunTTestCSVParserTestExtractFields);
  lSuite.AddTest('TestBadChar', @RunTTestCSVParserTestBadChar);
  lSuite.AddTest('TestMissingQuote', @RunTTestCSVParserTestMissingQuote);
end;



initialization
  RegisterTests;

end.


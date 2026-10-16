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
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
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
  TestContext.AssertTrue((Field1)=(FFieldList[0]), 'Failing on 1');
  { Remove quotes to test Field2 - parser remove outer double quotes }
  TestContext.AssertTrue((MidStr(Field2, 2, Length(Field2)-2))=(FFieldList[1]), 'Failing on 2');
  TestContext.AssertTrue((Field3)=(FFieldList[2]), 'Failing on 3');
  TestContext.AssertTrue((Field4)=(FFieldList[3]), 'Failing on 4');
end;


procedure TTestCSVParser.TestBadChar;
begin
  TestContext.AssertRaises(Exception, @BadChar, 'Did not raise exception for extra chars after end quote');
end;


procedure TTestCSVParser.TestMissingQuote;
begin
  TestContext.AssertRaises(Exception, @MissingQuote, 'Did not raise exception for missing quote');
end;

constructor TTestCSVParser.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestCSVParserTestExtractFields(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create(AContext, 'TestExtractFields');
  try
    lFixture.SetUp;
    try lFixture.TestExtractFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCSVParserTestBadChar(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create(AContext, 'TestBadChar');
  try
    lFixture.SetUp;
    try lFixture.TestBadChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCSVParserTestMissingQuote(AContext: TNXTestContext);
var lFixture: TTestCSVParser;
begin
  lFixture:=TTestCSVParser.Create(AContext, 'TestMissingQuote');
  try
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



end.


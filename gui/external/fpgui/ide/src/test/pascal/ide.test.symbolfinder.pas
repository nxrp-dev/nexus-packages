{
    fpGUI IDE - Symbol Finder Tests

    Tests for symbol extraction and fuzzy filtering logic used by
    the Navigate to Symbol dialog (Ctrl+N).
}
unit ide.test.symbolfinder;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.filefinder,
  ide.symbolfinder;

type

  { TTestScanSourceForSymbols }

  TTestScanSourceForSymbols = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FSymbols: TSymbolEntryArray;
    procedure ScanSource(const ASource: string);
    function FindSymbol(const AName: string): Integer;
  public
    procedure TestExtractProcedure;
    procedure TestExtractFunction;
    procedure TestExtractClassType;
    procedure TestExtractRecordType;
    procedure TestExtractEnumType;
    procedure TestExtractConst;
    procedure TestExtractVar;
    procedure TestExtractMultipleSymbols;
    procedure TestIgnoresImplementation;
    procedure TestClassMethods;
    procedure TestConstructorDestructor;
    procedure TestProgramFile;
    procedure TestEmptySource;
    procedure TestLineNumbers;
  end;

  { TTestFilterSymbols }

  TTestFilterSymbols = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FSymbols: TSymbolEntryArray;
    function MakeSymbol(const AName: string; AKind: TSymbolKind;
      ALine: Integer): TSymbolEntry;
    procedure SetupTestSymbols;
  protected
    procedure SetUp; virtual;
  public
    procedure TestFilterByName;
    procedure TestFilterCamelCase;
    procedure TestFilterEmptyReturnsAll;
    procedure TestFilterNoMatch;
    procedure TestFilterSortedByScore;
  end;

  { TTestSymbolKindToStr }

  TTestSymbolKindToStr = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestAllKinds;
  end;


procedure RegisteridetestsymbolfinderTests(ARegistry: TNXTestRegistry);

implementation

{ TTestScanSourceForSymbols }

procedure TTestScanSourceForSymbols.ScanSource(const ASource: string);
begin
  SetLength(FSymbols, 0);
  ScanSourceForSymbols(ASource, 'test.pas', FSymbols);
end;

function TTestScanSourceForSymbols.FindSymbol(const AName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FSymbols) do
    if FSymbols[i].Name = AName then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

procedure TTestScanSourceForSymbols.TestExtractProcedure;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'procedure DoSomething;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(Length(FSymbols) >= 1, Format('Expected at least 1 symbol, got %d', [Length(FSymbols)]));
  FContext.AssertTrue(('DoSomething')=(FSymbols[FindSymbol('DoSomething')].Name), '');
  FContext.AssertTrue(FSymbols[FindSymbol('DoSomething')].Kind = skProcedure, 'Should be skProcedure');
end;

procedure TTestScanSourceForSymbols.TestExtractFunction;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'function GetValue: Integer;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('GetValue') >= 0, 'Should find GetValue');
  FContext.AssertTrue(FSymbols[FindSymbol('GetValue')].Kind = skFunction, 'Should be skFunction');
end;

procedure TTestScanSourceForSymbols.TestExtractClassType;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TMyClass = class(TObject)' + LineEnding +
    '  end;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('TMyClass') >= 0, 'Should find TMyClass');
  FContext.AssertTrue(FSymbols[FindSymbol('TMyClass')].Kind = skType, 'Should be skType');
end;

procedure TTestScanSourceForSymbols.TestExtractRecordType;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TPoint = record' + LineEnding +
    '    X, Y: Integer;' + LineEnding +
    '  end;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('TPoint') >= 0, 'Should find TPoint');
  FContext.AssertTrue(FSymbols[FindSymbol('TPoint')].Kind = skType, 'Should be skType');
end;

procedure TTestScanSourceForSymbols.TestExtractEnumType;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TColor = (clRed, clGreen, clBlue);' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('TColor') >= 0, 'Should find TColor');
  FContext.AssertTrue(FSymbols[FindSymbol('TColor')].Kind = skType, 'Should be skType');
end;

procedure TTestScanSourceForSymbols.TestExtractConst;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'const' + LineEnding +
    '  MaxItems = 100;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('MaxItems') >= 0, 'Should find MaxItems');
  FContext.AssertTrue(FSymbols[FindSymbol('MaxItems')].Kind = skConst, 'Should be skConst');
end;

procedure TTestScanSourceForSymbols.TestExtractVar;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'var' + LineEnding +
    '  GlobalCount: Integer;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('GlobalCount') >= 0, 'Should find GlobalCount');
  FContext.AssertTrue(FSymbols[FindSymbol('GlobalCount')].Kind = skVar, 'Should be skVar');
end;

procedure TTestScanSourceForSymbols.TestExtractMultipleSymbols;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TFoo = class' + LineEnding +
    '  end;' + LineEnding +
    'const' + LineEnding +
    '  Version = 1;' + LineEnding +
    'procedure Init;' + LineEnding +
    'function Done: Boolean;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('TFoo') >= 0, 'Should find TFoo');
  FContext.AssertTrue(FindSymbol('Version') >= 0, 'Should find Version');
  FContext.AssertTrue(FindSymbol('Init') >= 0, 'Should find Init');
  FContext.AssertTrue(FindSymbol('Done') >= 0, 'Should find Done');
  FContext.AssertTrue(Length(FSymbols) >= 4, Format('Expected at least 4 symbols, got %d', [Length(FSymbols)]));
end;

procedure TTestScanSourceForSymbols.TestIgnoresImplementation;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'procedure PublicProc;' + LineEnding +
    'implementation' + LineEnding +
    'procedure PrivateProc;' + LineEnding +
    'begin end;' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('PublicProc') >= 0, 'Should find PublicProc');
  FContext.AssertTrue(FindSymbol('PrivateProc') < 0, 'Should NOT find PrivateProc');
end;

procedure TTestScanSourceForSymbols.TestClassMethods;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TFoo = class' + LineEnding +
    '    procedure Bar;' + LineEnding +
    '    function Baz: Integer;' + LineEnding +
    '  end;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('TFoo') >= 0, 'Should find TFoo');
  { Class methods should appear with qualified display name }
  FContext.AssertTrue(FindSymbol('Bar') >= 0, 'Should find Bar');
  FContext.AssertTrue(FSymbols[FindSymbol('Bar')].DisplayName = 'TFoo.Bar', 'DisplayName should be TFoo.Bar');
end;

procedure TTestScanSourceForSymbols.TestConstructorDestructor;
begin
  ScanSource(
    'unit test;' + LineEnding +
    'interface' + LineEnding +
    'type' + LineEnding +
    '  TFoo = class' + LineEnding +
    '    constructor Create;' + LineEnding +
    '    destructor Destroy; override;' + LineEnding +
    '  end;' + LineEnding +
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('Create') >= 0, 'Should find Create');
  FContext.AssertTrue(FSymbols[FindSymbol('Create')].Kind = skConstructor, 'Should be skConstructor');
  FContext.AssertTrue(FindSymbol('Destroy') >= 0, 'Should find Destroy');
  FContext.AssertTrue(FSymbols[FindSymbol('Destroy')].Kind = skDestructor, 'Should be skDestructor');
end;

procedure TTestScanSourceForSymbols.TestProgramFile;
begin
  ScanSource(
    'program test;' + LineEnding +
    'procedure DoWork;' + LineEnding +
    'begin end;' + LineEnding +
    'begin' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('DoWork') >= 0, 'Program files should still extract top-level procedures');
end;

procedure TTestScanSourceForSymbols.TestEmptySource;
begin
  ScanSource('');
  FContext.AssertTrue((0)=(Length(FSymbols)), 'Empty source should produce no symbols');
end;

procedure TTestScanSourceForSymbols.TestLineNumbers;
begin
  ScanSource(
    'unit test;' + LineEnding +       { line 1 }
    'interface' + LineEnding +         { line 2 }
    'procedure First;' + LineEnding +  { line 3 }
    'procedure Second;' + LineEnding + { line 4 }
    'implementation' + LineEnding +
    'end.');
  FContext.AssertTrue(FindSymbol('First') >= 0, 'Should find First');
  FContext.AssertTrue((3)=(FSymbols[FindSymbol('First')].Line), 'First should be on line 3');
  FContext.AssertTrue(FindSymbol('Second') >= 0, 'Should find Second');
  FContext.AssertTrue((4)=(FSymbols[FindSymbol('Second')].Line), 'Second should be on line 4');
end;

{ TTestFilterSymbols }

function TTestFilterSymbols.MakeSymbol(const AName: string;
  AKind: TSymbolKind; ALine: Integer): TSymbolEntry;
begin
  Result.Name := AName;
  Result.DisplayName := AName;
  Result.Kind := AKind;
  Result.FileName := 'test.pas';
  Result.RelativePath := 'src/';
  Result.FullPath := '/project/src/test.pas';
  Result.Line := ALine;
end;

procedure TTestFilterSymbols.SetupTestSymbols;
begin
  SetLength(FSymbols, 5);
  FSymbols[0] := MakeSymbol('TMainForm', skType, 10);
  FSymbols[1] := MakeSymbol('DoSomething', skProcedure, 20);
  FSymbols[2] := MakeSymbol('GetMainValue', skFunction, 30);
  FSymbols[3] := MakeSymbol('MaxCount', skConst, 5);
  FSymbols[4] := MakeSymbol('Initialize', skProcedure, 40);
end;

procedure TTestFilterSymbols.SetUp;
begin
  SetupTestSymbols;
end;

procedure TTestFilterSymbols.TestFilterByName;
var
  Results: TFilteredSymbolArray;
begin
  Results := FilterSymbolsEx('DoSome', FSymbols);
  FContext.AssertTrue(Length(Results) >= 1, 'Should match at least 1 symbol');
  FContext.AssertTrue(('DoSomething')=(Results[0].Entry.Name), '');
end;

procedure TTestFilterSymbols.TestFilterCamelCase;
var
  Results: TFilteredSymbolArray;
begin
  Results := FilterSymbolsEx('MF', FSymbols);
  FContext.AssertTrue(Length(Results) >= 1, 'Should match at least 1 symbol for "MF"');
  FContext.AssertTrue(('TMainForm')=(Results[0].Entry.Name), 'TMainForm should match "MF" via word-start');
end;

procedure TTestFilterSymbols.TestFilterEmptyReturnsAll;
var
  Results: TFilteredSymbolArray;
begin
  Results := FilterSymbolsEx('', FSymbols);
  FContext.AssertTrue((Length(FSymbols))=(Length(Results)), 'Empty pattern should return all symbols');
end;

procedure TTestFilterSymbols.TestFilterNoMatch;
var
  Results: TFilteredSymbolArray;
begin
  Results := FilterSymbolsEx('zzzzz', FSymbols);
  FContext.AssertTrue((0)=(Length(Results)), 'Non-matching pattern should return empty');
end;

procedure TTestFilterSymbols.TestFilterSortedByScore;
var
  Results: TFilteredSymbolArray;
begin
  Results := FilterSymbolsEx('Main', FSymbols);
  FContext.AssertTrue(Length(Results) >= 2, 'Should match at least 2 symbols');
  { TMainForm should score higher than GetMainValue (prefix vs substring) }
  FContext.AssertTrue(('TMainForm')=(Results[0].Entry.Name), 'TMainForm should rank first (prefix match)');
end;

{ TTestSymbolKindToStr }

procedure TTestSymbolKindToStr.TestAllKinds;
begin
  FContext.AssertTrue(('procedure')=(SymbolKindToStr(skProcedure)), '');
  FContext.AssertTrue(('function')=(SymbolKindToStr(skFunction)), '');
  FContext.AssertTrue(('constructor')=(SymbolKindToStr(skConstructor)), '');
  FContext.AssertTrue(('destructor')=(SymbolKindToStr(skDestructor)), '');
  FContext.AssertTrue(('type')=(SymbolKindToStr(skType)), '');
  FContext.AssertTrue(('const')=(SymbolKindToStr(skConst)), '');
  FContext.AssertTrue(('var')=(SymbolKindToStr(skVar)), '');
  FContext.AssertTrue(('property')=(SymbolKindToStr(skProperty)), '');
end;



procedure RunTTestScanSourceForSymbolsTestExtractProcedure(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractProcedure';
    lFixture.TestExtractProcedure;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractFunction(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractFunction';
    lFixture.TestExtractFunction;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractClassType(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractClassType';
    lFixture.TestExtractClassType;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractRecordType(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractRecordType';
    lFixture.TestExtractRecordType;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractEnumType(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractEnumType';
    lFixture.TestExtractEnumType;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractConst(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractConst';
    lFixture.TestExtractConst;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractVar(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractVar';
    lFixture.TestExtractVar;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestExtractMultipleSymbols(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtractMultipleSymbols';
    lFixture.TestExtractMultipleSymbols;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestIgnoresImplementation(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIgnoresImplementation';
    lFixture.TestIgnoresImplementation;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestClassMethods(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClassMethods';
    lFixture.TestClassMethods;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestConstructorDestructor(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConstructorDestructor';
    lFixture.TestConstructorDestructor;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestProgramFile(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestProgramFile';
    lFixture.TestProgramFile;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestEmptySource(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptySource';
    lFixture.TestEmptySource;
  finally lFixture.Free; end;
end;

procedure RunTTestScanSourceForSymbolsTestLineNumbers(AContext: TNXTestContext);
var lFixture: TTestScanSourceForSymbols;
begin
  lFixture:=TTestScanSourceForSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineNumbers';
    lFixture.TestLineNumbers;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterSymbolsTestFilterByName(AContext: TNXTestContext);
var lFixture: TTestFilterSymbols;
begin
  lFixture:=TTestFilterSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterByName';
    lFixture.SetUp;
    lFixture.TestFilterByName;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterSymbolsTestFilterCamelCase(AContext: TNXTestContext);
var lFixture: TTestFilterSymbols;
begin
  lFixture:=TTestFilterSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterCamelCase';
    lFixture.SetUp;
    lFixture.TestFilterCamelCase;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterSymbolsTestFilterEmptyReturnsAll(AContext: TNXTestContext);
var lFixture: TTestFilterSymbols;
begin
  lFixture:=TTestFilterSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterEmptyReturnsAll';
    lFixture.SetUp;
    lFixture.TestFilterEmptyReturnsAll;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterSymbolsTestFilterNoMatch(AContext: TNXTestContext);
var lFixture: TTestFilterSymbols;
begin
  lFixture:=TTestFilterSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterNoMatch';
    lFixture.SetUp;
    lFixture.TestFilterNoMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestFilterSymbolsTestFilterSortedByScore(AContext: TNXTestContext);
var lFixture: TTestFilterSymbols;
begin
  lFixture:=TTestFilterSymbols.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFilterSortedByScore';
    lFixture.SetUp;
    lFixture.TestFilterSortedByScore;
  finally lFixture.Free; end;
end;

procedure RunTTestSymbolKindToStrTestAllKinds(AContext: TNXTestContext);
var lFixture: TTestSymbolKindToStr;
begin
  lFixture:=TTestSymbolKindToStr.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAllKinds';
    lFixture.TestAllKinds;
  finally lFixture.Free; end;
end;

procedure RegisteridetestsymbolfinderTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.symbolfinder.TTestScanSourceForSymbols');
  lSuite.AddTest('TestExtractProcedure', @RunTTestScanSourceForSymbolsTestExtractProcedure);
  lSuite.AddTest('TestExtractFunction', @RunTTestScanSourceForSymbolsTestExtractFunction);
  lSuite.AddTest('TestExtractClassType', @RunTTestScanSourceForSymbolsTestExtractClassType);
  lSuite.AddTest('TestExtractRecordType', @RunTTestScanSourceForSymbolsTestExtractRecordType);
  lSuite.AddTest('TestExtractEnumType', @RunTTestScanSourceForSymbolsTestExtractEnumType);
  lSuite.AddTest('TestExtractConst', @RunTTestScanSourceForSymbolsTestExtractConst);
  lSuite.AddTest('TestExtractVar', @RunTTestScanSourceForSymbolsTestExtractVar);
  lSuite.AddTest('TestExtractMultipleSymbols', @RunTTestScanSourceForSymbolsTestExtractMultipleSymbols);
  lSuite.AddTest('TestIgnoresImplementation', @RunTTestScanSourceForSymbolsTestIgnoresImplementation);
  lSuite.AddTest('TestClassMethods', @RunTTestScanSourceForSymbolsTestClassMethods);
  lSuite.AddTest('TestConstructorDestructor', @RunTTestScanSourceForSymbolsTestConstructorDestructor);
  lSuite.AddTest('TestProgramFile', @RunTTestScanSourceForSymbolsTestProgramFile);
  lSuite.AddTest('TestEmptySource', @RunTTestScanSourceForSymbolsTestEmptySource);
  lSuite.AddTest('TestLineNumbers', @RunTTestScanSourceForSymbolsTestLineNumbers);
  lSuite:=ARegistry.AddSuite('ide.test.symbolfinder.TTestFilterSymbols');
  lSuite.AddTest('TestFilterByName', @RunTTestFilterSymbolsTestFilterByName);
  lSuite.AddTest('TestFilterCamelCase', @RunTTestFilterSymbolsTestFilterCamelCase);
  lSuite.AddTest('TestFilterEmptyReturnsAll', @RunTTestFilterSymbolsTestFilterEmptyReturnsAll);
  lSuite.AddTest('TestFilterNoMatch', @RunTTestFilterSymbolsTestFilterNoMatch);
  lSuite.AddTest('TestFilterSortedByScore', @RunTTestFilterSymbolsTestFilterSortedByScore);
  lSuite:=ARegistry.AddSuite('ide.test.symbolfinder.TTestSymbolKindToStr');
  lSuite.AddTest('TestAllKinds', @RunTTestSymbolKindToStrTestAllKinds);
end;

end.
